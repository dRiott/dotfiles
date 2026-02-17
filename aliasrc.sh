# =============================================================================
# Aliases
# =============================================================================
# Note: Functions are in functionrc.sh, work-specific in company.sh
# Legacy/archived functions are in archive/legacy-functions.sh

# -----------------------------------------------------------------------------
# System / Troubleshooting
# -----------------------------------------------------------------------------
# Bluetooth issues
alias btAdapt="sudo nvram bluetoothHostControllerSwitchBehavior=always"
alias btReset="sudo pkill bluetoothd"
alias btRmPref="rm ~/Library/Preferences/com.apple.Bluetooth.plist"
alias btRmHost="rm ~/Library/Preferences/com.apple.Bluetooh*"

# Typo fixes
alias cladue="claude"

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

# Config file editing
alias sourceZshrc="source $ZDOTDIR/.zshrc && echo Sourced $ZDOTDIR/.zshrc"
alias zshrc="nvim $ZDOTDIR/.zshrc && sourceZshrc"
alias aliasrc="nvim $XDG_CONFIG_HOME/aliasrc.sh && sourceZshrc"
alias frc="nvim $XDG_CONFIG_HOME/functionrc.sh && sourceZshrc"
alias src="nvim $XDG_CONFIG_HOME/secrets.sh && sourceZshrc"
alias crc="nvim $XDG_CONFIG_HOME/company.sh && sourceZshrc"

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
alias gm='git commit -m'
alias fm='ga -A && gm $1'
alias gb='git branch'
alias gc='git checkout'
alias gpu='git pull'
alias gcl='git clone'
alias gtag='git tag -a -m'
alias gtl='git tag -l -n1'

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
# Misc
# -----------------------------------------------------------------------------
alias captureWorkday="osascript $HOME/code/shell/applescript/captureWorkday.scpt"
alias changeExt="$HOME/code/shell/change-extensions.sh"
alias deletevideostream="kill -9 \$(lsof -i TCP:5556 | awk '{print \$2}')"
