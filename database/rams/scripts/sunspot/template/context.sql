connect SYS/change_on_install as SYSDBA
set echo on
spool _LOGS_DIR_/context.log
@_DB_HOME_/ctx/admin/dr0csys change_on_install DRSYS TEMP;
connect CTXSYS/change_on_install
@_DB_HOME_/ctx/admin/dr0inst _DB_HOME_/lib/libctxx9.so;
@_DB_HOME_/ctx/admin/defaults/dr0defin.sql AMERICAN;
spool off
exit;
