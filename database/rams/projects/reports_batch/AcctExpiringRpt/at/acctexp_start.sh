#!/bin/sh

cd /usr/costing/ccreport/AcctExp

e=1

prog=`basename $0 .sh`

trap 'e=$?; exit' 1 2 15
trap 'rm -f /tmp/${prog}$$*; trap 0; exit $e' 0

LOG=log/acctexpProc.log
OLDLOG=log/acctexpProc-old.log

MYTS=`whenis -f "%year%02nmonth%02day%02hour%02min" now`

find ${OLDLOG} -mtime +31 -exec mv -f ${LOG} {} \;

#sh -c "exec bin/oasme.sh bin/acctexpProc.pl "$@" >>${LOG} 2>&1"; 
#sh -c "exec bin/oasme.sh bin/acctexpProc.pl notify -c '/@hostdb.fac.cs.cmu.edu' --tmpl_dir etc -m etc/.mailconf.test 1  >>${LOG} 2>&1"; 

sh -c "exec bin/oasme.sh bin/acctexpProc.pl process -v -v -v	\
	-c '/@hostdb.fac.cs.cmu.edu'	\
	--tmpl_dir etc	\
	-m etc/.mailconf	\
	>>${LOG} 2>&1 "; 

#sh -c "exec bin/oasme.sh bin/acctexpProc.pl record -v -v -v 	\
#	-c '/@hostdb.fac.cs.cmu.edu'	\
#	>>${LOG} 2>&1 "; 
#sh -c "exec bin/oasme.sh bin/acctexpProc.pl notify	\
#	-c '/@hostdb.fac.cs.cmu.edu'	\
#	--tmpl_dir etc		\
#	-m etc/.mailconf.test 2		\
#	>>${LOG} 2>&1"; 

status=$?

mv .reportobj.perldata log/reportobj.perldata.${MYTS}

if [ $status -ne 0 ]; then
	echo "acctexpProc failed with status $status"
	tail ${LOG}
fi

e=$status
