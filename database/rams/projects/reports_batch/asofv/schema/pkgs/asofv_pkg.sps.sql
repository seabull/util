-- $Id: asofv_pkg.sps.sql,v 1.4 2006/08/07 18:01:53 yangl Exp $
--

create or replace package utility.asofv_pkg
	authid current_user
as
	-- Type definitions

	-- Public Constants, should they be private?
	NEWLINE		constant varchar2(1)		:= chr(10);
	PARAMTBLSCHEMA	constant all_tables.owner%TYPE	:= 'UTILITY';
	PARAMTBLNAME	constant all_tables.table_name%TYPE	:= 'ASOFV_PARAM';
	ASOFV_POSTFIX	constant varchar2(6)		:= '_ASOFV';
	ParamTblFlag	constant utility.asofv_param.flag%TYPE	:= 'H';

	-- public functions/procedures
	--function vcreate(
	procedure vcreate(
			pTblSchema	IN	all_tables.owner%TYPE
			,pTblName	IN	all_tables.table_name%TYPE
			,pVSchema	IN	all_tables.owner%TYPE
			,pVName		IN	all_tables.table_name%TYPE
			,pParamTblFlag	IN	varchar2	default ParamTblFlag
			,pParamTblSchema	IN	all_tables.owner%TYPE	default PARAMTBLSCHEMA
			,pParamTblName	IN	all_tables.table_name%TYPE	default PARAMTBLNAME
			)
		;
		--return boolean;

end asofv_pkg;
/
show error

