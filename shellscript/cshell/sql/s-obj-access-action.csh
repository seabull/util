#!/bin/csh -f
#-----------------------------------------------------------------------------

# clear up any trash matching the current process id ($$)

  ( rm -f /var/tmp/$$.* >& /dev/null & )

  set out = /var/tmp/$$.s-obj-access-action.tmp
 
#-----------------------------------------------------------------------------

  unset connect		; unsetenv connect
  unset brief		; unsetenv brief

  set grant_users	= ( )
  set grant_rights	= ( )
  set revoke_users	= ( )
  set revoke_rights	= ( )

  while ( "$1" =~ -* )
    set opt = "$1"
    switch ( "$opt" )
      case "-brief"
        set brief = 1
        breaksw
      case "-c":			# Set connection string
        if ( $?connect != 0 ) then
          set msg = "Second connection option found - please only specify one"
          goto usage
        endif
        if ( "$2" == "" ) then
          set msg = "Option '$opt' missing argument"
          goto usage
        endif
        set connect = "$2" ; shift
        breaksw
      case "-grant":
        while ( "$2" != ":" && "$2" !~ -* && "$2" != "" )
          set grant_users = ( $grant_users $2 )
          shift
        end
        if ( "$2" =~ -* ) then
          set msg = "Option '$opt' grant user list terminated by an option ($2)."
          goto usage
        endif
        if ( "$2" == "" ) then
          set msg = "Option '$opt' grant user list terminated by empty string (not colon)."
          goto usage
        endif
        shift	# skip over ':'
        while ( "$2" != ":" && "$2" !~ -* && "$2" != "" )
          set grant_rights = ( $grant_rights $2 )
          shift
        end
        if ( "$2" == ":" ) then 
          set msg = "Option '$opt' grant access list terminated by a ':' ($2) - see usage."
          goto usage
        endif
        if ( $#grant_users != $#grant_rights ) then
          set msg = "Option '$opt' - <u> & <a> not equal - found $#grant_users for $#grant_rights"
          goto usage
        endif
        breaksw
      case "-revoke":
        while ( "$2" != ":" && "$2" !~ -* && "$2" != "" )
          set revoke_users = ( $revoke_users $2 )
          shift
        end
        if ( "$2" =~ -* ) then
          set msg = "Option '$opt' revoke user list terminated by an option ($2) - see usage."
          goto usage
        endif
        if ( "$2" == "" ) then
          set msg = "Option '$opt' grant user list terminated by empty string (not colon)."
          goto usage
        endif
        shift	# skip over ':'
        while ( "$2" != ":" && "$2" !~ -* && "$2" != "" )
          set revoke_rights = ( $revoke_rights $2 )
          shift
        end
        if ( "$2" == ":" ) then
          set msg = "Option '$opt' revoke access list terminated by a ':' ($2) - see usage."
          goto usage
        endif
        if ( $#revoke_users != $#revoke_rights ) then
          set msg = "Option '$opt' - <u> & <a> not equal - found $#revoke_users for $#revoke_rights"
          goto usage
        endif
        breaksw
      default:
        set msg = "Unrecognized option '$opt'"
        goto usage
    endsw
    shift
  end

  if ( $#argv != 0 ) then
    set msg = "unexpected arguments after options:  $*"
    goto usage
  endif


#------------------------------------------------------------------------------

  if ( $?connect == 0 ) then
    set msg = "'-c <connect>' missing - please specify a connection string."
    goto usage
  endif

#------------------------------------------------------------------------------

  expand | tr A-Z a-z > $out	# copy input to temporary file

  if ( $status != 0 ) then
    set msg = "tr or expand failed"
    goto usage
  endif

# alias action 'cat'
# echo "<->"
# cat $out
# echo "<->"

  alias action 'sh -x'

#------------------------------------------------------------------------------

  @ i = 1 ;

  while ( $i <= $#grant_users )
    set fmt = "s-grant -c $connect $grant_rights[$i] %s.%s $grant_users[$i]\n"
    cat $out | awk '{ printf "'"$fmt"'", $1, $2 }' | action
    if ( $status != 0 ) then
      set msg = "awk or s-grant failed"
      goto usage
    endif
    @ i = $i + 1
  end

#------------------------------------------------------------------------------

  @ i = 1 ;

  while ( $i <= $#revoke_users )
    set fmt = "s-revoke -c $connect $revoke_rights[$i] %s.%s $revoke_users[$i]\n"
    cat $out | awk '{ printf "'"$fmt"'", $1, $2 }' | action
    if ( $status != 0 ) then
      set msg = "awk or s-revoke failed"
      goto usage
    endif
    @ i = $i + 1
  end

  exit 0

#-----------------------------------------------------------------------------

usage:

  if ( $?brief == 1 ) goto brief

  echo ""
  echo "Error:  $msg"
  echo ""
  echo "Usage:  s-obj-access-action -c <connect> [-brief] [ [ -grant | -revoke ] [ <u> ... ] : [ <a> ... ] ] ..."
  echo ""
  echo "- Given input of lines '<owner> <object> <type>', grant/revoke user <u>'s access <a> to <object>"
  echo ""
  echo "- Multiple -grant and revoke options may be specified with multiple user and access lists "
  echo ""
  echo "- The user and access lists, <u> and <a>, must agree in order."
  echo ""
  echo "- However, it is not an error to have empty user and access lists.  If both"
  echo "  are emtpy then no actions will be taken."
  echo ""

  rm -f $out

  exit -1

#-----------------------------------------------------------------------------

brief:

  echo "s-obj-access-action:  $msg"

  exit -1

#------------------------------------------------------------------------------
