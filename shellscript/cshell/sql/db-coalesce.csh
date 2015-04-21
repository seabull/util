#!/bin/csh -f
#------------------------------------------------------------------------------

  ( echo set head off feedback off ; echo "select tablespace_name from dba_tablespaces ;" ) \
    | sqlplus -s $CXAPPS \
    | sed '/^$/d' \
    | awk '{ printf "alter tablespace %s coalesce ;\n", $1 }' \
    | awk '{ printf "prompt + %s\n%s\n", $0, $0 }' \
    | sqlplus -s $CXAPPS \
    | sed '/^$/d'

#------------------------------------------------------------------------------
