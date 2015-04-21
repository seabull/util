#!/bin/csh -f
#------------------------------------------------------------------------------

  set context = 5			# Number of lines of context to print

  if ( $?CXAPPS == 0 ) then
    set connect = "/"
  else
    set connect = "$CXAPPS"
  endif

#------------------------------------------------------------------------------

  while ( "$1" =~ -* )
    #
    # Lines of context may be set using -<number> or -n <number>
    #
    set check = "` echo ' $1' | sed -e 's/^ -//' | tr -d '0-9'`"
    if ( "$1" != "-" && "$check" == "" ) then
      set context = "` echo $1 | sed -e 's/.//' `"
      shift
      continue
    endif
    #
    switch ( "$1" )			# Process options & source type flags
    # Options
      case "-c":			# Set connection string
        if ( "$2" == "" ) then
          set msg = "option '$1' missing argument"
          goto usage
        endif
        set connect = "$2" ; shift
        breaksw
      case "-n":			# Set the number lines of context
        if ( "$2" == "" ) then
          set msg = "option '$1' missing argument"
          goto usage
        endif
        set check = "` echo $2 | tr -d '0-9' `"
        if ( "$check" != "" ) then
          set msg = "option '$1', argument '$2' - contains non-digits"
          goto usage
        endif
        set context = "$2" ; shift
        breaksw
    #
    # Source type flags - exactly one must be specified
    #
      case "-procedure":
      case "-proc":
      case "-sp":
      case "-p":
        if ( $?type != 0 ) goto extra_type
        set type = "procedure"
        breaksw
      case "-function":
      case "-fun":
      case "-fcn":
      case "-sf":
      case "-f":
        if ( $?type != 0 ) goto extra_type
        set type = "function"
        breaksw
      case "-pkh":
      case "-h":
        if ( $?type != 0 ) goto extra_type
        set type = "package"
        breaksw
      case "-pkb":
      case "-b":
        if ( $?type != 0 ) goto extra_type
        set type = "package body"
        breaksw
      case "-trig":
      case "-t":
        if ( $?type != 0 ) goto extra_type
        set type = "trigger"
        breaksw
    #
      default:
        set msg = "unrecognized option '$1'"
        goto usage
    endsw
    shift
  end

  if ( $?type == 0 ) then
    set msg = "Please specify the object type"
    goto usage
  endif

#------------------------------------------------------------------------------

  if ( $#argv < 1 ) then
    set msg = "Missing object name argument"
    goto usage
  endif

  if ( $#argv > 2 ) then
    set msg = "Too many arguments - expected object name, found '$*'"
    goto usage
  endif

#------------------------------------------------------------------------------

  set name = "` echo $1 | tr '-' '_' `"

  if ( "$name" == "" ) then
    set msg = "Invalid name specified - empty string"
    goto usage
  endif

#------------------------------------------------------------------------------

  set line = "$2" ; set check = "` echo $line | tr -d '0-9' `"

  if ( "$check" != "" ) then
    set msg = "<line> = '$line' - argument may only contain digits"
    goto usage
  endif

  if ( $line <= 0 ) then
    set msg = "<line> = '$line' - argument must be greater than zero"
    goto usage
  endif

#------------------------------------------------------------------------------

  @ start = $line - $context ; @ end = $line + $context

#------------------------------------------------------------------------------

sqlplus -s $connect <<-Sql-Done- | tr -d '\014'

  Set ServerOutput On Size 30000 PageSize 0 FeedBack Off ;

 Declare

  Obj_Pattern	VarChar2(60)	:= Upper ( '$name' ) ;
  Obj_Type	VarChar2(60)	:= Upper ( '$type' ) ;
  Obj_Name      VarChar2(60) ;
  Nxt_Name      VarChar2(60) ;

  Ln_Start	Number		:= $start ;
  Ln_End	Number		:= $end ;
  Ln_Cur	Number ;

  Text		VarChar2(500) ;

  -- -----------------------------------------------------------------------

  Cursor Csr_Object ( xObj_Pattern VarChar2, xObj_Type VarChar2 ) Is
    Select    Distinct(Name)
      from    User_Source
      where   Name like Upper ( xObj_Pattern )
      and     Type = Upper ( xObj_Type )
    ;

  -- -----------------------------------------------------------------------

  Cursor Csr_Source Is
    Select    us.Line, us.Text
      from    User_Source us
      where   ( us.name = Upper ( Obj_Name ) )
      and     ( us.type = Upper ( Obj_Type ) Or us.type Is Null )
      and     ( Ln_Start <= us.line and us.line <= Ln_End )
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
    Dbms_Output.Put_Line('* no object found matching "'||Obj_Pattern||'"  '||Obj_Type) ;
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

    Text := '.'||LPad(To_Char(Source.Line),5,' ') || '  ' || Source.Text ;

    -- Strip trailing newline

    if ( SubStr(Text,Length(Text),1) = Chr(10) ) Then
       Text := SubStr(Text,1,Length(Text)-1) ;
    End If ;

    Dbms_Output.Put_Line ( Text ) ;

    Fetch Csr_Source Into Source ;

  End Loop ;

  Dbms_Output.Put_Line ( Chr(9) ) ;

  Close Csr_Source ;

  -- -----------------------------------------------------------------------

<<done>>

  null ;

 End ;
/

-Sql-Done-

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

extra_type:

  set msg = "Extra source type flag '$1' - type already set to '$type'"

usage:

  echo ""
  echo "Error:  $msg"
  echo ""
  echo "Usage:  s-near [options] <object-type-flag> <object-name-pattern> <line-number>"
  echo ""
  echo "Object type flags:"
  echo ""
  echo "  -pkh, -ps, -h   PL/SQL Package Specification"
  echo ""
  echo "  -pkb, -pb, -b   PL/SQL Package Body"
  echo ""
  echo "  -sp, -p         PL/SQL Stored Procedure"
  echo ""
  echo "  -sf, -f         PL/SQL Stored Function"
  echo ""
  echo "  -trig, -t       PL/SQL Database Trigger"
  echo ""
  echo "Options:"
  echo ""
  echo "  -c <string>     Oracle connection string, default /."
  echo "                  ( or taken from 'CXAPPS' if defined )"
  echo ""
  echo "  -n <lines>      Set the number of lines of context to display."
  echo "  -<lines>        ( default is 5 before & after: -n 5 or -5 )"
  echo ""

  exit -1

#------------------------------------------------------------------------------
