-- $Header: c:\\Repository/sql/oracle/month_aggr.sql,v 1.4 2006/03/14 21:15:25 yangl Exp $
--
/**********************************
examples:
	select deptno, monthagg(ename)
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
-- exec this file to create monthagg.
-- grant execute on month_agg_type to public;
-- grant execute on monthagg to public;
--
-- as sysdba
-- create public synonym month_agg_type for month_agg_type ;
-- create public synonym monthagg for monthagg ;
-- revoke create session, create procedure,create table, create type from utility;
-- 


create or replace type month_agg_type as object
(
	total		varchar2(4000)
	,lastdate	date
	,consecutive	number(2)

	,static function ODCIAggregateInitialize(sctx IN OUT month_agg_type )
		return number
	,member function ODCIAggregateIterate(self IN OUT month_agg_type 
						, value IN varchar2 )
		return number

	,member function ODCIAggregateTerminate(self IN month_agg_type
						, returnValue OUT  varchar2
						, flags IN number)
		return number
	,member function ODCIAggregateMerge(self IN OUT month_agg_type
						, ctx2 IN month_agg_type)
		return number
);
/

create or replace type body month_agg_type
is

	/*********************
		init
	***********************/
	static function ODCIAggregateInitialize(sctx IN OUT month_agg_type)
		return number
	is
	begin
		sctx := month_agg_type( null, null, 0 );
		return ODCIConst.Success;
	end;

	member function ODCIAggregateIterate(self IN OUT month_agg_type
						, value IN varchar2 )
		return number
	is
		l_sep	char(1)	:= ',';
		--l_xx	number(2) := 0;
		l_gap	number(2)	:= 0;
	begin
		if(self.total is null) then
			traceit.log(traceit.constDEBUGLEVEL_A, '%s', value);
			self.total := to_char(to_date(value), 'Mon');
			self.lastdate := trunc(to_date(value));
			self.consecutive := 0;
		else
			--l_xx := instr(self.total, ','||value);
			l_gap := floor(months_between(trunc(to_date(value)), trunc(self.lastdate)));
			traceit.log(traceit.constDEBUGLEVEL_A, 'l_gap=%s, %s, %s', l_gap, self.lastdate, value);
			if l_gap < 0 then
				raise_application_error(-20100, 'Expect increasing months. Got'||l_gap);
			elsif (l_gap <= 1 ) then
				if l_gap > 0 then
					--
					-- do nothing for l_gap=0 i.e. adjustments in the same month.
					-- 
					--self.lastdate := to_date(value);
					self.consecutive := self.consecutive + 1;
				end if;
			else
				-- need to make sure l_gap > 1
				if self.consecutive > 0 then
					self.consecutive := 0;
					self.total := self.total || '-' || to_char(self.lastdate, 'Mon') ;
					-- self.total := self.total || l_sep || to_char(self.lastdate, 'Mon');
				end if;
				self.total := self.total || l_sep || to_char(to_date(value), 'Mon');
			end if;
			self.lastdate := to_date(value);
		end if;
		traceit.log(traceit.constDEBUGLEVEL_A, 'total=%s', self.total);
		return ODCIConst.Success;
	end;
 
	member function ODCIAggregateTerminate(self IN month_agg_type
					, returnValue OUT varchar2
					, flags IN number)
		return number
	is
	begin
		traceit.log(traceit.constDEBUGLEVEL_A, 'Term - %s, %s', self.consecutive, self.lastdate);
		if self.consecutive > 0 then
			-- self.consecutive := 0;
			returnValue := self.total || '-' || to_char(self.lastdate, 'Mon') ;
		else
			returnValue := self.total;
		end if;
		traceit.log(traceit.constDEBUGLEVEL_A, 'Term - %s', returnValue);
		-- trim the leading comma
		-- returnValue := ltrim(self.total,',');
		return ODCIConst.Success;
	end;
  
	member function ODCIAggregateMerge(self IN OUT month_agg_type, ctx2 IN month_agg_type)
		return number
	is
	begin
		self.total := self.total || ctx2.total;
		return ODCIConst.Success;
	end;
end;
/

CREATE or replace FUNCTION monthagg(input varchar2 )
	RETURN varchar2
	PARALLEL_ENABLE AGGREGATE USING month_agg_type;
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
