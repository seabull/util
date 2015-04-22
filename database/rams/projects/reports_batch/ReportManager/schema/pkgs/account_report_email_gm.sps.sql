-- $Id: account_report_email_gm.sps.sql,v 1.1 2007/10/22 14:03:06 yangl Exp $
create or replace package hostdbAccount_Report_Email_GM
is
  -- ------------------------------------------------------------------------

  E_Error_Start			Integer := Account_Report_Email.E_Error_Start ;
  E_Invalid_Mode		Integer	:= Account_Report_Email.E_Invalid_Mode ;

  -- ------------------------------------------------------------------------

  mProduction		varchar2(30)	:= Account_Report_Email.mProduction ;
  mReportManagerOnly	varchar2(30)	:= Account_Report_Email.mReportManagerOnly ;
  mDevelopment		varchar2(30)	:= Account_Report_Email.mDevelopment ;

  -- ------------------------------------------------------------------------

  procedure Get_Addresses
    ( xAccount_String	In	Varchar2
    , xMode		In	Varchar2	default 'development'
    , xAsOfDate		In	Date		default trunc(SysDate)
    , xSuspend_Until	In	Boolean		default false
    , xSender		Out	Varchar2
    , xTO		Out	Varchar2
    , xCC		Out	Varchar2
    , xBCC		Out	Varchar2
    , xErrorMsg		Out	Varchar2
    ) ;

end ;
/
Show Errors
