#!/bin/sh

e=1
#-----------------------------------------------------------------------------
#set -x

trap 'e=$?; exit' 1 2 15
trap 'rm -f /tmp/${prog}$$T*; trap 0; exit $e' 0

prog=`basename $0 .sh`
T="/tmp/${prog}$$T"

#-----------------------------------------------------------------------------
SQLPLUS=sqlplus
CONN=
ACCESS=
OBJ=
WHO=

#-----------------------------------------------------------------------------
usage()
{
	echo $2
	cat << EOF_USAGE
Usage: ${prog} -c <connect> <access> <object> <recipient>
SQL:
	GRANT <access> ON <object> TO <recipient>
Example:
	${prog} scott/tiger select emp john

EOF_USAGE
	exit $1

#echo "Usage:  s-grant -c <connect> <access> <object> <recipient>"
#echo "Example:"
#echo "- <connect> grants <access> on <object> to <recipient>"
#echo ""
#echo "  s-grant -c apps/apps select fnd_user goods"
#echo ""
}
#------------------------------------------------------------------------------

if [ $# -eq 0 ]; then
	usage 1 "Empty argument list" 1>&2
fi

while [ $# -gt 0 ]; do
	case "$1" in 
	-c)
		CONN=$2
		shift 2
		;;
	-c*)
		CONN=`echo "$1" | sed 's/^..//'`
		shift
		;;
	-h)
		usage 0 "------------" 1>&2
		;;
	-*)	usage 1 "Not supported option $1" 1>&2
		;;
	*)
		break
		;;
	esac
done

if [ $# -ne 3 ]; then 
	usage 1 "Wrong number of arguments" 1>&2
fi

ACCESS=${1:?}
OBJ=${2:?}
WHO=${3:?}
SCHEMA=

if [ x"$CONN" = x"/" ]; then
	SCHEMA=$LOGIN
else
	SCHEMA='echo "$CONN" | sed 's,/.*,,`
fi

if [ x"$SCHEMA" = "x" ]; then
	usage 1 "<connect> has to contain a schema name. " 1>&2
fi

if [ x"$SCHEMA" = x"$WHO" ]; then
	usage 1 "Source and Destination schemas are the same." 1>&2
fi

#------------------------------------------------------------------------------

${SQLPLUS} -s $CONN << _EOF_SQL_ >& ${T}
whenever sqlerror exit -1
GRANT $ACCESS ON $OBJ TO $WHO;
quit
_EOF_SQL_

#------------------------------------------------------------------------------
e=$?
