-- $Header: c:\\Repository/database/rams/projects/reports_batch/ChargeChangeBatch/schema/pkgs/Error_Codes.sps.sql,v 1.2 2006/04/24 20:36:21 yangl Exp $
--
create or replace package Error_Codes 
	authid definer
as
	-- Codes for application errors in ccreport
	err_codes_start		pls_integer := -20200;

	err_invalid_reportid	pls_integer := err_codes_start - 1;
	-- 20202
	err_reportid_notfound	pls_integer := err_codes_start - 2;

	err_method_call		pls_integer := err_codes_start - 3;

	err_arg_null		pls_integer := err_codes_start - 4;

end Error_Codes;
/
show error

grant execute on Error_Codes to public;
