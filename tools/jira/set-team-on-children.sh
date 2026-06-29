#!/usr/bin/env bash
set -euo pipefail

# Sets the Jira "Team[Team]" field on all children of the given epic(s).
# Reads the API token from the macOS keychain (stored by acli).
#
# Usage:
#   ./set-team-on-children.sh DDR-21882 DDR-24734 ...
#   TEAM_ID=<uuid> ./set-team-on-children.sh DDR-21882
#   ./set-team-on-children.sh --dry-run DDR-21882

SITE="cyberhaven.atlassian.net"
EMAIL="david.riott@cyberhaven.com"
TEAM_FIELD="customfield_10300"
TEAM_ID="${TEAM_ID:-a9170743-e4e3-40fd-8655-81db66428cf7}"  # AI Classification

DRY_RUN=false
EPICS=()

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --help|-h)
      echo "Usage: $0 [--dry-run] EPIC-KEY [EPIC-KEY ...]"
      echo ""
      echo "Sets Team[Team] to AI Classification on all children of the given epics."
      echo ""
      echo "Options:"
      echo "  --dry-run   List children without updating"
      echo ""
      echo "Environment:"
      echo "  TEAM_ID     Override the team UUID (default: AI Classification)"
      exit 0
      ;;
    *) EPICS+=("$arg") ;;
  esac
done

if [ ${#EPICS[@]} -eq 0 ]; then
  echo "Error: provide at least one epic key" >&2
  exit 1
fi

TOKEN=$(security find-generic-password -s "acli" -w | python3 -c "
import sys, base64
raw = sys.stdin.read().strip()
if raw.startswith('go-keyring-base64:'):
    print(base64.b64decode(raw[18:]).decode())
else:
    print(raw)
")

if [ -z "$TOKEN" ]; then
  echo "Error: could not read API token from keychain. Run: acli jira auth login" >&2
  exit 1
fi

AUTH="$EMAIL:$TOKEN"
API="https://$SITE/rest/api/3"

fetch_children() {
  local epic="$1"
  curl -s -X POST -u "$AUTH" \
    -H "Content-Type: application/json" \
    -d "{\"jql\":\"parent = $epic\",\"maxResults\":100,\"fields\":[\"key\",\"summary\"]}" \
    "$API/search/jql" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for i in data.get('issues', []):
    print(i['key'] + '\t' + i['fields']['summary'])
"
}

ALL_KEYS=()
for epic in "${EPICS[@]}"; do
  echo "=== $epic ==="
  children=$(fetch_children "$epic")
  count=$(echo "$children" | grep -c $'\t' || true)
  echo "  $count children"

  while IFS=$'\t' read -r key summary; do
    [ -z "$key" ] && continue
    echo "  $key  $summary"
    ALL_KEYS+=("$key")
  done <<< "$children"
done

UNIQUE_KEYS=($(printf '%s\n' "${ALL_KEYS[@]}" | sort -u))
echo ""
echo "Total unique children: ${#UNIQUE_KEYS[@]}"

if $DRY_RUN; then
  echo "(dry run - no changes made)"
  exit 0
fi

echo ""
ok=0
fail=0
for key in "${UNIQUE_KEYS[@]}"; do
  code=$(curl -s -o /dev/null -w "%{http_code}" -u "$AUTH" \
    -X PUT -H "Content-Type: application/json" \
    -d "{\"fields\":{\"$TEAM_FIELD\":\"$TEAM_ID\"}}" \
    "$API/issue/$key")
  if [ "$code" = "204" ]; then
    ok=$((ok + 1))
  else
    fail=$((fail + 1))
    echo "  FAIL $key: HTTP $code"
  fi
done

echo "Done: $ok updated, $fail failed"
