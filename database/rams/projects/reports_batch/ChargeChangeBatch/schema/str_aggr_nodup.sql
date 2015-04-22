-- $Header: c:\\Repository/database/rams/projects/reports_batch/ChargeChangeBatch/schema/str_aggr_nodup.sql,v 1.2 2006/02/20 15:27:13 yangl Exp $
--
-- grant execute on string_agg_type to public;
-- grant execute on stragg to public;
--

create or replace type string_agg_nodup_type as object
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

create or replace type body string_agg_nodup_type
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
	begin
		if(self.total is null) then
			self.total := l_sep||value;
		else
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

CREATE or replace FUNCTION stragg_nodup(input varchar2 )
	RETURN varchar2
	PARALLEL_ENABLE AGGREGATE USING string_agg_nodup_type;
/

grant execute on string_agg_nodup_type to public;
grant execute on stragg_nodup to public;
