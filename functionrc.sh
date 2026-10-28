#!/bin/zsh

# =============================================================================
# Aliases & Functions
# =============================================================================
# Note: Work-specific aliases/functions are in company.sh
# Legacy/archived functions are in archive/legacy-functions.sh

# =============================================================================
# Aliases
# =============================================================================

alias python="python3"

# -----------------------------------------------------------------------------
# System / Troubleshooting
# -----------------------------------------------------------------------------
# Bluetooth issues
alias btAdapt="sudo nvram bluetoothHostControllerSwitchBehavior=always"
alias btReset="sudo pkill bluetoothd"
alias btRmPref="rm ~/Library/Preferences/com.apple.Bluetooth.plist"
alias btRmHost="rm ~/Library/Preferences/com.apple.Bluetooh*"

# Typo fixes
alias cl="claude --model claude-opus-4-6"
alias cld="claude --model claude-opus-4-6 --dangerously-skip-permissions"
alias cld8="claude --model claude-opus-4-8 --dangerously-skip-permissions"
alias cc="cld8"
alias cls="claude --model sonnet"
alias clsd="claude --model sonnet --dangerously-skip-permissions"
alias clobs="cd /Users/driott/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/CloudSync && claude"
alias obs="cd /Users/driott/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/CloudSync"

# -----------------------------------------------------------------------------
# File Navigation & Editing
# -----------------------------------------------------------------------------
alias ls="ls -Gla --color=auto"
alias t="tree -L 2"
alias vim="nvim"
alias v="nvim"
alias vimrc="nvim $HOME/.config/nvim/init.vim"
alias xbar="cd $HOME/Library/Application\ Support/xbar/plugins"

# Directory shortcuts
alias gocode="cd ~/code"
alias gowork="cd ~/Documents/work"
alias goobs="cd \"/Users/driott/Library/Mobile Documents/iCloud~md~obsidian/Documents/CloudSync\""

# Config file editing
alias sourceZshrc="source $ZDOTDIR/.zshrc && echo Sourced $ZDOTDIR/.zshrc"
alias zshrc="nvim $ZDOTDIR/.zshrc && sourceZshrc"
alias frc="nvim $XDG_CONFIG_HOME/functionrc.sh && sourceZshrc"
alias src="nvim $XDG_CONFIG_HOME/secrets.sh && sourceZshrc"
alias crc="nvim $XDG_CONFIG_HOME/company.sh && sourceZshrc"
alias aliasrc="crc"

# AWS config
alias config="nvim ~/.aws/config"

# Karabiner
alias vgok="nvim $HOME/.config/karabiner/karabiner.edn && goku"

# -----------------------------------------------------------------------------
# Docker
# -----------------------------------------------------------------------------
alias dup="docker-compose -f .docker/docker-compose.yml up"
alias ddown="docker-compose -f .docker/docker-compose.yml down"

# -----------------------------------------------------------------------------
# Difftests
# -----------------------------------------------------------------------------
alias dtss="difftests | grep -Ev 'CONT|RUN|PASS|PAUSE|DEBUG|INFO|WARN|ERROR|Spanner emulator|go:|2025|2026|2027'"
alias dts="difftests"

# -----------------------------------------------------------------------------
# AWS
# -----------------------------------------------------------------------------
alias awsp="aws --profile=$PROFILE"
alias awsls="aws --profile=$PROFILE s3 ls "

# -----------------------------------------------------------------------------
# Git
# -----------------------------------------------------------------------------
# Global .gitignore: vim ~/.gitignore_global
# Apply: git config --global core.excludesfile ~/.gitignore_global
# Remove: git config --global --unset core.excludesfile

alias gitignore='nvim ~/.gitignore_global'
alias ga='git add'
alias gl='git log --graph --decorate --oneline'
alias gma='git commit --amend --no-verify'
alias gs='git status'
alias gm='git commit --no-verify -m'
alias fm='ga -A && gm $1'
alias gb='git branch'
alias gc='git checkout'
alias gpu='git pull'
alias gcl='git clone'
alias gtag='git tag -a -m'
alias gtl='git tag -l -n1'

# Audit with Goland the diff, based on:
# git config --global diff.tool goland
# git config --global difftool.goland.cmd '/Users/driott/.local/bin/goland diff --wait "$LOCAL" "$REMOTE"'
# git config --global difftool.prompt false
alias gdv='nvim -c "DiffviewOpen HEAD"'

# Force push and quick commits
alias fp='git push --force'
alias commitm='ga -A && git commit -m "m" && git rebase -i HEAD~2'
alias yeet='ga -A && gma && fp'

# Branch checkout shortcuts
alias master="gc master && gpu"
alias develop="gc develop && gpu"
alias fmaster="gc --force master && gpu"

# -----------------------------------------------------------------------------
# Kubernetes
# -----------------------------------------------------------------------------
alias k="kubectl"
alias kgp="k get pods"
alias getk8secrets='k get secrets -o yaml > secrets.yaml && echo Created secrets.yaml file in $(pwd) && nvim secrets.yaml && rm secrets.yaml && echo Deleted secrets.yaml'

# -----------------------------------------------------------------------------
# Monitoring / Ops
# -----------------------------------------------------------------------------
alias check-categ-overrides="$HOME/code/scripts/check-disable-categorization-overrides.sh"

# -----------------------------------------------------------------------------
# Misc
# -----------------------------------------------------------------------------
alias captureWorkday="osascript $HOME/code/shell/applescript/captureWorkday.scpt"
alias changeExt="$HOME/code/shell/change-extensions.sh"
alias deletevideostream="kill -9 \$(lsof -i TCP:5556 | awk '{print \$2}')"

# =============================================================================
# Functions
# =============================================================================

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

# Push current branch with force and set upstream
function fpp() {
    local branch_name=$(git rev-parse --abbrev-ref HEAD)
    git push --set-upstream origin "$branch_name" --force
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

# github rerun - reruns failed jobs from your PRs
# Usage: ghrr [PR_NUMBER] or ghrr --all
function ghrr() {
  local repo="CyberhavenInc/dataflow"

  if [ "$1" = "--all" ]; then
    echo "Checking failed runs for all open PRs in repository: $repo"
    gh pr list --repo "$repo" --json number,headRefName | jq -c '.[]' | while read -r pr; do
      _ghrr_process_pr "$pr" "$repo"
    done
  elif [ -n "$1" ]; then
    echo "Checking failed runs for PR #$1 in repository: $repo"
    pr_data=$(gh pr view "$1" --repo "$repo" --json number,headRefName)
    _ghrr_process_pr "$pr_data" "$repo"
  else
    echo "Checking failed runs for your PRs in repository: $repo"
    gh pr list --repo "$repo" --author "@me" --json number,headRefName | jq -c '.[]' | while read -r pr; do
      _ghrr_process_pr "$pr" "$repo"
    done
  fi
}

# -----------------------------------------------------------------------------
# GCloud Account Switching
# -----------------------------------------------------------------------------

function gcwork() {
  gcloud config set account david.riott@cyberhaven.com
  gcloud config set project es-scalability-test
  echo "Switched to: $(gcloud config get-value account) / $(gcloud config get-value project)"
}

function gcpersonal() {
  gcloud config set account david.riott1@gmail.com
  gcloud config set project project-1b3a4253-5531-4b2b-ba6
  echo "Switched to: $(gcloud config get-value account) / $(gcloud config get-value project)"
}

function _ghrr_process_pr() {
  local pr="$1"
  local repo="$2"
  local number=$(echo "$pr" | jq -r '.number')
  local branch=$(echo "$pr" | jq -r '.headRefName')

  echo ""
  echo "Checking PR #$number (branch: $branch)..."

  local failed_runs=$(gh run list --repo "$repo" --branch "$branch" --status completed --limit 20 --json databaseId,conclusion,displayTitle --jq '.[] | select(.conclusion=="failure")')

  if [ -z "$failed_runs" ]; then
    echo "  No failed runs found"
    return
  fi

  echo "$failed_runs" | jq -r '.databaseId' | while read -r run_id; do
    if [ -n "$run_id" ]; then
      local title=$(echo "$failed_runs" | jq -r "select(.databaseId==$run_id) | .displayTitle" | head -1)
      echo "  Rerunning failed run $run_id: $title"
      gh run rerun "$run_id" --repo "$repo" --failed 2>&1 | sed 's/^/    /'
    fi
  done
}
