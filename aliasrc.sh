# bluetooth issues
alias btAdapt="sudo nvram bluetoothHostControllerSwitchBehavior=always"
alias btReset="sudo pkill bluetoothd"
alias btRmPref="rm ~/Library/Preferences/com.apple.Bluetooth.plist"
alias btRmHost="rm ~/Library/Preferences/com.apple.Bluetooh*"

##### COMMANDS #####
#
### GRADLE ###
#
# alias gradle="./gradlew"
alias gw8="./gradlew -Dorg.gradle.java.home=/Library/Java/JavaVirtualMachines/amazon-corretto-11.jdk/Contents/Home "
alias gw="./gradlew -Dorg.gradle.java.home=/Library/Java/JavaVirtualMachines/amazon-corretto-11.jdk/Contents/Home "
alias check="./gradlew check"
alias gbuild="./gradlew clean build --info -Dorg.gradle.warning.mode=fail"
alias gtest="./gradlew test"
alias coverage="gw clean test jacocoTestReport jacocoTestCoverage jacocoTestCoverageVerification"
alias seeCov="open ./build/reports/jacoco/html/index.html"
alias funky="gradle copyNativeDeps && cp /Users/driott/.gradle/caches/modules-2/files-2.1/com.almworks.sqlite4java/libsqlite4java-osx-aarch64-1.0.392.dylib ./build/libs"
alias spot="gw spotlessJava && ./gradlew spotlessJavaApply"
alias spotbugs="gw spotbugsMain && ./gradlew spotbugsReport"
alias coverage="./gradlew clean test jacocoTestReport jacocoTestCoverage jacocoTestCoverageVerification"

##### OPENING FILES #####
alias sourceZshrc="source $ZDOTDIR/.zshrc && echo Sourced $ZDOTDIR/.zshrc"
alias zshrc="nvim $ZDOTDIR/.zshrc && sourceZshrc"
alias aliasrc="nvim $XDG_CONFIG_HOME/aliasrc.sh && sourceZshrc"
alias frc="nvim $XDG_CONFIG_HOME/functionrc.sh && sourceZshrc"
alias src="nvim $XDG_CONFIG_HOME/secrets.sh && sourceZshrc"

alias ls="ls -la"
alias vim="nvim"
alias v="nvim"
alias vimrc="nvim ~/.nvim/.nvimrc"
alias xbar="cd /Users/driott/Library/Application\ Support/xbar/plugins"
alias top50="nvim ~/top50.txt"

# Custom Functions
alias deletevideostream="kill -9 $(lsof -i TCP:5556 | awk '{print $2}')"
alias changeExt="/Users/driott/code/shell/change-extensions.sh"

# Directory Aliases
alias gocode="cd ~/code"
alias gowork="cd ~/Documents/work"

alias config="nvim ~/.aws/config"

alias phpv7="brew unlink php && brew link php@7.4"
alias phpv8="brew unlink php@7.4 && brew link php"

# DOCKER
alias dlogin="echo "$ARTIFACTORY_PASSWORD" | docker login --username "$ARTIFACTORY_USER" --password-stdin automox.jfrog.io"
alias dup="docker-compose -f .docker/docker-compose.yml up"
alias ddown="docker-compose -f .docker/docker-compose.yml down"


prodToLocal () {
   echo "Searching for Order #$1 in production..."
   ORDER_QUERY="{\"orderId\":{\"S\":\"$1\"}}"
   ORDER=$(aws dynamodb get-item --table-name nepp-order-state-prod --profile default --region us-west-2 --key $ORDER_QUERY)
   # echo "Found order in production: $ORDER"
   PAYLOAD=$(echo $ORDER | sed '2d' | sed '$d')
   # echo "Configured payload: $PAYLOAD"
   LOCALSTACK_DYNAMODB_PORT=$(docker inspect --format='{{(index (index .NetworkSettings.Ports "4569/tcp") 0).HostPort}}' $(docker container ls -f "ancestor=gitlab-registry.nordstrom.com/py/nepp/nepp-infrastructure/localstack:0.11.2" --format "{{.ID}}"))
   echo "Found Localstack DynamoDB port: $LOCALSTACK_DYNAMODB_PORT"
   aws --endpoint-url=http://localhost:$LOCALSTACK_DYNAMODB_PORT dynamodb put-item --table-name nepp-order-state-local --region us-west-2 --profile default --item $PAYLOAD
}

##### AWS #####
alias awsp="aws --profile=$PROFILE"
alias awsls="aws --profile=$PROFILE s3 ls "

alias ecsBounceProd="aws ecs update-service --force-new-deployment --service nepp-service-v3-prod-NeppService-TI6KZ689FZP7 --cluster nepp-ecs-cluster-prod --region=us-west-2"
alias ecsBounce="aws ecs update-service --force-new-deployment --service nepp-service-v3-dev-NeppService-YaeUwbR7illP --cluster nepp-ecs-cluster-dev --region=us-west-2 && aws ecs update-service --force-new-deployment --service nepp-service-v3-int-NeppService-1JBRLSOC27D36 --cluster nepp-ecs-cluster-int --region=us-west-2"

# Makefile aliases
alias ms="make style"

##### GIT #####
# Git Aliases
alias mga='make style && git add'
alias ga='git add'
alias gl='git log --graph --decorate --oneline'
alias gma='git commit --amend'
alias head='git reset --hard HEAD'
alias gs='git status'
alias gm='git commit -m'
alias fm='ga -A && gm $1'
alias gb='git branch'
alias gc='git checkout'
alias gpu='git pull'
alias gcl='git clone'
alias gta='git tag -a -m'

# Further Git Aliases
alias fp='git push --force'
alias shyeet='ms && ga -A && gma && fp && echo Cleaned that RIGHT up.'
alias yeet='ms && ga -A && gma && fp && echo Cleaned that RIGHT up.'
alias commitm='ga -A && git commit -m "m" && git rebase -i HEAD~2'

# Checking out Git branches
alias release="gc release && gpu"
alias frelease="gc --force release && gpu"
alias master="gc master && gpu"
alias main="gc main && gpu"
alias fmaster="gc --force master && gpu"

# Git Functions
lb() {
  git branch -vv | grep ": gone]"
}
rlb() {
  git branch -vv | grep ": gone]" | sed -rn 's/.{2}(.*)*$/\1/p' | sed -rn 's/([\/a-zA-Z0-9_-]+) *.*/\1/p' | xargs git branch -d
}
rlbForce() {
  git branch -vv | grep ": gone]" | sed -rn 's/.{2}(.*)*$/\1/p' | sed -rn 's/([\/a-zA-Z0-9_-]+) *.*/\1/p' | xargs git branch -D
}

alias ml="moxie login"
alias mc="moxie console" # opens the AWS Console in a browser window.
alias mldrc="ml --role=$MOXIE_DEV_RC_ADMIN -cdev-usw2-mox0"
alias mlprc="ml --role=$MOXIE_PROD_RC_ADMIN -cprod-usw2-mox0"

##### KUBERNETES #####
# Also see functions in separate file.
alias k="kubectl"
alias kgp="k get pods"
alias k8login='kubelogin login aws-nonprod && k8nonprod'
alias k8loginprod='kubelogin login aws-prod && k8prod'
alias k8mini='k config use-context minikube'
alias k8prod='k config use-context aws_prod_west_barcelona'
alias k8nonprod='k config use-context aws_nonprod_west_hydrogen'
alias getk8secrets='k get secrets -o yaml > secrets.yaml && echo Created secrets.yaml file in $(pwd) && vim secrets.yaml && rm secrets.yaml && echo Deleted secrets.yaml'


##### KAFKA #####
#
# $1 is partition, $2 is offset
# e.g. kcatprod 13 912420
function kcatOrders() {
  kcat -t order-events-avro -b meadow.prod.us-west-2.aws.proton.nordstrom.com:9093 -X security.protocol=sasl_ssl -X sasl.mechanisms=SCRAM-SHA-512 -X sasl.username=$PROTON_MEADOW_ACCESS_KEY -X sasl.password=$PROTON_MEADOW_SECRET_KEY -C -p $1 -o $2 -c 1 -s value=avro -r https://$PROTON_MEADOW_ACCESS_KEY:$PROTON_MEADOW_SECRET_KEY@schema-registry.prod.us-west-2.aws.proton.nordstrom.com -e -f '\nHeaders: %h \nKey (%K bytes): %k\t\nValue (%S bytes): %s\nPartition: %p\tOffset: %o\n--\n'
}


##### REMOTECONTROL #####
alias amrun="sudo launchctl list | grep -E 'remotecontrold|automox'"
alias rcdstop="set RCD_PATH=/Library/LaunchDaemons/remotecontrold.plist && sudo launchctl stop $RCD_PATH && sudo launchctl unload $RCD_PATH && unset RCD_PATH"

