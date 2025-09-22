#!/bin/bash

#using if condition 

echo "enter a numabr to find even or odd"

read NUMBER

if [ $((NUMBER % 2)) -eq 0 ]; then
    echo "$NUMBER is Even Number"
    else
    echo "$NUMBER is Odd NUmber"
fi