#!/bin/sh

. /usr1/app/yangl/dba/daily/oraenv
cd /usr1/app/yangl/dba/daily

e=1

prog=`basename $0 .sh`

trap 'e=$?; exit' 1 2 15
trap 'rm -f /tmp/${prog}$$*; trap 0; exit $e' 0

LOG=log/dba_daily.log
OLDLOG=log/dba_daily-old.log

find ${OLDLOG} -mtime +31 -exec mv -f ${LOG} {} \;

sh -c "exec dba_daily_check_csv.sh >>${LOG} 2>&1"
