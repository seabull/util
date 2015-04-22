set pagesize 50000
set heading on
set echo off
set termout off
set feedback off
/*
select
	unique granted_role
from dba_role_privs
where granted_role not like 'JAVA%'
and granted_role not like 'AQ%'
and granted_role not like 'AUTHENTICATEDUSER%'
and granted_role not like 'CONNECT'
and granted_role not like 'CTX%'
and granted_role not like 'DBA%'
and granted_role not like 'DELETE%'
and granted_role not like 'EJB%'
and granted_role not like 'EXP%'
and granted_role not like 'EXECUTE%'
and granted_role not like 'GATHER_SYSTEM_STATISTICS%'
and granted_role not like 'HS_ADMIN_ROLE%'
and granted_role not like 'IMP%'
and granted_role not like 'LOGSTDBY_ADMINISTRATOR%'
and granted_role not like 'OEM%'
and granted_role not like 'OLAP%'
and granted_role not like 'RECOVER%'
and granted_role not like 'RESOURCE%'
and granted_role not like 'SELECT%'
and granted_role not like 'WKUSER%'
and granted_role not like 'WM%'
and granted_role not like 'XDB%'
/
*/

REM object privileges granted to each role

column roles heading role format a16
column priv heading priv format a8
column table_name format a36
spool rolesResult.lst

select 
	grantee roles
	,owner||'.'||table_name table_name
	,privilege priv
from dba_tab_privs
where 
	grantee in (
		select
			unique granted_role
		from dba_role_privs
		where granted_role not like 'JAVA%'
		and granted_role not like 'AQ%'
		and granted_role not like 'AUTHENTICATEDUSER%'
		and granted_role not like 'CONNECT'
		and granted_role not like 'CTX%'
		and granted_role not like 'DBA%'
		and granted_role not like 'DELETE%'
		and granted_role not like 'EJB%'
		and granted_role not like 'EXP%'
		and granted_role not like 'EXECUTE%'
		and granted_role not like 'GATHER_SYSTEM_STATISTICS%'
		and granted_role not like 'HS_ADMIN_ROLE%'
		and granted_role not like 'IMP%'
		and granted_role not like 'LOGSTDBY_ADMINISTRATOR%'
		and granted_role not like 'OEM%'
		and granted_role not like 'OLAP%'
		and granted_role not like 'RECOVER%'
		and granted_role not like 'RESOURCE%'
		and granted_role not like 'SELECT%'
		and granted_role not like 'WKUSER%'
		and granted_role not like 'WM%'
		and granted_role not like 'XDB%'
	)
	--and grantee like '%VIEW'
	--and privilege in ('INSERT','DELETE','UPDATE')
order by grantee, owner, table_name, privilege
/

REM roles granted to each user

column grantee heading grantee format a36
select 
	grantee
	,granted_role
	--,admin_option
from dba_role_privs
where grantee not in (
			select granted_role
			from dba_role_privs
			)
and grantee not IN ('XDB','SYS','WMSYS','WKSYS','SYSTEM','OUTLN','ODM','OLAPSYS','CTXSYS','DBSNMP')
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

