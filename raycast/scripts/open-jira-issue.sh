#!/bin/bash
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open Jira Issue
# @raycast.mode compact
#
# Optional parameters:
#
# Documentation:
# @raycast.description Opens a Jira ticket from clipboard
# @raycast.author You
# @raycast.authorURL https://github.com/dRiott

input=$(pbpaste 2>/dev/null)

if [ -z "$input" ]; then
  echo "Clipboard is empty."
  exit 1
fi

# Extract DDR ticket number from input (e.g., "DDR-23854" from "DDR-23854-provenance-troubleshooting")
ticket=$(echo "$input" | grep -oE 'DDR-[0-9]+' | head -n 1)

if [ -z "$ticket" ]; then
  echo "No valid DDR ticket number found in input: $input"
  exit 1
fi

echo "Opening ticket: $ticket"
open https://cyberhaven.atlassian.net/browse/$ticket

# Wait for browser to focus, then refresh the page (Cmd+R)
sleep 1
osascript -e 'tell application "System Events" to keystroke "r" using command down'
