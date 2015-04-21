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

  if ( $?where == 1 ) then
    set where = "where $where"
  else
    set where = ""
  endif

#------------------------------------------------------------------------------

  if ( $#argv > 0 ) then
    set msg = "too many arguments - none expected after options"
    goto usage
  endif

#------------------------------------------------------------------------------

# Process each additional argument as a table name

#  foreach name ( $* )

#    if ( "$name" == "" ) continue

#    echo "- Table '$name'"

sqlplus -s $connect <<-Sql-Done- | tr -d '\014' | sed '/^$/d'
--
  Set FeedBack Off Heading Off
--
  Select  s.UserName, s.Sid, s.Serial#
    from  v\$session s
    order by 1, 2, 3
  ;
--
-Sql-Done-

    echo ""

#  end

  exit 0

#------------------------------------------------------------------------------

usage:

  echo ""
  echo "Error:  $msg"
  echo ""
  echo "Usage:  s-sessions [options]"
  echo ""
  echo "Options:"
  echo ""
  echo "  -c <s>   Oracle connection string, default /."
  echo "           (or taken from '$CXAPPS' if defined)"
  echo ""
  echo "  -w <c>   Sql where clause constraints - do not provide 'where '"
  echo ""

  exit -1

#------------------------------------------------------------------------------
