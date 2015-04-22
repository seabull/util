set pagesize 50000
set heading on
set echo off
set termout off
set feedback off

-------------------------------------------------------------
-- roles granted to each user
-------------------------------------------------------------

column grantee heading grantee format a36

spool result_user_roles.lst
select 
	grantee
	,granted_role
	--,admin_option
from dba_role_privs
where grantee not in (
			select granted_role
			from dba_role_privs
			)
and grantee not IN 
	('XDB','SYS','WMSYS','WKSYS','SYSTEM','OUTLN','ODM','OLAPSYS','CTXSYS','DBSNMP')
and granted_role='WEB_VIEW'
order by grantee, granted_role
/
spool off


/*
 REM GRANTEE                                               NOT NULL VARCHAR2(30)
 REM OWNER                                                 NOT NULL VARCHAR2(30)
 REM TABLE_NAME                                            NOT NULL VARCHAR2(30)
 REM GRANTOR                                               NOT NULL VARCHAR2(30)
 REM PRIVILEGE                                             NOT NULL VARCHAR2(40)
 REM GRANTABLE                                                      VARCHAR2(3)
 REM HIERARCHY                                                      VARCHAR2(3)
*/

