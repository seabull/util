connect SYS/change_on_install as SYSDBA
set echo on
spool _LOGS_DIR_/postDBCreation.log
@_DB_HOME_/rdbms/admin/utlrp.sql;
shutdown ;
startup mount pfile="_INIT_ORA_";
alter database archivelog;
alter database open;
alter system archive log start;
shutdown ;
connect SYS/change_on_install as SYSDBA
set echo on
spool _LOGS_DIR_/postDBCreation.log
create spfile='_SPFILE_NAME_' FROM pfile='_INIT_ORA_';
startup ;
