#!/bin/csh -f
#------------------------------------------------------------------------------

  if ( $?CXAPPS == 0 ) then
    set connect = "/"
  else
    set connect = "$CXAPPS"
  endif

#------------------------------------------------------------------------------

  while ( "$1" =~ -* )
    switch ( "$1" )
    #
    # Options
    #
      case "-c":			# Set connection string
        if ( "$2" == "" ) then
          set msg = "option '$1' missing argument"
          goto usage
        endif
        set connect = "$2" ; shift
        breaksw
    #
    # Source type flags
    #
      case "-proc":
      case "-sp":
      case "-p":
        if ( $?type != 0 ) goto extra_type
        set type = "procedure"
        breaksw
      case "-fun":
      case "-fcn":
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

  if ( $#argv > 1 ) then
    set msg = "Too many arguments - expected single object name, found '$*'"
    goto usage
  endif

  set name = "$1"

  if ( "$name" == "" ) then
    set msg = "Invalid name specified - empty string"
    goto usage
  endif

#------------------------------------------------------------------------------

# fold to uppercase

  set name = "` echo $name | tr 'a-z' 'A-Z' `"
  set type = "` echo $type | tr 'a-z' 'A-Z' `"

#------------------------------------------------------------------------------

# cat <<-Sql-Done-

sqlplus -s $connect <<-Sql-Done- | tr -d '\014'
--
  Set ServerOutput On Size 100000 FeedBack Off LineSize 300 ;
--
  Declare
  --
    Cursor Csr_Object ( Obj_Name VarChar2, Obj_Type VarChar2 ) Is
      Select   Distinct(us.Name)
        from   All_Source us
        where  us.Name like Obj_Name and us.Type = Obj_Type
--      where  us.Name like Obj_Name
        order by 1
    ;
  --
    Obj_Name	VarChar2(30) ;
  --
    Cursor Csr_Source ( Obj_Name VarChar2, Obj_Type VarChar2 ) Is
      Select   us.Line, us.Text
        from   All_Source us
        where  us.Name = Obj_Name and us.Type = Obj_Type
--      where  us.Name = Obj_Name
        order by 1
    ;
  --
    Source	Csr_Source%RowType ;
  --
--
  Begin

    Open Csr_Object ( '$name', '$type' ) ;
 
    Fetch Csr_Object into Obj_Name ;

    If ( Csr_Object%NotFound ) then
      Dbms_Output.Put_Line('* no objects found matching "$name"') ;
      goto done ;
    End If ;

    Dbms_Output.Put_Line('--') ;

    While ( Not Csr_Object%NotFound )
    Loop

      Open Csr_Source ( Obj_Name, '$type' ) ;

      Fetch Csr_Source into Source ;

      If ( Csr_Source%NotFound ) then
        Dbms_Output.Put_Line('* no source lines found matching "'||Obj_Name||'"') ;
        goto done ;
      End If ;

      While ( Not Csr_Source%NotFound )
      Loop
        If ( substr(Source.Text,length(Source.Text),1) = chr(10) ) then
          Source.Text := rtrim(substr(Source.Text,1,length(Source.Text)-1)) ;
        End If ;
        Dbms_Output.Put('.'||lpad(Source.Line,5,' ')||'  ') ;
        Dbms_Output.Put_Line(rtrim(Source.Text)) ;
        Fetch Csr_Source into Source ;
      End Loop ;

      Close Csr_Source ;

      Dbms_Output.Put_Line('--') ;

      Fetch Csr_Object into Obj_Name ;

    End Loop ;

  <<done>>

    Close Csr_Object ;

  End ;
/
--
-Sql-Done-

exit 0

#------------------------------------------------------------------------------

extra_type:

  set msg = "Extra source type flag '$1' - type already set to '$type'"

usage:

  echo ""
  echo "Error:  $msg"
  echo ""
  echo "Usage:  s-list [options] <object-type-flag> <object-name>"
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
  echo "                  (or taken from 'CXAPPS' if defined)"
  echo ""

  exit -1

#------------------------------------------------------------------------------
