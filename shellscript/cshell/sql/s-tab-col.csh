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

set out = /usr/tmp/.s-tab-col.tmp

sqlplus -s $connect <<-Sql-Done- | tr -d '\014' | tee $out | list
--
  Set LineSize 100 PageSize 1000 FeedBack Off ;

  Column Col_Size Format A14 ;

  Select      Table_Name, Column_Name, Data_Type,
              '(' || Decode
                     ( Data_Type, 'NUMBER',
                       To_Char(Data_Precision) || ',' || To_Char(Data_Scale),
                       To_Char(Data_Length)
                     )
                  || ')' Col_Size,
              Nullable
    from      All_Tab_Columns
    where     Column_Name like Upper('$name%')
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
  echo "Usage:  s-tab-col [options] <column-name-pattern>"
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
