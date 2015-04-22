-- $Header: c:\\Repository/sql/oracle/plsql/utils/asof/asof_views.sps.sql,v 1.1 2006/03/02 18:39:54 yangl Exp $
set serveroutput on
create or replace package asof_views
	authid current_user
as
	type colname_tab is table of all_tables.table_name%TYPE;

	procedure new(p_srcOwner IN all_tables.owner%TYPE
			,p_srcTab	IN all_tables.table_name%TYPE
			,p_dstOwner	IN all_tables.owner%TYPE
			,p_dstView	IN all_tables.table_name%TYPE
			);
end;
/
show error

--/*
--select
--	unique
--	owner||'.'||table_name
--	,iot_type
--  from dba_tables
-- where owner='HOSTDB'
--/
--
---- Primary key
--select
--	cc.table_name
--	,cc.column_name
--	,cc.position
--  from dba_constraints
-- where owner='HOSTDB'
--   and constraint_type='P'
--   and status='ENABLED'
--   and c.owner=cc.owner
--   and c.table_name=cc.table_name
--order by cc.table_name, cc.position
--/
--
---- Unique constraint
--select
--	cc.table_name
--	,cc.column_name
--	,cc.position
--  from dba_constraints c
--	,dba_cons_columns cc
-- where c.owner='HOSTDB'
--   and constraint_type='U'
--   and status='ENABLED'
--   and c.owner=cc.owner
--   and c.table_name=cc.table_name
--order by cc.table_name, cc.position
--/
--*/
