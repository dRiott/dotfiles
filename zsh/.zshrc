### Expects the following to be set in $HOME/.zshenv:
# export XDG_CONFIG_HOME="$HOME/.config"
# export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

### Expects the following tools to be installed:
# Homebrew: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# oh-my-zsh: sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# zsh-syntax-highlighting: git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
# zsh-autosuggestions: git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# =============================================================================
# PATH Configuration
# =============================================================================
typeset -U PATH  # Automatically remove duplicate entries

# Cache these values to avoid running subshells on every startup
# Refresh by running: hash -r && exec zsh
: ${GOPATH_BIN:=$(go env GOPATH 2>/dev/null)/bin}
: ${PYTHON_USER_BIN:=$(python3 -m site --user-base 2>/dev/null)/bin}

path=(
    $HOME/.local/bin
    $HOME/bin
    /opt/homebrew/bin
    $GOPATH_BIN
    $PYTHON_USER_BIN
    "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
    $path
)

# =============================================================================
# Environment Variables
# =============================================================================
export EDITOR=nvim
export ZSH="$HOME/.oh-my-zsh"
export GOKU_EDN_CONFIG_FILE="$XDG_CONFIG_HOME/karabiner/karabiner.edn"

# =============================================================================
# Oh-My-Zsh Configuration
# =============================================================================
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
plugins=(git zsh-syntax-highlighting zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh

# =============================================================================
# Powerlevel10k (DISABLED - was for iTerm, now using Ghostty)
# =============================================================================
# To re-enable:
# 1. Install: git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
# 2. Uncomment the lines below
# 3. Set ZSH_THEME="powerlevel10k/powerlevel10k" above

# # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi
#
# # To customize prompt, run `p10k configure` or edit $ZDOTDIR/.p10k.zsh.
# [[ ! -f $ZDOTDIR/.p10k.zsh ]] || source $ZDOTDIR/.p10k.zsh

# =============================================================================
# Source Configuration Files
# =============================================================================
[ -f "$XDG_CONFIG_HOME/aliasrc.sh" ] && source "$XDG_CONFIG_HOME/aliasrc.sh"
[ -f "$XDG_CONFIG_HOME/functionrc.sh" ] && source "$XDG_CONFIG_HOME/functionrc.sh"
[ -f "$XDG_CONFIG_HOME/secrets.sh" ] && source "$XDG_CONFIG_HOME/secrets.sh"
[ -f "$XDG_CONFIG_HOME/company.sh" ] && source "$XDG_CONFIG_HOME/company.sh"
[ -f "$XDG_CONFIG_HOME/dataflow-workflow.sh" ] && source "$XDG_CONFIG_HOME/dataflow-workflow.sh"

# =============================================================================
# Tool Integrations
# =============================================================================

# Kubectl autocomplete
[[ $commands[kubectl] ]] && source <(kubectl completion zsh)

# NVM (Node Version Manager) - Lazy loaded for faster shell startup
export NVM_DIR="$HOME/.config/nvm"
nvm() {
  unfunction nvm node npm npx 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  nvm "$@"
}
node() { nvm; node "$@"; }
npm() { nvm; npm "$@"; }
npx() { nvm; npx "$@"; }

# Ghostty shell integration
if [[ -n "$GHOSTTY_RESOURCES_DIR" ]]; then
  source "$GHOSTTY_RESOURCES_DIR/shell-integration/zsh/ghostty-integration"
fi

# =============================================================================
# iTerm2 (DISABLED - now using Ghostty)
# =============================================================================
# [ -f ~/.iterm2_shell_integration.zsh ] && source ~/.iterm2_shell_integration.zsh
#
# # Kubernetes Context in iTerm2's Status Bar
# function iterm2_print_user_vars() {
#   iterm2_set_user_var kubecontext $(kubectl config current-context):$(kubectl config view --minify --output 'jsonpath={..namespace}')
# }
