#!/bin/sh
e=1

prog=`basename \$0 .sh`

trap 'e=$?; exit' 1 2 15
trap 'rm -f /tmp/${prog}$$*; trap 0; exit $e' 0

#krb5=/afs/cs.cmu.edu/misc/krb5/@sys/omega/
krb5=/usr/local/

ORACLE_BASE=/usr1/app/oracle
ORACLE_HOME=${ORACLE_BASE}/product/9.2
PATH=$ORACLE_HOME/bin:$PATH
LD_LIBRARY_PATH=${ORACLE_HOME}/lib:/usr/dt/lib:/usr/openwin/lib:${krb5}lib
KRB5CCNAME=${KRB5CCNAME-"/tkt/${USER}-v5"}
KRB5CCNAME=`echo $KRB5CCNAME | sed -e 's/^FILE://'`

export ORACLE_BASE ORACLE_HOME ORACLE_SID PATH LD_LIBRARY_PATH KRB5CCNAME

${krb5}bin/kinit -k -t /usr/costing/etc/keytab --fcache-version=3 costing

exec "$@"
