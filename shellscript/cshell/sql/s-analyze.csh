#!/bin/csh -f
#------------------------------------------------------------------------------

  set def_connect	= "/"
  set def_mode		= "table"
  set def_method	= "COMPUTE"
  set def_percent	= 30

#------------------------------------------------------------------------------

  set cur_connect	= "$def_connect"
  set cur_mode		= "$def_mode"
  set cur_method	= "$def_method"
  set cur_percent	= "$def_percent"

process_options:

  unset connect
  unset mode
  unset method
  unset percent

  while ( "$1" =~ -* )
    switch ( "$1" )
    #
    # Options
    #
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
      case "-schema":
      case "-table":
      case "-index":
      case "-cluster":
        if ( $?mode != 0 ) then
          set msg = "Second mode option ($1) found - please specify only one"
          goto usage
        endif
	set mode = "` echo $1 | sed s/^-//g `"
        breaksw
      case "-compute":
      case "-estimate":
      case "-delete":
        if ( $?method != 0 ) then
          set msg = "Second method option ($1) found - please specify only one"
          goto usage
        endif
	set method = "` echo $1 | sed s/^-//g | tr 'a-z' 'A-Z' `"
        breaksw
      case "-percent":
        if ( $?percent != 0 ) then
          set msg = "Second '$1' option found - please only specify one"
          goto usage
        endif
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        set check = "` echo $1 | sed 's/[0-9]//g' `"
        if ( "$check" != "" ) then
          set msg = "Option '$1' - argument ($2) contains non-digit characters"
          goto usage
        endif
        set percent = "$2" ; shift
        breaksw
      default:
        set msg = "Unrecognized option '$1'"
        goto usage
    endsw
    shift
  end

#------------------------------------------------------------------------------

  if ( $?mode == 0 ) set mode = "$cur_mode"

  set cur_mode = "$mode"

#------------------------------------------------------------------------------

  if ( $?method == 0 ) set method = "$cur_method"

  set cur_method = "$mode"

#------------------------------------------------------------------------------

  if ( $?percent == 0 ) set percent = "$cur_percent"

  set cur_percent = "$percent"

#------------------------------------------------------------------------------

  if ( $?connect == 0 ) then
    if ( $?CXAPPS == 0 ) then
      set connect = "$cur_connect"
    else
      set connect = "$CXAPPS"
    endif
  endif

  set cur_connect = "$connect"

#------------------------------------------------------------------------------

  if ( $#argv < 1 ) then
    set msg = "Missing $mode name - you must provide at least one."
    goto usage
  endif

#------------------------------------------------------------------------------

# Process each additional argument as a table name

  while ( "$1" !~ -* )

    if ( "$1" == "" ) continue

    set name = "$1"

    echo "- Analyzing $mode '$name'"

    if ( "$mode" == "schema" ) then

sqlplus -s $connect <<-Sql-Done- | tr -d '\014'
--
  Set ServerOutput On Size 100000 FeedBack On
--
  Execute dbms_utility.analyze_schema ( '$name', '$method', $percent, Null, Null ) ;
--
  exit
--
-Sql-Done-

    else

      switch ( "$method" )
        case "COMPUTE":
          set method = "compute statistics" ; breaksw
        case "ESTIMATE":
          set method = "estimate statistics sample $percent percent" ; breaksw
        case "DELETE":
          set method = "compute statistics" ; breaksw
      endsw

sqlplus -s $connect <<-Sql-Done- | tr -d '\014'
--
  Set ServerOutput On Size 100000 FeedBack On
--
  analyze $mode $name $method ;
--
  exit
--
-Sql-Done-

    endif

    shift

    if ( $#argv == 0 ) break

  end

# If necessary, process additional options

  if ( $#argv != 0 ) goto process_options

  exit 0

#------------------------------------------------------------------------------

usage:

  echo ""
  echo "Error:  $msg"
  echo ""
  echo "Usage:  s-analyze [options] <name> [ [options] <name> ... ]"
  echo ""
  echo "- Analyze the named objects (or schemas if '-schema' is specified)"
  echo ""
  echo "Options :"
  echo ""
  echo "  -c <string>     Oracle connection string, default '$def_connect'."
  echo "                  (or taken from 'CXAPPS' if defined)"
  echo ""
  echo "  -table          Analyze the named tables    (Default)"
  echo ""
  echo "  -index          Analyze the named indexes"
  echo ""
  echo "  -cluster        Analyze the named clusters"
  echo ""
  echo "  -schema         Analyze the named schemas"
  echo ""
  echo "  -compute        Compute statistics          (Default)"
  echo ""
  echo "  -estimate       Estimate statistics"
  echo ""
  echo "  -delete         Delete statistics"
  echo ""
  echo "Examples:"
  echo ""
  echo "  s-analyze -c etl/... -schema -estimate etl -table -compute foo bar"
  echo ""

  exit -1

#------------------------------------------------------------------------------
