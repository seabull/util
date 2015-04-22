#!/bin/sh
set -x

TBL=${1?"Table name expected."}
exp userid=/ tables=${TBL} \
&&	\
imp userid=/ full=y indexfile=${TBL}.sql
