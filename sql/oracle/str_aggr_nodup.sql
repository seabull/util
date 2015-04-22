-- $Id: str_aggr_nodup.sql,v 1.1 2006/08/25 17:29:19 yangl Exp $
--
/**********************************
examples:
	select deptno, stragg(ename)
	  from emp
	group by deptno
/

    DEPTNO STRAGG(ENAME)
---------- --------------------------------
        10 CLARK,KING,MILLER

        20 SMITH,FORD,ADAMS,SCOTT,JONES

        30 ALLEN,BLAKE,MARTIN,TURNER,JAMES,WARD

******************************************/
-- as sysdba
-- grant create session, create procedure, create table, create type to utility;
--  
-- as utility
--
-- exec this file to create stragg.
-- grant execute on string_agg_type to public;
-- grant execute on stragg to public;
--
-- as sysdba
-- create public synonym string_agg_type for utility.string_agg_type ;
-- create public synonym stragg for utility.stragg ;
-- revoke create session, create procedure,create table, create type from utility;
-- 


create or replace type utility.string_agg_nodup_type as object
(
	total varchar2(4000)

	,static function ODCIAggregateInitialize(sctx IN OUT string_agg_nodup_type )
		return number
	,member function ODCIAggregateIterate(self IN OUT string_agg_nodup_type 
						, value IN varchar2 )
		return number

	,member function ODCIAggregateTerminate(self IN string_agg_nodup_type
						, returnValue OUT  varchar2
						, flags IN number)
		return number
	,member function ODCIAggregateMerge(self IN OUT string_agg_nodup_type
						, ctx2 IN string_agg_nodup_type)
		return number
);
/

create or replace type body utility.string_agg_nodup_type
is

	/*********************
		init
	***********************/
	static function ODCIAggregateInitialize(sctx IN OUT string_agg_nodup_type)
		return number
	is
	begin
		sctx := string_agg_nodup_type( null );
		return ODCIConst.Success;
	end;

	member function ODCIAggregateIterate(self IN OUT string_agg_nodup_type
						, value IN varchar2 )
		return number
	is
		l_sep	char(1)	:= ',';
		--l_xx	pls_integer := 0;
	begin
		if(self.total is null) then
			self.total := l_sep||value;
		else
			--l_xx := instr(self.total, ','||value);
			if(instr(self.total, l_sep||value) = 0) then
				self.total := self.total || l_sep || value;
			end if;
		end if;
		return ODCIConst.Success;
	end;
 
	member function ODCIAggregateTerminate(self IN string_agg_nodup_type
					, returnValue OUT varchar2
					, flags IN number)
		return number
	is
	begin
		-- trim the leading comma
		returnValue := ltrim(self.total,',');
		return ODCIConst.Success;
	end;
  
	member function ODCIAggregateMerge(self IN OUT string_agg_nodup_type, ctx2 IN string_agg_nodup_type)
		return number
	is
	begin
		self.total := self.total || ctx2.total;
		return ODCIConst.Success;
	end;
end;
/

CREATE or replace FUNCTION utility.stragg_nodup(input varchar2 )
	RETURN varchar2
	PARALLEL_ENABLE AGGREGATE USING string_agg_nodup_type;
/

/**********************************************

If the max number of values within each group is finite, known, and relatively 
small, then straight sql will do.  For example, my hypothetical company has a 
maximum number of five employees per department:

SQL> ---------------------
SQL> -- View sample table.
SQL> ---------------------
SQL> 
SQL> select dept,
  2          emp_name
  3  from temp_01_tb
  4  order by 1,2
  5  ;

   DEPT  EMP_NAME
-------  --------------------
      1  Bob
      1  David
      1  Sally
      1  Sam
      2  Jane
      2  Jennifer
      2  Joe
SQL> 
SQL> -------------------------
SQL> -- Perform string concat.
SQL> -------------------------
SQL> 
SQL> select dept,
  2          max(decode(my_seq,1,emp_name)) || ' ' ||
  3          max(decode(my_seq,2,emp_name)) || ' ' ||
  4          max(decode(my_seq,3,emp_name)) || ' ' ||
  5          max(decode(my_seq,4,emp_name)) || ' ' ||
  6          max(decode(my_seq,5,emp_name)) emp_list
  7  from (
  8        select dept,
  9           emp_name,
 10           row_number() over
 11             (partition by dept order by emp_name) my_seq
 12        from temp_01_tb
 13        )
 14  group by dept
 15  order by 1
 16  ;

   DEPT  EMP_LIST
-------  --------------------------------------------
      1  Bob David Sally Sam
      2  Jane Jennifer Joe

***********************************************/
