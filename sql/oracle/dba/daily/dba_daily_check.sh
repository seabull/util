#!/bin/sh

#
#  Report some benchmark data as email 
#	drafted by yangl

e=1

prog=`basename $0 .sh`; export prog

trap 'e=$?; exit' 1 2 15
trap 'rm -f /tmp/${prog}$$* ${RMTMP}; trap 0; exit $e' 0

#cd /usr/costing/Run
set -x

SRC=/usr/oracle/ylj/scripts
#DB_HOST=hostdb.fac.cs.cmu.edu
DB_HOST=facdev
MAILER=/usr/costing/bin/metasend
ARCHIVE=${SRC}/archive_dba

stamp=`date '+%Y%m%d'`
rpt=${stamp}dba_daily
sql=dba_daily_check.sql

to=yangl@cs.cmu.edu
#cc=yangl+jereport@cs.cmu.edu,cosgrove+@cs.cmu.edu,nikithse+@cs.cmu.edu
cc=yangl+prod@cs.cmu.edu
replyto=yangl+@cs.cmu.edu

#find ./ -name ${rpt} -exec rm -f {} \; 

#sqlplus -s /@${DB_HOST} @${SRC}/${sql} ${ARCHIVE}/${rpt}
sqlplus -s / @${SRC}/${sql} ${ARCHIVE}/${rpt}

mv ${ARCHIVE}/${rpt}.lst ${ARCHIVE}/${rpt}.txt
echo "[ Sending DBA Daily Report as eMail Attachment ${rpt} ]"

${MAILER} \
-b \
-t  $to \
-c  $cc \
-s  "DBA Daily Prod Report - ${rpt}" \
-m "application/octet-stream" \
-A "attachment;filename=${rpt}.txt" \
-f  "${ARCHIVE}/${rpt}.txt" \
-D "${rpt}" \
-F ${replyto} \
-S 5242880



e=$?
