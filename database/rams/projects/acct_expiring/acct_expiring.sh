#!/bin/sh
# $Id: acct_expiring.sh,v 1.2 2005/07/25 21:26:52 yangl Exp $

USER=costing
HOME=/usr/${USER}
PATH=${HOME}/acct_expiring/bin:${HOME}/bin:/usr/bin:/usr/ucb:/usr/local/bin

export USER HOME PATH 

LOG=log/acct_expiring.log
OLDLOG=log/acct_expiring-old.log

find ${OLDLOG} -mtime +31 -exec mv -f ${LOG} {} \;

TS=`whenis -f "%04year%02nmonth%02day%02hour" now`

cd $HOME \
&& \
( \
	cd acct_expiring;      \
	date; \
	bin/oascosting.sh bin/report_acctexp.pl -v archive/acct_exp${TS};
) >> log/acct_expiring.log 2>&1
