-- $Header: c:\\Repository/database/rams/projects/reports_batch/Emails/types/emails.sql,v 1.1 2006/05/17 18:09:01 yangl Exp $
--
--drop type ccreport.EmailRecTbl;

--create or replace type email_rec as object (
create or replace type ccreport.EmailRec as object (
	acct_string	varchar2(24)
	,mailTo		varchar2(4000)
	,mailFrom	varchar2(4000)
	,mailReplyTo	varchar2(4000)
	,mailCC		varchar2(4000)
	,mailBCC	varchar2(4000)
	,msg		varchar2(4000)
);
/
show error

--create or replace type EmailInfo_tc is table of email_rec ;
create or replace type ccreport.EmailRecTbl is table of EmailRec ;
/
show error
