-- $Header: c:\\Repository/database/rams/projects/reports_batch/AcctExpiringRpt/schema/pkgs/emailinfo.sps.sql,v 1.6 2006/07/17 20:32:53 yangl Exp $
--
create or replace package emailinfo 
	--authid current_user
	authid definer
as
	subtype acctstring_t	is varchar2(24);
	subtype acctid_t	is hostdb.accounts.id%TYPE;
	subtype acctstatus_t	is char;

	type accts_tc is table of acctstring_t index by binary_integer;

	-- Package Variable for Email mode
	--gEmailMode	varchar2(30)	:= hostdb.Account_Report_Email.mReportManagerOnly;
	gEmailMode	varchar2(30)	:= hostdb.Account_Report_Email.mProduction;

	procedure setEmailMode(p_Mode IN varchar2 default null);

	function fetchAEEmailInfo(
					p_numofdays IN pls_integer
					, p_asof IN date
			) return sys_refcursor;

	function fetchAEEmailInfo(
				p_rptid IN acctexp_rpt.rptid_type default null
				)
		return sys_refcursor;

	function fetchEmailInfo_pipe(
					p_acctstr_csr IN sys_refcursor
					, p_asof IN date
				)
		return EmailRecTbl
		pipelined;

	function fetchEmailInfo_cl(
					p_acctstr_csr IN sys_refcursor
					, p_asof IN date
				)
		return EmailRecTbl;

	procedure closeCursor(p_csr IN sys_refcursor);
end emailinfo;
/
show errors

grant execute on emailinfo to "COSTING@CS.CMU.EDU";
grant execute on emailinfo to ccreport_admin;
