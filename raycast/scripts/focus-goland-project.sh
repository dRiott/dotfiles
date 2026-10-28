#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Focus or Open Project
# @raycast.mode silent

# Optional parameters:
# @raycast.argument1 { "type": "text", "placeholder": "Alias (d, an, ed...)", "optional": false }

# Strip spaces and periods, e.g. "protos #71." -> "protos#71"
alias="${1//[ .]/}"
basePath="$HOME/code"

# Split off a trailing "#123" PR suffix, if any
prNumber=""
openRepo=""
if [[ "$alias" == \$* ]]; then
  openRepo=1
  alias="${alias#\$}"
elif [[ "$alias" == *"#"* ]]; then
  prNumber="${alias##*#}"
  alias="${alias%%#*}"
fi

case "$alias" in
  an)     projectName="anomaly-and-triage"       ;;
  a|ad)   projectName="applications-definitions" ;;
  c|cv|v) projectName="charts-values"            ;;
  d|df)   projectName="dataflow"                 ;;
  ed)     projectName="environments-definitions" ;;
  et)     projectName="environments-templates"   ;;
  g)      projectName="groundcover"              ;;
  h|hc)   projectName="helm-charts"              ;;
  pi)     projectName="prod-infrastructure"      ;;
  *)
    # Use the provided argument as the project name directly
    projectName="$alias"
    ;;
esac

# A leading "$" opens the repo home page in the browser
if [ -n "$openRepo" ]; then
  open "https://github.com/CyberhavenInc/$projectName/"
  echo "Opening $projectName repo..."
  exit 0
fi

# If a PR number was supplied, open the PR in the browser and stop
if [ -n "$prNumber" ]; then
  open "https://github.com/CyberhavenInc/$projectName/pull/$prNumber"
  echo "Opening $projectName PR #$prNumber..."
  exit 0
fi

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
