#!/bin/csh -f
#------------------------------------------------------------------------------

  set tmp = /usr/tmp/.s-desc.$$

  if ( $?CXAPPS == 0 ) then
    set connect = "/"
  else
    set connect = "$CXAPPS"
  endif

# set sort_columns  = 1
  set cap_words     = 1

#------------------------------------------------------------------------------

  while ( "$1" =~ -* )
    switch ( "$1" )
      case "-capitalize":
      case "-cap":
        set cap_words = 1
        breaksw
      case "-nocapitalize":
      case "-nocap":
        if ( $?cap_words ) unset cap_words
        breaksw
      case "-sort":
        set sort_columns = 1
        breaksw
      case "-nosort":
        if ( $?sort_columns ) unset sort_columns
        breaksw
      case "-print":
      case "-p":
        set print = 1
        breaksw
      case "-silent":
      case "-s":
        set silent = 1
        breaksw       
      case "-connect":
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

  if ( $#argv < 1 ) then
    set msg = "Missing table name"
    goto usage
  endif

start:

  set name = "$1"

  if ( "$name" == "" ) then
    set msg = "Invalid name specified - empty string"
    goto usage
  endif

  echo "$name" > $tmp

  set name = "` cat $tmp | tr '-' '_' | tr '\044' '~' `"

#------------------------------------------------------------------------------

  set dst = ~/tables

  if ( -d $dst/. ) then
    set out = "$dst/` echo $name | sed -e 's/[^.]*\.//' -e 's/_/-/g' -e 's/~/./g' `.dsc"
  else
    set out = $tmp
  endif

  set name = "` echo $name | tr '~' '\044' `"

#------------------------------------------------------------------------------

  ( echo "Table:  $name" ; echo "" ; \
    ; ( echo "describe $name ;" | sqlplus -s $connect ) | tr -d '\014' ) > $out

  if ( $?cap_words ) then
    s-desc-cap-words $out
  endif

  if ( $?sort_columns ) then
    s-desc-sort-columns $out
  endif

  if ( ! $?silent ) then
    cat $out
  endif

  if ( $?print ) then
    print $out
  endif

  rm -f $tmp

  shift

  if ( $#argv > 0 ) goto start

  exit 0

#------------------------------------------------------------------------------

usage:

  echo ""
  echo "Error:  $msg"
  echo ""
  echo "Usage:  s-desc [options] <table-name> [ <table-name> ... ]"
  echo ""
  echo "Options:"
  echo ""
  echo "  -c <connect>            Connection string user/password"
  echo ""
  echo "  -print, -p              Print table names listing"
  echo ""
  echo "  -silent, -s             Run silently, useful just to print listing"
  echo ""
  echo "  -capitalize, -cap       Capitalize all words (default)"
  echo ""
  echo "  -nocapitalize, -nocap   Do not capitalize all words"
  echo ""
  echo "  -nosort                 Do not sort column names (default)"
  echo ""
  echo "  -sort                   Sort column names"
  echo ""

  rm -f $tmp

  exit -1

#------------------------------------------------------------------------------
