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
usage()
{
	echo $2
	cat << EOF_USAGE
Usage: ${prog} [options]
Options:
	-r 	start recover
EOF_USAGE
	exit $1
}
#------------------------------------------------------------------------------
RECOVER=FALSE
SQLPLUS=svrmgrl
#------------------------------------------------------------------------------
#if [ $# -eq 0 ]; then
	#usage 1 "Empty argument list" 1>&2
#fi

while [ $# -gt 0 ]; do
	case "$1" in 
	-r)
		RECOVER=TRUE
		shift
		;;
	-*)	usage 1 "Not supported option $1" 1>&2
		;;
	*)
		break
		;;
	esac
done
#------------------------------------------------------------------------------
if [ $RECOVER ]; then

${SQLPLUS} << EOF_A
--
  connect /
--
  startup nomount
--
  recover database ;
--
  alter database open ;
--
--
EOF_A
else
${SQLPLUS} << EOF_B
--
  connect /
--
  startup
--
EOF_B
fi

e=$?
#------------------------------------------------------------------------------
