#!/bin/bash

USERID=$(id -u)

if [ $USERID -eq 0 ]; then
    echo "running script as root"
    dnf install nginx -y
else
    echo "please run the script as root"
fi