REM
REM see plantable.sql for info to create plan_table.
REM
REM	related: V$SQL_PLAN - contains actual plan for an *executed* SQL
REM
REM @?/rdbms/admin/utlxplan.sql to create plan_table
REM @?/rdbms/admin/utlxplp.sql displays the contents of the plan table.
REM @?/rdbms/admin/utlxpls.sql displays the contents of the plan table for normal plans.
REM 

REM Usage of explain plan
REM
REM explain plan [set statement_id='text'] [into [owner.]tablename] for statement;
REM @?/rdbms/admin/utlxpls

REM
REM Usage of DBMS_XPLAN and V$SQL_PLAN
REM
REM create or replace view dynamic_plan_table
REM	as select
REM		rawtohex(Address) || '_' || child_number statement_id
REM		,sysdate timestamp
REM		, operation
REM		, options
REM		, object_node
REM		, object_owner
REM		, object_name
REM		, 0
REM		, object_instance
REM		, optimizer
REM		, search_columns
REM		, id
REM		, parent_id
REM		, position
REM		, cost
REM		, cardinality
REM		, bytes
REM		, other_tag
REM		, partition_start
REM		, partition_stop
REM		, partition_id
REM		, other
REM		, distribution
REM		, cpu_cost
REM		, io_cost
REM		, temp_space
REM		, access_predicates
REM		, filter_predicates
REM	from v$sql_plan
REM
REM	SQLPLUS>select plan_table_output from TABLE(dbms_xplan.display('dynamic_plan_table',
REM			select rawtohex(address)||'_'||child_number x
REM			from v$sql
REM			where sql_text='select * from t t1 where object_id > 32000')
REM			, 'serial' ))
REM	SQLPLUS>/

