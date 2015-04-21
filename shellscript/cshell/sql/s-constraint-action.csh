#!/bin/csh -f
#-----------------------------------------------------------------------------

  if ( $#argv != 3 ) then
    set msg = "wrong number of arguments"
    goto usage
  endif

  if ( "$1" != "-c" ) then
    set msg = "Argument '-c' missing."
    goto usage
  endif

  set connect = "$2"

  if ( "$connect" == "" ) then
    set msg = "<connect> is an empty string - expected <schema>/<password>[@<instance>]"
    goto usage
  endif

  set action = "$3"

  if ( "$action" != "enable" && "$action" != "disable" && "$action" != "drop" ) then
    set msg = "Unexpected value for <action> - expected 'enable' or 'disable'."
    goto usage
  endif

#-----------------------------------------------------------------------------

  set cmd = 'alter table %s '"$action"' constraint %s ;\n", $2, $3'

  awk 'NF>0&&$1!="Owner"&&substr($1,1,1)!="-"{ printf "prompt + '"$cmd"' ; printf "'"$cmd"' }' \
    | sqlplus -s $connect

  if ( $status != 0 ) then
    set msg = "awk or sqlplus failed"
    goto usage
  endif

  exit 0

#-----------------------------------------------------------------------------

usage:

  echo ""
  echo "Error:  $msg"
  echo ""
  echo "Usage:  s-constraint-action -c <connect> < enable | disable | drop >"
  echo ""
  echo "- Enable, disable, drop the constraints on list piped from s-constraint output."
  echo ""

  exit -1

#-----------------------------------------------------------------------------
