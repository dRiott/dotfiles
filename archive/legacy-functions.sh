#!/bin/zsh
# =============================================================================
# Legacy Functions Archive
# =============================================================================
# These functions/aliases are from previous employers/projects and are kept for
# reference. They are NOT sourced by default.
#
# To use any of these, either:
#   1. Copy the function/alias to your active config
#   2. Source this file manually: source "$XDG_CONFIG_HOME/archive/legacy-functions.sh"
# =============================================================================

# -----------------------------------------------------------------------------
# Gradle / Java Aliases
# -----------------------------------------------------------------------------
alias gw8="./gradlew -Dorg.gradle.java.home=/Library/Java/JavaVirtualMachines/amazon-corretto-11.jdk/Contents/Home "
alias gw="./gradlew -Dorg.gradle.java.home=/Library/Java/JavaVirtualMachines/amazon-corretto-11.jdk/Contents/Home "
alias check="./gradlew check"
alias gbuild="./gradlew clean build --info -Dorg.gradle.warning.mode=fail"
alias gtest="./gradlew test"
alias coverage="./gradlew clean test jacocoTestReport jacocoTestCoverage jacocoTestCoverageVerification"
alias seeCov="open ./build/reports/jacoco/html/index.html"
alias funky="gradle copyNativeDeps && cp $HOME/.gradle/caches/modules-2/files-2.1/com.almworks.sqlite4java/libsqlite4java-osx-aarch64-1.0.392.dylib ./build/libs"
alias spot="gw spotlessJava && ./gradlew spotlessJavaApply"
alias spotbugs="gw spotbugsMain && ./gradlew spotbugsReport"

# -----------------------------------------------------------------------------
# Nordstrom / NEPP Functions
# -----------------------------------------------------------------------------

function prodToLocal() {
   echo "Searching for Order #$1 in production..."
   ORDER_QUERY="{\"orderId\":{\"S\":\"$1\"}}"
   ORDER=$(aws dynamodb get-item --table-name nepp-order-state-prod --profile default --region us-west-2 --key $ORDER_QUERY)
   PAYLOAD=$(echo $ORDER | sed '2d' | sed '$d')
   LOCALSTACK_DYNAMODB_PORT=$(docker inspect --format='{{(index (index .NetworkSettings.Ports "4569/tcp") 0).HostPort}}' $(docker container ls -f "ancestor=gitlab-registry.nordstrom.com/py/nepp/nepp-infrastructure/localstack:0.11.2" --format "{{.ID}}"))
   echo "Found Localstack DynamoDB port: $LOCALSTACK_DYNAMODB_PORT"
   aws --endpoint-url=http://localhost:$LOCALSTACK_DYNAMODB_PORT dynamodb put-item --table-name nepp-order-state-local --region us-west-2 --profile default --item $PAYLOAD
}

# Accepts first argument that is the date to copy from ERTM's 2019 S3 bucket
function getS3Strings() {
    echo "s3://ertm-prod-transactions-proton-sink/ertm-transactions-prod-encrypted-pii-avro/2019/$1 s3://prod-historical-ertm-files/2019/$1"
}

# Accepts first argument that is the date to copy from historical-ERTM's 2019 S3 bucket
function getHistoricalToErtmDataS3Strings() {
    echo "s3://prod-historical-ertm-files/2019/$1 s3://prod-fraud-ertm-data"
}

function getArchiveErtmDataS3Strings() {
    echo "s3://prod-fraud-file-archives/$1 s3://prod-fraud-ertm-data"
}

function prodDecrypt() {
  java -jar /Users/edun/code/fraud-utility/build/libs/file-ingest-util.jar --secret-manager-key-name=prod-fraud-client-encryption-key --encryption-option=DECRYPT -r $1
}

# Kafka consumer for Nordstrom order events
# $1 is partition, $2 is offset
# e.g. kcatprod 13 912420
function kcatOrders() {
  kcat -t order-events-avro -b meadow.prod.us-west-2.aws.proton.nordstrom.com:9093 -X security.protocol=sasl_ssl -X sasl.mechanisms=SCRAM-SHA-512 -X sasl.username=$PROTON_MEADOW_ACCESS_KEY -X sasl.password=$PROTON_MEADOW_SECRET_KEY -C -p $1 -o $2 -c 1 -s value=avro -r https://$PROTON_MEADOW_ACCESS_KEY:$PROTON_MEADOW_SECRET_KEY@schema-registry.prod.us-west-2.aws.proton.nordstrom.com -e -f '\nHeaders: %h \nKey (%K bytes): %k\t\nValue (%S bytes): %s\nPartition: %p\tOffset: %o\n--\n'
}

# -----------------------------------------------------------------------------
# Automox Functions
# -----------------------------------------------------------------------------

function kpv() {
  k get -o json pod $(k get pods --namespace remotecontrol -l "app.kubernetes.io/name=ax-generic-service,app.kubernetes.io/instance=$1" -o jsonpath="{.items[0].metadata.name}") | grep "\"image\": \"automox.jfrog.io"
}

# Login to Docker with AWS ECR creds
function ecrdocker() {
  docker login -u AWS -p $(aws ecr get-login-password --region us-west-2) 402475032688.dkr.ecr.us-west-2.amazonaws.com
}

function mvDevice() {
  sh $HOME/code/shell/moveDeviceToOrg.sh $1
}

function getDBCreds() {
	echo "username:\n" && kubectl get secret db-psdb-aurora-dev --template={{.data.dbuser}} -n dev | base64 -D && echo "\npassword:\n" && kubectl get secret db-psdb-aurora-dev --template={{.data.dbpass}} -n dev | base64 -D
}

# Stops the RemoteControlD daemon.
function rcdstop() {
  RCD_PATH=/Library/LaunchDaemons/remotecontrold.plist
  echo $RCD_PATH
  sudo launchctl stop $RCD_PATH && echo "Stopped."
  sudo launchctl unload $RCD_PATH && echo "Unloaded."
}

# Starts the RemoteControlD daemon.
function rcdstart() {
  RCD_PATH=/Library/LaunchDaemons/remotecontrold.plist
  echo $RCD_PATH
  sudo launchctl load $RCD_PATH && echo "Loaded."
}

# Stops the Automox Agent
function amstop() {
  sudo launchctl unload /Library/LaunchDaemons/com.automox.agent.plist
}

# Starts the Automox Agent
function amstart() {
  sudo launchctl load /Library/LaunchDaemons/com.automox.agent.plist
}

# Stops & Starts the Automox Agent
function amrestart() { amstop && amstart }

function get_iam_rds_password() {
    export AWS_PROFILE=saml
    moxie login
    all_good=0;
    REGION=us-west-2;
    DB_USERNAME="${2:-psdb-readwrite-prod}";
    if [[ "$1" = "stg" ]]; then
        RDSHOST="ax-db-k8s-staging-replica.c84tajvtp0ss.us-west-2.rds.amazonaws.com";
        all_good=1;
    else
        if [[ "$1" = "prod" ]]; then
            RDSHOST="am-db95-prod-02.czakv1rc16fd.us-west-2.rds.amazonaws.com";
            all_good=1;
        else
            echo "Please specify an environment - stg, prod";
            echo "Usage: get_rds_password <env>";
        fi;
    fi;
    if [[ "$all_good" -eq 1 ]]; then
        echo "DB Hostname: $RDSHOST";
        echo "DB Username: $DB_USERNAME";
        PGPASSWORD="$(aws rds generate-db-auth-token --hostname $RDSHOST --port 5432 --region $REGION --username $DB_USERNAME)";
        sleep 3
        echo "DB Password: $PGPASSWORD";
        psql "sslmode=require host=$RDSHOST user=$DB_USERNAME dbname=ps"
    fi
}

function dbeaverProd() {
  /Applications/DBeaver.app/Contents/MacOS/dbeaver dbeaver -con "driver=postgresql|name=moxie-cli|url=$(moxie db login --url-format=jdbc | tail -1)"
}

# -----------------------------------------------------------------------------
# Misc Legacy Functions
# -----------------------------------------------------------------------------

function rebaseme() {
    BRANCH=$(cat .git/HEAD | sed -e "s/^ref: refs\/heads\///")
    $(release && git rebase HEAD $BRANCH)
    echo Done?
}

# https://sethrobertson.github.io/GitFixUm/fixup.html#change_deep
function deleteCommit() {
  git rebase -p --onto $1^ $1
}

function testLoopy() {
  executionState="Running"
  maxAttempts=2
  sleepSeconds=1s
  attemptCount=0
  until [ "$executionState" != "Running" ] || [ $attemptCount -eq $maxAttempts ]; do
    printf "Looking to see how the StepFunction is doing!"
    executionDescription="One two three Running"
    executionState=$(echo "$executionDescription" | awk '{print $4}')
    attemptCount=$(attemptCount + 1)
    printf "\n%s attempts have been made to test for Acceptance Test completion, executionState=%s" "${attemptCount}" "${executionState}"
    sleep $sleepSeconds
  done
}
