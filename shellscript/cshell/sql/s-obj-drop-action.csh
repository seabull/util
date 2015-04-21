#!/bin/csh -f
#-----------------------------------------------------------------------------

# clear up any trash matching the current process id ($$)

  ( rm -f /var/tmp/$$.* >& /dev/null & )

  set out = /var/tmp/$$.s-obj-drop-action.tmp
 
#-----------------------------------------------------------------------------

  unset cascade
  unset connect
  unset brief

  while ( "$1" =~ -* )
    switch ( "$1" )
      case "-brief"
        set brief = 1
        breaksw
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
      case "-cascade":
        set cascade = 1
        breaksw
      default:
        set msg = "Unrecognized option '$1'"
        goto usage
    endsw
    shift
  end

#------------------------------------------------------------------------------

  if ( $?connect == 0 ) then
    set msg = "'-c <connect>' missing - please specify a connection string."
    goto usage
  endif

#------------------------------------------------------------------------------

  if ( $#argv > 1 ) then
    set msg = "too many arguments"
    goto usage
  endif

  if ( $#argv < 1 ) then
    set msg = "missing < show | run > argument - please specify."
    goto usage
  endif

  set action = "$1"

  alias action " cat "

  if ( "$action" == "show" ) goto stmts_show

  if ( "$action" == "run"  ) goto stmts_run

  set msg = "Found '$action' - expected either 'show' or 'run'"
  goto usage

  # *** does not pass this point ***

#-----------------------------------------------------------------------------

# execute drops in reverse of possible dependency order

stmts_run:

  alias action " sh -x "

stmts_show:

  expand | tr A-Z a-z > $out

  if ( $status != 0 ) then
    set msg = "tr or expand failed"
    goto usage
  endif

  awk '$3 == "trigger"  { printf "s-drop -c '"$connect"' -brief -trigger %s\n", $2 }' < $out | action

  if ( $status != 0 ) then
    set msg = "awk or s-drop failed"
    goto usage
  endif

  awk '$3 == "view"     { printf "s-drop -c '"$connect"' -brief -view %s\n", $2 }' < $out | action
 
  if ( $status != 0 ) then
    set msg = "awk or s-drop failed"
    goto usage
  endif

  awk '$3 == "table"	{ printf "s-constraint -c '"$connect"' -table %s -type foreign -drop %%\n", $2 }' < $out | action

  if ( $status != 0 ) then
    set msg = "awk or 's-constaint .. -drop %' failed"
    goto usage
  endif

#  awk '$3 == "table"	{ printf "s-drop -c '"$connect"' -brief -pk %s\n", $2 }' < $out | action
#
#  if ( $status != 0 ) then
#    set msg = "awk or s-drop failed"
#    goto usage
#  endif

  awk '$3 == "index"	{ printf "s-drop -c '"$connect"' -brief -index %s\n", $2 }' < $out | action

  if ( $status != 0 ) then
    set msg = "awk or s-drop failed"
    goto usage
  endif

  if ( $?cascade == 0 ) then
    awk '$3 == "table"	{ printf "s-drop -c '"$connect"' -brief -table %s\n", $2 }' < $out | action
  else
    awk '$3 == "table"	{ printf "s-drop -c '"$connect"' -brief -cascade %s\n", $2 }' < $out | action
  endif

  if ( $status != 0 ) then
    set msg = "awk or s-drop failed"
    goto usage
  endif

  cat $out \
    | sed -e '/[ ]trigger/d' -e '/[ ]view/d' -e '/[ ]index/d' -e '/[ ]table/d' \
    | awk '{ printf "s-drop -c '"$connect"' -brief -%s %s\n", $3, $2 }' \
    | action

  if ( $status != 0 ) then
    set msg = "awk or s-drop failed"
    goto usage
  endif

  exit 0

#-----------------------------------------------------------------------------

usage:

  if ( $?brief == 1 ) goto brief

  echo ""
  echo "Error:  $msg"
  echo ""
  echo "Usage:  s-obj-drop-action -c <connect> [-brief] [-cascade] < show | run >"
  echo ""
  echo "- Show or run the drop the objects on list piped from s-obj output."
  echo ""
  echo "- Use '-cascade' to drop tables with 'cascade constraints' option."
  echo ""

  rm -f $out

  exit -1

#-----------------------------------------------------------------------------

brief:

  echo "s-obj-drop-action:  $msg"

  exit -1

#------------------------------------------------------------------------------
