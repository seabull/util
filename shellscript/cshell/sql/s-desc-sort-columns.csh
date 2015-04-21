#!/bin/csh -f
#-----------------------------------------------------------------------------

  if ( $#argv > 1 ) then
    set msg = "too many arguments"
    goto usage
  endif
 
  set file = "$1"

  if ( "$file" == "" ) then
    set msg = "no file provided"
    goto usage
  endif

  if ( ! -f "$file" ) then
    set msg = "'$file' does not exist or is not a plain file"
    goto usage
  endif

#-----------------------------------------------------------------------------

  set base	= /usr/tmp/.sort-columns.$$
  set temp	= $base.temp
  set save	= $base.save

#-----------------------------------------------------------------------------

  ( head -4 $file ; sed -e '1,4D' -e '/^$/D' $file | sort ) > $temp

  if ( $status != 0 ) goto error

  mv $file $save

  if ( $status != 0 ) goto error

  mv $temp $file

  if ( $status != 0 ) then
    mv $save $file
    set msg = "mv error occured - attempted to restore original"
    goto usage
  endif

#-----------------------------------------------------------------------------

  ( rm -f $base.* >& /dev/null )

  exit 0

#-----------------------------------------------------------------------------

usage:

  echo ""
  echo "Error:  $msg"
  echo ""
  echo "Usage:  sort-columns <file>"
  echo ""

error:

  ( rm -f $base.* >& /dev/null )

  exit -1

#-----------------------------------------------------------------------------
