connect SYS/change_on_install as SYSDBA
set echo on
spool _LOGS_DIR_/CreateDBCatalog.log
@_DB_HOME_/rdbms/admin/catalog.sql;
@_DB_HOME_/rdbms/admin/catexp7.sql;
@_DB_HOME_/rdbms/admin/catblock.sql;
@_DB_HOME_/rdbms/admin/catproc.sql;
@_DB_HOME_/rdbms/admin/catoctk.sql;
@_DB_HOME_/rdbms/admin/owminst.plb;
connect SYSTEM/manager
@_DB_HOME_/sqlplus/admin/pupbld.sql;
spool off
connect SYSTEM/manager
set echo on
spool logs/sqlPlusHelp.log
@_DB_HOME_/sqlplus/admin/help/hlpbld.sql helpus.sql;
spool off
exit;
