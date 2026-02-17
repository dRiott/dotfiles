#!/bin/zsh
# =============================================================================
# Dataflow Worktree Workflow
# =============================================================================
# Functions for managing dataflow git worktrees with Jira integration.
# Jira operations are handled by Claude via the /ticket-setup skill.
#
# Usage:
#   dfstart DDR-1234    # Create worktree, launch Claude with /ticket-setup
#   df DDR-1234         # Launch Claude in existing worktree
#   dfls                # List all dataflow worktrees
#   dfrm DDR-1234       # Remove a worktree
# =============================================================================

# Main dataflow repo path
DATAFLOW_ROOT="${GIT_REPO_PATH:-$HOME/code}/dataflow"

# -----------------------------------------------------------------------------
# dfstart - Create new worktree from Jira ticket and launch Claude
# -----------------------------------------------------------------------------
dfstart() {
  local ticket="${1:?Usage: dfstart <ticket-id> (e.g., DDR-1234)}"
  local worktree_path="${DATAFLOW_ROOT}-${ticket}"

  # Validate ticket format
  if [[ ! "$ticket" =~ ^DDR-[0-9]+$ ]]; then
    echo "Error: Ticket must be in format DDR-1234"
    return 1
  fi

  # Check if worktree already exists
  if [[ -d "$worktree_path" ]]; then
    echo "Worktree already exists at $worktree_path"
    echo "Use 'df $ticket' to launch Claude there, or 'dfrm $ticket' to remove it first."
    return 1
  fi

  # Fetch latest from remote
  echo "Fetching latest from origin..."
  git -C "$DATAFLOW_ROOT" fetch origin

  # Create worktree with temporary branch name (Claude will rename after fetching ticket)
  echo "Creating worktree at $worktree_path..."
  git -C "$DATAFLOW_ROOT" worktree add -b "$ticket" "$worktree_path" origin/master

  # Add TICKET.md to local gitignore
  local worktree_name=$(basename "$worktree_path")
  local exclude_dir="$DATAFLOW_ROOT/.git/worktrees/$worktree_name/info"
  mkdir -p "$exclude_dir"
  if ! grep -q "TICKET.md" "$exclude_dir/exclude" 2>/dev/null; then
    echo "TICKET.md" >> "$exclude_dir/exclude"
  fi

  # Symlink .claude directory to share settings/skills with main repo
  if [[ -d "$DATAFLOW_ROOT/.claude" ]]; then
    ln -s "$DATAFLOW_ROOT/.claude" "$worktree_path/.claude"
  fi

  echo "Launching Claude with /ticket-setup..."
  cd "$worktree_path" && claude "/ticket-setup $ticket"
}

# -----------------------------------------------------------------------------
# df - Launch Claude in existing worktree
# -----------------------------------------------------------------------------
df() {
  local name="${1:-}"
  local target_path

  if [[ -z "$name" ]]; then
    target_path="$DATAFLOW_ROOT"
  else
    target_path="${DATAFLOW_ROOT}-${name}"
  fi

  if [[ ! -d "$target_path" ]]; then
    echo "Error: Directory not found: $target_path"
    echo "Available worktrees:"
    dfls
    return 1
  fi

  cd "$target_path" && claude
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
  local name="${1:?Usage: dfrm <worktree-name> (e.g., DDR-1234)}"
  local worktree_path="${DATAFLOW_ROOT}-${name}"

  if [[ ! -d "$worktree_path" ]]; then
    echo "Error: Worktree not found: $worktree_path"
    return 1
  fi

  echo "Removing worktree: $worktree_path"
  git -C "$DATAFLOW_ROOT" worktree remove "$worktree_path"

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
