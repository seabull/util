-- $Header: c:\\Repository/database/rams/projects/reports_batch/AcctExpiringRpt/schema/pkgs/acctexp_conf.sps.sql,v 1.3 2006/05/17 20:05:13 yangl Exp $
--
create or replace package acctexp_conf 
	--authid current_user
	authid definer
as
	subtype id_t is ccreport.acctexp_config.ID%TYPE;
	subtype datecount_t is ccreport.acctexp_config.datecount%TYPE;
	subtype mflag_t is ccreport.acctexp_config.monthend_flag%TYPE;

	function getMaxID return id_t;

	procedure setDateCount (p_datecount IN datecount_t);
	function  getDateCount (p_id IN id_t default null) return datecount_t;

	procedure setMonthendFlag (p_mflag IN mflag_t);
	function  getMonthendFlag (p_id IN id_t default null) return mflag_t;

	-- Effective Date can only be changed if it has not taken effect yet.
	procedure setEffectiveDate (p_effectivedate IN date);
	function  getEffectiveDate (p_id IN id_t default null) return date;

	procedure setNewConfig (p_datecount		IN datecount_t
				, p_mflag		IN mflag_t
				, p_effectivedate	IN date
				);

	procedure getCurrentConfig (p_datecount		OUT datecount_t
				, p_mflag		OUT mflag_t
				, p_effectivedate	OUT date
				);
	
	procedure getConfig (	p_id			IN  id_t
				, p_datecount		OUT datecount_t
				, p_mflag		OUT mflag_t
				, p_effectivedate	OUT date
				);
	
end acctexp_conf;
/
show errors

grant execute on acctexp_conf to "COSTING@CS.CMU.EDU";
grant execute on acctexp_conf to ccreport_admin;
