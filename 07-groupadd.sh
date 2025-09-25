#!/bin/bash

create_group(){
GROUP_NAME=$1
GROUP_ID=$2

getent group $GROUP_NAME > /dev/null

if [ $? -ne 0 ]; then
        getent group $GROUP_ID > /dev/null
        if [ $? -ne 0 ]; then
            groupadd $GROUP_NAME -g $GROUP_ID
                echo "$GROUP_NAME created with gid $GROUP_ID"
        else
                echo "group id $GROUP_ID already exists"
        fi
else
        echo "$GROUP_NAME group already existed"
fi
}

create_group ram 1050
create_group rama 1051
create_group leaders 1100
create_group remo 1052