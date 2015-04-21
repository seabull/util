#!/bin/csh -f
#------------------------------------------------------------------------------

  set out = /usr/tmp/.s-synonym.$$.out

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

  if ( $#argv != 2 ) then
    set msg = "Wrong number of arguments - expected two after the connection string."
    goto usage
  endif

  if ( "$1" == "" ) then
    set msg = "<synonym-name> is an empty string"
    goto usage
  endif

  set synonym = "$1" ; shift

  if ( "$1" == "" ) then
    set msg = "<user-name>.<object-name> is an empty string"
    goto usage
  endif

  set object = "$1" ; shift

#------------------------------------------------------------------------------

sqlplus -s $connect <<-Sql-Done- >& $out
--
  Whenever SqlError Exit -1
--
  Create synonym $synonym for $object ;
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
  echo "Usage:  s-synonym -c <connect> <synonym-name> <user-name>.<object-name>"
  echo ""
  echo "- Create a synonym <synonym-name> for <user-name>.<object-name>"
  echo ""
  echo "  s-synonym -c apps/apps custs ra.customers"
  echo ""

  rm -f $out

  exit -1

#------------------------------------------------------------------------------
