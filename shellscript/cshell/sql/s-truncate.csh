#!/bin/csh -f
#------------------------------------------------------------------------------

  set storage	= "Drop Storage" ;
  set truncate	= 1

  while ( "$1" =~ -* )
    switch ( "$1" )
    #
    # Options
    #
      case "-c":			# Set connection string
        if ( $?connect != 0 ) then
          set msg = "Second connection option found - please only specify one"
          goto usage
        endif
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        set connect = "$2" ; shift
        breaksw
      case "-t":			# Use 'truncate' rather than 'delete'
        set truncate = 1
        breaksw
      case "-reuse":			# Truncate w/o droping storage
        set truncate = 1
        set storage = "Reuse Storage"
        breaksw
      case "-d":			# Use 'delete' rather than 'truncate'
        set truncate = 0
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

#------------------------------------------------------------------------------

  if ( $#argv < 1 ) then
    set msg = "Missing table name argument"
    goto usage
  endif

#------------------------------------------------------------------------------

# Process each additional argument as a table name

  foreach name ( $* )

    if ( "$name" == "" ) continue

    echo "- Truncating '$name'"

  # fold to uppercase

    set name = "` echo '$name' | tr 'a-z-' 'A-Z_' `"

    if ( $truncate > - ) then

sqlplus -s $connect <<-Sql-Done- | tr -d '\014'
--
  Truncate table $name $storage ;
--
-Sql-Done-

    else

sqlplus -s $connect <<-Sql-Done- | tr -d '\014'
--
-- Truncate will not work through a synonym - switch to delete - phdye
--
  Set FeedBack off Heading Off ServerOutput On
--
-- Use a loop to keep the transaction size small
--
  Declare
    rows        Number(38) := 0 ;
    cnt         Number(38) := 0 ;
  Begin
    Loop
      Delete from $name where RowNum <= 1000 ;
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

    endif

  end

  exit 0

#------------------------------------------------------------------------------

extra_type:

  set msg = "Extra source type flag '$1' - type already set to '$type'"

usage:

  echo ""
  echo "Error:  $msg"
  echo ""
  echo "Usage:  s-truncate [options] <table-name> [...]"
  echo ""
  echo "Options:"
  echo ""
  echo "  -c <string>     Oracle connection string, default /."
  echo "                  (or taken from 'CXAPPS' if defined)"
  echo ""
  echo "  -t              Use 'truncate' to remove the rows.  (default)"
  echo ""
  echo "  -d              Use 'delete' rather than 'truncate'.  'truncate'"
  echo "                  will not always work - such as through synonyms."
  echo ""

  exit -1

#------------------------------------------------------------------------------
