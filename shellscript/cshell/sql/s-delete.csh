#!/bin/csh -f
#------------------------------------------------------------------------------

  unset connect		; unsetenv connect
  unset where		; unsetenv where

  while ( "$1" =~ -* )
    switch ( "$1" )
    #
    # Options
    #
      case "-c":			# Set connection string
        if ( $?connect != 0 ) then
          set msg = "Second '$1' option found - please specify only one"
          goto usage
        endif
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        set connect = "$2" ; shift
        breaksw
      case "-w":			# Set where clause
        if ( $?where != 0 ) then
          set msg = "Second '$1' option found - please specify only one"
          goto usage
        endif
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        set where = "$2" ; shift
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

  if ( $?where == 0 ) then
    set msg = "no where clause specified"
    goto usage
  endif

#------------------------------------------------------------------------------

  if ( $#argv < 1 ) then
    set msg = "Missing table name argument"
    goto usage
  endif

#------------------------------------------------------------------------------

# Process each additional argument as a table name

  foreach name ( $* )

    if ( "$name" == "" ) continue

    echo "- Table '$name'"

sqlplus -s $connect <<-Sql-Done- | tr -d '\014' | sed '/^$/d'
--
  Set FeedBack off Heading Off ServerOutput On
--
-- Use a loop to keep the transaction size small
--
  Declare
    rows	Number(38) := 0 ;
    cnt		Number(38) := 0 ;
  Begin
    Loop
      Delete from $name where $where and RowNum <= 1000 ;
      cnt   := Sql%RowCount ;
      rows  := rows + cnt ;
      commit ;
      Exit When cnt <= 0 ;
    End Loop ;
    commit ;
    Dbms_Output.Put_Line(rows||' rows deleted.') ;
  End ;
/
--
-Sql-Done-

    echo ""

  end

  exit 0

#------------------------------------------------------------------------------

usage:

  echo ""
  echo "Error:  $msg"
  echo ""
  echo "Usage:  s-delete [options] -w <where-clause> <table-name> [...]"
  echo ""
  echo "- Delete rows from the tables that satisfy the where clause."
  echo ""
  echo ""  echo "Options:"
  echo ""
  echo "  -c <s>   Oracle connection string, default /."
  echo "           (or taken from '$CXAPPS' if defined)"
  echo ""
  echo "  -w <w>   Sql where clause constraints - do not provide 'where '"
  echo ""


  exit -1

#------------------------------------------------------------------------------
