#!/bin/bash
# apply-dashboard.sh
# Applies ui-mode-dashboard.yaml back to Home Assistant via the REST API
#
# Usage: ./apply-dashboard.sh
#
# Requirements:
#   - HA_TOKEN: Long-lived access token from HA
#   - HA_URL: Your Home Assistant URL
#
# Setup: Add these to your ~/.zshrc or ~/.bashrc:
#   export HA_URL="http://homeassistant.local:8123"
#   export HA_TOKEN="your_long_lived_token_here"

set -e

DASHBOARD_FILE="$(dirname "$0")/ui-mode-dashboard.yaml"
DASHBOARD_URL_PATH="ui-mode"

# Check dependencies
if ! command -v python3 &>/dev/null; then
  echo "❌ python3 is required"
  exit 1
fi

if ! python3 -c "import yaml" &>/dev/null; then
  echo "❌ PyYAML is required: pip3 install pyyaml"
  exit 1
fi

# Check env vars
if [ -z "$HA_TOKEN" ] || [ -z "$HA_URL" ]; then
  echo "❌ Set HA_TOKEN and HA_URL environment variables first."
  echo ""
  echo "Add to ~/.zshrc:"
  echo "  export HA_URL=\"http://homeassistant.local:8123\""
  echo "  export HA_TOKEN=\"your_long_lived_token\""
  exit 1
fi

# Check file exists
if [ ! -f "$DASHBOARD_FILE" ]; then
  echo "❌ Dashboard file not found: $DASHBOARD_FILE"
  exit 1
fi

echo "📂 Reading $DASHBOARD_FILE..."

# Convert YAML to JSON and POST to HA API
python3 << EOF
import yaml, json, urllib.request, urllib.error, os, sys

with open("$DASHBOARD_FILE", "r") as f:
    config = yaml.safe_load(f)

payload = json.dumps({"config": config}).encode("utf-8")

url = "${HA_URL}/api/lovelace/dashboards/${DASHBOARD_URL_PATH}/config"
req = urllib.request.Request(
    url,
    data=payload,
    method="POST",
    headers={
        "Authorization": "Bearer ${HA_TOKEN}",
        "Content-Type": "application/json",
    }
)

try:
    with urllib.request.urlopen(req) as resp:
        print(f"✅ Dashboard applied successfully! Status: {resp.status}")
except urllib.error.HTTPError as e:
    body = e.read().decode()
    print(f"❌ Failed: HTTP {e.code} - {body}", file=sys.stderr)
    sys.exit(1)
EOF
