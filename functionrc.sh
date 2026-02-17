#!/bin/zsh
# =============================================================================
# Functions
# =============================================================================
# Note: Work-specific functions are in company.sh
# Legacy/archived functions are in archive/legacy-functions.sh

# -----------------------------------------------------------------------------
# Git Functions
# -----------------------------------------------------------------------------

# Interactive rebase on last N commits
function grb() {
  if [ -z "$1" ]; then
    echo "Error: Please provide the number of commits."
    echo "Usage: grb <number>"
    return 1
  fi
  git rebase -i HEAD~"$1"
}

# Rebase current branch onto target (defaults to master)
function rebase() {
  local branch=$(git rev-parse --abbrev-ref HEAD)
  local target=${1:-master}
  echo "Rebasing $branch onto target $target"

  gc $target && gpu
  gc $branch
  git rebase $target
}

# Push current branch and set upstream
function gpp() {
    local branch_name=$(git rev-parse --abbrev-ref HEAD)
    git push --set-upstream origin "$branch_name"
}

# Checkout main or master based on repo
function main() {
  if [[ "$PWD" == */dataflow* ]]; then
    gc master && gpu
  else
    gc main && gpu
  fi
}

# List local branches whose remote is gone
function lb() {
  git branch -vv | grep ": gone]"
}

# Remove local branches whose remote is gone
function rlb() {
  git branch -vv | grep ": gone]" | sed -rn 's/.{2}(.*)*$/\1/p' | sed -rn 's/([\/a-zA-Z0-9_-]+) *.*/\1/p' | xargs git branch -d
}

# Force remove local branches whose remote is gone
function rlbForce() {
  git branch -vv | grep ": gone]" | sed -rn 's/.{2}(.*)*$/\1/p' | sed -rn 's/([\/a-zA-Z0-9_-]+) *.*/\1/p' | xargs git branch -D
}

# Create a diff of current branch vs base for LLM review
function llmdiff() {
    local BASE_BRANCH=${1:-"main"}
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

    if [ -z "$CURRENT_BRANCH" ]; then
      echo "Error: Not in a Git repository or cannot determine current branch."
      return 1
    fi
    git diff $BASE_BRANCH...$CURRENT_BRANCH > feature_review.diff
    pbcopy < feature_review.diff
    rm feature_review.diff
    echo "Diff copied to clipboard"
}
