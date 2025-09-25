#!/bin/bash

USER_NAME=$1
USER_ID=$2
PGRP_ID=$3
SGRP_ID=$7
USER_SHELL=$4
USER_HOMEDIR=$5
USER_CMT=$6

id $USER_NAME 2&> /dev/null

if [ $? -ne 0 ]; then
    id $USER_ID 2&> /dev/null
    if [ $? -ne 0 ]; then
        useradd -u $USER_ID $USER_NAME
        echo "user $USER_NAME with id  $USER_ID are created"
    else
        echo "USer $USER_NAME not existed but $USER_ID already existed"
    fi
else
    echo "user $USER_NAME already existed"
fi