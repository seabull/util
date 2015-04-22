#!/bin/sh

cd /usr/costing/ccreport/ServiceCharge

e=1

prog=`basename $0 .sh`

trap 'e=$?; exit' 1 2 15
trap 'rm -f /tmp/${prog}$$*; trap 0; exit $e' 0

LOG=log/rptProc.log
OLDLOG=log/rptProc-old.log

MYTS=`/usr/local/bin/whenis -f "%year%02nmonth%02day%02hour%02min" now`

find ${OLDLOG} -mtime +31 -exec mv -f ${LOG} {} \;

#sh -c "exec bin/oasme.sh bin/rptProc.pl "$@" >>${LOG} 2>&1"; 
#sh -c "exec bin/oasme.sh bin/rptProc.pl notify -c 'ccreport/ccreport@hostdb.fac.cs.cmu.edu' --tmpl_dir etc -m etc/.mailconf.test 1  >>${LOG} 2>&1"; 

# For post JE
#sh -c "exec bin/oasme.sh bin/rptProc.pl process -v -v -v -c 'ccreport/ccreport@hostdb.fac.cs.cmu.edu' --tmpl_dir etc -m etc/.mailconf -t 2  >>${LOG} 2>&1"; 

sh -c "exec bin/oasme.sh bin/rptProc.pl process -v -v -v	\
	-c '/@hostdb.fac.cs.cmu.edu'	\
	--tmpl_dir etc	\
	-m etc/.mailconf	\
	-t 1  >>${LOG} 2>&1"; 

#sh -c "exec bin/oasme.sh bin/rptProc.pl record -v -v -v -c '/@hostdb.fac.cs.cmu.edu' -t 1 -1 'July 2, 2006 10:00 AM' -2 'now' >>${LOG} 2>&1"; 
#sh -c "exec bin/oasme.sh bin/rptProc.pl notify -v -v -v	\
#	-c '/@hostdb.fac.cs.cmu.edu'	\
#	--tmpl_dir etc	\
#	-m etc/.mailconf 1	\
#	>>${LOG} 2>&1"; 

status=$?

mv .reportobj.perldata log/reportobj.perldata.${MYTS}

if [ $status -ne 0 ]; then
	echo "rptProc failed with status $status"
	tail ${LOG}
fi

e=$status
