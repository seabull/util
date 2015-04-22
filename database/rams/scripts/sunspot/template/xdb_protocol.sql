connect SYS/change_on_install as SYSDBA
set echo on
spool _LOGS_DIR_/xdb_protocol.log
@_DB_HOME_/rdbms/admin/catqm.sql change_on_install XDB TEMP;
connect SYS/change_on_install as SYSDBA
@_DB_HOME_/rdbms/admin/catxdbj.sql;
spool off
exit;
