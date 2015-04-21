#!/bin/csh -f
#------------------------------------------------------------------------------

  set out = /usr/tmp/.s-revoke.$$.out

  unsetenv connect ; unset connect

  while ( "$1" =~ -* )
    switch ( "$1" )
      case "-c":
        if ( $?connect != 0 ) then
          set msg = "Option '$1' may only be specified once."
          goto usage
        endif
        if ( $#argv < 2 ) then
          set msg = "Option '$1' must be followed by an argument"
          goto usage
        endif
        set connect = "$2" ; shift
        breaksw
      default:
        set msg = "Unrecognized option '$1'"
        goto usage
    endsw
    shift
  end

  if ( $?connect == 0 ) then
    set msg = "Please provide a connection string"
    goto usage
  endif

  if ( $#argv != 3 ) then
    set msg = "Wrong number of arguments - expected three after the connection string."
    goto usage
  endif

  if ( "$1" == "" ) then
    set msg = "<access> is an empty string"
    goto usage
  endif

  set access = "$1" ; shift

  if ( "$1" == "" ) then
    set msg = "<object> is an empty string"
    goto usage
  endif

  set object = "$1" ; shift

  if ( "$1" == "" ) then
    set msg = "<recipient> is an empty string"
    goto usage
  endif

  set recipient = "$1" ; shift

#------------------------------------------------------------------------------

  if ( "$connect" == "/" ) then
    set schema = 'ops$'"$LOGIN"
  else
    set schema = "` echo $connect | sed 's,/.*,,' `"
    if ( "$schema" == "" ) then
      set msg = "Connection string '$connect' must contain a schema name"
      goto usage
    endif
  endif

#------------------------------------------------------------------------------

  if ( "$recipient" == "$schema" ) then
    set msg = "source and destination schema are identical"
    goto usage
  endif

#------------------------------------------------------------------------------

sqlplus -s $connect <<-Sql-Done- >& $out
--
  Whenever SqlError Exit -1
--
  revoke $access on $object from $recipient;
--
  Quit
--
-Sql-Done-

  if ( $status != 0 ) then
    cat $out
    rm -f $out
    exit -1
  endif

  rm -f $out

  exit 0

#------------------------------------------------------------------------------

usage:

  echo ""
  echo "Error:  $msg"
  echo ""
  echo "Usage:  s-revoke -c <connect> <access> <object> <recipient>"
  echo ""
  echo "- <connect> revokes <access> on <object> to <recipient>"
  echo ""
  echo "  s-revoke -c apps/apps select fnd_user goods"
  echo ""

  rm -f $out

  exit -1

#------------------------------------------------------------------------------
