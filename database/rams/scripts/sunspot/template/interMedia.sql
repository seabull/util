connect SYS/change_on_install as SYSDBA
set echo on
spool _LOGS_DIR_/interMedia.log
@_DB_HOME_/ord/im/admin/iminst.sql;
spool off
exit;
