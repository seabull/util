set echo on
spool _LOGS_DIR_/cwmlite.log
connect SYS/change_on_install as SYSDBA
@_DB_HOME_/olap/admin/olap.sql _DB_SID_;
connect SYS/change_on_install as SYSDBA
@_DB_HOME_/cwmlite/admin/oneinstl.sql CWMLITE TEMP;
spool off
exit;
