-- $Header: c:\\Repository/sql/oracle/plsql/utils/asof/asof_views.spb.sql,v 1.3 2006/03/02 21:03:07 yangl Exp $
create or replace package body asof_views
as
	function getKey (p_owner IN all_tables.owner%TYPE
			, p_tabname IN all_tables.table_name%TYPE)
		return colname_tab;

	procedure new(p_srcOwner IN all_tables.owner%TYPE
				,p_srcTab	IN all_tables.table_name%TYPE
				,p_dstOwner	IN all_tables.owner%TYPE
				,p_dstView	IN all_tables.table_name%TYPE
				)
	is
	
		cursor csrAllTabs (p_owner all_tables.owner%TYPE) is
			select
				unique
				owner||'.'||table_name
				,iot_type
			  from all_tables
			 where owner=p_owner
			;
	
		cursor csrTabCols (p_owner		all_tables.owner%TYPE
					,p_tabname	all_tables.table_name%TYPE)
		is
			select
				column_name
				,data_type
				,data_length
				,data_precision
				,data_scale
			  from all_tab_columns
			 where owner=p_owner
			   and table_name=p_tabname
			;
	
		l_owner		all_tables.owner%TYPE		:= upper(p_srcOwner);
		l_tab		all_tables.table_name%TYPE	:= upper(p_srcTab);
		l_cols		varchar2(4000)			:= '';
		l_parcols	varchar2(4000)			:= '';
		l_hvtab		all_tables.table_name%TYPE	:= 'HISTVIEW_PARAM';
		l_keycols	colname_tab;
		l_i		pls_integer;
		l_sql		varchar2(30000);
		l_audOwner	all_tables.owner%TYPE		:= 'aud_' ||l_owner|| '.' || l_tab ;
	
	begin
		for col in csrTabCols(l_owner, l_tab) loop
				l_cols := l_cols || ',' || col.column_name || chr(10);
		end loop;
	
		l_keycols := getKey(l_owner, l_tab);
	
		if l_keycols is null then
			l_parcols := l_cols;
		else
			l_i := l_keycols.first;
			while l_i is not null loop
				l_parcols := ',' || l_keycols(l_i);
				l_i := l_keycols.next(l_i);
			end loop;
		end if;
		l_sql := ' create or replace view ' || p_dstOwner ||'.'|| p_dstView || chr(10)
				|| ' as ' || chr(10)
				|| ' select ' || ltrim(l_cols, ',') 
				|| '	( ' || chr(10)
					||' select ' || 'aud_ts ' || chr(10)
					|| l_cols 
					|| ',case when row_number() over (partition by '
					|| ltrim(l_parcols, ',') || ' order by aud_ts desc)=1 then ' || chr(10)
	                        	|| ' aud_action' || chr(10)
	                		|| ' end xxxxflag' || chr(10)
					|| ' from ' || l_audOwner || chr(10)
					|| ' where ' 
					|| ' aud_ts<=(select ts from ' 
								|| l_hvtab
							|| ' where id=(select max(id) from ' || l_hvtab
										|| ' where flag=''h'') '
							|| ' ) '
				|| '	) x ' || chr(10)
				|| ' where x.xxxxflag != ''D'';'
			;
	
		traceit.log(2, 'sql=%s', l_sql);
		execute immediate l_sql;
		--dbms_output.put_line(l_parcols);
	end new;

	function getKey (p_owner IN all_tables.owner%TYPE, p_tabname IN all_tables.table_name%TYPE)
		return colname_tab
	is
		l_owner		all_tables.owner%TYPE	:= upper(p_owner);
		l_tabname	all_tables.table_name%TYPE	:= upper(p_tabname);
		l_tColName	colname_tab;
		l_uniqcons	all_constraints.constraint_name%TYPE;
	begin
		begin
			select
				column_name
			bulk collect into l_tColName
			  from all_constraints c
				, all_cons_columns cc
			 where c.owner=l_owner
			   and c.table_name=l_tabname
			   and c.constraint_type='P'
			   and c.status='ENABLED'
			   and c.table_name=cc.table_name
			   and c.owner=cc.owner
			   and c.constraint_name=cc.constraint_name
			order by cc.position
			;
		exception
			when no_data_found then
				begin
					select c.constraint_name 
					  into l_uniqcons
					  from all_constraints c
					 where c.owner=l_owner
					   and c.table_name=l_tabname
					   and c.constraint_type='U'
					   and c.status='ENABLED'
					   and rownum < 2
					;

					select
						cc.column_name
					  bulk collect into l_tColName
					  from all_cons_columns cc
					 where cc.owner=l_owner
					   and cc.table_name=l_tabname
					   and cc.constraint_name=l_uniqcons
					order by cc.constraint_name, cc.position
					;
				exception
					when no_data_found then
						l_tColName := null;
				end;
		end;
		return l_tColName;
	end getKey;
	
end asof_views;
/
show error

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

