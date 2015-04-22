-- $Id: account_report_email.spb.sql,v 1.6 2007/11/14 17:07:50 yangl Exp $
create or replace package body hostdb.Account_Report_Email
is

  -- ------------------------------------------------------------------------

  vSuspend_Until	Boolean := false ;

  -- ------------------------------------------------------------------------

  procedure Suspend_Until_Enable
  is
  begin
    vSuspend_Until := true ;
  end ;

  -- ------------------------------------------------------------------------

  procedure Suspend_Until_Disable
  is
  begin
    vSuspend_Until := false ;
  end ;

  -- ------------------------------------------------------------------------

  procedure Append_Help_RamsNotify(xAddress IN OUT varchar2)
  is
  begin
    traceit.log(traceit.constDEBUGLEVEL_B, 'Entering Append_Help_RamsNotify(%s)', xAddress);
    if (xAddress is null) then
        xAddress := Help_RamsNotify_Email;
    else
        xAddress := xAddress || ',' || Help_RamsNotify_Email;
    end if;
    traceit.log(traceit.constDEBUGLEVEL_B, 'Exiting Append_Help_RamsNotify(%s)', xAddress);
  end Append_Help_RamsNotify;

  -- ------------------------------------------------------------------------

  procedure Append_Business_Functions(xAddress IN OUT varchar2)
  is
  begin
    traceit.log(traceit.constDEBUGLEVEL_B, 'Entering Append_Business_Functions(%s)', xAddress);
    if (xAddress is null) then
        xAddress := Business_Functions_Email;
    else
        xAddress := xAddress || ',' || Business_Functions_Email;
    end if;
    traceit.log(traceit.constDEBUGLEVEL_B, 'Exiting Append_Business_Functions(%s)', xAddress);
  end Append_Business_Functions;

  -- ------------------------------------------------------------------------

  function Suspend_Until_State
    return Boolean
  is
  begin
    return vSuspend_Until ;
  end ;

  -- ------------------------------------------------------------------------

  procedure Get_Addresses
    ( xAccount_String	In	varchar2
    , xMode		In	varchar2	default 'development'
    , xAsOfDate		In	Date
    , xSender		Out	Varchar2
    , xTO		Out	Varchar2
    , xCC		Out	Varchar2
    , xBCC		Out	Varchar2
    , xErrorMsg		Out	Varchar2
    )
  is
  --
    vMode		varchar2(30) := nvl(xMode,mDevelopment) ;
  --
    xAccount_Type	varchar2(30) ;
  --
  begin

    Always ( xSender, xBCC, xErrorMsg ) ;

    if  (	( vMode	<> mProduction )
	and	( vMode	<> mReportManagerOnly )
	and	( vMode	<> mDevelopment )
	)
    then
      Raise_Application_Error ( E_Invalid_Mode
	, 'Account_Report_Email():  invalid mode ''' || vMode || '''' ) ;
    end if ;

    begin
      select	decode(x.Project,Null,'GL','GM')
	into	xAccount_Type
	from	hostdb.Accounts_Str_V	x
	where	x.Acct_String		= xAccount_String ;
    exception
      When No_Data_Found then
        xErrorMsg := 'Account '''||xAccount_String||''' not recognized.';
        Fail ( vMode, xTO, xCC, xBCC, xErrorMsg ) ;
        return ;
    end ;

    if ( xAccount_Type = 'GM' ) then

      Account_Report_Email_GM.Get_Addresses
        ( xAccount_String
        , vMode
        , xAsOfDate
	, vSuspend_Until
        , xSender
        , xTO
        , xCC
        , xBCC
        , xErrorMsg
        ) ;
/*
        xErrorMsg := 'GM Account:  '''||xAccount_String||'''' ;
        Fail ( vMode, xTO, xCC, xBCC, xErrorMsg ) ;
*/
--
    else -- ( xAccount_Type = 'GL' )

      Account_Report_Email_GL.Get_Addresses
        ( xAccount_String
        , vMode
        , xAsOfDate
	, vSuspend_Until
        , xSender
        , xTO
        , xCC
        , xBCC
        , xErrorMsg
        ) ;

    end if ;

    -- If sent to help+costing i.e. no BM or RM found, don't send to ramsnotify.
    -- CC instead of BCC to ramsnotify so that Remedy can see it.
    -- Per Kelly and Michael, 2007/10.
    if ( xTO = Business_Functions_Email ) then
        null;
    else
        -- send to help+costing if no report manager found (even if only BM found).
        -- otherwise, send to help+ramsnotify
        if (xErrorMsg is null) then
            Append_Help_RamsNotify(xCC);
        else
            Append_Business_Functions(xCC);
        end if;
    end if;

  end ;

  -- ------------------------------------------------------------------------

  procedure Get_Addresses
    ( xAccount_Id	In	Number
    , xMode		In	varchar2	default 'development'
    , xAsOfDate		In	Date
    , xSender		Out	Varchar2
    , xTO		Out	Varchar2
    , xCC		Out	Varchar2
    , xBCC		Out	Varchar2
    , xErrorMsg		Out	Varchar2
    )
  is
  --
    vMode		varchar2(30) := nvl(xMode,mDevelopment) ;
  --
    xAccount_String	varchar2(60) := hostdb.Account_String_by_Id(xAccount_Id);
  --
  begin

    Always ( xSender, xBCC, xErrorMsg ) ;

    if (  xAccount_String is null ) then

      xErrorMsg := 'Account Id '''||xAccount_Id||''' not recognized.';

      Fail ( vMode, xTO, xCC, xBCC, xErrorMsg ) ;

      return ;

    end if ;

    Get_Addresses ( xAccount_String, vMode, xAsoFDate, xSender, xTO, xCC
			, xBCC, xErrorMsg ) ;

  end ;

  -- ------------------------------------------------------------------------
--
  procedure Get_Addresses
    ( xAccount_Id	In	Number
    , xMode		In	varchar2	default 'development'
    , xSender		Out	Varchar2
    , xTO		Out	Varchar2
    , xCC		Out	Varchar2
    , xBCC		Out	Varchar2
    , xErrorMsg		Out	Varchar2
    )
  is
  begin

    Get_Addresses ( xAccount_Id, xMode, SysDate, xSender, xTO, xCC
			, xBCC, xErrorMsg ) ;

  end ;

  -- ------------------------------------------------------------------------

  procedure Get_Addresses
    ( xAccount_String	In	Varchar2
    , xMode		In	varchar2	default 'development'
    , xSender		Out	Varchar2
    , xTO		Out	Varchar2
    , xCC		Out	Varchar2
    , xBCC		Out	Varchar2
    , xErrorMsg		Out	Varchar2
    )
  is
  begin

    Get_Addresses ( xAccount_String, xMode, SysDate, xSender, xTO, xCC
			, xBCC, xErrorMsg ) ;

  end ;

  -- ------------------------------------------------------------------------

  procedure Append_Addresses
    ( xErrorMsg		In Out	Varchar2
    , xTO		In	Varchar2
    , xCC		In	Varchar2
    , xBCC		In	Varchar2
    )
  is
  begin

    xErrorMsg 	:= xErrorMsg  || chr(10)  || chr(10)
		|| 'To:     ' || xTO      || chr(10)
		|| 'CC:     ' || xCC      || chr(10)
		|| 'BCC:    ' || xBCC     || chr(10) ;

  end ;

  -- ------------------------------------------------------------------------
--
  function Insert_Mode
    ( xEmail		In	varchar2
    , xMode		In	varchar2
    )
    return	varchar2
  is
    xOutput	varchar2(300) ;
    at_sign	integer ;
  begin

    at_sign := instr ( xEmail, '@' ) ;
    if ( ( at_sign is null ) or ( at_sign <= 1 ) ) then
      return xEmail ;
    end if ;

    xOutput := substr(xEmail,1,at_sign-1) ;
    if ( substr(xOutput,at_sign-1,1) <> '+' ) then
      xOutput := xOutput || '+' ;
    end if ;
    return xOutput || xMode || substr(xEmail,at_sign) ;

  end ;

  -- ------------------------------------------------------------------------

  procedure Always
    ( xSender		Out	Varchar2
    , xBCC		Out	Varchar2
    , xErrorMsg		Out	Varchar2
    )
  is
  begin
    xSender	:= Business_Functions_Email ;
    --xBCC	:= RAMS_CYA_EMAIL || ',' || Help_RamsNotify_Email;
    xBCC	:= RAMS_CYA_EMAIL;
    xErrorMsg	:= '' ;
  end ;

  -- ------------------------------------------------------------------------

  procedure Fail
    ( xMode		In	Varchar2
    , xTO		Out	Varchar2
    , xCC		Out	Varchar2
    , xBCC		In Out	Varchar2
    , xErrorMsg		In Out	Varchar2
    )
  is
  begin

    if ( xMode = mProduction ) then
      xTO  := Business_Functions_Email ;
      --xTO  := Help_RamsNotify_Email ;
      xCC  := '' ;
      xBCC := RAMS_CYA_EMAIL;
    else
      Send_to_RAMSCYA ( xMode, xTO, xCC, xBCC, xErrorMsg ) ;
    end if ;

  end ;

  -- ------------------------------------------------------------------------
--
  procedure Send_to_RAMSCYA
    ( xMode		In	Varchar2
    , xTO		In Out	Varchar2
    , xCC		In Out	Varchar2
    , xBCC		In Out	Varchar2
    , xErrorMsg		In Out	Varchar2
    )
  is
  begin

    Account_Report_Email.Append_Addresses ( xErrorMsg, xTO, xCC, xBCC ) ;

    xTo   := Insert_Mode ( RAMS_CYA_EMAIL, xMode ) ;
    xCC   := '' ;
    xBCC  := '' ;

    return ;

  end ;

  -- ------------------------------------------------------------------------

  function SCS_Full_Name ( xSCS_Email  In  Varchar2 )
    return Varchar2
  is
  --
    xUserId	Varchar2(100) ;
    xFull_Name	Varchar2(100) ;
  --
  begin

    xUserId := substr(xSCS_Email,1,instr(xSCS_Email,'+@')-1) ;

    select	x.Name
	into	xFull_Name
	from	hostdb.Name			x
	where   x.Princ				= xUserId
	and	x.Pri				= 0 ;

    return xFull_Name ;

  exception

    when others then

      return '' ;

  end ;

  -- ------------------------------------------------------------------------
--
  function m_Production
    return varchar2
  is
  begin
    return mProduction ;
  end ;

  -- ------------------------------------------------------------------------

  function m_ReportManagerOnly
    return varchar2
  is
  begin
    return mReportManagerOnly ;
  end ;

  -- ------------------------------------------------------------------------

  function m_Development
    return varchar2
  is
  begin
    return mDevelopment ;
  end ;

  -- ------------------------------------------------------------------------

end ;
/
Show Errors
