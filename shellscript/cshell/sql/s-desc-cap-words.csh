#!/bin/csh -f
#-----------------------------------------------------------------------------

  set base	= /usr/tmp/.cap-words.$$
  set words	= $base.words
  set temp	= $base.temp
  set filter	= $base.awk
  set caps	= $base.sed
  set save	= $base.sav

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

  cat $file  \
    | sed -e 's/[^A-Z ][^A-Z ]*/ /g'	\
    | tr ' ' '\012'			\
    | sed -e '/^$/D' -e '/^[A-Z]$/D'	\
    | sort -ru 				\
    > $words

  if ( $status != 0 ) goto error

#-----------------------------------------------------------------------------

cat <<-StdIn-Done- > $filter
#
function change_word ( src, dst )
{
  printf "s/\\\\([^A-Za-z]\\\\)%s\\\\([^A-Za-z]\\\\)/\\\\1%s\\\\2/g\\n", src, dst ;

  printf "s/\\\\([^A-Za-z]\\\\)%s\$/\\\\1%s/g\\n", src, dst ;

  printf "s/^%s\\\\([^A-Za-z]\\\\)/%s\\\\1/g\\n", src, dst ;

  printf "s/^%s\$/%s/g\\n", src, dst ;
}
#
BEGIN {
  change_word("VARCHAR","VarChar") ;
}
#
{
  change_word(\$1,substr(\$1,1,1)tolower(substr(\$1,2))) ;
}
#
-StdIn-Done-
 
#-----------------------------------------------------------------------------

  set path = ( /usr/xpg4/bin $path )

  if ( "`uname`" != "SunOS" ) then
    awk -f $filter < $words > $caps
    if ( $status != 0 ) goto error
    sed -f $caps < $file > $temp
    if ( $status != 0 ) goto error
  else
    s-desc-cap-words.by-word.pl $file $filter < $words > $temp
    if ( $status != 0 ) goto error
  endif

  mv $file $save

  if ( $status != 0 ) goto error

  mv $temp $file

  if ( $status != 0 ) then
    mv $save $file
    set msg = "mv error occured - attempted to restore original"
    goto usage
  endif

  ( rm -f $base.* >& /dev/null )

  exit 0

#-----------------------------------------------------------------------------

usage:

  echo ""
  echo "Error:  $msg"
  echo ""
  echo "Usage:  cap-words <file>"
  echo ""

error:

  ( rm -f $base.* >& /dev/null )

  exit -1

#-----------------------------------------------------------------------------
