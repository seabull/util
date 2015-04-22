#!/bin/sh

e=1

prog=`basename $0 .sh`; export prog

trap 'e=$?; exit' 1 2 15
trap 'rm -f /tmp/${prog}$$* ${RMTMP}; trap 0; exit $e' 0

SRC=src/
#DB_HOST=hostdb.fac.cs.cmu.edu
DB_HOST=fac_je
X_SCP=/usr/local/bin/scp
src="${1?}"
rpt="${2?}"

which=`head -1 <$src | awk '{print $4;}'`

test -n "$which" || exit 

which=${which}.rpt

echo "[ Fetching $which ]"

${X_SCP} -i ${HOME}/fmp-down \
    transfer@mistral.as.cmu.edu:cs_recharge/logs/${which}  . \
&& \
cp $which $rpt
#${SRC}errors.pl feeder.rpt > ${SRC}feeder.sql
#${SRC}oasme.sh sqlplus -s /@${DB_HOST} @${SRC}feeder.sql
e=$?
