-- $Id: account_report_email_gm.spb.sql,v 1.3 2007/10/22 15:32:03 yangl Exp $
create or replace package body hostdb.Account_Report_Email_GM
is
  -- ------------------------------------------------------------------------

  Type Email_Table	is table of Number index by varchar2(100) ;

  -- ------------------------------------------------------------------------

  procedure Get_Headers
    ( xAccount_String	In	varchar2
    , xMode		In	Varchar2
    , xAsOfDate		In	Date
    , xSuspend_Until	In	Boolean
    , xSender		Out	Varchar2
    , xTO		Out	Varchar2
    , xCC		Out	Varchar2
    , xBCC		Out	Varchar2
    , xErrorMsg		Out	Varchar2
    ) ;

  -- ------------------------------------------------------------------------

  procedure Get_Admin_Email_Addresses
    ( xManager_Id	In	Number
    , xAsOfDate		In	Date
    , xSuffix		In	Varchar2
    , xAddresses	In Out	Varchar2
    , xAdminGathered	In Out	Email_Table
    ) ;

  procedure Get_BM_Email_Addresses
    ( xAccount_String	In	varchar2
    , xAsOfDate		In	Date
    , xAddresses	Out	Varchar2
    , xErrorMsg		Out	Varchar2
    ) ;

  -- ------------------------------------------------------------------------

  procedure Set_Account_Id
    ( xManager_Id	Integer
    , xAccount_String	varchar2
    ) ;

  -- ------------------------------------------------------------------------

  procedure Get_Addresses
    ( xAccount_String	In	varchar2
    , xMode		In	varchar2	default 'development'
    , xAsOfDate		In	Date		default trunc(SysDate)
    , xSuspend_Until	In	Boolean		default false
    , xSender		Out	Varchar2
    , xTO		Out	Varchar2
    , xCC		Out	Varchar2
    , xBCC		Out	Varchar2
    , xErrorMsg		Out	Varchar2
    )
  is
  --
    vMode		varchar2(30)	:= nvl(xMode,mDevelopment) ;
    vAsOfDate		Date		:= nvl(xAsOfDate,trunc(SysDate)) ;
    vSuspend_Until	Boolean		:= nvl(xSuspend_Until,false) ;
  --
  begin

    Get_Headers(xAccount_String,vMode,xAsOfDate,vSuspend_Until,xSender,xTO,xCC,xBCC,xErrorMsg) ;

    if ( vMode = mProduction ) then
      return ;
    end if ;

    if ( vMode = mDevelopment ) then
      Account_Report_Email.Send_to_RAMSCYA ( vMode, xTO, xCC, xBCC, xErrorMsg ) ;
      return ;
    end if ;

    if ( vMode = mReportManagerOnly ) then  -- beta test
      if ( length(xErrorMsg) > 0 ) then
        Account_Report_Email.Send_to_RAMSCYA ( vMode, xTO, xCC, xBCC, xErrorMsg ) ;
      end if ;
      return ;
    end if ;

    Raise_Application_Error ( E_Invalid_Mode, 'Account '''
	|| xAccount_String
	|| ''', invalid mode ''' || vMode || '''' ) ;

  end ;

  -- ------------------------------------------------------------------------

  procedure Get_Headers
    ( xAccount_String	In	varchar2
    , xMode		In	Varchar2
    , xAsOfDate		In	Date
    , xSuspend_Until	In	Boolean
    , xSender		Out	Varchar2
    , xTO		Out	Varchar2
    , xCC		Out	Varchar2
    , xBCC		Out	Varchar2
    , xErrorMsg		Out	Varchar2
    )
  is
  --
    Cursor Managers ( cAccount_String varchar2, cAsOfDate Date ) is
      select	distinct
	/**/	m.Account_Report_Manager_Id			Manager_Id
	,	m.Account_Id
	,	m.Suspend_Until
	,	decode
		  ( instr(m.Full_Name,',')
		  , 0, m.Full_Name
		  , ltrim(substr(m.Full_Name,instr(m.Full_Name,',')+1))
	|| ' ' || substr(m.Full_Name,1,instr(m.Full_Name,',')-1)
		  )						Full_Name
	,	m.SCS_UserId					SCS
	,	m.Andrew_UserId					Andrew
      --
	from	hostdb.Account_Report_Manager	m
      --
	where   m.Account_String		= cAccount_String
-- !!!	and	m.Start_Date_Active		>= cAsOfDate  -- Liz, 1/16/05
        and	m.End_Date_Active		>= cAsOfDate
      --
	order by 2
	;
  --
    separator		Varchar2(3) := '' ;
    xEmail		Varchar2(100) ;
    xSuffix		Varchar2(100) ;
    xName		Varchar2(100) ;
  --
    xAdminGathered	Email_Table ;
  --
    vAsOfDate		Date		:= trunc(nvl(xAsOfDate,SysDate)) ;
  --
    xAccount_Id		integer ;
  --
  begin

--  dbms_output.put_line('as of date = '||to_char(vAsOfDate,'Mon DD, YYYY')) ;

    Account_Report_Email.Always ( xSender, xBCC, xErrorMsg ) ;

    xTO := '' ;
    xCC := '' ;

    for r in Managers ( xAccount_String, xAsOfDate ) loop

        if ( instr(xTo,'RAMS CYA') > 0 ) then
          xTo		:= '' ;
          separator	:= '' ;
        end if ;

        xEmail := '' ;

        if ( r.SCS is not Null ) then
          --if ( ( r.SCS <> 'ramscya' ) or ( xTo is null ) ) then
          if ( r.SCS <> 'ramscya' ) then
            xEmail := lower(r.SCS) ;
            xName  := nvl(Account_Report_Email.SCS_Full_Name(xEmail),r.Full_Name) ;
            xEmail := '"' || xName || '" <' || xEmail || '+@cs.cmu.edu>' ;
          end if ;
        else -- Andrew
          xEmail := '"' || r.Full_Name || '" <' || lower(r.Andrew) || '+@andrew.cmu.edu>' ;
        end if ;

        if ( xEmail is not Null ) then

          xSuffix := '' ;

          if ( xSuspend_Until and ( r.Suspend_Until is not null ) ) then
            if ( r.Suspend_Until >= xAsOfDate ) then
              xSuffix  := ' ( Suspend-Until: ' || to_char(r.Suspend_Until,'Mon DD YYYY') || ' )' ;
            end if ;
          end if ;

          xTO := xTO || separator || xEmail || xSuffix ;

          Get_Admin_Email_Addresses
	    ( r.Manager_Id, xAsOfDate, xSuffix, xCC, xAdminGathered ) ;

          separator := ', ' ;

        end if ;

	if ( r.Account_Id is null ) then
	  Set_Account_Id ( r.Manager_Id, xAccount_String ) ;
	end if ;

    end loop ;

    --dbms_output.put_line('xTO: '|| xTO) ;
    if ( xTO is null ) then

      Get_BM_Email_Addresses ( xAccount_String, xAsOfDate, xTO, xErrorMsg ) ;

      if ( xErrorMsg is not null ) then
        Account_Report_Email.Fail ( xMode, xTO, xCC, xBCC, xErrorMsg ) ;
        return ;
      end if ;

      xErrorMsg := 'No report managers found for GM account.' ;

      return ;

    end if ;

  end ;

  -- ------------------------------------------------------------------------

  procedure Get_Admin_Email_Addresses
    ( xManager_Id	In	Number
    , xAsOfDate		In	Date
    , xSuffix		In	Varchar2
    , xAddresses	In Out	Varchar2
    , xAdminGathered	In Out	Email_Table
    )
  is
  --
    Cursor Admins ( cManager_Id Number, cAsOfDate Date ) is
      select	distinct
	/**/	decode  ( x.SCS_UserId, NULL
			, x.Andrew_UserId	|| '@andrew.cmu.edu'
			, x.SCS_UserId		|| '+@cs.cmu.edu'
			)			Email
	from	hostdb.Account_Report_Admin	x
	where   x.Account_Report_Manager_Id	= cManager_Id
--
-- !!!  and	x.Start_Date_Active		>= cAsOfDate  -- Liz, 1/16/05
--
        and	x.End_Date_Active		>= cAsOfDate
	and not ( x.SCS_UserId			is null
 	      and x.Andrew_UserId		is null
		) ;
  --
    xEmail		Varchar2(200) ;
    xName		Varchar2(100) ;
    separator		Varchar2(3) ;
  --
  begin

    if ( xAdminGathered.Count <= 0 ) then
      separator := '' ;
    else
      separator := ', ' ;
    end if ;

    for r in Admins ( xManager_Id, xAsOfDate ) loop

      if ( not xAdminGathered.Exists(r.Email) ) then

        xAdminGathered(r.Email) := 1 ;

        xEmail := lower(r.Email) ;

        if ( instr(xEmail,'+@cs.cmu.edu') > 0 ) then
          xName := Account_Report_Email.SCS_Full_Name(xEmail) ;
          if ( xName is not Null ) then
            xEMail  := '"' || xName || '" <' || xEmail || '>' ;
          end if ;
        end if ;

        xAddresses := xAddresses || separator || xEmail || xSuffix ;

        separator := ', ' ;

      end if ;

    end loop ;

  end ;

  -- ------------------------------------------------------------------------

  procedure Get_BM_Email_Addresses
    ( xAccount_String	In	varchar2
    , xAsOfDate		In	Date
    , xAddresses	Out	Varchar2
    , xErrorMsg		Out	Varchar2
    )
  is
  --
    Cursor Business_Managers ( cAccount_Id number, cAsOfDate Date ) is
      select	distinct
	/**/	'"'||InitCap(acl.First_Name||' '||acl.Last_Name)||'" '
        ||	'<'||lower(acl.Andrew_UserId)||'@andrew.cmu.edu>' Email
      --
	from	hostdb.Acl_Account_User		acl
      --
	where   acl.Account_Id			= cAccount_Id
	and	acl.Project_Role		like '%Business Manager%'
--
-- !!!  and	acl.Start_Date_Active		>= cAsOfDate  -- Liz, 1/16/05
--
        and	acl.End_Date_Active		>= cAsOfDate ;
  --
    separator		Varchar2(3)	:= '' ;
    xEmail		Varchar2(100) ;
    xName		Varchar2(100) ;
  --
    xGathered		Email_Table ;
  --
    xAccount_Id		Number := hostdb.Account_Id_from_String(xAccount_String) ;
  --
  begin

    xErrorMsg   := '' ;
    xAddresses  := '' ;

    for r in Business_Managers ( xAccount_Id, xAsOfDate ) loop

      if ( not xGathered.Exists(r.Email) ) then

        xGathered(r.Email) := 1 ;

        xAddresses := xAddresses || separator || r.Email ;

        separator := ', ' ;

      end if ;

    end loop ;

    if ( length(xAddresses) = 0 or xAddresses is null ) then
      xErrorMsg := 'No report managers or business managers found.' ;
    end if ;

  end ;

  -- ------------------------------------------------------------------------

  procedure Set_Account_Id
    ( xManager_Id	Integer
    , xAccount_String	varchar2
    )
  --
  is
  --
    pragma Autonomous_Transaction ;
  --
--  xAccount_Id		Number := hostdb.Account_Id_from_String(xAccount_String) ;
    xAccount_Id		Number ;
  --
  begin

    update hostdb.Report_Manager m
	set	m.Account_Id	= 0			/* forces lookup */
	where	m.Id		= xManager_Id ;

    commit ;

  exception

    when No_Data_Found then
       dbms_output.put_line('  : not found') ;
       rollback ;

  end ;

end ;
/
Show Errors
