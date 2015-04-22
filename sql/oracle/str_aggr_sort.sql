-- $Id: str_aggr_sort.sql,v 1.1 2005/06/10 18:01:54 yangl Exp $
--
/***
	Just take the original stragg unchanged:
	ORA9IR2>  select deptno, stragg(ename) over (partition by deptno order by ename) ename
		from emp;
 
    	DEPTNO ENAME
	---------- ----------------------------------------
       	10 CLARK
       	10 CLARK,KING
       	10 CLARK,KING,MILLER
       	20 ADAMS
       	20 ADAMS,FORD
       	20 ADAMS,FORD,JONES
       	20 ADAMS,FORD,JONES,SCOTT
       	20 ADAMS,FORD,JONES,SCOTT,SMITH
       	30 ALLEN
       	30 ALLEN,BLAKE
       	30 ALLEN,BLAKE,JAMES
       	30 ALLEN,BLAKE,JAMES,MARTIN
       	30 ALLEN,BLAKE,JAMES,MARTIN,TURNER
       	30 ALLEN,BLAKE,JAMES,MARTIN,TURNER,WARD

	Ok, here is one that does "sorted" aggregates:
***/ 

create or replace type vcArray as table of varchar2(4000)
/


create or replace type string_agg_type as object
(
	data  vcArray,
	static function ODCIAggregateInitialize(sctx IN OUT string_agg_type )
		return number
	,member function ODCIAggregateIterate(	
				self IN OUT string_agg_type 
				,value IN varchar2 )
		return number
	,member function ODCIAggregateTerminate(
				self IN string_agg_type
				,returnValue OUT  varchar2
				,flags IN number
				)
		return number
	,member function ODCIAggregateMerge(
				self IN OUT string_agg_type
				,ctx2 IN string_agg_type
				)
		return number
);
/

create or replace type body string_agg_type
is
	static function ODCIAggregateInitialize(sctx IN OUT string_agg_type)
		return number
	is
	begin
		sctx := string_agg_type( vcArray() );
		return ODCIConst.Success;
	end;

	member function ODCIAggregateIterate(
					self IN OUT string_agg_type
					,value IN varchar2 
					)
		return number
	is
	begin
		data.extend;
		data(data.count) := value;
		return ODCIConst.Success;
	end;

	member function ODCIAggregateTerminate(self IN string_agg_type,
			returnValue OUT varchar2,
			flags IN number)
		return number
	is
		l_data varchar2(4000);
	begin
		for x in ( select column_value from TABLE(data) order by 1 )
		loop
			l_data := l_data || ',' || x.column_value;
		end loop;
		returnValue := ltrim(l_data,',');
		return ODCIConst.Success;
	end;

	member function ODCIAggregateMerge(self IN OUT string_agg_type,
			ctx2 IN string_agg_type)
		return number
	is
	begin -- not really tested ;)
		for i in 1 .. ctx2.data.count
		loop
			data.extend;
			data(data.count) := ctx2.data(i);
		end loop;
		return ODCIConst.Success;
	end;


end;
/
 
CREATE or replace FUNCTION stragg(input varchar2 )
	RETURN varchar2
	PARALLEL_ENABLE AGGREGATE USING string_agg_type;
/
 
/**
ORA9IR2> column ename format a40
ORA9IR2> select deptno, stragg(ename) ename
  2    from emp
  3   group by deptno
  4  /
 
    DEPTNO ENAME
---------- ----------------------------------------
        10 CLARK,KING,MILLER
        20 ADAMS,FORD,JONES,SCOTT,SMITH
        30 ALLEN,BLAKE,JAMES,MARTIN,TURNER,WARD
 


You could take the above other example and apply the same technique (the 
row_number() concept is intriguing as it allows you to specify some other sorted order) 
 
***/
