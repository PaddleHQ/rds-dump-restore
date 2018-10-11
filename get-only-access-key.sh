#!/bin/bash

# This script ensures that we have a new access key not known anywhere
# else.  This can be used in testing - if someone is already running a
# test, that will break but the later one will run to competion without
# interruption (or until another, later test starts).

# The output is a JSON map as for aws iam create-access-key which can be
# consumed to configure local access files.

# For many use cases, temporary access keys may be better than this,
# though they won't have the same lockout effect.

username=$1
if [ a"$username" = "a" ]
then
    echo no username provided - please give as an argument to the script >&2
    exit 2
fi

set -vx

( for i in $(aws iam list-access-keys  --user-name=$username | grep AccessKeyId | sed -e 's/",//' -e 's/.*"//' ) 
do
    aws iam delete-access-key  --user-name=$username --access-key-id=$i
done ) >&2

aws iam create-access-key --user-name=$username
