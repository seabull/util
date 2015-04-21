#!/bin/csh -f
#------------------------------------------------------------------------------

  set def_connect = "/"

  while ( "$1" =~ -* )
    switch ( "$1" )
    # Oracle connection string
      case "-c":
        if ( $?connect != 0 ) then
          set msg = "Option '$1' found twice - please only specify one"
          goto usage
        endif
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        set connect = "$2" ; shift
        breaksw
    # Unrecognized option
      default:
        set msg = "Unrecognized option '$1'"
        goto usage
    endsw
    shift
  end

#------------------------------------------------------------------------------

  if ( $?connect == 0 ) then
    if ( $?CXAPPS != 0 ) then
      set connect = "$CXAPPS"
    else
      set connect = "$def_connect"
    endif
  endif

#------------------------------------------------------------------------------

  if ( $#argv != 2 ) then
    set msg = "Wrong number of arguments - expected two beyond options"
    goto usage
  endif

  set src = "$1"
  set dst = "$2"

#------------------------------------------------------------------------------

echo "<> $connect"

sqlplus -s $connect <<--Sql-Done-- |& tr -d '\014'
--
  Whenever SqlError Exit -1 ;
--
  Rename $src to $dst ;
--
--Sql-Done--

  if ( $status != 0 ) then
    set msg = "sqlplus exit status non-zero"
    goto usage
  endif

  exit 0

#------------------------------------------------------------------------------

usage:

  echo ""
  echo "Error:  $msg"
  echo ""
  echo "Usage:  s-rename [options] <name> <new-name>"
  echo ""
  echo "Options:"
  echo ""
  echo "  -c <string>           Oracle connection string, default '$def_connect'."
  echo "                        (or taken from 'CXAPPS' if defined)"
  echo ""
  echo "Examples:"
  echo ""
  echo "  s-rename trouble old_trouble"
  echo ""
  echo "  s-rename -c test/test old_trouble new_trouble"
  echo ""

  exit -1

#------------------------------------------------------------------------------
@
