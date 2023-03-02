### Expects the following to be set in $HOME/.zshenv:
# export XDG_CONFIG_HOME="$HOME/.config"
# export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

### HOMEBREW
# e.g. brew install nvim oh-my-zsh zsh-syntax-highlighting

### JAVA
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
#export JAVA_HOME=$(/usr/libexec/java_home -v 11)
# /Library/Java/JavaVirtualMachines/amazon-corretto-17.jdk/Contents/Home

### VIM
export EDITOR=nvim
#export IDEA_VM_OPTIONS=~/.idea.properties

### ZSH
export PATH=/opt/homebrew/bin:$PATH # Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Random: to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# random, robbyrussell, gnzh, powerlevel10k, pure
ZSH_THEME="powerlevel10k/powerlevel10k"

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Expects git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
plugins=(git zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

### VSCODE

# Add vscode's "code" to path
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

### SKAFFOLD

export SKAFFOLD_NAMESPACE=driott

### Aliases, Functions, and Secrets
[ -f "$XDG_CONFIG_HOME/aliasrc.sh" ] && source "$XDG_CONFIG_HOME/aliasrc.sh"
[ -f "$XDG_CONFIG_HOME/functionrc.sh" ] && source "$XDG_CONFIG_HOME/functionrc.sh"
[ -f "$XDG_CONFIG_HOME/secrets.sh" ] && source "$XDG_CONFIG_HOME/secrets.sh"

### Golang

#/Users/driott/code/go/golib
export GOPATH=$HOME/code/go/golib
export GOROOT="$(brew --prefix golang)/libexec"
export PATH="$PATH:${GOPATH}/bin:${GOROOT}/bin"
export GOPATH=$GOPATH:$HOME/code/go/gocode
export GOPRIVATE=github.com/PatchSimple/*,github.com/patchsimple/*

# add K8s autocomplete permanently to your zsh shell
[[ $commands[kubectl] ]] && source <(kubectl completion zsh)
