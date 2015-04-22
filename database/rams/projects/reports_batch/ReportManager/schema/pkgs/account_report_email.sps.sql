-- $Id: account_report_email.sps.sql,v 1.2 2007/10/10 15:07:02 yangl Exp $
create or replace package hostdb.Account_Report_Email
is

  RAMS_CYA_Email		Varchar2(60) := 'ramscya+@cs.cmu.edu' ;
  Business_Functions_Email	Varchar2(60) := 'help+costing@cs.cmu.edu' ;
  Help_RamsNotify_Email	Varchar2(60) := 'help+ramsnotify@cs.cmu.edu' ;

  -- ------------------------------------------------------------------------

  E_Error_Start			Integer := hostdb.Error_Start.Account_Report_Email ;

  E_Invalid_Mode		Integer	:= E_Error_Start - 0 ;
--E_Account_String_Invalid	Integer	:= E_Error_Start - 1 ;

  -- ------------------------------------------------------------------------

  mProduction		varchar2(30)	:= 'production' ;
  mReportManagerOnly	varchar2(30)	:= 'rm-only' ;
  mDevelopment		varchar2(30)	:= 'development' ;

  -- ------------------------------------------------------------------------

  function m_Production		return varchar2 ;
  function m_ReportManagerOnly	return varchar2 ;
  function m_Development	return varchar2 ;

  -- ------------------------------------------------------------------------

  procedure Get_Addresses
    ( xAccount_Id	In	Number		-- xAsOfDate = SysDate
    , xMode		In	Varchar2	default 'development'
    , xSender		Out	Varchar2
    , xTO		Out	Varchar2
    , xCC		Out	Varchar2
    , xBCC		Out	Varchar2
    , xErrorMsg		Out	Varchar2
    ) ;

  procedure Get_Addresses
    ( xAccount_String	In	Varchar2	-- xAsOfDate = SysDate
    , xMode		In	Varchar2	default 'development'
    , xSender		Out	Varchar2
    , xTO		Out	Varchar2
    , xCC		Out	Varchar2
    , xBCC		Out	Varchar2
    , xErrorMsg		Out	Varchar2
    ) ;

  -- ------------------------------------------------------------------------

  procedure Get_Addresses
    ( xAccount_Id	In	Number
    , xMode		In	Varchar2	default 'development'
    , xAsOfDate		In	Date
    , xSender		Out	Varchar2
    , xTO		Out	Varchar2
    , xCC		Out	Varchar2
    , xBCC		Out	Varchar2
    , xErrorMsg		Out	Varchar2
    ) ;
--
  procedure Get_Addresses
    ( xAccount_String	In	Varchar2
    , xMode		In	Varchar2	default 'development'
    , xAsOfDate		In	Date
    , xSender		Out	Varchar2
    , xTO		Out	Varchar2
    , xCC		Out	Varchar2
    , xBCC		Out	Varchar2
    , xErrorMsg		Out	Varchar2
    ) ;

  -- ------------------------------------------------------------------------

  procedure Always
    ( xSender		Out	Varchar2
    , xBCC		Out	Varchar2
    , xErrorMsg		Out	Varchar2
    ) ;

  procedure Fail
    ( xMode		In	Varchar2
    , xTO		Out	Varchar2
    , xCC		Out	Varchar2
    , xBCC		In Out	Varchar2
    , xErrorMsg		In Out	Varchar2
    ) ;

  -- ------------------------------------------------------------------------

  function SCS_Full_Name ( xSCS_Email varchar2 )
    return Varchar2 ;

  -- ------------------------------------------------------------------------

  procedure Append_Addresses
    ( xErrorMsg		In Out	Varchar2
    , xTO		In	Varchar2
    , xCC		In	Varchar2
    , xBCC		In	Varchar2
    ) ;

  function Insert_Mode
    ( xEmail		In	varchar2
    , xMode		In	varchar2
    )
    return varchar2 ;

  -- ------------------------------------------------------------------------

  procedure Send_to_RAMSCYA
    ( xMode		In	Varchar2
    , xTO		In Out	Varchar2
    , xCC		In Out	Varchar2
    , xBCC		In Out	Varchar2
    , xErrorMsg		In Out	Varchar2
    ) ;

  -- ------------------------------------------------------------------------

  procedure Suspend_Until_Enable ;
  procedure Suspend_Until_Disable ;	-- default state

  function  Suspend_Until_State
    return boolean ;

  -- ------------------------------------------------------------------------

end ;
/
Show Errors
