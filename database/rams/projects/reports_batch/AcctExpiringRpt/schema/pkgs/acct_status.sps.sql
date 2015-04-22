-- $Header: c:\\Repository/database/rams/projects/reports_batch/AcctExpiringRpt/schema/pkgs/acct_status.sps.sql,v 1.2 2006/05/17 20:05:13 yangl Exp $
--
create or replace package ccreport.acct_status 
	--authid current_user
	authid definer
as
	subtype acctstring_t	is varchar2(24);
	subtype acctid_t	is hostdb.accounts.id%TYPE;
	subtype acctstatus_t	is char;

	function getStatus(p_acct	IN acctstring_t) return acctstatus_t;
	function getStatus(p_acct	IN acctid_t) return acctstatus_t;

	procedure getStatus(p_acct	IN acctstring_t, p_reason OUT varchar2);
	procedure getStatus(p_acct	IN acctstring_t, p_reason OUT varchar2, p_date OUT date);
	
	function getAcctstrC(p_status	IN pls_integer) return sys_refcursor;
	function getAcctstrC(p_status	IN pls_integer
				,p_date	IN date
				,p_asof	IN date default sysdate) 
		return sys_refcursor;

	function getAcctstrC(p_status	IN acctstatus_t) return sys_refcursor;
	function getAcctstrC(p_status	IN acctstatus_t
				,p_date	IN date
				,p_asof	IN date default sysdate) 
		return sys_refcursor;

	function getExpAcctstrDataC(p_status IN acctstatus_t
				, p_date IN date
				, p_asof IN date default sysdate) 
		return sys_refcursor;

	--function getAcctstr(p_status IN pls_integer) return varchar2 pipelined;
	--function getAcctstr(p_status IN char) return varchar2 pipelined;
	function fetchEmailInfo_pipe(p_AsOf IN date)
			return acct_report.EmailInfo_tc pipelined;
	function fetchEmailInfo_pipe
			return acct_report.EmailInfo_tc pipelined;
	function fetchEmailInfo(p_AsOf IN date default sysdate) return sys_refcursor;
	--function fetchAcctStrings return sys_refcursor;
	function fetchAcctStrings(p_date IN date default sysdate+60, p_asof IN date default sysdate) return sys_refcursor;
	procedure closeReport(p_csr IN sys_refcursor);
end acct_status;
/
show errors

grant execute on acct_status to "COSTING@CS.CMU.EDU";
grant execute on acct_status to ccreport_admin;
