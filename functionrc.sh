#!/bin/zsh

# KUBE
#
function kpv() {
  k get -o json pod $(k get pods --namespace remotecontrol -l "app.kubernetes.io/name=ax-generic-service,app.kubernetes.io/instance=$1" -o jsonpath="{.items[0].metadata.name}") | grep "\"image\": \"automox.jfrog.io"
}
#
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

# Login to Docker with AWS ECR creds
function ecrdocker {
  docker login -u AWS -p $(aws ecr get-login-password --region us-west-2) 402475032688.dkr.ecr.us-west-2.amazonaws.com
}

function rebaseme() {
    BRANCH=$(cat .git/HEAD | sed -e "s/^ref: refs\/heads\///")
    $(release && git rebase HEAD $BRANCH)
    echo Done?
}

# https://sethrobertson.github.io/GitFixUm/fixup.html#change_deep
function deleteCommit() {
  git rebase -p --onto $1^ $1
}

function prodDecrypt() {
  java -jar /Users/edun/code/fraud-utility/build/libs/file-ingest-util.jar --secret-manager-key-name=prod-fraud-client-encryption-key --encryption-option=DECRYPT -r $1
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

function get_iam_rds_password()
{
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
