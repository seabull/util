-- $Id: asofv_util.sps.sql,v 1.3 2006/08/07 18:01:53 yangl Exp $
--

create or replace package utility.asofv_util
	authid current_user
as
	-- Public Constants, should use the definition in asofv_pkg?
	PARAMTBLSCHEMA	constant all_tables.owner%TYPE		:= 'UTILITY';
	PARAMTBLNAME	constant all_tables.table_name%TYPE	:= 'ASOFV_PARAM';
	ParamTblFlag	constant utility.asofv_param.flag%TYPE	:= 'H';
	--
	-- procedures/functions to operate on param table.
	--
	procedure set_time(	pTS		in timestamp
				,pParamTblFlag	in varchar2	default ParamTblFlag
			);
	function get_time(	
				pParamTblFlag	in varchar2	default ParamTblFlag
			) return timestamp;
	procedure clear_time;
end asofv_util;
/
show error
