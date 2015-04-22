#!/bin/sh
set -x

DB_CONN="hostdb.fac.cs.cmu.edu"
#DB_CONN=fac_ipc
SQLPLUS=sqlplus
MONITOR_SCRIPT=object.sql
MAILER=/usr/bin/mailx
TO="yangl+@cs.cmu.edu"
CC="yangl+@cs.cmu.edu"
MAIL_BODY=obj_changed
#MAIL_SUB="Objects changed during the last week"

#${SQLPLUS} -s /@${DB_CONN} @${MONITOR_SCRIPT} ${MAIL_BODY}
${SQLPLUS} -s / @${MONITOR_SCRIPT} ${MAIL_BODY}

#Get return value from sqlplus?
cat ${MAIL_BODY}.lst | ${MAILER} -s "Objects changed during the last week" -c $TO $CC
