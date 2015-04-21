#!/bin/sh

e=1
#-----------------------------------------------------------------------------
#set -x

trap 'e=$?; exit' 1 2 15
trap 'rm -f /tmp/${prog}$$T*; trap 0; exit $e' 0

prog=`basename $0 .sh`
T="/tmp/${prog}$$T"

#TT="/tmp/${prog}$$TT"
#cmd ${@+"$@"}
#-----------------------------------------------------------------------------
SQLPLUS=svrmgrl

${SQLPLUS} << _EOF_
--
  connect internal
--
  shutdown immediate
--
  startup
--
_EOF_

e=$?

#------------------------------------------------------------------------------
