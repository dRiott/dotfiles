#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Expand Prompt
# @raycast.mode compact
# @raycast.packageName Voice Tools

# Optional parameters:
# @raycast.icon 🎤

INPUT=$(pbpaste)

if [ -z "$INPUT" ]; then
  echo "Clipboard is empty"
  exit 1
fi

SYSTEM="You receive rough dictated notes from a user. Rewrite them as a clear, structured, well-formed prompt suitable for a large AI model. Do not answer the question or add commentary. Output only the rewritten prompt."

EXPANDED=$(claude -p "$INPUT" \
  --model haiku \
  --system-prompt "$SYSTEM" \
  --no-session-persistence \
  2>/dev/null)

if [ -z "$EXPANDED" ]; then
  echo "Error: no output from claude"
  exit 1
fi

echo "$EXPANDED" | pbcopy
echo "Copied to clipboard"
