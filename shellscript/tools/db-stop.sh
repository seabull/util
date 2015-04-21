#!/bin/sh

e=1
#-----------------------------------------------------------------------------
#set -x

trap 'e=$?; exit' 1 2 15
trap 'rm -f /tmp/${prog}$$T*; trap 0; exit $e' 0

prog=`basename $0 .sh`
T="/tmp/${prog}$$T"

#TT="/tmp/${prog}$$TT"
#-----------------------------------------------------------------------------
SQLPLUS=svrmgrl

#-----------------------------------------------------------------------------
if [ x"$1" = x"-a" ] then
${SQLPLUS} << EOF_A
--
  connect /
--
  shutdown abort
--
EOF_A
else
${SQLPLUS} << EOF_B
--
  connect /
--
  shutdown immediate
--
EOF_B
fi

e=$?
#------------------------------------------------------------------------------
