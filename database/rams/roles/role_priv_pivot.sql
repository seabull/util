set pagesize 50000
set heading off
set echo off
set termout off
set feedback off

REM object privileges granted to each role

column roles heading role format a16
column priv heading priv format a8
column table_name format a36
column BACKUP_ADMIN heading BACKUP_ADMIN format a10
column BACKUP_CHANGE heading BACKUP_CHANGE format a10
column COSTING_ADMIN heading  COSTING_ADMIN format a10
column COSTING_CHANGE heading  COSTING_CHANGE format a10
column COSTING_VIEW heading  COSTING_VIEW format a10
column EQUIP_ADMIN heading  EQUIP_ADMIN format a10
column EQUIP_CHANGE heading  EQUIP_CHANGE format a10
column EQUIP_VIEW heading  EQUIP_VIEW format a10
column EQUIP_WIZARD heading  EQUIP_WIZARD format a10
column MAD_CHANGE heading  MAD_CHANGE format a10
column MAD_VIEW heading  MAD_VIEW format a10
column NET_CHANGE heading  NET_CHANGE format a10
column NET_VIEW heading  NET_VIEW format a10
column PURCH_QUERY heading  PURCH_QUERY format a10
column PURCH_UPDATE heading  PURCH_UPDATE format a10
column PURCH_VIEW heading  PURCH_VIEW format a10
column WEB_ACL_VIEW heading  WEB_ACL_VIEW format a10
column WEB_CHANGE heading  WEB_CHANGE format a10
column WEB_VIEW heading  WEB_VIEW format a10

spool rolesPivot.lst

select 
	'|'||'*table_name priv*'
	||'|'||'*BACKUP_ADMIN*'
	||'|'||'*BACKUP_CHANGE*'
	||'|'||'*COSTING_ADMIN*'
	||'|'||'*COSTING_CHANGE*'
	||'|'||'*COSTING_VIEW*'
	||'|'||'*EQUIP_ADMIN*'
	||'|'||'*EQUIP_CHANGE*'
	||'|'||'*EQUIP_VIEW*'
	||'|'||'*EQUIP_WIZARD*'
	||'|'||'*MAD_CHANGE*'
	||'|'||'*MAD_VIEW*'
	||'|'||'*NET_CHANGE*'
	||'|'||'*NET_VIEW*'
	||'|'||'*PURCH_QUERY*'
	||'|'||'*PURCH_UPDATE*'
	||'|'||'*PURCH_VIEW*'
	||'|'||'*WEB_ACL_VIEW*'
	||'|'||'*WEB_CHANGE*'
	||'|'||'*WEB_VIEW*'
	||'|'
from dual
/

select 
	'|'||table_name
	||'|'||max( decode(grantee,'BACKUP_ADMIN', 'X', ' ') ) 
	||'|'||max( decode(grantee,'BACKUP_CHANGE', 'X', ' ') ) 
	||'|'||max( decode(grantee,'COSTING_ADMIN', 'X', ' ') ) 
	||'|'||max( decode(grantee,'COSTING_CHANGE', 'X', ' ') ) 
	||'|'||max( decode(grantee,'COSTING_VIEW', 'X', ' ') )
	||'|'||max( decode(grantee,'EQUIP_ADMIN', 'X', ' ') )
	||'|'||max( decode(grantee,'EQUIP_CHANGE', 'X', ' ') )
	||'|'||max( decode(grantee,'EQUIP_VIEW', 'X', ' ') )
	||'|'||max( decode(grantee,'EQUIP_WIZARD', 'X', ' ') )
	||'|'||max( decode(grantee,'MAD_CHANGE', 'X', ' ') )
	||'|'||max( decode(grantee,'MAD_VIEW', 'X', ' ') ) 
	||'|'||max( decode(grantee,'NET_CHANGE', 'X', ' ') )
	||'|'||max( decode(grantee,'NET_VIEW', 'X', ' ') ) 
	||'|'||max( decode(grantee,'PURCH_QUERY', 'X', ' ') ) 
	||'|'||max( decode(grantee,'PURCH_UPDATE', 'X', ' ') ) 
	||'|'||max( decode(grantee,'PURCH_VIEW', 'X', ' ') ) 
	||'|'||max( decode(grantee,'WEB_ACL_VIEW', 'X', ' ') ) 
	||'|'||max( decode(grantee,'WEB_CHANGE', 'X', ' ') ) 
	||'|'||max( decode(grantee,'WEB_VIEW', 'X', ' ') ) 
	||'|'
from (
	select 
		grantee ,owner||'.'||table_name||' '||privilege table_name
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
)
group by table_name
/

REM roles granted to each user

column grantee heading grantee format a36
select 
	'|'||'*table_name priv*'
	||'|'||'*BACKUP_ADMIN*'
	||'|'||'*BACKUP_CHANGE*'
	||'|'||'*COSTING_ADMIN*'
	||'|'||'*COSTING_CHANGE*'
	||'|'||'*COSTING_VIEW*'
	||'|'||'*EQUIP_ADMIN*'
	||'|'||'*EQUIP_CHANGE*'
	||'|'||'*EQUIP_VIEW*'
	||'|'||'*EQUIP_WIZARD*'
	||'|'||'*MAD_CHANGE*'
	||'|'||'*MAD_VIEW*'
	||'|'||'*NET_CHANGE*'
	||'|'||'*NET_VIEW*'
	||'|'||'*PURCH_QUERY*'
	||'|'||'*PURCH_UPDATE*'
	||'|'||'*PURCH_VIEW*'
	||'|'||'*WEB_ACL_VIEW*'
	||'|'||'*WEB_CHANGE*'
	||'|'||'*WEB_VIEW*'
	||'|'
from dual
/
select 
	'|'||grantee 
	||'|'||max( decode(granted_role,'BACKUP_ADMIN', 'X', ' ') ) 
	||'|'||max( decode(granted_role,'BACKUP_CHANGE', 'X', ' ') ) 
	||'|'||max( decode(granted_role,'COSTING_ADMIN', 'X', ' ') ) 
	||'|'||max( decode(granted_role,'COSTING_CHANGE', 'X', ' ') ) 
	||'|'||max( decode(granted_role,'COSTING_VIEW', 'X', ' ') ) 
	||'|'||max( decode(granted_role,'EQUIP_ADMIN', 'X', ' ') ) 
	||'|'||max( decode(granted_role,'EQUIP_CHANGE', 'X', ' ') ) 
	||'|'||max( decode(granted_role,'EQUIP_VIEW', 'X', ' ') ) 
	||'|'||max( decode(granted_role,'EQUIP_WIZARD', 'X', ' ') ) 
	||'|'||max( decode(granted_role,'MAD_CHANGE', 'X', ' ') ) 
	||'|'||max( decode(granted_role,'MAD_VIEW', 'X', ' ') ) 
	||'|'||max( decode(granted_role,'NET_CHANGE', 'X', ' ') ) 
	||'|'||max( decode(granted_role,'NET_VIEW', 'X', ' ') ) 
	||'|'||max( decode(granted_role,'PURCH_QUERY', 'X', ' ') ) 
	||'|'||max( decode(granted_role,'PURCH_UPDATE', 'X', ' ') ) 
	||'|'||max( decode(granted_role,'PURCH_VIEW', 'X', ' ') ) 
	||'|'||max( decode(granted_role,'WEB_ACL_VIEW', 'X', ' ') )
	||'|'||max( decode(granted_role,'WEB_CHANGE', 'X', ' ') )
	||'|'||max( decode(granted_role,'WEB_VIEW', 'X', ' ') ) 
	||'|'
from (
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
)
group by grantee
/

/*
select 
	granted_role
	,grantee
	--,admin_option
from dba_role_privs
where grantee not in (
			select granted_role
			from dba_role_privs
			)
and grantee not IN ('XDB','SYS','WMSYS','WKSYS','SYSTEM','OUTLN','ODM','OLAPSYS','CTXSYS','DBSNMP')
order by granted_role, grantee
/
*/

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

