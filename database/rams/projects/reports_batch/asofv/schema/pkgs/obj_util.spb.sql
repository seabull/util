-- $Id
--
create or replace package body utility.obj_util is
	--
	-- Function to check if the given object is a table in user's schema 
	--
	function is_table(
			pOwner in varchar2
			,pName in varchar2
		) return boolean
	is
		stmt_cursor number;	-- stmt cursor
		rc          number;	-- return code
		found       number;
	begin
		found := 0;
		stmt_cursor := dbms_sql.open_cursor;
		dbms_sql.parse(stmt_cursor,
			'begin
				select 1
				  into :found
				  from all_tables
				 where table_name = upper(:item_name)
				   and owner      = upper(:item_owner);
			exception
				when others then
					:found := 0;
			end;'
			, dbms_sql.native
		);
		dbms_sql.bind_variable(stmt_cursor, ':item_owner', pOwner);
		dbms_sql.bind_variable(stmt_cursor, ':item_name', pName);
		dbms_sql.bind_variable(stmt_cursor, ':found', found);

		rc := dbms_sql.execute(stmt_cursor);

		dbms_sql.variable_value(stmt_cursor, ':found', found);
		dbms_sql.close_cursor(stmt_cursor);
		return(found <> 0);
	end is_table;
	
	--
	-- Function to check if the given object is a view in user's schema */
	--
	function is_view(
			pOwner in varchar2
			,pName in varchar2
		) return boolean
	is
		stmt_cursor	number;	-- stmt cursor
		rc		number;	-- return code
		found		number;
	begin
		found := 0;
		stmt_cursor := dbms_sql.open_cursor;
		dbms_sql.parse(stmt_cursor,
			'begin
				select 1
				  into :found
				  from all_views
				 where view_name = upper(:item_name)
				   and owner     = upper(:item_owner);
			 exception
				when others then
					:found := 0;
			 end;'
			, dbms_sql.native
			);
		dbms_sql.bind_variable(stmt_cursor, ':item_owner', pOwner);
		dbms_sql.bind_variable(stmt_cursor, ':item_name', pName);
		dbms_sql.bind_variable(stmt_cursor, ':found', found);

		rc := dbms_sql.execute(stmt_cursor);

		dbms_sql.variable_value(stmt_cursor, ':found', found);
		dbms_sql.close_cursor(stmt_cursor);
		return(found <> 0);
	end is_view;

end obj_util;
/
Show errors
grant execute on utility.obj_util to public;
create public synonym obj_util for utility.obj_util;
