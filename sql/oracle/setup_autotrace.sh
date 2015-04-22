#!/bin/sh

cd $ORACLE_HOME/rdbms/admin
#
# The Oracle user has to have CREATE TABLE and CREATE PUBLIC SYNONYM privs.
# Make sure PLAN_TABLE universally available.
#
sqlplus / <<EOF
@plustrace
grant plustrace to public;
quit
EOF

