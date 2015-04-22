-- $Header: c:\\Repository/database/rams/projects/reports_batch/AcctExpiringRpt/schema/pkgs/acctexp_rpt.sps.sql,v 1.6 2006/05/17 20:05:13 yangl Exp $
create or replace package acctexp_rpt authid definer
as
	-- Types and subtypes
	subtype rptid_type is	number ;

	constRptStatusInit	char(1)	:= 'i';
	constRptStatusRecorded	char(1)	:= 'r';

	--constRptDateCount	pls_integer	:= 45;
	
	function new return rptid_type;
	--function record return pls_integer;

	procedure closeReport(p_csr IN sys_refcursor);

	function record(p_rptid IN rptid_type)
		return pls_integer;

	function last return rptid_type;

	--function getExpAcctstrDataC(p_status IN acctstatus_t
	--			, p_date IN date
	--			, p_asof IN date default sysdate) 
	--	return sys_refcursor;

	function getRptEntries(p_id IN rptid_type default null)
		return sys_refcursor;

	function getRptEntriesAll(p_id IN rptid_type default null)
		return sys_refcursor;

	function getRptEntriesExpd(p_id IN rptid_type default null)
		return sys_refcursor;

	function matchReportByDate(p_gendate IN date) return rptid_type;

	function getAdhocExpEntries(p_numdays IN pls_integer default 30
				, p_asof IN date)
				--, p_asof IN date default trunc(sysdate))
		return sys_refcursor;

	function getAdhocExpEntries(p_numdays IN pls_integer default 30
				, p_asof IN pls_integer default 0)
		return sys_refcursor;

	function fetchExpAcctStrings(p_numdays IN pls_integer 
				, p_asof IN date)
		return sys_refcursor;

	function fetchExpAcctStrings(p_rptid IN rptid_type default null)
		return sys_refcursor;

end acctexp_rpt;
/
show error

grant execute on acctexp_rpt to "COSTING@CS.CMU.EDU";
grant execute on acctexp_rpt to ccreport_admin;
