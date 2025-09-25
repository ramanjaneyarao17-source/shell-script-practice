#!/bin/bash

USER_NAME=$1
USER_ID=$2
PGRP_ID=$3
SGRP_ID=$7
USER_SHELL=$4
USER_HOMEDIR=$5
USER_CMT=$6

if [ 'id $USER_NAME > /dev/null'; $? -ne 0 ]; then
    echo "user $USER_NAME not existed"
else
    echo "user $USER_NAME already existed"
fi