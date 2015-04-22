-- $Id: str_aggr.sql,v 1.1 2005/10/11 14:08:49 yangl Exp $
--

grant create session, create procedure, create type to utility;

create or replace type utility.string_agg_type as object
(
	total varchar2(4000)

	,static function ODCIAggregateInitialize(sctx IN OUT string_agg_type )
		return number
	,member function ODCIAggregateIterate(self IN OUT string_agg_type 
						, value IN varchar2 )
		return number

	,member function ODCIAggregateTerminate(self IN string_agg_type
						, returnValue OUT  varchar2
						, flags IN number)
		return number
	,member function ODCIAggregateMerge(self IN OUT string_agg_type
						, ctx2 IN string_agg_type)
		return number
);
/

create or replace type body utility.string_agg_type
is

	/*********************
		init
	***********************/
	static function ODCIAggregateInitialize(sctx IN OUT string_agg_type)
		return number
	is
	begin
		sctx := string_agg_type( null );
		return ODCIConst.Success;
	end;

	member function ODCIAggregateIterate(self IN OUT string_agg_type
						, value IN varchar2 )
		return number
	is
	begin
		self.total := self.total || ',' || value;
		return ODCIConst.Success;
	end;
 
	member function ODCIAggregateTerminate(self IN string_agg_type
					, returnValue OUT varchar2
					, flags IN number)
		return number
	is
	begin
		-- trim the leading comma
		returnValue := ltrim(self.total,',');
		return ODCIConst.Success;
	end;
  
	member function ODCIAggregateMerge(self IN OUT string_agg_type, ctx2 IN string_agg_type)
		return number
	is
	begin
		self.total := self.total || ctx2.total;
		return ODCIConst.Success;
	end;
end;
/

CREATE or replace FUNCTION utility.stragg(input varchar2 )
	RETURN varchar2
	PARALLEL_ENABLE AGGREGATE USING string_agg_type;
/

grant execute on utility.stragg to public;
grant execute on utility.string_agg_type to public;
create public synonym stragg for utility.stragg;
revoke create session, create procedure, create type from utility;
