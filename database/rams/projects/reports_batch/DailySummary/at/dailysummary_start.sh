#!/bin/sh

e=1

prog=`basename $0 .sh`
proghome=`dirname $0`

#
# Default run-time directory is bin (where dailysummary.pl is)
#
runhome=`(cd $proghome/..;pwd)`

trap 'e=$?; exit' 1 2 15
trap 'rm -f /tmp/${prog}$$*; trap 0; exit $e' 0

cd $runhome

LOGDIR=log
LOG=${LOGDIR}/dailysummary.log
OLDLOG=${LOGDIR}/dailysummary-old.log

TS=`/usr/local/bin/whenis -f '%year%02nmonth%02day%02hour%02min' now`
RPTFILENAME="dailysummary${TS}.csv"

echo RPTFILENAME="dailysummary${TS}.csv"

find ${OLDLOG} -mtime +31 -exec mv -f ${LOG} {} \;
find ${LOGDIR} -mtime +31 -name dailysummary\*.csv -exec rm -f {} \;

	#-m etc/.mailconf	\
#sh -c "exec bin/dailysummary.pl -v 	\
sh -c "exec bin/oascosting.sh bin/dailysummary.pl -v 	\
	-c '/@hostdb.fac.cs.cmu.edu'	\
	-r "log/$RPTFILENAME"	\
	-m "etc/.mailconf"	\
	--tmpl_dir etc	\
	>>${LOG} 2>&1 "; 

status=$?

if [ $status -ne 1 ]; then
	echo "Daily Summary Report failed with status $status"
	tail ${LOG}
else
	status=0
fi

e=$status
