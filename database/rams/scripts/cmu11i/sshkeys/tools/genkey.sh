#!/bin/sh

set -x

KEYFILE=${1:?"Error: expect keyfile name as argument"}

ssh-keygen -N '' -b 1024 -t dsa -f $KEYFILE
