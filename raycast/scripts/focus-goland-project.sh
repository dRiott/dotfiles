#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Focus or Open Project
# @raycast.mode silent

# Optional parameters:
# @raycast.argument1 { "type": "text", "placeholder": "Alias (d, an, ed...)", "optional": false }

alias="$1"
basePath="$HOME/code"

case "$alias" in
  ed)     projectName="environments-definitions" ;;
  et)     projectName="environments-templates"   ;;
  d|df)   projectName="dataflow"                 ;;
  a|ad)   projectName="applications-definitions" ;;
  h|hc)   projectName="helm-charts"              ;;
  c|cv|v) projectName="charts-values"            ;;
  an)     projectName="anomaly-and-triage"       ;;
  *)
    echo "Unknown alias: $alias"
    exit 1
    ;;
esac

if [[ "$projectName" == "dataflow" || "$projectName" == "anomaly-and-triage" ]]; then
  appTarget="GoLand"
  openCmd="open -a \"GoLand\""
else
  appTarget="Zed"
  openCmd="open -a Zed" # Zed usually installs a CLI tool; if not, use 'open -a Zed'
fi

# 1. Try to find and focus the window via AppleScript
# We return "FOUND" or "NOT_FOUND" to the shell
status=$(osascript <<EOF
tell application "$appTarget" to activate
delay 0.3
tell application "System Events"
    if exists process "$appTarget" then
        tell process "$appTarget"
            repeat with w in windows
                if name of w contains "$projectName" then
                    perform action "AXRaise" of w
                    set frontmost to true
                    return "FOUND"
                end if
            end repeat
        end tell
    end if
end tell
return "NOT_FOUND"
EOF
)

# 2. If window wasn't found, open the directory
if [ "$status" == "NOT_FOUND" ]; then
  projectPath="$basePath/$projectName"
  
  if [ -d "$projectPath" ]; then
    eval "$openCmd \"$projectPath\""
    echo "Opening $projectName in $appTarget..."
  else
    echo "Directory not found: $projectPath"
    exit 1
  fi
else
  # Close Raycast window (Esc) if we just focused an existing window
  osascript -e 'tell application "System Events" to key code 53'
  echo "Focused $projectName"
fi
