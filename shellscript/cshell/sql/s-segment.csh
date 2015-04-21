#!/bin/csh -f
#------------------------------------------------------------------------------

  set out = /usr/tmp/.s-obj.$$.tmp
  set sql = /usr/tmp/.s-obj.$$.sql

  alias list	' cat '
  alias action	' cat '

#------------------------------------------------------------------------------

  set col_names  = ( owner name partname type ts hf hb bytes blocks extents )
  set col_names  = ( $col_names initial next min max pcti fl flg rfno bp )

  set col_args   = ( Owner Segment_Name Partition_Name Segment_Type Tablespace_Name )
  set col_args   = ( $col_args Header_File Header_Block Bytes Blocks Extents )
  set col_args   = ( $col_args Initial_Extent Next_Extent Min_Extents  )
  set col_args   = ( $col_args Max_Extents Pct_Increase Freelists )
  set col_args   = ( $col_args Freelist_Groups Relative_Fno Buffer_Pool )

  set col_types  = ( s s s s s n n n n n n n n n n n n n s )

  set def_cols   = ( owner name type blocks )
  set cols       = ( $def_cols )

#------------------------------------------------------------------------------

  set Src_Table		= "User_Segments"

  set xname		= ""
  set xowner		= ""
  set xtype		= ""
  set xts		= ""
  set xcoleq		= ""

  unset name
  unset owner
  unset type
  unset ts
  unset coleq

  unset print
  unset pipe
  unset show_sql

#------------------------------------------------------------------------------

  while ( "$1" =~ -* )
    switch ( "$1" )
      case "-all":
        set msg = "'-all' - there is no such table as 'All_Segments' - use default of '-user'"
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
      case "=col":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing <c> argument - column name abreviation"
          goto usage
        endif
        if ( "$3" == "" ) then
          set msg = "Option '$1' missing <p> argument - column name pattern"
          goto usage
        endif
	set col = "` echo $2 | tr 'A-Z' 'a-z' `"
        set check = "` args $col_names | grep $col `"
	if ( "$check" == "" ) then
          set msg = "Option '$1' - column '$2' not in display list"
          goto usage
        endif
        set col_name = ( `elt-map -skip "$col_args" "$col_names" "$col" ` )
        if ( $#col_name != 1 ) then
          set msg = "Option '$1' - internal error - could not map '$col' to column name."
          goto usage
        endif
	set expr = " t.$col_name like Upper('$3') "
	if ( $?coleq == 0 ) then
          set coleq = " $expr "
        else
          set coleq = " $coleq or $expr "
        endif
        shift
        breaksw
      case "=xcol":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing <c> argument - column name abreviation"
          goto usage
        endif
        if ( "$3" == "" ) then
          set msg = "Option '$1' missing <p> argument - column name pattern"
          goto usage
        endif
	set col = "` echo $2 | tr 'A-Z' 'a-z' `"
        set check = "` args $col_names | grep $col `"
	if ( "$check" == "" ) then
          set msg = "Option '$1' - column '$2' not in display list"
          goto usage
        endif
        set col_name = ( `elt-map -skip "$col_args" "$col_names" "$col" ` )
        if ( $#col_name != 1 ) then
          set msg = "Option '$1' - internal error - could not map '$col' to column name."
          goto usage
        endif
        set xcoleq = " $xcoleq and t.$col_name Not like Upper('$3') "
        shift
        breaksw
      case "-dba":
        set Src_Table = "sys.Dba_Segments"
        breaksw
      case "-name":
        if ( "$2" == "" ) then
          set msg = "Option '$1' missing argument"
          goto usage
        endif
	set expr = " t.Segment_Name like Upper('$2') "
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
        set xname = " $xname and t.Segment_Name Not like Upper('$2') "
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
      case "-s":
        alias list ' cat > /dev/null '
        breaksw       
      case "-sql":
        set show_sql = 1
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
        set expr = " Segment_Type like Upper('$2') "
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
        set xtype = "$xtype and t.Segment_Type not like Upper('$2') "
        shift
        breaksw
      case "-unused":
         set show_unused = 1
         breaksw
      case "-used":
         set show_used = 1
         breaksw
      case "-user":
         set Src_Table = "User_Segments"
         breaksw
      case "-user":
         set Src_Table = "User_Segments"
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

  if ( $?coleq == 1 ) then
    set coleq = " and ( $coleq ) "
  else
    set coleq = ""
  endif

  if ( $?ts == 0 ) then
    set ts_tab = " "
    set ts_whx = " "
  else
    set ts_tab = " , dba_segments s "
    set ts_whx = "and s.segment_name = t.Segment_Name "
    set ts_whx = " $ts_whx   and    s.segment_type = t.Segment_Type "
    set ts_whx = " $ts_whx   and    s.segment_type = t.Segment_Type "
    if ( $Src_Table != "User_Segments" ) then
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
    set msg = "Missing segment name pattern"
    goto usage
  endif

  if ( $#argv > 1 ) then
    set msg = "Expect segment name pattern - found '$*'"
    goto usage
  endif

  set pattern = "$1"

  if ( "$pattern" == "" ) then
    set msg = "Invalid name specified - empty string"
    goto usage
  endif

#------------------------------------------------------------------------------

  if ( $?drop != 0 ) then
    if ( $?drop_force == 1 ) then
      set action = "show"
    else
      set action = "run"
    endif
    alias action "s-obj-drop-action -brief $cascade -c $connect $action"
    set cols = ( $def_cols )
    set pipe = 1
  endif

#------------------------------------------------------------------------------

  if ( "$Src_Table" == "User_Segments" ) then
    set cols = ( ` elt-rm "$cols" owner ` )
    set xowner = ""
    set owner = "" 
  endif

# set col_sel	= ( ` elt-map -sep , "$col_args" "$col_names" "$cols" ` )

  set col_list	= ( ` elt-map "$col_args" "$col_names" "$cols" ` )

  set idx = 1 ; set col_sel = ""
  while ( $idx <= $#col_list )
    if ( "` elt-map '$col_types' '$col_args' $col_list[$idx] `" == "s" ) then
      set col_sel = "$col_sel , Rtrim(Initcap(t.$col_list[$idx])) $col_list[$idx]"
    else
      set col_sel = "$col_sel , t.$col_list[$idx]"
    endif
    @ idx = $idx + 1
  end

  set col_sel = "` echo '$col_sel' | sed -e 's/^[ ]*,[ ]*//' `"

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

#  set view = 'v$parameter'
#
#  if ( $?show_alloc != 0 || $?show_used != 0 || $?show_unused != 0 ) then
#    set dbs = ", ( Select value as DB_Block_Size, (1024*1024) as MB "
#    set dbs = "$dbs  from $view Where   name = 'db_block_size' "
#    set dbs = "$dbs  where   name = 'db_block_size' ) "
#  endif

#------------------------------------------------------------------------------

cat <<-Sql-Done- > $sql
--
  Set  LineSize 130  Space 2  $Set_Commands
--
--set feedback off
--
  Create or Replace function Seg_Space_Total ( o Varchar2, n VarChar2, t Varchar2 )
    Return 	Number
   as
    t_blocks	Number ;
    t_bytes	Number ;
    u_blocks	Number ;
    u_bytes	Number ;
    fileid	Number ;
    blockid	Number ;
    block	Number ;
  begin
    dbms_space.unused_space ( o, n, t, t_blocks, t_bytes, u_blocks, u_bytes, fileid, blockid, block ) ;
    return t_bytes ;
  end ;
/
  show errors
--
  Create or Replace function Seg_Space_Used ( o Varchar2, n VarChar2, t Varchar2 )
    Return 	Number
   as
    t_blocks	Number ;
    t_bytes	Number ;
    u_blocks	Number ;
    u_bytes	Number ;
    fileid	Number ;
    blockid	Number ;
    block	Number ;
  begin
    dbms_space.unused_space ( o, n, t, t_blocks, t_bytes, u_blocks, u_bytes, fileid, blockid, block ) ;
    return t_bytes - u_bytes ;
  end ;
/
  show errors
--
  Create or Replace function Seg_Space_Unused ( o Varchar2, n VarChar2, t Varchar2 )
    Return 	Number
   as
    t_blocks	Number ;
    t_bytes	Number ;
    u_blocks	Number ;
    u_bytes	Number ;
    fileid	Number ;
    blockid	Number ;
    block	Number ;
  begin
    dbms_space.unused_space ( o, n, t, t_blocks, t_bytes, u_blocks, u_bytes, fileid, blockid, block ) ;
    return u_bytes ;
  end ;
/
  show errors
--
  Column  Owner			Format A20		Heading "Owner"
  Column  Segment_Name		Format A30		Heading "Segment"
  Column  Segment_Type		Format A10		Heading "Type"
  Column  Partition_Name	Format A30		Heading "Partition"
  Column  Tablespace_Name	Format A30		Heading "Tablespace"
  Column  Header_File		Format 99999		Heading "Header File"
  Column  Header_Block		Format 99999		Heading "Header Block"
  Column  Bytes			Format 999,999,999,999	Heading "Bytes"
  Column  Blocks		Format 999,999,999	Heading "Blocks"
  Column  Extents		Format 999,999		Heading "Extents"
  Column  Initial_Extent	Format 999,999,999	Heading "Initial"
  Column  Next_Extent		Format 999,999,999	Heading "Next"
  Column  Min_Extents		Format 999,999,999	Heading "Min Extents"
  Column  Max_Extents		Format 999,999,999	Heading "Max Extents"
  Column  Pct_Increase		Format 999		Heading "Pct Increase"
  Column  Freelists		Format 999		Heading "Freelists"
  Column  Freelist_Groups	Format 999		Heading "Freelist Groups"
  Column  Relative_Fno		Format 999		Heading "Relative Fno"
  Column  Buffer_Pool		Format A7		Heading "Buffer"
--
  Column  Allocated		Format 999,999,999	Heading "Allocated"
  Column  Unused		Format 999,999,999	Heading "Unused"
  Column  Used			Format 999,999,999	Heading "Used"
--
  Select      $col_sel
    ,         Seg_Space_Used(t.Owner,t.Segment_Name,t.Segment_Type) Used
    ,         Seg_Space_Unused(t.Owner,t.Segment_Name,t.Segment_Type) Unused
    from      $Src_Table t $ts_tab
    where     t.Segment_Name like Upper('$pattern')	--
              $name $xname				--
              $owner $xowner				--
              $type $xtype				--
              $coleq $xcoleq				--
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
    sqlplus -s $connect @$sql < /dev/null | tr -d '\014' | autotrace-flatten | tee $out | action | list
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
  echo "Usage:  s-obj [options] <segment-name-pattern>"
  echo ""
  echo "Options:"
  echo ""
  echo "X -all            Search all segments accessible by the user."
  echo "                  *** not available for segments ***"
  echo ""
  echo "  -alloc          Show allocated space."
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
  echo "  =col <c> <p>    Include rows which column <c> matching pattern <p>."
  echo ""
  echo "    =xcol <c> <p> Exclude rows which column <c> matching pattern <p>."
  echo ""
  echo "  -dba            Search all segments in the database"
  echo ""
  echo "  -name <p>       Include name matching <p> (really the same as the required patern argument)."
  echo ""
  echo "    -xname <p>    Exclude names not matching <p>, values and'd together."
  echo ""
  echo "  -owner <p>      Owned by schema <p>"
  echo ""
  echo "  -p              Print listing"
  echo ""
  echo "  -pipe           Output piped - no headings or feedback"
  echo ""
  echo "  -s              Run silently, useful just to print listing"
  echo ""
  echo "  -sql            Show generated SQL - do not run."
  echo ""
  echo "  -ts <p>         In tablespace <p>"
  echo ""
  echo "  -type <p>       Segment type name like 'index', 'view', 'package', ..."
  echo ""
  echo "  -unused         Show unused space."
  echo ""
  echo "  -used           Show used space."
  echo ""
  echo "  -user           Search all segments owned by the user"
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
