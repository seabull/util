#!/bin/sh
#------------------------------------------------------------------------------
#$Id: match_name.sh,v 1.12 2008/04/17 20:48:20 costing Exp $
#------------------------------------------------------------------------------

prog=`basename $0 .sh`
TMPFILE="/tmp/T${prog}.$$"

#------------------------------------------------------------------------------
error=1

trap ' rm -f $TMPFILE ; trap 0 ; exit $error ; ' 0

# catch SIGHUP SIGINT SIGTERM
trap ' error=$? ; exit 0 ; ' 1 2 15

#------------------------------------------------------------------------------
#to=yangl+@cs.cmu.edu
#cc=yangl+@cs.cmu.edu
#replyto=yangl+@cs.cmu.edu
to=fac-name-multimatch-notify+@cs.cmu.edu
cc=yangl+@cs.cmu.edu
replyto=fac-name-multimatch-notify+@cs.cmu.edu

OPT_REPORT_ONLY=FALSE

#------------------------------------------------------------------------------
usage()
{
	echo $2
	cat << EOF_USAGE
Usage: ${prog} [options] <procedure name>
	Currently only match_fullname is supported as procedure name".
Options:
	-r	: report only mode.
	-v	: verbose
	
EOF_USAGE
	exit $1
}

#------------------------------------------------------------------------------

while getopts :vr OPT
do
        case $OPT in
	r)	OPT_REPORT_ONLY=TRUE
		;;
        v)      OPT_VERBOSE=TRUE
                ;;
        \?)     "Invalid option '$OPT'"
                ;;
        esac
done
shift `expr $OPTIND - 1`

if [ $# -lt 1 ] ; then
        usage 1 "At least one argument expected beyond the options."
fi

#------------------------------------------------------------------------------
# some common commands used in many scripts
#------------------------------------------------------------------------------

STAGE=${1:?"Please specify procedure you want to use to update employee IDs."}
DB_CONNECTION=${RAMS_DB_CONNECTION:-"/@hostdb.fac.cs.cmu.edu"}
#NOPROCESS=${RAMS_NO_PROCESSJE}

#Assume the current directory is $HOME/match_name
L_TS=`whenis -f '%04year-%02nmonth-%02day-%02hour%02min' now`
L_SQL=${RAMS_SQL:-sql}
L_BIN=${RAMS_BIN:-bin}
L_LOG=${RAMS_LOG:-log}
L_REPORT=${L_LOG}/name_multimatch${L_TS}.csv
L_RPT_CANDIDATES=${L_LOG}/name_candidates${L_TS}.csv

MAILER=${L_BIN}/metasend
#------------------------------------------------------------------------------
set -x
set -e

#------------------------------------------------------------------------------
if [ x"$OPT_REPORT_ONLY" = "xFALSE" ]; then
	${L_BIN}/oasme sqlplus  -s ${DB_CONNECTION}	\
				@sql/run_nm	\
				${STAGE}
fi

#------------------------------------------------------------------------------

${L_BIN}/oasme sqlplus  -s ${DB_CONNECTION}	\
				@sql/report_error	\
				$L_REPORT

${L_BIN}/oasme sqlplus  -s ${DB_CONNECTION}	\
				@sql/report_fuzzy	\
				$L_RPT_CANDIDATES

#------------------------------------------------------------------------------
L_LINES=`wc -l $L_REPORT | awk '{print $1}'`


if [ $L_LINES -gt 1 ]; then
	${MAILER} \
		-b \
		-t  $to \
		-c  $cc \
		-s  "Name with multiple matches report - ${L_REPORT}" \
		-m "application/octet-stream" \
		-A "attachment;filename=${L_REPORT}" \
		-f  "${L_REPORT}" \
		-D "${L_REPORT}" \
		-F ${replyto} \
		-S 5242880
fi

L_LINES=`wc -l $L_RPT_CANDIDATES | awk '{print $1}'`


if [ $L_LINES -gt 1 ]; then
	${MAILER} \
		-b \
		-t  $to \
		-c  $cc \
		-s  "Names match First/Last report - ${L_RPT_CANDIDATES}" \
		-m "application/octet-stream" \
		-A "attachment;filename=${L_RPT_CANDIDATES}" \
		-f  "${L_RPT_CANDIDATES}" \
		-D "${L_RPT_CANDIDATES}" \
		-F ${replyto} \
		-S 5242880
fi

#find . -name ${L_REPORT} -exec rm -f ${L_REPORT} \;

#------------------------------------------------------------------------------
set +x
set +e
error=0

