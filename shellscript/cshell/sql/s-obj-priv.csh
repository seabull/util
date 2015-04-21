#!/bin/csh -f
#------------------------------------------------------------------------------

  set out = /usr/tmp/.s-obj-priv.$$.tmp
  set sql = /usr/tmp/.s-obj-priv.$$.sql

  alias list ' cat '

#------------------------------------------------------------------------------

  set col_names  = ( grantor grantee owner object priv admin )

  set col_args   = ( Grantor Grantee Owner Table_Name Privilege Grantable )

  set cols       = ( grantor grantee owner object priv admin )

#------------------------------------------------------------------------------

  set xgrantor		= ""
  set xgrantee		= ""
  set xowner		= ""
  set xobject		= ""
  set xprivilege	= ""

  unset show_sql
  unset print
  unset pipe

#------------------------------------------------------------------------------

  while ( "$1" =~ -* )
    switch ( "$1" )
      case "-c":
        if ( $?connect != 0 ) then
          set msg = "Multiple connection options"
          goto usage
        endif
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        set connect = "$2" ; shift
        breaksw
#
      case "-grantor":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
	set expr = " t.Grantor like Upper('$2') "
	if ( $?grantor == 0 ) then
          set grantor = " $expr "
        else
          set grantor = " $grantor or $expr "
        endif
        shift
        breaksw
      case "-xgrantor":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        set xgrantor = " $xgrantor and t.Grantor Not like Upper('$2') "
        shift
        breaksw
#
      case "-grantee":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
	set expr = " t.Grantee like Upper('$2') "
	if ( $?grantee == 0 ) then
          set grantee = " $expr "
        else
          set grantee = " $grantee or $expr "
        endif
        shift
        breaksw
      case "-xgrantee":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        set xgrantee = " $xgrantee and t.Grantee Not like Upper('$2') "
        shift
        breaksw
#
#
      case "-owner":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
	set expr = " t.Owner like Upper('$2') "
	if ( $?owner == 0 ) then
          set owner = " $expr "
        else
          set owner = " $owner or $expr "
        endif
        shift
        breaksw
      case "-xowner":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        set xowner = " $xowner and t.Owner Not like Upper('$2') "
        shift
        breaksw
#
      case "-obj":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
	set expr = " t.Table_Name like Upper('$2') "
	if ( $?object == 0 ) then
          set object = " $expr "
        else
          set object = " $object or $expr "
        endif
        shift
        breaksw
      case "-xobj":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        set xobject = " $xobject and t.Table_Name Not like Upper('$2') "
        shift
        breaksw
#
      case "-priv":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
	set expr = " t.Privilege like Upper('$2') "
	if ( $?privilege == 0 ) then
          set privilege = " $expr "
        else
          set privilege = " $privilege or $expr "
        endif
        shift
        breaksw
      case "-xpriv":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        set xprivilege = " $xprivilege and t.Privilege Not like Upper('$2') "
        shift
        breaksw
#
      case "-col":
        if ( "$2" == "" ) then
          set msg = "Option '$1' - missing argument"
          goto usage
        endif 
	set col = "` echo $2 | tr 'A-Z' 'a-z' `"
        set check = "` args $col_names | grep $col `"
	if ( "$check" == "" ) then
          set msg = "Option '$1' - column '$2' not in display list"
          goto usage
        endif
        set cols = ( $cols $col )
        shift
        breaksw
      case "-xcol":
        if ( "$2" == "" ) then
          set msg = "Option '$1' - missing argument"
          goto usage
        endif
	set col = "` echo $2 | tr 'A-Z' 'a-z' `"
        set new_list = ( ` elt-rm "$cols" "$col" ` )
        if ( "$new_list" =~ Error:* ) then
          set msg = "Option '$1' - column '$2' not in displayable list"
          goto usage
        endif
	set cols = ( $new_list )
        shift
        breaksw
#
      case "-s":
        alias list ' cat > /dev/null '
        breaksw       
      case "-pipe":
        set pipe = 1
        breaksw
      case "-p":
        set print = 1
        breaksw
      case "-sql":
        set show_sql = 1
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

  if ( $?grantor == 0 ) then
    set grantor = ""
  else
    set grantor = " and ( $grantor ) "
  endif

  if ( $?grantee == 0 ) then
    set grantee = ""
  else
    set grantee = " and ( $grantee ) "
  endif

  if ( $?owner == 0 ) then
    set owner = ""
  else
    set owner = " and ( $owner ) "
  endif

  if ( $?object == 0 ) then
    set object = ""
  else
    set object = " and ( $object ) "
  endif

  if ( $?privilege == 0 ) then
    set privilege = ""
  else
    set privilege = " and ( $privilege ) "
  endif

#------------------------------------------------------------------------------

  if ( $#argv < 1 ) then
    set msg = "Missing grantee name pattern"
    goto usage
  endif

  if ( $#argv > 1 ) then
    set msg = "Expect grantee name pattern - found '$*'"
    goto usage
  endif

  set name = "$1"

  if ( "$name" == "" ) then
    set msg = "Invalid name specified - empty string"
    goto usage
  endif

#------------------------------------------------------------------------------

  set col_list	= ( ` elt-map "$col_args" "$col_names" "$cols" ` )

  set col_sel = "Initcap(t.$col_list[1]) #$col_list[1]#"
  set idx = 2 ;
  while ( $idx <= $#col_list )
    set col_sel = "$col_sel , Initcap(t.$col_list[$idx])"
    if ( $col_names[$idx] == "admin" ) then
      set col_sel = "$col_sel #Admin#"
    else
      set col_sel = "$col_sel #$col_list[$idx]#"
    endif
    @ idx = $idx + 1
  end

  echo "$col_sel" | tr '#' '"' > $out

  set col_sel = "` cat $out `"

  set order = "1" ; @ i = 2
  foreach x ( $cols[2-] )
    set order = "$order, $i"
    @ i = $i + 1
  end

#------------------------------------------------------------------------------

  if ( $?pipe == 0 ) then
    set Set_Commands = "PageSize  50000  FeedBack On"
  else
    set Set_Commands = "PageSize    0  FeedBack Off"
  endif

#------------------------------------------------------------------------------

cat <<-Sql-Done- > $sql
--
  Set  LineSize 112  Space 2  $Set_Commands
--
  Column "Grantor"	Format A15
  Column "Grantee"	Format A15
  Column "Privilege"	Format A10
--Column "Role"		Format A20
  Column "Owner"	Format A15
  Column "Table"	Format A30
  Column "Admin"	Format A5
--
  Select      $col_sel
    From      Dba_Tab_Privs t
    Where     t.Grantee like Upper('$name')	--
              $grantor	$xgrantor		--
              $grantee	$xgrantee		--
              $owner	$xowner			--
              $object	$xobject		--
              $privilege $xprivilege		--
    Order by  $order
  ;
--
  Quit ;
--
-Sql-Done-

#------------------------------------------------------------------------------

# Premature exit is an error

  set rc = -1

#------------------------------------------------------------------------------

  if ( $?show_sql == 0 ) then
    sqlplus -s $connect @$sql < /dev/null | tr -d '\014' | tee $out | list
    if ( $status != 0 ) then
      echo "s-obj: sqlplus failed"
      goto done
    endif
    if ( $?print ) then
      print $out
    endif
  else
    cat $sql
    if ( $?print ) then
      print $sql
    endif
  endif

  set rc = 0

done:

  rm -f $out $sql

  exit $rc

#------------------------------------------------------------------------------

usage:

  echo ""
  echo "Error:  $msg"
  echo ""
  echo "Usage:  s-obj-priv [options] <grantee-name-pattern>"
  echo ""
  echo "Options:"
  echo ""
  echo "  -c <connect>    Connection string user/password"
  echo ""
  echo "  -grantor <p>    User which granteed the privilege"
  echo ""
  echo "  -grantee <p>    User granted the privilege"
  echo ""
  echo "  -owmer <p>      Owner of the object"
  echo ""
  echo "  -obj <p>        Object name"
  echo ""
  echo "  -priv <p>       Privilege granted"
  echo ""
  echo "  -col <c>        Add column to the display list."
  echo "                  ( $col_names )"
  echo ""
  echo "  -xcol <c>       Remove column <c> from the display list."
  echo ""
  echo "  -pipe           Output piped - no headings or feedback"
  echo ""
  echo "  -sql            Show generated SQL - do not run."
  echo ""
  echo "  -p              Print listing"
  echo ""
  echo "  -s              Run silently, useful just to print listing"
  echo ""
  echo "- Each <p> is a pattern string for 'like' comparisions"
  echo ""
  echo "- Column value options ('-owner',...) may be specified multiple times"
  echo "  with each being Or'ed in the final where clause.  They may also be"
  echo "  prefixed with 'x' ('-xowner') to negate the value."
  echo ""
  echo "Example:"
  echo ""
  echo "  s-obj-priv -owner apps -obj so_% %"
  echo ""

  rm -f $out $sql

  exit -1

#------------------------------------------------------------------------------
