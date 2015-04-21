#!/bin/sh

e=1
#-----------------------------------------------------------------------------
#set -x

trap 'e=$?; exit' 1 2 15
trap 'rm -f /tmp/${prog}$$T*; trap 0; exit $e' 0

prog=`basename $0 .sh`
T="/tmp/${prog}$$T"
TT="/tmp/${prog}$$TT"

#cmd ${@+"$@"}
#------------------------------------------------------------------------------
X_AWK=awk
X_GREP=grep
XSHELL=${SHELL:-sh}
USE_TWO_TASK=${TWO_TASK:-FALSE}
USE_ORACLE_SID=${ORACLE_SID:-FALSE}
INSTANCE=
PATH=${PATH:=""}

OLD_PATH=$PATH
OLD_ORACLE_SID=${ORACLE_SID:=""}
OLD_ORACLE_BASE=${ORACLE_BASE:=""}
OLD_ORACLE_HOME=${ORACLE_HOME:=""}

#-----------------------------------------------------------------------------
usage()
{
	echo $2
	cat << EOF_USAGE

-----------------------------------------------------------------------------
Description: Set the oracle environment based on the new instance (or sid).
Usage: ${prog} [options] <oracle_instance_name>
Options:
	-s	Born Shell 
	-c	C Shell
	-2	set TWO_TASK
Example:
	${prog} facdev
EOF_USAGE
	exit $1
}
#------------------------------------------------------------------------------
# clear all ORACLE_HOME directories from PATH 
clear_ora_environments()
{
	#ora-homes | ${X_AWK} '{ if(NR>1) printf ( "|"); else printf(""); printf $2 "/.*" }' > $TT
	#Get all the oracle homes seperated by space
	eval PATH=\`'ora-homes | awk '"'"'{ if (NR > 1) printf(" "); else printf("");  printf $2 ; }'"'"\` ;
	for X in $PATH
	do
		# get rif of the oracle home related directories from PATH
		eval PATH=\`'echo $PATH | sed -e '"'""s,$X/[a-zA-z_-]*,,g""'"' -e '"'"'s/:::*//g'"'"\`
	done
	#echo "----XX-----"
	#echo $XX
	#echo "----YY-----"
	#echo $YY
	#echo "----PP-----"
	#echo $PATH
}
#------------------------------------------------------------------------------
set_orasid()
{
	echo "Changing Oracle Environment..."
	echo "ORACLE_SID=$OLD_ORACLE_SID ===> $ORACLE_SID" 
	echo "ORACLE_HOME=$OLD_ORACLE_HOME ===> $ORACLE_HOME" 
	export ORACLE_SID ORACLE_HOME PATH
}
#------------------------------------------------------------------------------
set_ora2task()
{
	echo "Changing Oracle Environment..."
	echo "TWO_TASK=$OLD_TWO_TASK ===> $TWO_TASK" 
	echo "ORACLE_HOME=$OLD_ORACLE_HOME ===> $ORACLE_HOME" 
	export TWO_TASK ORACLE_HOME PATH
}
#------------------------------------------------------------------------------

if [ $# -eq 0 ]; then
	usage 1 "Empty argument list" 1>&2
fi

while [ $# -gt 0 ]; do
	case "$1" in 
	-c)
		XSHELL=csh
		shift
		;;
	-s)
		XSHELL=sh
		;;
	-2)
		USE_TWO_TASK=TRUE
		;;
	--)	
		break;
		;;
	-*)	usage 1 "Not supported option $1" 1>&2
		;;
	*)
		break
		;;
	esac
done

if [ $# -gt 2 ]; then
	usage 1 "Too many arguments." 1>&2
fi
if [ $# -eq 1 ]; then
	INSTANCE=$1
fi
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

if [ "$USE_TWO_TASK"="TRUE" ]; then
#------------------------------------------------------------------------------
	:
#------------------------------------------------------------------------------
elif [ $USE_ORACLE_SID ]; then
#------------------------------------------------------------------------------
	:
#------------------------------------------------------------------------------
else
	# set environments for the new instance
	ora-home $INSTANCE >/dev/null 1>&2
	if [ $? ]; then
		echo "Warning:  '$ORACLE_SID' $ORACLE_SID not found in oratab"
		echo "Keep original environment."
		echo "ORACLE_SID=$ORACLE_SID"
		echo "ORACLE_HOME=$ORACLE_HOME"
		e=1
		exit $e;
	fi
	ORACLE_SID=$INSTANCE
	ORACLE_HOME=`ora-home $INSTANCE`
	#ORACLE_BASE=
	clear_ora_environments
	PATH=$ORALCE_HOME/bin:$PATH
	set_orasid
fi


#------------------------------------------------------------------------------


