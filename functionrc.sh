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

