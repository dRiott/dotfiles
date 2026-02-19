#!/bin/bash
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open ArgoCD UI
# @raycast.mode fullOutput
#
# Optional parameters:
# @raycast.argument1 { "type": "text", "placeholder": "Cluster (e.g. l)" }
#
# Documentation:
# @raycast.description Opens ArgoCD UI for a given cluster
# @raycast.author You
# @raycast.authorURL https://github.com/you

alias="$1"

# Fallback if no input
if [ -z "$alias" ]; then
  echo "No cluster alias provided."
  exit 1
fi

# Map aliases to full project names
case "$alias" in
  l)
    cluster="labs"
    ;;
  2)
    cluster="labs2"
    ;;
  p)
    cluster="pre-release"
    ;;
  *)
    cluster="$alias"
    ;;
esac

open https://argocd.$cluster.cyberhaven.dev

echo "tell application \"System Events\" to key code 53" | osascript
