connect SYS/change_on_install as SYSDBA
set echo on
spool _LOGS_DIR_/ultraSearch.log
@_DB_HOME_/ultrasearch/admin/wk0install.sql SYS change_on_install change_on_install DRSYS TEMP "" PORTAL false;
spool off
exit;
