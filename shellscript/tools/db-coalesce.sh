#!/bin/sh

e=1
#-----------------------------------------------------------------------------
#set -x

trap 'e=$?; exit' 1 2 15
trap 'rm -f /tmp/${prog}$$T*; trap 0; exit $e' 0

prog=`basename $0 .sh`
T="/tmp/${prog}$$T"

#TT="/tmp/${prog}$$TT"

#------------------------------------------------------------------------------
SQLPLUS=sqlplus
AWK=awk
CONNECT=$CXAPPS

#------------------------------------------------------------------------------
( echo set head off feedback off \
  echo "select tablespace_name from dba_tablespaces ;" ) \
    | ${SQLPLUS} -s $CONNECT \
    | sed '/^$/d' \
    | ${AWK} '{ printf "alter tablespace %s coalesce ;\n", $1 }' \
    | ${AWK} '{ printf "prompt + %s\n%s\n", $0, $0 }' \
    | ${SQLPLUS} -s $CONNECT \
    | sed '/^$/d'

#------------------------------------------------------------------------------
