# Path to your oh-my-zsh installation.
export ZSH=/Users/PoorYorick/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="robbyrussell"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

# User configuration
export PS1="_________________________________________________________________________________________________\n| \w @ \h (\u) \n| => "
export PS2="| => "

export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_45.jdk/Contents/Home
export DERBY_HOME=$HOME/SD/Tools/db-derby-10.11.1.1-bin
export ANT_HOME=$HOME/SD/Tools/apache-ant-1.9.6
export TOMCAT_HOME=$HOME/SD/Tools/apache-tomcat-8.0.24
export EC2_HOME=/usr/local/ec2/ec2-api-tools-1.7.5.1
export MONGO_HOME=/usr/local/mongodb

export PATH="/Library/Java/JavaVirtualMachines/jdk1.8.0_45.jdk/Contents/Home/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/git/bin:/Users/PoorYorick/SD/Tools/db-derby-10.11.1.1-bin/bin:/Users/PoorYorick/SD/Tools/apache-ant-1.9.6/bin:/usr/local/mysql/bin:/usr/local/ec2/ec2-api-tools-1.7.5.1/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/git/bin:/usr/local/mongodb/bin"

export CLASSPATH=.:$TOMCAT_HOME/lib/servlet-api.jar
# export MANPATH="/usr/local/man:$MANPATH"

# include private zshrc information if it exists
if [ -f ~/.zshrc_private ]; then
    . ~/.zshrc_private
fi

source $ZSH/oh-my-zsh.sh

# If you need to manually set your language environment
# export LANG=en_US.UTF-8

#set vim command to call 'mvim -v'
alias vim='mvim -v'

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='vim'
fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.

# ------------------------#
#     Personal Aliases    #
# ------------------------#
alias zshconfig="vim ~/.zshrc"
alias ohmyzsh="vim ~/.oh-my-zsh"

#set up alias for showing and hiding 'hidden' files.
alias showFiles="defaults write com.apple.finder AppleShowAllFiles YES; killall Finder /System/Library/CoreServices/Finder.app"
alias hideFiles="defaults write com.apple.finder AppleShowAllFiles NO; killall Finder /System/Library/CoreServices/Finder.app"

#use VideoLan (VLC) with Terminal
alias vlc="/Applications/VLC.app/Contents/MacOS/VLC"

#alias for ls to use full list and directories end with /
alias ls="ls -lpa"

# ------------------------#
#          Git            #
# ------------------------#
alias ga='git add'
alias gp='git push'
alias gl='git log'
alias gs='git status'
alias gd='git diff'
alias gm='git commit -m'
alias gma='git commit -am'
alias gb='git branch'
alias gc='git checkout'
alias gra='git remote add'
alias grr='git remote rm'
alias gpu='git pull'
alias gcl='git clone'
alias gta='git tag -a -m'
alias gf='git reflog'

#functions used in calculating prompt.
function git_prompt_info() {
  ref=$(git symbolic-ref HEAD 2> /dev/null) || return
  echo "$(parse_git_dirty)$ZSH_THEME_GIT_PROMPT_PREFIX$(current_branch)$ZSH_THEME_GIT_PROMPT_SUFFIX"
}

ZSH_THEME_GIT_PROMPT_PREFIX="[git:"
ZSH_THEME_GIT_PROMPT_SUFFIX="]$reset_color"
ZSH_THEME_GIT_PROMPT_DIRTY="$fg[red]+"
ZSH_THEME_GIT_PROMPT_CLEAN="$fg[green]"

function battery_charge() {
    if [ -e ~/Code/libs/Python/batcharge.py ]
    then
        echo `python ~/Code/libs/Python/batcharge.py`
    else
        echo '';
    fi
}


PROMPT='
%{$fg[blue]%}%n%{$reset_color%} on %{$fg[yellow]%}%m%{$reset_color%} in %{$fg[green]%}%~%b%{$reset_color%}
$(git_prompt_info) $(battery_charge)
➜ '
