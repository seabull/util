#!/bin/sh
# $Id: acct_exp.sh,v 1.1 2005/09/13 17:37:01 yangl Exp $

USER=kzm
HOME=/afs/cs/user/${USER}
PATH=${HOME}/acct_expiring/bin:${HOME}/bin:/usr/bin:/usr/ucb:/usr/local/bin

export USER HOME PATH 

LOG=log/acct_expiring.log
OLDLOG=log/acct_expiring-old.log

#find ${OLDLOG} -mtime +31 -exec mv -f ${LOG} {} \;

TS=`whenis -f "%04year%02nmonth%02day%02hour" now`

#cd $HOME \
#&& \
#( \
	#cd acct_expiring;      \
	#date; \
	#bin/oascosting.sh bin/report_acctexp.pl -v --to kzm+@cs.cmu.edu --cc yangl+ -f archive/acct_exp${TS};
#) >> log/acct_expiring.log 2>&1
( \
date;\
./report_acctexp.pl -v -c /@fac_03.apogee --to yangl+@cs.cmu.edu --cc yangl+ -f ./acct_exp${TS} "$@"; \
) >> acct.log 2>&1
