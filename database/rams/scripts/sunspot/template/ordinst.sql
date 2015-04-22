connect SYS/change_on_install as SYSDBA
set echo on
spool _LOGS_DIR_/ordinst.log
@_DB_HOME_/ord/admin/ordinst.sql;
spool off
exit;
