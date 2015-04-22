connect SYS/change_on_install as SYSDBA
set echo on
spool _LOGS_DIR_/spatial.log
@_DB_HOME_/md/admin/mdinst.sql;
spool off
exit;
