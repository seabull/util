#!/bin/csh -f
#------------------------------------------------------------------------------

  alias list ' cat '

#------------------------------------------------------------------------------

  set Src_Table		= "All_Tables"
  set NameSuffix	= "%"

  unset connect
  unset owner

  while ( "$1" =~ -* )
    switch ( "$1" )
      case "-p":
        set print = 1
        breaksw
      case "-s":
        alias list ' cat > /dev/null '
        breaksw       
      case "-c":
        if ( $?connect != 0 ) then
          set msg = "option '$1' already set"
          goto usage
        endif
        if ( "$2" == "" ) then
          set msg = "option '$1' missing argument"
          goto usage
        endif
        set connect = "$2" ; shift
        breaksw
      case "-owner":
        if ( $?owner != 0 ) then
          set msg = "option '$1' already set"
          goto usage
        endif
        if ( "$2" == "" ) then
          set msg = "option '$1' missing argument"
          goto usage
        endif
        set owner = "$2" ; shift
        breaksw
      case "-all":
        set Src_Table = "All_Tables"
        breaksw
      case "-dba":
        set Src_Table = "Dba_Tables"
        breaksw
      case "-user":
         set Src_Table = "User_Tables"
         breaksw
      case "-exact":
         set Name_Suffix = ""
         breaksw
      default:
        set msg = "unrecognized option '$1'"
        goto usage
    endsw
    shift
  end

#------------------------------------------------------------------------------

  if ( $?connect == 0 ) then
    if ( $?CXAPPS == 0 ) then
      set connect = "/"
    else
      set connect = "$CXAPPS"
    endif
  endif

  if ( $#argv != 1 ) then
    set msg = "wrong number of arguments"
    goto usage
  endif

  set Table_Name = "$1"

  if ( "$Table_Name" == "" ) then
    set msg = "Invalid name specified - empty string"
    goto usage
  endif

  set Table_Name = "` echo $Table_Name | tr '-' '_' `"

#------------------------------------------------------------------------------

  if ( $?owner != 0 ) then
    set Owner_Clause = " and Owner like Upper('$owner') "
  else
    set Owner_Clause = ""
  endif

#------------------------------------------------------------------------------

set out = /usr/tmp/.s-tab.tmp

sqlplus -s $connect <<-Sql-Done- | tr -d '\014' | tee $out | list
--
  Set  PageSize 999  Feedback Off
--
  Select      Owner, Table_Name
    from      $Src_Table
    where     Table_Name like Upper('$Table_Name$NameSuffix')  $Owner_Clause
    Order by  1, 2
  ;
--
-Sql-Done-

#------------------------------------------------------------------------------

  if ( $?print ) then
    print $out
  endif

  rm -f $out

  exit 0

#------------------------------------------------------------------------------

usage:

  echo ""
  echo "Error:  $msg"
  echo ""
  echo "Usage:  s-tab [options] <table-name-pattern>"
  echo ""
  echo "Options:"
  echo ""
  echo "  -c <connect>    Connection string user/password"
  echo ""
  echo "  -owner <user>   Table owned by <user>"
  echo ""
  echo "  -p              Print table names listing"
  echo ""
  echo "  -s              Run silently, useful just to print listing"
  echo ""

  exit -1

#------------------------------------------------------------------------------
