#!/bin/bash
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Focus GoLand Project
# @raycast.mode fullOutput
#
# Optional parameters:
# @raycast.argument1 { "type": "text", "placeholder": "Project Alias (e.g. env-d)" }
#
# Documentation:
# @raycast.description Focuses a GoLand window by project alias
# @raycast.author You
# @raycast.authorURL https://github.com/you

alias="$1"

# Fallback if no input
if [ -z "$alias" ]; then
  echo "No project alias provided."
  exit 1
fi

# Map aliases to full project names
case "$alias" in
  ed)
    projectName="environments-definitions"
    ;;
  et)
    projectName="environments-templates"
    ;;
  d)
    projectName="dataflow"
    ;;
  df)
    projectName="dataflow"
    ;;
  a)
    projectName="applications-definitions"
    ;;
  ad)
    projectName="applications-definitions"
    ;;
  h)
    projectName="helm-charts"
    ;;
  hc)
    projectName="helm-charts"
    ;;
  c)
    projectName="charts-values"
    ;;
  cv)
    projectName="charts-values"
    ;;
  v)
    projectName="charts-values"
    ;;
  an)
    projectName="anomaly-and-triage"
    ;;
  *)
    echo "Unknown alias: $alias"
    exit 1
    ;;
esac

# AppleScript to focus the Goland window with the project name
osascript <<EOF
tell application "GoLand"
  activate
end tell

delay 0.2

tell application "System Events"
  tell process "GoLand"
    repeat with w in windows
      if name of w contains "$projectName" then
        perform action "AXRaise" of w
        set frontmost to true
        exit repeat
      end if
    end repeat
  end tell
end tell

tell application "System Events" to key code 53
EOF

#echo "tell application \"System Events\" to key code 53" | osascript

