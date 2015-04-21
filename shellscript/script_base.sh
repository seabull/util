#!/bin/sh
#$Header: c:\\Repository/shellscript/script_base.sh,v 1.2 2004/07/14 15:22:12 yangl Exp $
#$Author: yangl $

e=1
#-----------------------------------------------------------------------------
#set -x

# catch 0, SIGHUP(1), SIGINT(2), SIGTERM(15)
trap 'e=$?; exit' 1 2 15
trap 'rm -f /tmp/${prog}$$T*; trap 0; exit $e' 0

prog=`basename $0 .sh`
T="/tmp/${prog}$$T"

#TT="/tmp/${prog}$$TT"
#cmd ${@+"$@"}
#-----------------------------------------------------------------------------
usage()
{
	echo $2
	cat << EOF_USAGE
Usage: ${prog} [options]
Options:

EOF_USAGE
	exit $1
}
#------------------------------------------------------------------------------
CONN=
VERBOSE=
#------------------------------------------------------------------------------

if [ $# -eq 0 ]; then
	usage 1 "Empty argument list" 1>&2
fi

if [ "$OPTIND" = 1 ]; then
	while getopts vc:h OPT
	do
		case $OPT in
		v)	VERBOSE=TRUE
			;;
		c)	CONN=$OPTARG
			;;
		h)	usage 1 "----------" 1>&2
			;;
		\?)	usage 1 "Wrong arguments." 1>&2
			;;
		esac
	done
	shift `expr $OPTIND - 1`
else
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
fi

if [ $# -ne 3 ]; then 
	usage 1 "Wrong number of arguments" 1>&2
fi
#------------------------------------------------------------------------------
