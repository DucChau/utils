#!/bin/sh

AWS_PROFILE=$1
MACHINE_NAME=$2

if [ "$1" = "" ]; then
    MACHINE_NAME="api"
fi

echo "Listing IP's for: $MACHINE_NAME"

aws --profile=$AWS_PROFILE ec2 describe-instances --filters "Name=tag:Name,Values=$MACHINE_NAME" | grep PrivateIpAddress | cut -d'"' -f4 | sort -u | sed '/^$/d' | sed 's/^/"/' | sed 's/$/"/'
