#!/bin/csh -f
#------------------------------------------------------------------------------

  set out = /usr/tmp/.s-priv.$$.tmp
  set sql = /usr/tmp/.s-priv.$$.sql

#------------------------------------------------------------------------------

  alias s-priv-cmd s-priv-role

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
      case "-role":
        alias s-priv-cmd s-priv-role
        breaksw
      case "-sys":
        alias s-priv-cmd s-priv-sys
        breaksw
      case "-obj":
      case "-tab":
        alias s-priv-cmd s-priv-obj
        breaksw
      case "-xowner":
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
      case "-ts":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        if ( $?ts == 0 ) set ts = ( )
        set ts = ( $ts "$2" )
        shift
        breaksw
      case "-xts":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        set ts = ( $xts "$2" )
        shift
        breaksw
      case "-type":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        set expr = " Object_Type like Upper('$2') "
        if ( $?type == 0 ) then
          set type = "$expr"
        else
          set type = "$type or $expr"
	endif
        shift
        breaksw
      case "-xtype":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        set xtype = "$xtype and t.Object_Type not like Upper('$2') "
        shift
        breaksw
      case "-status":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        set expr = " t.Status like Upper('$2') "
        if ( $?ostatus == 0 ) then
          set ostatus = "$expr"
        else
          set ostatus = "$ostatus or $expr"
	endif
        shift
        breaksw
      case "-xstatus":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        set xstatus = "$xstatus and t.Status not like Upper('$2') "
        shift
        breaksw
      case "-created":
        set Date_Column = "t.Creation"
        breaksw
      case "-last":
        set Date_Column = "t.Last_DDL_Date"
        breaksw
      case "-date":
        set Date_Prefix = ""
        breaksw
      case "-time":
        set Date_Prefix = "$Today "
        breaksw
      case "-since":
        set op = "<"
        goto date_arg
      case "-before":
        set op = ">"
        goto date_arg
      case "-xat":
        set op = "<>"
      date_arg:
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        set dates = " $dates and To_Date('$Date_Prefix$2','$Fmt_TS') $op $Date_Column "
        shift
        breaksw
      case "-at":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        set expr = " To_Date('$2','$Fmt_TS') = $Date_Column "
        if ( $?at_time == 1 ) then
          set at_time = " $at_time Or $expr "
        else
          set at_time = " $expr "
        endif
        shift
        breaksw
      case "-today":
        set arg = "$Today"
        goto object_on_date
      case "-on":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        set arg = "$2" ; shift
    object_on_date:
        set expr = " To_Date('$arg','$Fmt_Date') = Trunc($Date_Column) "
        if ( $?on_date == 1 ) then
          set on_date = " $on_date Or $expr "
        else
          set on_date = " $expr "
        endif
        breaksw
      case "-xon":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
	set dates = " $dates And To_Date('$2','$Fmt_Date') <> Trunc($Date_Column) "
        shift
        breaksw
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

  if ( $?owner == 0 ) then
    set owner = ""
  else
    set owner = " and ( $owner ) "
  endif

  if ( $?type == 1 ) then
    set type = " and ( $type ) "
  else
    set type = ""
  endif

  if ( $?ostatus == 1 ) then
    set ostatus = " and ( $ostatus ) "
  else
    set ostatus = ""
  endif

  if ( $?on_date == 1 ) then
    set dates = "$dates and ( $on_date ) "
  endif

  if ( $?ts == 0 ) then
    set ts_tab = " "
    set ts_whx = " "
  else
    set ts_tab = " , dba_segments s "
    set ts_whx = "and s.segment_name = t.Object_Name "
    set ts_whx = " $ts_whx   and    s.segment_type = t.Object_Type "
    set ts_whx = " $ts_whx   and    s.segment_type = t.Object_Type "
    if ( $Src_Table != "User_Objects" ) then
      set ts_whx = " $ts_whx   and    s.Owner = t.Owner "
    endif
    set ts_whx = " $ts_whx   and    ( "
    set cnt = 0
    foreach p ( $ts )
      @ cnt = $cnt + 1
      if ( $cnt > 1 ) set ts_whx = "$ts_whx Or "
      set ts_whx = " $ts_whx s.tablespace_name like Upper('$p') "
    end
    set ts_whx = " $ts_whx ) "   
    foreach p ( $xts )
      set ts_whx = " $ts_whx and    s.tablespace_name not like Upper('$p') "
    end
  endif

#------------------------------------------------------------------------------

  if ( $#argv < 1 ) then
    set msg = "Missing object name pattern"
    goto usage
  endif

  if ( $#argv > 1 ) then
    set msg = "Expect object name pattern - found '$*'"
    goto usage
  endif

  set name = "$1"

  if ( "$name" == "" ) then
    set msg = "Invalid name specified - empty string"
    goto usage
  endif

#------------------------------------------------------------------------------


  if ( "$Src_Table" == "User_Objects" ) then
    set cols = ( ` elt-rm "$cols" owner ` )
    set xowner = ""
    set owner = "" 
  endif

# set col_sel	= ( ` elt-map -sep , "$col_args" "$col_names" "$cols" ` )

  set col_list	= ( ` elt-map "$col_args" "$col_names" "$cols" ` )

  set col_sel = "Initcap(t.$col_list[1]) $col_list[1]"
  set idx = 2 ;
  while ( $idx <= $#col_list )
    set col_sel = "$col_sel , Initcap(t.$col_list[$idx]) $col_list[$idx]"
    @ idx = $idx + 1
  end

  set order = "1" ; @ i = 2
  foreach x ( $cols[2-] )
    set order = "$order, $i"
    @ i = $i + 1
  end

#------------------------------------------------------------------------------
  
  set expr_cr = "s/t.Created/To_Char(t.Created,'DD-Mon-YYYY HH24:Mi:SS')/g"
  set expr_ld = "s/t.Last_DDL/To_Char(t.Last_DDL_Time,'DD-Mon-YYYY HH24:Mi:SS')/g"

  echo $col_sel | sed -e "$expr_cr" -e "$expr_ld" > $out

  set col_sel = "` cat $out `"

#------------------------------------------------------------------------------

  if ( $?pipe == 0 ) then
    set Set_Commands = "PageSize  999  FeedBack On"
  else
    set Set_Commands = "PageSize    0  FeedBack Off"
  endif

#------------------------------------------------------------------------------

cat <<-Sql-Done- > $sql
--
  Set  LineSize 80  Space 2  $Set_Commands
--
  Column  Owner			Format A20
  Column  Object_Name		Format A30
  Column  Subobject_Name	Format A30
  Column  Object_Id		Format A8
  Column  Data_Object_Id	Format A8
  Column  Object_Type		Format A15
  Column  Created		Format A8
  Column  Last_Ddl_Time		Format A8
  Column  Timestamp		Format A19
  Column  Status		Format A7
  Column  Temporary		Format A1
  Column  Generated		Format A1
--
  Select      $col_sel
    from      $Src_Table t $ts_tab
    where     t.Object_Name like Upper('$name')		--
              $owner $xowner				--
              $type $xtype				--
              $ostatus $xstatus				--
              $dates $ts_whx				--
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
  echo "Usage:  s-obj [options] <object-name-pattern>"
  echo ""
  echo "Options:"
  echo ""
  echo "  -c <connect>    Connection string user/password"
  echo ""
  echo "  -dba            Search all objects in the database"
  echo ""
  echo "  -all            Search all objects accessible by the user"
  echo ""
  echo "  -user           Search all objects owned by the user"
  echo ""
  echo "  -type <p>       Object type name like 'index', 'view', 'package', ..."
  echo ""
  echo "  -owner <p>      Owned by schema <p>"
  echo ""
  echo "  -ts <p>         In tablespace <p>"
  echo ""
  echo "  -created        Apply succeeding date arguments against the Object's"
  echo "                  Creation Date (DD-Mon-YYYY).         (Default)"
  echo ""
  echo "  -last           Apply succeeding date arguments against the Last"
  echo "                  DDL Date."
  echo ""
  echo "  -date           Timestamp format = '$Fmt_Date'       (Default)"
  echo "                  ( time elements may be ommitted )"
  echo ""
  echo "  -time           Timestamp format = '$Fmt_Time' - on the current date"
  echo ""
  echo "  -since <t>      Created/Last_DDL greater than <t>"
  echo ""
  echo "  -before <t>     Created/Last_DDL less than <t>"
  echo ""
  echo "  -at <t>         Created/Last_DDL equal to <t>"
  echo ""
  echo "  -xat <t>        Created/Last_DDL not equal to <t>"
  echo ""
  echo "  -on <date>      Date part of Created/Last_DDL equal to <t>"
  echo "                  ( expensive due to trunc() applied to column )"
  echo ""
  echo "  -xon <date>     Date part of Created/Last_DDL not equal to <t>"
  echo ""
  echo "  -today          Date part of Created/Last_DDL equal to current date"
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
  echo "The following command might be used to find all packages starting"
  echo "with 'dev_' that are owned by karen, jones, and johnson, but not"
  echo "john (assuming there are only 3 schema names starting with 'jo')."
  echo ""
  echo "  s-obj -owner jo% -owner karen -xowner john -type package dev_%"
  echo ""

  rm -f $out $sql

  exit -1

#------------------------------------------------------------------------------
