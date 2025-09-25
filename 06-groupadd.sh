#!/bin/bash

GROUP_NAME=$1
GROUP_ID=$2

getent group $GROUP_NAME > /dev/null

if [ $? -ne 0 ]; then
        getent group $GROUP_ID > /dev/null
        if [ $? -ne 0 ]; then
            groupadd $GROUP_NAME -g $GROUP_ID
                echo "$GROUP_NAME created with gid $GROUP_ID"
        else
                echo "$GROUP_ID already exists"
        fi
else
        echo "$GROUP_NAME group already existed"
fi