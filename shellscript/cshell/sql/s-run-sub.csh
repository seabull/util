#!/bin/csh -f
#------------------------------------------------------------------------------

  if ( $?CXAPPS == 0 ) then
    set connect = "/"
  else
    set connect = "$CXAPPS"
  endif

#------------------------------------------------------------------------------

# set log = /dev/null

  unset elapsed		; unsetenv elapsed
  unset date		; unsetenv date
  unset log		; unsetenv log

  while ( "$1" =~ -* )
    switch ( "$1" )
      case "-sid":
        set sid = 1
        breaksw
      case "-b":
        set background = 1
        breaksw
      case "-d":
        set date = 1
        breaksw
      case "-nd":
        unset date
        breaksw
      case "-t":
        set elapsed = 1
        breaksw
      case "-nt":
        unset elapsed
        breaksw
      case "-l":
        if ( "$2" == "" ) then
          set msg = "Flag '$1' missing argument"
          goto usage
        endif
        set log = "$2" ; 
        shift
        breaksw
      case "+l":
        unset log
        breaksw
      case "-n":
        set log = "/dev/null"
        breaksw
      case "-c":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
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

#------------------------------------------------------------------------------

  if ( $#argv != 1 ) then
    set msg = "Wrong number of arguments - expected one after options"
    goto usage
  endif

  set sql = "$1"

  if ( "$sql" == "" ) then
    set msg = "Invalid name specified - empty string"
    goto usage
  endif

  if ( ! -f "$sql" ) then
    set file = "$sql.sql"
    if ( ! -f "$file" ) then
      set msg = "Neither '$sql' nor '$file' seem to be accessible"
      goto usage
    endif
    set sql = "$file"
  endif

#------------------------------------------------------------------------------

  if ( $?log == 0 ) then
    set area = ~/log/oracle
    if ( ! -d $area/. ) set area = "."
    if ( -d $area/misc/. ) set area = $area/misc
    if ( $?sid == 0 ) then
      set log = "$sql:r.log"
    else
      set dst = $HOME/logs/oracle/$ORACLE_SID
      if ( -d $dst/. ) set area = $dst
      set log = "$sql:r.`date +%Y-%d-%m.%R`"
    endif
    set log = "$area/$log:t"
  endif

  if ( "$sql" == "$log" ) then
    set msg = "Sql script '$sql' and log file may not be the same '$log'."
    goto usage
  endif

# echo "log:  $log"

#------------------------------------------------------------------------------

  if ( $?elapsed != 0 ) then
    set tcmd = "/bin/time"
  else
    set tcmd = ""
  endif

  if ( $?date != 0 ) then
    set dcmd = "date"
  else
    set dcmd = ""
  endif

  set cmd = "$tcmd sqlplus -s $connect @$sql"

  if ( $?background ) then
    ( ( $dcmd ; $cmd < /dev/null | tr -d '\014' ; $dcmd ) |& autotrace-flatten >& $log & )
  else
#   ( echo "" ; $cmd < /dev/null |& tr -d '\014' ; echo "" ) |& autotrace-flatten |& tee $log
    ( $dcmd ; $cmd < /dev/null |& tr -d '\014' ; echo "" ; $dcmd ) |& autotrace-flatten |& tee $log
  endif

  exit 0

#------------------------------------------------------------------------------

usage:

  echo ""
  echo "Error:  $msg"
  echo ""
  echo "Usage:  s-run-sub [options] <sql-script>"
  echo ""
  echo "Options:"
  echo ""
  echo "  -c <connect>   Connect using '<connect>', the default is /"
  echo ""
  echo "  -l <log>       Redirect out to the specified file, the default"
  echo "                 is <sql-script>.log"
  echo ""
  echo "  -n             Do not generate a log file ( default now )"
  echo ""
  echo "  +n             Generate the standard log file."
  echo ""
  echo "  -t             Show elapsed time."
  echo ""
  echo "  -b             Run the script in the background"
  echo ""

  exit -1

#------------------------------------------------------------------------------
