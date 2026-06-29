#!/bin/zsh
# =============================================================================
# Dataflow Worktree Workflow
# =============================================================================
# Functions for managing dataflow git worktrees with Jira integration.
# Jira operations are handled by Claude via the /ticket-setup skill.
# Epics auto-initialize Beads for persistent task tracking across sessions.
#
# Usage:
#   dfstart DDR-1234          # Create worktree (auto-detects Epics → Beads)
#   dfstart DDR-1234 --beads  # Force Beads even for non-epic tickets
#   df DDR-1234               # Resume Claude in existing worktree
#   dfls                      # List all dataflow worktrees
#   dfrm DDR-1234             # Remove a worktree
# =============================================================================

# Main dataflow repo path
DATAFLOW_ROOT="${GIT_REPO_PATH:-$HOME/code}/dataflow"

# -----------------------------------------------------------------------------
# Internal helpers
# -----------------------------------------------------------------------------

# Check if a Jira ticket is an Epic
_df_is_epic() {
  jira-is-epic "$1" 2>/dev/null
}

# Jira base URL for ticket links
JIRA_BASE_URL="https://cyberhaven.atlassian.net/browse"

# Extract plain text from Jira ADF description (best-effort, no truncation)
_df_jira_description_text() {
  jq -r '
    [.. | .text? // empty] | join(" ")
    | gsub("\\n+"; " ") | gsub("  +"; " ")
    | if . == "" then empty else . end
  ' 2>/dev/null
}

# Build a rich bead description from Jira fields
_df_build_description() {
  local key="$1" summary="$2" desc_text="$3" jira_url="$4" parent_key="$5"

  local parts=""
  parts+="Jira: ${jira_url}"
  [[ -n "$parent_key" ]] && parts+=$'\n'"Parent: ${JIRA_BASE_URL}/${parent_key}"
  parts+=$'\n'
  if [[ -n "$desc_text" ]]; then
    parts+=$'\n'"${desc_text}"
  else
    parts+=$'\n'"No Jira description. Needs spec enrichment before implementation."
    parts+=$'\n'"Run: bd mol wisp spec-enrich --var ticket=${key} --var bead_id=<this-bead-id>"
  fi
  echo "$parts"
}

# Initialize Beads in a worktree and seed from Jira
_df_init_beads() {
  local ticket="$1"
  local wt_path="$2"

  (
    cd "$wt_path" || return 1
    bd init --quiet
    bd setup claude

    # Fetch full epic ticket data
    local epic_json
    epic_json=$(jira-view "$ticket" --fields '*all' 2>/dev/null)

    local summary description parent_key
    summary=$(echo "$epic_json" | jq -r '.fields.summary // empty')
    description=$(echo "$epic_json" | jq '.fields.description // empty' | _df_jira_description_text)
    parent_key=$(echo "$epic_json" | jq -r '.fields.parent.key // empty')

    local epic_desc
    epic_desc=$(_df_build_description "$ticket" "$summary" "$description" "${JIRA_BASE_URL}/${ticket}" "$parent_key")

    bd create \
      --title="${ticket}: ${summary:-$ticket}" \
      --description="${epic_desc}" \
      --type=epic --priority=1

    # Seed child tickets as task beads
    local children
    children=$(jira-children "$ticket" --exclude-done --fields "key,summary,description" 2>/dev/null)

    if [[ -n "$children" && "$children" != "[]" ]]; then
      echo "$children" | jq -c '.[]' | while IFS= read -r child; do
        local ckey csummary cdesc child_desc
        ckey=$(echo "$child" | jq -r '.key')
        csummary=$(echo "$child" | jq -r '.fields.summary // empty')
        cdesc=$(echo "$child" | jq '.fields.description // empty' | _df_jira_description_text)

        child_desc=$(_df_build_description "$ckey" "$csummary" "$cdesc" "${JIRA_BASE_URL}/${ckey}" "$ticket")

        bd create \
          --title="${ckey}: ${csummary:-$ckey}" \
          --description="${child_desc}" \
          --type=task --priority=2
      done
    fi

    local count
    count=$(bd list --json 2>/dev/null | jq 'length')
    echo "Beads initialized: 1 epic + $((count - 1)) child tasks."
  )
}

# -----------------------------------------------------------------------------
# dfstart - Create new worktree, auto-detect Epics for Beads
# -----------------------------------------------------------------------------
dfstart() {
  local input="${1:?Usage: dfstart <ticket-id> [--beads]}"
  local ticket=$(echo "$input" | grep -oE 'DDR-[0-9]+' | head -n 1)

  if [[ -z "$ticket" ]]; then
    echo "Error: No valid DDR ticket number found."
    return 1
  fi

  local worktree_path="${DATAFLOW_ROOT}-${ticket}"

  if [[ -d "$worktree_path" ]]; then
    echo "Worktree already exists. Use 'df $ticket'."
    return 1
  fi

  echo "Fetching latest and creating worktree..."
  git -C "$DATAFLOW_ROOT" fetch origin
  git -C "$DATAFLOW_ROOT" worktree add -b "$ticket" "$worktree_path" origin/master

  # Symlink Claude configuration and memory
  if [[ -d "$DATAFLOW_ROOT/.claude" ]]; then
    ln -s "$DATAFLOW_ROOT/.claude" "$worktree_path/.claude"
  fi

  # Decide whether to use Beads: explicit --beads flag or auto-detect Epic
  local use_beads=false
  if [[ "${2:-}" == "--beads" ]]; then
    use_beads=true
    echo "Beads requested via --beads flag."
  else
    echo "Checking if $ticket is an Epic..."
    if _df_is_epic "$ticket"; then
      use_beads=true
      echo "Epic detected — initializing Beads."
    fi
  fi

  if $use_beads; then
    _df_init_beads "$ticket" "$worktree_path"
    cd "$worktree_path" && claude "/ticket-setup $ticket"
  else
    cd "$worktree_path" && claude "/ticket-setup $ticket"
  fi
}

# -----------------------------------------------------------------------------
# df - Resume Claude session (Beads hooks auto-inject context if present)
# -----------------------------------------------------------------------------
df() {
  local input="${1:-}"
  local target_path
  local name=""

  if [[ -z "$input" ]]; then
    target_path="$DATAFLOW_ROOT"
  else
    name=$(echo "$input" | grep -oE 'DDR-[0-9]+' | head -n 1)
    [[ -z "$name" ]] && name="$input"
    target_path="${DATAFLOW_ROOT}-${name}"
  fi

  if [[ ! -d "$target_path" ]]; then
    echo "Error: Directory not found: $target_path"
    return 1
  fi

  if [[ -d "$target_path/.beads" ]]; then
    # Beads SessionStart hooks auto-inject context — just launch Claude
    echo "Resuming with Beads context..."
    cd "$target_path" && claude
  else
    cd "$target_path" && claude "/ticket-setup ${name:-}"
  fi
}

# -----------------------------------------------------------------------------
# dfls - List all dataflow worktrees
# -----------------------------------------------------------------------------
dfls() {
  echo "Dataflow worktrees:"
  git -C "$DATAFLOW_ROOT" worktree list | grep dataflow
}

# -----------------------------------------------------------------------------
# dfrm - Remove a worktree
# -----------------------------------------------------------------------------
dfrm() {
  local input="${1:?Usage: dfrm <worktree-name> (e.g., DDR-1234)}"
  local force_flag=""

  # If second argument provided, use --force
  if [[ -n "${2:-}" ]]; then
    force_flag="--force"
  fi

  # Extract DDR ticket number from input
  local name=$(echo "$input" | grep -oE 'DDR-[0-9]+' | head -n 1)

  # If no DDR ticket found, use input as-is (for backwards compatibility)
  if [[ -z "$name" ]]; then
    name="$input"
  fi

  local worktree_path="${DATAFLOW_ROOT}-${name}"

  if [[ ! -d "$worktree_path" ]]; then
    echo "Error: Worktree not found: $worktree_path"
    return 1
  fi

  echo "Removing worktree: $worktree_path"
  git -C "$DATAFLOW_ROOT" worktree remove "$worktree_path" $force_flag

  # Optionally delete the branch too
  read -q "REPLY?Delete branch '$name' as well? [y/N] "
  echo
  if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    git -C "$DATAFLOW_ROOT" branch -d "$name" 2>/dev/null || \
    git -C "$DATAFLOW_ROOT" branch -D "$name"
    echo "Branch deleted."
  fi
}

# -----------------------------------------------------------------------------
# dfclean - Remove all worktrees except main
# -----------------------------------------------------------------------------
dfclean() {
  echo "This will remove ALL dataflow worktrees except the main one."
  read -q "REPLY?Are you sure? [y/N] "
  echo
  if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    git -C "$DATAFLOW_ROOT" worktree list | grep -v "^$DATAFLOW_ROOT " | awk '{print $1}' | while read wt; do
      echo "Removing: $wt"
      git -C "$DATAFLOW_ROOT" worktree remove "$wt" --force
    done
    echo "Done. Remaining worktrees:"
    dfls
  fi
}
