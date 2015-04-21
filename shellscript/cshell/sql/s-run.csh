#!/bin/csh -f
#------------------------------------------------------------------------------

  if ( $?CXAPPS == 0 ) then
    set connect = "/"
  else
    set connect = "$CXAPPS"
  endif

#------------------------------------------------------------------------------

  set options = ( )

  if ( -f ~/.s-run.options ) set options = ( $options ` cat ~/.s-run.options ` )

  unset list

  while ( "$1" =~ -* )
    switch ( "$1" )
      case "-list":
        set list = 1
        breaksw
      case "-list":
      case "-sid":
      case "-b":	# background
      case "-t":	# 
      case "-n":	# no log
      case "-p":	# print output
      case "+l":
        set options = ( $options "$1" )
        breaksw
      case "-l":
      case "-c":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        set options = ( $options "$1" "$2" )
        shift
        breaksw
      default:
        set msg = "Unrecognized option '$1'"
        goto usage
    endsw
    shift
  end

#------------------------------------------------------------------------------

  if ( $#argv <= 0 ) then
    set msg = "No sql scripts specified - expected at least one."
    goto usage
  endif

  while ( $#argv > 0 )
    if ( $?list == 1 ) echo "- $1"
    s-run-sub $options "$1"
    if ( $status != 0 ) exit -1
    shift
  end

  exit 0

#------------------------------------------------------------------------------

usage:

  echo ""
  echo "Error:  $msg"
  echo ""
  echo "Usage:  s-run [options] <sql-script> [...]"
  echo ""
  echo "- Run the sql script(s) individually using sqlplus (running silently)."
  echo ""
  echo "- If <sql-script> isn't found then it tries <sql-script>.sql."
  echo ""
  echo "- Unless otherwise directed a log file is generated for each"
  echo "  sql script, replacing the '.sql' with '.log'.  The log is"
  echo "  placed in the current directory or under ~/log/oracle if it"
  echo "  exists."
  echo ""
  echo "- A user may place options in ~/.s-run.options to apply them everytime."
  echo "  This is why there are inverse options that ..."
  echo ""
  echo "- ... "
  echo ""
  echo "Options:"
  echo ""
  echo "  -c <connect>   Connect using '<connect>', '$CXAPPS', or '/', standard"
  echo "                 Oracle connection string <schema>/<password>[@<instance>]."
  echo ""
  echo "  -l <log>       Redirect out to the specified file, the default"
  echo "                 is <sql-script>.log"
  echo ""
  echo "  -n             Do not generate a log file."
  echo ""
  echo "  -t             Show elapsed time."
  echo ""
  echo "    -xt          Do not show elapsed time."
  echo ""
  echo "  -b             Run the script in the background"
  echo ""
  echo "    -xb          Run the script in the foreground (default)."
  echo ""

  exit -1

#------------------------------------------------------------------------------
