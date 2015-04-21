#!/bin/csh -f
#------------------------------------------------------------------------------

  set out = /usr/tmp/.s-obj.$$.tmp
  set sql = /usr/tmp/.s-obj.$$.sql

  alias list	' cat '
  alias action	' cat '

#------------------------------------------------------------------------------

  set col_names		= ( owner name subname obj-id data-obj-id type )
  set col_names		= ( $col_names ts status temp gen created last )

  set col_args		= ( Owner Object_Name SubObject_Name Object_Id )
  set col_args		= ( $col_args Data_Object_Id Object_Type TimeStamp )
  set col_args		= ( $col_args Status Temporary Generated )
  set col_args		= ( $col_args Created Last_DDL_Time )

  set def_cols		= ( owner name type )
  set cols		= ( $def_cols )

  set grant_users	= ( )
  set grant_rights	= ( )

  set revoke_users	= ( )
  set revoke_rights	= ( )

#------------------------------------------------------------------------------

  set Fmt_Time		= "HH24:Mi:SS"
  set Fmt_Date		= "DD-Mon-YYYY"
  set Fmt_TS		= "$Fmt_Date $Fmt_Time"
  set Today		= "` date +%d-%h-%Y `"
  set Date_Prefix	= ""

  set Src_Table		= "All_Objects"
  set Date_Column	= "t.Created"
  set Date_Format	= "$Fmt_TS"

  set xname		= ""
  set xowner		= ""
  set xstatus		= ""
  set xts		= ""

  set xtype		= ( )

  set dates		= ""

  unset name
  unset owner
  unset type
  unset status
  unset ts

  unset print
  unset pipe
  unset show_sql
  unset at_time
  unset on_date
  unset drop
  unset drop_force

  set cascade = ""

#------------------------------------------------------------------------------

  while ( "$1" =~ -* )
    switch ( "$1" )
      case "-all":
        set Src_Table = "All_Objects"
        breaksw
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
      case "-cascade":
        set cascade = "$1"
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
      case "-created":
        set Date_Column = "t.Creation"
        breaksw
      case "-date":
        set Date_Prefix = ""
        breaksw
      case "-dba":
        set Src_Table = "Dba_Objects"
        breaksw
      case "-drop":
        set drop = 1
        if ( "$2" == "force" ) then
          set drop_force = 1
          shift
        endif
        breaksw
      case "-grant":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing user argument (<u>)."
          goto usage
        endif
        if ( "$3" == "" ) then
          set msg = "Option '$1' missing access argument (<a>)."
          goto usage
        endif
        set grant_users  = ( $grant_users   "$2" )
        set grant_rights = ( $grant_rights  "$3" )
        shift ; shift
        breaksw
      case "-last":
        set Date_Column = "t.Last_DDL_Date"
        breaksw
      case "-name":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
	set expr = " t.Object_Name like Upper('$2') "
	if ( $?name == 0 ) then
          set name = " $expr "
        else
          set name = " $name or $expr "
        endif
        shift
        breaksw
      case "-xname":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        set xname = " $xname and t.Object_Name Not like Upper('$2') "
        shift
        breaksw
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
      case "-p":
        set print = 1
        breaksw
      case "-pipe":
        set pipe = 1
        breaksw
      case "-revoke":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing user argument (<u>)."
          goto usage
        endif
        if ( "$3" == "" ) then
          set msg = "Option '$1' missing access argument (<a>)."
          goto usage
        endif
        set revoke_users  = ( $revoke_users   "$2" )
        set revoke_rights = ( $revoke_rights  "$3" )
        shift ; shift
        breaksw
      case "-s":
        alias list ' cat > /dev/null '
        breaksw       
      case "-sql":
        set show_sql = 1
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
        set xts = ( $xts "$2" )
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
        set xtype = ( $xtype "$2" )
        shift
        breaksw
      case "-user":
         set Src_Table = "User_Objects"
         breaksw
      case "-time":
        set Date_Prefix = "$Today "
        breaksw
      #----------------------------------------------------------------------
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
      case "-xat":
        set op = "<>"
        goto date_arg
      case "-since":
        set op = "<"
        goto date_arg
      case "-before":
        set op = ">"
        goto date_arg
      date_arg:
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        set dates = " $dates and To_Date('$Date_Prefix$2','$Fmt_TS') $op $Date_Column "
        shift
        breaksw
      #----------------------------------------------------------------------
      case "-on":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
        set arg = "$2" ; shift
        goto object_on_date
      case "-xon":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
	set dates = " $dates And To_Date('$2','$Fmt_Date') <> Trunc($Date_Column) "
        shift
        breaksw
      case "-today":
        set arg = "$Today"
        goto object_on_date
      object_on_date:
        set expr = " To_Date('$arg','$Fmt_Date') = Trunc($Date_Column) "
        if ( $?on_date == 1 ) then
          set on_date = " $on_date Or $expr "
        else
          set on_date = " $expr "
        endif
        breaksw
      #----------------------------------------------------------------------
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

  if ( $?name == 0 ) then
    set name = ""
  else
    set name = " and ( $name ) "
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

  set pattern = "$1"

  if ( "$pattern" == "" ) then
    set msg = "Invalid name specified - empty string"
    goto usage
  endif

#------------------------------------------------------------------------------

  if ( $?drop != 0 ) then
    if ( $#grant_users > 0 || $#revoke_users > 0 ) then
      set msg = "-grant and -revoke are not compatible with '-drop'"
      goto usage
    endif
    if ( $?drop_force == 1 ) then
      set action = "run"
    else
      set action = "show"
    endif
    alias action "s-obj-drop-action -brief $cascade -c $connect $action" 
    set cols = ( $def_cols )
    set pipe = 1
  else
    if ( $#grant_users > 0 || $#revoke_users > 0 ) then
      set grants   = "-grant  $grant_users  : $grant_rights"
      set revokes  = "-revoke $revoke_users : $revoke_rights"
      alias action "s-obj-access-action -brief -c $connect $grants $revokes"
      set cols = ( $def_cols )
      set pipe = 1
      set xtype = ( $xtype index synonym sequence trigger )
    endif
  endif

#------------------------------------------------------------------------------

  set text = ""

  foreach xt ( $xtype )
    set text = "$text and t.Object_Type not like Upper('$xt') "
  end
  set xtype = "$text"

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
    where     t.Object_Name like Upper('$pattern')	--
              $name $xname				--
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
    sqlplus -s $connect @$sql < /dev/null | tr -d '\014' | tee $out | action | list
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
  echo "  -all            Search all objects accessible by the user"
  echo ""
  echo "  -at <t>         Created/Last_DDL equal to <t>"
  echo ""
  echo "    -xat <t>      Created/Last_DDL not equal to <t>"
  echo ""
  echo "  -before <t>     Created/Last_DDL less than <t>"
  echo ""
  echo "  -c <connect>    Connection string user/password"
  echo ""
  echo "  -col <c>        Add column to the display list."
  echo "                  ( $col_names )"
  echo ""
  echo "    -xcol <c>     Remove column <c> from the display list."
  echo ""
  echo "  -created        Apply succeeding date arguments against the Object's"
  echo "                  Creation Date (DD-Mon-YYYY).         (Default)"
  echo ""
  echo "  -date           Timestamp format = '$Fmt_Date'       (Default)"
  echo "                  ( time elements may be ommitted )"
  echo ""
  echo "  -dba            Search all objects in the database"
  echo ""
  echo '  -drop [force]   \!\!\! Drop the matching objects \!\!\!  Be very careful with this.'
  echo "                  Without 'force' this only shows the drop commands."
  echo ""
  echo "    -cascade      Use 'cascade constraints' option when dropping tables."
  echo ""
  echo "  -grant <u> <r>  Grant user <u> rights <r> to all matching objects"
  echo ""
  echo "  -last           Apply succeeding date arguments against the Last"
  echo "                  DDL Date."
  echo ""
  echo "  -name <p>       Include name matching <p> (really the same as the required patern argument)."
  echo ""
  echo "    -xname <p>    Exclude names not matching <p>, values and'd together."
  echo ""
  echo "  -on <date>      Date part of Created/Last_DDL equal to <t>"
  echo "                  ( expensive due to trunc() applied to column )"
  echo ""
  echo "    -xon <date>   Date part of Created/Last_DDL not equal to <t>"
  echo ""
  echo "  -owner <p>      Owned by schema <p>"
  echo ""
  echo "  -p              Print listing"
  echo ""
  echo "  -pipe           Output piped - no headings or feedback"
  echo ""
  echo "  -revoke <u> <r> Revoke user <u>'s right <r> to all matching objects"
  echo ""
  echo "  -s              Run silently, useful just to print listing"
  echo ""
  echo "  -since <t>      Created/Last_DDL greater than <t>"
  echo ""
  echo "  -sql            Show generated SQL - do not run."
  echo ""
  echo "  -status         ?"
  echo ""
  echo "    -xstatus      ?"
  echo ""
  echo "  -time           Timestamp format = '$Fmt_Time' - on the current date"
  echo ""
  echo "  -today          Date part of Created/Last_DDL equal to current date"
  echo ""
  echo "  -ts <p>         In tablespace <p>"
  echo ""
  echo "  -type <p>       Object type name like 'index', 'view', 'package', ..."
  echo ""
  echo "  -user           Search all objects owned by the user"
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
