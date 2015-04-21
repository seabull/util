#!/bin/csh -f
#------------------------------------------------------------------------------

  set out = /usr/tmp/.ar-loc.$$.tmp
  set sql = /usr/tmp/.ar-loc.$$.sql

  alias list ' cat '

#------------------------------------------------------------------------------

  while ( "$1" =~ -* )
    switch ( "$1" )
      case "-c":
        if ( $?connect != 0 ) then
          set msg = "Multiple connection options"
          goto usage
        endif
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        set connect = "$2" ; shift
        breaksw
      case "-type":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        set expr = " Object_Type like Upper('$2') "
        if ( $?type == 0 ) then
          set type = "$expr"
        else
          set type = "$type or $expr"
	endif
        shift
        breaksw
      case "-xtype":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        set xtype = "$xtype and t.Object_Type not like Upper('$2') "
        shift
        breaksw
      case "-status":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        set expr = " t.Status like Upper('$2') "
        if ( $?ostatus == 0 ) then
          set ostatus = "$expr"
        else
          set ostatus = "$ostatus or $expr"
	endif
        shift
        breaksw
      case "-xstatus":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        set xstatus = "$xstatus and t.Status not like Upper('$2') "
        shift
        breaksw
      default:
        set msg = "Unrecognized option '$1'"
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

  if ( $?type == 1 ) then
    set type = " and ( $type ) "
  else
    set type = ""
  endif

  if ( $?ostatus == 1 ) then
    set ostatus = " and ( $ostatus ) "
  else
    set ostatus = ""
  endif

#------------------------------------------------------------------------------

  if ( $#argv < 1 ) then
    set msg = "Missing location pattern"
    goto usage
  endif

  if ( $#argv > 1 ) then
    set msg = "Expect location pattern - found '$*'"
    goto usage
  endif

  set name = "$1"

  if ( "$name" == "" ) then
    set msg = "Invalid location specified - empty string"
    goto usage
  endif

#------------------------------------------------------------------------------

  if ( $?pipe == 0 ) then
    set Set_Commands = "PageSize  999  FeedBack On"
  else
    set Set_Commands = "PageSize    0  FeedBack Off"
  endif

#------------------------------------------------------------------------------

cat <<-Sql-Done- > $sql
--
  Set  LineSize 80  Space 2  $Set_Commands
--
  Column  "NIF"			Format A20
  Column  "Name"		Format A40
--
  Select	/*+ Index(use) */
    /**/	cust.jgzz_fiscal_code	"NIF"
    ,		cust.Customer_Name	"Name"
    ,		cust.Customer_Id	"Customer Id"
  --
    From	RA_Customers		cust
  --
    Where	cust.jgzz_fiscal_code	like Upper('$name')
  --
    Order by	1
  ;
--
  Quit ;
--
-Sql-Done-

#------------------------------------------------------------------------------

# Premature exit is an error

  set rc = -1

#------------------------------------------------------------------------------

  if ( $?show_sql == 0 ) then
    sqlplus -s $connect @$sql < /dev/null | tr -d '\014' | tee $out | list
    if ( $status != 0 ) then
      echo "s-obj: sqlplus failed"
      goto done
    endif
    if ( $?print ) then
      print $out
    endif
  else
    cat $sql
    if ( $?print ) then
      print $sql
    endif
  endif

  set rc = 0

done:

  rm -f $out $sql

  exit $rc

#------------------------------------------------------------------------------

usage:

  echo ""
  echo "Error:  $msg"
  echo ""
  echo "Usage:  ar-nif [options] <nif-pattern>"
  echo ""
  echo "Options:"
  echo ""
  echo "  -c <connect>    Connection string user/password"
  echo ""
#  echo "  -type <p>       Object type name like 'index', 'view', 'package', ..."
#  echo ""
  echo "  -pipe           Output piped - no headings or feedback"
  echo ""
  echo "  -sql            Show generated SQL - do not run."
  echo ""
  echo "  -p              Print listing"
  echo ""
  echo "  -s              Run silently, useful just to print listing"
  echo ""
  echo "- Each <p> is a pattern string for 'like' comparisions"
  echo ""
#  echo "The following command might be used to find all packages starting"
#  echo "with 'dev_' that are owned by karen, jones, and johnson, but not"
#  echo "john (assuming there are only 3 schema names starting with 'jo')."
#  echo ""
#  echo "  s-obj -owner jo% -owner karen -xowner john -type package dev_%"
#  echo ""

  rm -f $out $sql

  exit -1

#------------------------------------------------------------------------------
