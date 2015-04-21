#!/bin/csh -f
#------------------------------------------------------------------------------

  set Src_Table = "Dba_Views"

  alias list ' cat '

  set out = /usr/tmp/.s-view.tmp.$$

  cat /dev/null > $out

#------------------------------------------------------------------------------

# Sure I'm using some labels and goto's for overall processing but it works
# pretty well and is clear enough to read.  Perl would be a better choice but
# I can't depend upon perl being available on my client's machines.

start_option:

  while ( "$1" =~ -* )
    switch ( "$1" )
      case "-p":
        set print = 1
        breaksw
      case "-s":
        alias list ' cat > /dev/null '
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
      case "-list":
        set list = 1
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
      case "-all":
        set Src_Table = "All_Views"
        breaksw
      case "-dba":
        set Src_Table = "Dba_Views"
        breaksw
      case "-user":
         set Src_Table = "User_Views"
         breaksw
      default:
        set msg = "Unrecognized option '$1'"
        goto usage
    endsw
    shift
  end

#------------------------------------------------------------------------------

start_name:

  if ( $#argv <= 0 ) then
    set msg = "Missing view name pattern - expected at least one after options"
    goto usage
  endif

  set Name = "$1"

  if ( "$Name" == "" ) then
    set msg = "Invalid name specified - empty string"
    goto usage
  endif

  set Name = "` echo $Name | tr '-' '_' `"

#------------------------------------------------------------------------------

  if ( $?connect == 0 ) then
    if ( $?CXAPPS == 0 ) then
      set connect = "/"
    else
      set connect = "$CXAPPS"
    endif
  endif

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

# Either locate the names or list the sql source for the matching view names

  if ( $?list != 0 ) goto list_source

#------------------------------------------------------------------------------

sqlplus -s $connect <<-Sql-Done- | tr -d '\014' | tee $out | list
--
  Set  PageSize 999  LineSize 80  Space 2
--
  Column      Owner		Format A30
  Column      View_Name		Format A30
--
  Select      v.Owner, v.View_Name
    from      $Src_Table v
    where     v.View_Name like Upper('$Name')  $Owner_Clause
    Order by  1, 2
  ;
--
-Sql-Done-

  goto done

#------------------------------------------------------------------------------

list_source:

sqlplus -s $connect <<-Sql-Done- | tr -d '\014' | tee $out | list
--
  Set FeedBack Off PageSize 0 Long 100000
--
  Select  Text
    From  $Src_Table
    Where View_Name = Upper('$Name')
  ;
--
-Sql-Done-

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
  echo "Usage:  s-view [options] <name-pattern> [ [options] <name-pattern> ... ]"
  echo ""
  echo "Options:"
  echo ""
  echo "  -c <connect>    Connection string user/password"
  echo ""
  echo "  -list           List view SQL source"
  echo ""
  echo "  -dba            Search all views in the database"
  echo ""
  echo "  -all            Search all views accessible by the user"
  echo ""
  echo "  -user           Search all views owned by the user"
  echo ""
  echo "  -p              Print table names listing"
  echo ""
  echo "  -s              Run silently, useful just to print listing"
  echo ""

  rm -f $out

  exit -1

#------------------------------------------------------------------------------
