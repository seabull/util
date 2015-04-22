#!/bin/sh
#$Header: c:\\Repository/sql/oracle/dba/daily/dba_alert_monitor.sh,v 1.1 2004/09/24 15:51:54 yangl Exp $
#--------------------------------------------------------------------
#This script is used to monitor the alert.log
#It sends email to DBALIST if there is ORA- appear in the alert.log
#--------------------------------------------------------------------

#set up the environment
#. oracle.profile

SIDLIST="fac"
HOST_EXEC=`hostname`
DBALIST="yangl+@cs.cmu.edu"

GREP=egrep
TIMESTAMP=`whenis -f '%04Year%02nmonth%02day%02hour%02min' now`
#for SID in `cat $ORACLE_HOME/sidlist`
for SID in $SIDLIST ;
do
    cd $ORACLE_BASE/admin/$SID/bdump
    if [ -f alert_${SID}.log ]
    then
        mv alert_${SID}.log alert_work.log
        touch alert_${SID}.log
        cat alert_work.log >> alert_${SID}.hist
        ${GREP} -n 'ORA-|Checkpoint' alert_work.log > alert.err
    fi
    if [ `cat alert.err|wc -l` -gt 0 ]
    then
        mailx -s "${SID} ORACLE ALERT ERRORS - from ${HOST_EXEC}" $DBALIST < alert.err
	cp alert_work.log alert_work.log${TIMESTAMP}
    fi
    rm -f alert.err
    rm -f alert_work.log
done
