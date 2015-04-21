#!/bin/csh -f
#------------------------------------------------------------------------------

  set options = ""

  unset connect
  unset brief

start:

  while ( "$1" =~ -* )
    switch ( "$1" )
    #
    # Options
    #
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
    #
    # Source type flags
    #
      case "-primarykey":
      case "-primary":
      case "-pk":
        if ( $?type != 0 ) goto extra_type
        set type = "primary key"
        breaksw
      case "-synonym":
        if ( $?type != 0 ) goto extra_type
        set type = "synonym"
        breaksw
      case "-psynonym":
        if ( $?type != 0 ) goto extra_type
        set type = "public synonym"
        breaksw
      case "-table":
        if ( $?type != 0 ) goto extra_type
        set type = "table" ; set options = ""
        breaksw
      case "-tablespace":
        if ( $?type != 0 ) goto extra_type
        set type = "tablespace" ; set options = ""
        breaksw
      case "-cascade":
        if ( $?type != 0 ) goto extra_type
        set type = "table" ; set options = "cascade constraints"
        breaksw
      case "-view":
        if ( $?type != 0 ) goto extra_type
        set type = "view"
        breaksw
      case "-index":
        if ( $?type != 0 ) goto extra_type
        set type = "index"
        breaksw
      case "-sequence":
      case "-seq":
        if ( $?type != 0 ) goto extra_type
        set type = "sequence"
        breaksw
      case "-procedure":
      case "-proc":
      case "-sp":
        if ( $?type != 0 ) goto extra_type
        set type = "procedure"
        breaksw
      case "-function":
      case "-fun":
      case "-sf":
        if ( $?type != 0 ) goto extra_type
        set type = "function"
        breaksw
      case "-trigger":
      case "-trig":
      case "-st":
        if ( $?type != 0 ) goto extra_type
        set type = "trigger"
        breaksw
      case "-package":
      case "-pkh":
      case "-sps":
        if ( $?type != 0 ) goto extra_type
        set type = "package"
        breaksw
      case "-pkb":
      case "-spb":
        if ( $?type != 0 ) goto extra_type
        set type = "package body"
        breaksw
    #
      default:
        set msg = "Unrecognized option '$1'"
        goto usage
    endsw
    shift
  end

  if ( $?type == 0 ) then
    set msg = "Please specify the object type"
    goto usage
  endif

#------------------------------------------------------------------------------

  if ( $?connect == 0 ) then
    if ( $?CXAPPS == 0 ) then
      set connect = "/"
    else
      set connect = "$CXAPPS"
    endif
  endif

#------------------------------------------------------------------------------

  if ( $#argv < 1 ) then
    set msg = "Missing object name argument"
    goto usage
  endif

  if ( $#argv > 1 ) then
    set msg = "Too many arguments - expected single object name, found '$*'"
    goto usage
  endif

  set name = "$1" ; shift

  if ( "$name" == "" ) then
    set msg = "Invalid name specified - empty string"
    goto usage
  endif

#------------------------------------------------------------------------------

# fold to uppercase

  set name = "` echo '$name' | tr 'a-z-' 'A-Z_' `"
  set type = "` echo '$type' | tr 'a-z-' 'A-Z_' `"

#------------------------------------------------------------------------------

if ( "$type" != "PRIMARY KEY" ) then

  sqlplus -s $connect <<-Sql-Done- | tr -d '\014'
    --
      Drop $type $name $options ;
    --
      Quit
    --
-Sql-Done-

else

  sqlplus -s $connect <<-Sql-Done- | tr -d '\014'
    --
      alter table $name drop primary key ;
    --
      Quit
    --
-Sql-Done-

endif

  if ( $#argv > 0 ) goto start

exit 0

#------------------------------------------------------------------------------

extra_type:

  set msg = "Extra source type flag '$1' - type already set to '$type'"

usage:

  if ( $?brief == 1 ) goto brief

  echo ""
  echo "Error:  $msg"
  echo ""
  echo "Usage:  s-drop [options] <object-type-flag> <object-name>"
  echo ""
  echo "Object type flags:"
  echo "" 
  echo "  -table              Table without 'cascade constraints'"
  echo ""
  echo "  -primary, -pk       Drop table's primary key"
  echo ""
  echo "  -cascade            Table with 'cascade constraints'"
  echo ""
  echo "  -index              Named index"
  echo ""
  echo "  -seq[uence]         Named sequence"
  echo ""
  echo "  -package, -pkg      PL/SQL Package"
  echo ""
  echo "  -sps, -pkh          PL/SQL Package Specifcation"
  echo ""
  echo "  -spb, -pkb          PL/SQL Package Body"
  echo ""
  echo "  -proc[edure], -sp   PL/SQL Stored Procedure"
  echo ""
  echo "  -fun[ction], -sf    PL/SQL Stored Function"
  echo ""
  echo "  -trig[ger], -st     PL/SQL Database Trigger"
  echo ""
  echo "Options:"
  echo ""
  echo "  -brief              On error, show only error message without usage text."
  echo ""
  echo "  -c <string>         Oracle connection string, default /."
  echo "                      (or taken from CXAPPS if defined)"
  echo ""

  exit -1

#------------------------------------------------------------------------------

brief:

  echo "s-drop:  $msg"

  exit -1

#------------------------------------------------------------------------------
