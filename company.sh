
export GOPRIVATE=github.com/PatchSimple/*,github.com/patchsimple/*
export RCD=/Library/Application\ Support/Automox/modules
export RLOG="/usr/local/var/log/remotecontrold.log"

# Add artifactory to docker repositories
alias dlogin="echo "$ARTIFACTORY_PASSWORD" | docker login --username "$ARTIFACTORY_USER" --password-stdin automox.jfrog.io"

# Required for "Agent" unit tests (replace Apple-native tail with GNU's tail) 
#alias tail=gtail
alias gt="echo $GH_TOKEN | pbcopy"

##### PHP #####
alias phpv7="brew unlink php && brew link php@7.4"
alias phpv8="brew unlink php@7.4 && brew link php"

##### MAKE #####
alias ms="make style"

##### MOXIE #####
alias ml="moxie login"
alias mc="moxie console" # opens the AWS Console in a browser window.
alias mldrc="ml --role=$MOXIE_DEV_RC_ADMIN -cdev-usw2-mox0"
alias mlprc="ml --role=$MOXIE_PROD_RC_ADMIN -cprod-usw2-mox0"

##### DATABASES #####
alias dbeaverProd='/Applications/DBeaver.app/Contents/MacOS/dbeaver dbeaver -con \"driver=postgresql|name=moxie-cli|url=$(moxie db login --url-format=jdbc | tail -1)\"'

##### REMOTECONTROL #####
alias amrun="sudo launchctl list | grep -E 'remotecontrold|automox'"
# /usr/local/var/log/remotecontrold.err
alias rcdlog="sudo tail -f -n 100 /Library/Application\ Support/Automox/modules/remotecontrol/install.log /usr/local/var/log/remotecontrold.log"
alias rcdlogjq="sudo cat /usr/local/var/log/remotecontrold.log | jq"
alias rmrcdlog="sudo bash -c 'cat /dev/null > /usr/local/var/log/remotecontrold.log' && sudo bash -c 'cat /dev/null > /Library/Application\ Support/Automox/modules/remotecontrol/install.log'"
alias rlog="rmrcdlog && rcdlog"
alias rmrcd="sudo rm -rf /Library/Application\ Support/Automox/modules && sudo rm -rf /Applications/Remote\ Control.app/ && tccReset && sudo rm -f /Library/LaunchDaemons/remotecontrold.plist && rmlog"
alias tccReset="tccutil reset ScreenCapture com.automox.RemoteControl && tccutil reset Accessibility com.automox.RemoteControl"
alias tccResetGoland="tccutil reset ScreenCapture com.jetbrains.goland && tccutil reset Accessibility com.jetbrains.goland"
alias rmlog="sudo rm -f $RLOG"
