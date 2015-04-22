connect SYS/change_on_install as SYSDBA
set echo on
spool _LOGS_DIR_/odm.log
@_DB_HOME_/dm/admin/dminst.sql ODM TEMP _LOGS_DIR_/;
connect SYS/change_on_install as SYSDBA
revoke AQ_ADMINISTRATOR_ROLE from ODM;
spool off
exit;
