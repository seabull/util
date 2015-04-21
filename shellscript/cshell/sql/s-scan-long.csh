#!/bin/csh -f
#------------------------------------------------------------------------------

  if ( $#argv != 1 ) then
    set msg = "wrong number of arguments"
    goto usage
  endif

  set pattern = "$1"

  if ( "$pattern" == "" ) then
    set msg = "Invalid search pattern specified - empty string"
    goto usage
  endif

#------------------------------------------------------------------------------

set out = /usr/tmp/.scan-long.log.$$

sqlplus -s / <<-Sql-Done- | tr -d '\014' | tee $out

  Set ServerOutput On Size 30000 PageSize 0 FeedBack Off ;

 Declare

  Pattern	VarChar2(60)	:= '$name' ;

  Name		VarChar2(60) ;

  Text		Long ;

  -- -----------------------------------------------------------------------

  Cursor Csr_Tables Is
    Select    Distinct(Table_Name), Column_Name
      from    All_Tab_Columns
      where   Owner not in ( 'SYS', 'SYSTEM' )
      and     Data_Type like 'LONG%'
     Order By 1, 2
     Group By 1
    ;

  -- -----------------------------------------------------------------------

  Cursor Csr_Lines ( xTable, xColumn )
    Select    xColumn
      from    xTable
      where   xColumn is not Null
    ;
      where   ( name = Upper ( Obj_Name ) )
      and     ( type = Upper ( Obj_Type ) Or type Is Null )
      and     ( Ln_Start <= line and line <= Ln_End )
    ;

  Source        Csr_Source%RowType ;

  -- -----------------------------------------------------------------------

 Begin

  if ( Ln_Start > Ln_End ) then
    Dbms_Output.Put_Line ( 'get-src-line.sqm:  start line, ' || Ln_Start
      || ', is greater than the end line, ' || Ln_End || '.' ) ;
  End If ;

  -- Get the unique object name - exceptions handled by caller

  Open Csr_Object ( Obj_Pattern, Obj_Type ) ;

  Fetch Csr_Object into Obj_Name ;

  If ( Csr_Object%NotFound ) then
    Dbms_Output.Put_Line('* no object found matching "'||Obj_Pattern||'"') ;
    goto done ;
  End if ;

  Fetch Csr_Object into Nxt_Name ;

  If ( Not Csr_Object%NotFound ) then
    Dbms_Output.Put_Line('* more than one object matches "'||Obj_Pattern||'"') ;
    Dbms_Output.Put_Line('- '||Obj_Name) ;
    While ( Not Csr_Object%NotFound )
    Loop
      Dbms_Output.Put_Line('- '||Nxt_Name) ;
      Fetch Csr_Object into Nxt_Name ;
    End Loop ;
    Close Csr_Object ;
    goto done ;
  End if ;

  Close Csr_Object ;
      
  -- Display the source lines

  Dbms_Output.Put_Line ( Chr(9) ) ;	-- Blank line (using tab)
  Dbms_Output.Put_Line ( 'Object:  ' || Obj_Name ) ;
  Dbms_Output.Put_Line ( Chr(9) ) ;


  Open Csr_Source ;

  Fetch Csr_Source Into Source ;

  If Csr_Source%NotFound Then
    Text := '( ' || Ln_Start || ' - ' || Ln_End || ' )' ;
    Dbms_Output.Put_Line('* no sources lines in range ' || Text ) ;
    Close Csr_Source ;
    goto done ;
  End If ;

  While ( not Csr_Source%NotFound )
  Loop

    -- Must pad left using '_' because Dbms_Output strips leading spaces

    Text := LPad(To_Char(Source.Line),5,'_') || ' : ' || Source.Text ;

    -- Strip trailing newline

    if ( SubStr(Text,Length(Text),1) = Chr(10) ) Then
       Text := SubStr(Text,1,Length(Text)-1) ;
    End If ;

    Dbms_Output.Put_Line ( Text ) ;

    Fetch Csr_Source Into Source ;

  End Loop ;

  Dbms_Output.Put_Line ( Chr(9) ) ;

  -- -----------------------------------------------------------------------

<<done>>

  null ;

 End ;
/

-Sql-Done-

#------------------------------------------------------------------------------

  exit 0

#------------------------------------------------------------------------------

usage:

  echo ""
  echo "error:  $msg"
  echo ""
  echo "usage:  s-scan-longs <search-pattern>"
  echo ""

#------------------------------------------------------------------------------

  if ( "$1" == "" ) then
    echo "usage:  .scan-ctl <search-string>"
    exit -1
  endif

  awk '{printf "echo %s;grep -i '"$1"'/dev/null %s\n",$1,$1}' ctl-pos.rdx \
    | /bin/sh

  exit 0

#----------------------------------------------------------------------------

   119	17:13	echo "select table_name, column_name from all_tab_columns where data_type like 'LONG%' and  owner not in ( 'SYS', 'SYSTEM' ) ;" | sqlplus bom/bom
   120	17:14	echo "select table_name, column_name from all_tab_columns where data_type like 'LONG%' and  owner not in ( 'SYS', 'SYSTEM' ) ;" | sqlplus -s bom/bom | tr -d '\014'
   121	17:14	echo "select table_name, column_name from all_tab_columns where data_type like 'LONG%' and  owner not in ( 'SYS', 'SYSTEM' ) ;" | sqlplus -s bom/bom | tr -d '\014' | print
   122	17:15	echo "select table_name, column_name, data_type from all_tab_columns where data_type like 'LONG%' and  owner not in ( 'SYS', 'SYSTEM' ) ;" | sqlplus -s bom/bom | tr -d '\014'
   123	17:15	s-desc discoverer_all_docs
   124	17:16	s-desc -p discoverer_all_docs
   125	17:16	s-desc -p discoverer_docs
   126	17:17	echo "select count(*) from discoverer_all_docs ;" | sqlplus -s bom/bom | tr -d '\014'
   127	17:17	echo "select count(*) from discoverer_docs ;" | sqlplus -s bom/bom | tr -d '\014'
   128	17:17	h
   129	17:18	echo "select owner, table_name, column_name, data_type from all_tab_columns where data_type like 'LONG%' and  o;" | sqlplus -s bom/bom | tr -d '\014'
   130	17:18	echo "select owner, table_name, column_name, data_type from all_tab_columns where data_type like 'LONG%' ;" | sqlplus -s bom/bom | tr -d '\014'
   131	17:19	h
   132	17:20	history > .scan-long
#!/bin/csh -f
#------------------------------------------------------------------------------

  if ( $#argv != 3 ) then
    set msg = "wrong number of arguments"
    goto usage
  endif

  switch ( "$1" )
    case "-p":
      set type = "procedure"
      breaksw
    case "-f":
      set type = "function"
      breaksw
    case "-h":
      set type = "package"
      breaksw
    case "-b":
      set type = "package body"
      breaksw
    case "-t":
      set type = "trigger"
      breaksw
    default:
      set msg = "Unrecognized type flag '$1'"
      goto usage      
  endsw

  set name = "$2"

  if ( "$name" == "" ) then
    set msg = "Invalid name specified - empty string"
    goto usage
  endif

  @ line = 0 + $3

  if ( $line <= 0 ) then
    set msg = "<line>, $3, must be greater than zero"
    goto usage
  endif

#------------------------------------------------------------------------------

  @ space = 5 ; @ start = $line - $space ; @ end = $line + 5

#------------------------------------------------------------------------------

#  if ( $start < 0 ) @ start = 1
#
#  set nam = get-src-line
#  set sqm = $HOME/scripts/sql/$nam.sqm
#  set sql = /usr/tmp/.$nam.sql
#
#  sed -e "s/<Name>/$name/g" -e "s/<Type>/$type/g" -e "s/<Ln_Start>/$start/g" \
#    -e "s/<Ln_End>/$end/g" < $sqm > $sql
#
#  if ( $status != 0 ) then
#    set msg = "sed failed"
#    goto usage
#  endif
#
#  echo quit | sqlplus -s / @$sql | tr -d '\014'

  exit 0

#------------------------------------------------------------------------------

usage:

  echo ""
  echo "error:  $msg"
  echo ""
  echo "usage:  s-near <object-type-flag> <object-name> <line-number>"
  echo ""
  echo "Object type flags:"
  echo ""
  echo "  -ps, -h	PL/SQL Package Specification (header)"
  echo ""
  echo "  -pb, -b	PL/SQL Package Body"
  echo ""
  echo "  -p		PL/SQL Stored Procedure"
  echo ""
  echo "  -f		PL/SQL Stored Function"
  echo ""
  echo "  -t		PL/SQL Database Trigger"
  echo ""

  exit -1

#------------------------------------------------------------------------------
