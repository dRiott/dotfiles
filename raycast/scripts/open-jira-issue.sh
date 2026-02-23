#!/bin/bash
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open Jira Issue
# @raycast.mode fullOutput
#
# Optional parameters:
# @raycast.argument1 { "type": "text", "placeholder": "Ticket Identifier" }
#
# Documentation:
# @raycast.description Opens ArgoCD UI for a given cluster
# @raycast.author You
# @raycast.authorURL https://github.com/dRiott

ticket="$1"

# Fallback if no input
if [ -z "$ticket" ]; then
  echo "No ticket provided."
  exit 1
fi

open https://cyberhaven.atlassian.net/browse/$ticket

echo "tell application \"System Events\" to key code 53" | osascript
