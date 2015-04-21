#!/bin/csh -f
#------------------------------------------------------------------------------

  if ( $?CXAPPS == 0 ) then
    set connect = "/"
  else
    set connect = "$CXAPPS"
  endif

  alias list ' cat '

#------------------------------------------------------------------------------

  while ( "$1" =~ -* )
    switch ( "$1" )
      case "-p":
        set print = 1
        breaksw
      case "-s":
        alias list ' cat > /dev/null '
        breaksw       
      case "-c":
        if ( "$2" == "" ) then
          set msg = "option '$1' missing argument"
          goto usage
        endif
        set connect = "$2" ; shift
        breaksw
      default:
        set msg = "unrecognized option '$1'"
        goto usage
    endsw
    shift
  end

#------------------------------------------------------------------------------

  if ( $#argv != 1 ) then
    set msg = "wrong number of arguments"
    goto usage
  endif

  set name = "$1"

  if ( "$name" == "" ) then
    set msg = "Invalid name specified - empty string"
    goto usage
  endif

  set name = "` echo $name | tr '-' '_' `"

#------------------------------------------------------------------------------

set out = /usr/tmp/.s-tab.tmp

sqlplus -s $connect <<-Sql-Done- | tr -d '\014' | tee $out | list
--
  Set PageSize 999 LineSize 112 FeedBack Off
--
  Break on "Table" on "Index" Skip 1
--
  Column "Table"	Format A30
  Column "Index"	Format A30
  Column "Column"	Format A30
--
    Select	Initcap(i.Table_Name)		"Table"
	,	InitCap(i.Index_Name)		"Index"
	,	InitCap(c.Column_Name)		"Column"
    --
	From	all_ind_columns		c
        ,	all_indexes		i
    --
	Where	i.table_name		like Upper('$name')
 	And	c.index_owner		= i.owner
  	And	c.index_name		= i.index_name
    --
        Order by 1, 2, c.column_position
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
  echo "  -p              Print table names listing"
  echo ""
  echo "  -s              Run silently, useful just to print listing"
  echo ""

  exit -1

#------------------------------------------------------------------------------
