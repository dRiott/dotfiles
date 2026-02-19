#!/bin/bash
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open GitHub Pulls
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
  df)
    projectName="dataflow"
    ;;
  a)
    projectName="applications-definitions"
    ;;
  h)
    projectName="helm-charts"
    ;;
  c)
    projectName="charts-values"
    ;;
  an)
    projectName="anomaly-and-triage"
    ;;
  *)
    projectName="$alias"
    ;;
esac

open https://www.github.com/CyberhavenInc/$projectName/pulls/ch-davidriott

echo "tell application \"System Events\" to key code 53" | osascript

