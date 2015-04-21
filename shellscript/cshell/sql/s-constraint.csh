#!/bin/csh -f
#------------------------------------------------------------------------------

  set Src_Table		= "All_Constraints"
  set OwnerColumn 	= "v.Owner, "
  set OwnerOrder	= ", 2"
  set Where_Clause	= ""

  alias action	' cat '
  alias list	' cat '

  set out = /usr/tmp/.s-constraints.tmp.$$

  cat /dev/null > $out

#------------------------------------------------------------------------------

# Sure I'm using some labels and goto's for overall processing but it works
# pretty well and is clear enough to read.  Perl would be a better choice but
# I can't depend upon perl being available on my client's machines.

  unset pipe
  unset print
  unset xable

start_option:

  while ( "$1" =~ -* )
    switch ( "$1" )
      case "-all":
        set Src_Table		= "All_Constraints"
        set OwnerColumn 	= "v.Owner, "
        set OwnerOrder		= ", 2"
        breaksw
      case "-c":
        if ( $?connect != 0 ) then
          set msg = "Option '$1' already set"
          goto usage
        endif
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        set connect = "$2" ; shift
        breaksw
      case "-dba":
        set Src_Table		= "Dba_Constraints"
        set OwnerColumn 	= "v.Owner, "
        set OwnerOrder		= ", 2"
        breaksw
      case "-disable":
        if ( $?xable != 0 ) then
          set msg = "Option '$1' - disable/enable/drop option specified twice"
          goto usage
        endif
        set xable = "disable"
        breaksw
      case "-drop":
        if ( $?xable != 0 ) then
          set msg = "Option '$1' - disable/enable/drop option specified twice"
          goto usage
        endif
        set xable = "drop"
        breaksw
      case "-enable":
        if ( $?xable != 0 ) then
          set msg = "Option '$1' - disable/enable/drop option specified twice"
          goto usage
        endif
        set xable = "enable"
        breaksw
      case "-owner":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        if ( $?owners == 0 ) set owners = ( )
        set owners = ( $owners "$2" )
        shift
        breaksw
      case "-xowner":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        if ( $?xowners == 0 ) set xowners = ( )
        set xowners = ( $xowners "$2" )
        shift
        breaksw
      case "-p":
        set print = 1
        breaksw
      case "-pipe":
        set pipe = 1
        breaksw
      case "-s":
        alias list ' cat > /dev/null '
        breaksw       
      case "-table":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        if ( $?tables == 0 ) set tables = ( )
        set tables = ( $tables "$2" )
        shift
        breaksw
      case "-xtable":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        if ( $?xtables == 0 ) set xtables = ( )
        set xtables = ( $xtables "$2" )
        shift
        breaksw
      case "-type":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        if ( $?types == 0 ) set types = ( )
        switch ( "$2" )
          case "primary":
            set type = "R"
            breaksw
          case "foreign":
            set type = "R"
            breaksw
          case "check":
            set type = "C"
            breaksw
          case "notnull":
            set type = "N"
            breaksw
          case "unique":
            set type = "U"
            breaksw
          default:
            set msg = "Option '$1' missing argument"
            goto usage
        endsw
        set types = ( $types "$type" )
        shift
        breaksw
      case "-xtype":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        if ( $?xtypes == 0 ) set xtypes = ( )
        switch ( "$2" )
          case "primary":
            set type = "R"
            breaksw
          case "foreign":
            set type = "R"
            breaksw
          case "check":
            set type = "C"
            breaksw
          case "notnull":
            set type = "N"
            breaksw
          case "unique":
            set type = "U"
            breaksw
          default:
            set msg = "Option '$1' missing argument"
            goto usage
        endsw
        set xtypes = ( $xtypes "$type" )
        shift
        breaksw
      case "-user":
         set Src_Table		= "User_Constraints"
         set OwnerColumn	= ""
         set OwnerOrder		= ""
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

#------------------------------------------------------------------------------

  if ( $?xable != 0 ) then 
    alias action "s-constraint-action -c $connect $xable"
    set pipe = 1
  endif

#------------------------------------------------------------------------------

start_name:

  if ( $#argv <= 0 ) then
    set msg = "Missing constraint name pattern - expected at least one after options"
    goto usage
  endif

  set Name = "$1"

  if ( "$Name" == "" ) then
    set msg = "Invalid name specified - empty string"
    goto usage
  endif

  set Name = "` echo $Name | tr '-' '_' `"

#------------------------------------------------------------------------------

  if ( $?owners != 0 ) then
    set Owner_Clause = " v.Owner like Upper('$owners[1]') "
    if ( $#owners > 1 ) then
      foreach p ( $owners[2-] )
        set Owner_Clause = " $Owner_Clause  Or  v.Owner like Upper('$p') "
      end
    endif
    set Owner_Clause = " and ( $Owner_Clause ) "
  else
    set Owner_Clause = ""
  endif

  if ( $?xowners != 0 ) then
    foreach p ( $xowners )
      set Owner_Clause = " $Owner_Clause  And  v.Owner not like Upper('$p') "
    end
  endif

#------------------------------------------------------------------------------

  if ( $?tables != 0 ) then
    set Table_Clause = " v.Table_Name like Upper('$tables[1]') "
    if ( $#tables > 1 ) then
      foreach p ( $tables[2-] )
        set Table_Clause = " $Table_Clause  Or  v.Table_Name like Upper('$p') "
      end
    endif
    set Table_Clause = " and ( $Table_Clause ) "
  else
    set Table_Clause = ""
  endif

  if ( $?xtables != 0 ) then
    foreach p ( $xtables )
      set Table_Clause = " $Table_Clause  And  v.Table_Name not like Upper('$p') "
    end
  endif

#------------------------------------------------------------------------------

  if ( $?types != 0 ) then
    set Type_Clause = " v.Constraint_Type = Upper('$types[1]') "
    if ( $#types > 1 ) then
      foreach p ( $types[2-] )
        set Type_Clause = " $Type_Clause  Or  v.Constraint_Type = Upper('$p') "
      end
    endif
    set Type_Clause = " and ( $Type_Clause ) "
  else
    set Type_Clause = ""
  endif

  if ( $?xtypes != 0 ) then
    foreach p ( $xtypes )
      set Type_Clause = " $Type_Clause  And  v.Constraint_Type <> Upper('$p') "
    end
  endif

#------------------------------------------------------------------------------

  if ( $?pipe == 0 ) then
    set Set_Commands = "PageSize  999  FeedBack On"
  else
    set Set_Commands = "PageSize    0  FeedBack Off"
  endif

#------------------------------------------------------------------------------

sqlplus -s $connect <<-Sql-Done- | tr -d '\014' | sed '/^[ ]*$/d' | tee $out | action | list
--
  Set  LineSize 120  Space 2  $Set_Commands
--
  Column      Owner		Format A30	Heading "Owner"
  Column      Table_Name	Format A30	Heading "Table"
  Column      Constraint_Name	Format A30	Heading "Constaint"
--
  Select      $OwnerColumn v.Table_Name, v.Constraint_Name
    from      $Src_Table v
    where     v.Constraint_Name like Upper('$Name')  $Owner_Clause $Table_Clause $Type_Clause
    Order by  1 $OwnerOrder
  ;
--
-Sql-Done-

  if ( $status != 0 ) then
    set msg = "sqlplus failed"
    goto usage
  endif

  goto done

#------------------------------------------------------------------------------

done:

  shift

  if ( $#argv > 0 ) then
    if ( "$1" =~ -* ) goto start_option
    goto start_name
  endif

  if ( $?print ) then
    print $out
  endif

  rm -f $out
  exit 0

#------------------------------------------------------------------------------

usage:

  echo ""
  echo "Error:  $msg"
  echo ""
  echo "Usage:  s-constraint [options] <name-pattern> [ [options] <name-pattern> ... ]"
  echo ""
  echo "Options:"
  echo ""
  echo "  -all            Search all Constraints accessible by the user (default)"
  echo ""
  echo "  -c <connect>    Connection string user/password"
  echo ""
  echo "  -dba            Search all Constraints in the database"
  echo ""
  echo "  -disable        Disable the matching constraints."
  echo ""
  echo "  -enable         Enable the matching constraints."
  echo ""
  echo "  -owner <s>      Owned by schema <s>, multiple values or'd together."
  echo ""
  echo "    -xowner <s>   Not owned by schema <s>, multiple values and'd together."
  echo ""
  echo "  -p              print output to default printer."
  echo ""
  echo "  -pipe           Output piped - no headings or feedback"
  echo ""
  echo "  -s              Run silently, useful just to print listing"
  echo ""
  echo "  -table <t>      Show constraints for table <t>, multiple values or'd together."
  echo ""
  echo "    -xtable <t>   Do not show constraints for table <t>, multiple values or'd together."
  echo ""
  echo "  -type <t>       Show only constraints of type <t>, multiple values or'd together."
  echo "                    ( <t> : primary, foreign, check, notnull, unique )"
  echo ""
  echo "    -xtype <t>    Do not show constraints of type <t>, multiple values and'd together."
  echo ""
  echo "  -user           Search all Constraints owned by the user"
  echo ""

  rm -f $out

  exit -1

#------------------------------------------------------------------------------
