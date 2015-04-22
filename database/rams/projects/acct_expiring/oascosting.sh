#!/bin/sh
# $Id: oascosting.sh,v 1.1 2005/07/25 21:26:52 yangl Exp $

e=1

prog=`basename \$0 .sh`

trap 'e=$?; exit' 1 2 15
trap 'rm -f /tmp/${prog}$$*; trap 0; exit $e' 0

krb5=/usr/local/

ORACLE_BASE=/usr1/app/oracle
ORACLE_HOME=${ORACLE_BASE}/product/9.2
PATH=$ORACLE_HOME/bin:$PATH
LD_LIBRARY_PATH=${ORACLE_HOME}/lib:/usr/dt/lib:/usr/openwin/lib:${krb5}lib
KRB5CCNAME=${KRB5CCNAME-"/tkt/${USER}-v5"}

export ORACLE_BASE ORACLE_HOME PATH LD_LIBRARY_PATH KRB5CCNAME

${krb5}bin/kinit -k -t /usr/costing/etc/keytab --fcache-version=3 costing

exec "$@"
