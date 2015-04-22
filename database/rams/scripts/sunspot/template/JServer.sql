connect SYS/change_on_install as SYSDBA
set echo on
spool _LOGS_DIR_/JServer.log
@_DB_HOME_/javavm/install/initjvm.sql;
@_DB_HOME_/xdk/admin/initxml.sql;
@_DB_HOME_/xdk/admin/xmlja.sql;
@_DB_HOME_/rdbms/admin/catjava.sql;
spool off
exit;
