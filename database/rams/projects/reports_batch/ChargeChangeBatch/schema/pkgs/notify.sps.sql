-- $Header: c:\\Repository/database/rams/projects/reports_batch/ChargeChangeBatch/schema/pkgs/notify.sps.sql,v 1.6 2006/07/17 20:31:27 yangl Exp $
--
create or replace package acct_report 
	authid definer
as
	-- Types and subtypes
	subtype acct_string_t is varchar2(24);
	type accts_tc is table of acct_string_t index by binary_integer;

	type email_rec is record (
		acct_string	acct_string_t
		,mailTo		varchar2(4000)
		,mailFrom	varchar2(4000)
		,mailReplyTo	varchar2(4000)
		,mailCC		varchar2(4000)
		,mailBCC	varchar2(4000)
		,errmsg		varchar2(4000)
		);
	--type EmailInfo_tc is table of email_rec index by binary_integer;
	type EmailInfo_tc is table of email_rec ;

	-- package variables
	gTimestampFormat	varchar2(100)	:= 'DD-MON-YYYY HHMMSS AM';
	gReportID		number		:= 0;
	gEmailMode		varchar2(30)	:= hostdb.Account_Report_Email.mProduction;

	--
	-- procedures
	--
	procedure init(p_id IN varchar2 default null);
	procedure setEmailMode(p_Mode IN varchar2 default null);

	function fetchUserReport(p_acctstr IN varchar2) return sys_refcursor;
	function fetchMachineReport(p_acctstr IN varchar2) return sys_refcursor;
	procedure closeReport(p_csr IN sys_refcursor);
	function fetchAcctStrings return sys_refcursor;
	function fetchAcctStrings_cl return accts_tc;

	--function fetchEmailInfo return sys_refcursor;
	function fetchEmailInfo(p_AsOf IN date default sysdate) return sys_refcursor;
	function fetchEmailInfo(p_rptid IN pls_integer) return sys_refcursor;

	function fetchEmailInfo_cl(p_AsOf IN date default sysdate) return EmailRecTbl;
	function fetchEmailInfo_pipe return EmailRecTbl pipelined;
	function fetchEmailInfo_pipe(p_AsOf IN date ) return EmailRecTbl pipelined;
	--function fetchEmailInfo_pipe(p_AsOf IN date default sysdate) return EmailRecTbl pipelined;

	--
	-- getters and setters.
	--
	function getReportID return number;
	--pragma restrict_references (getReportID, wnds, rnds);

	function getTimestampFormat return varchar2 ;
	--pragma restrict_references (getTimestampFormat, wnds, rnds);

	procedure setTimestampFormat(p_ts_format IN varchar2);
	--pragma restrict_references (setTimestampFormat, wnds, rnds);
end acct_report;
/
show error

grant execute on ccreport.acct_report to		"COSTING@CS.CMU.EDU";
