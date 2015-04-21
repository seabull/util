#!/bin/csh -f
#------------------------------------------------------------------------------

  set Src_Table		= "Dba_Triggers"
  set OwnerColumn 	= "v.Owner, "
  set OwnerOrder	= ", 2"

  alias list ' cat '

  set out = /usr/tmp/.s-triggers.tmp.$$

  cat /dev/null > $out

#------------------------------------------------------------------------------

# Sure I'm using some labels and goto's for overall processing but it works
# pretty well and is clear enough to read.  Perl would be a better choice but
# I can't depend upon perl being available on my client's machines.

start_option:

  while ( "$1" =~ -* )
    switch ( "$1" )
      case "-pipe":
        set pipe = 1
        breaksw
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
        set Src_Table		= "All_Triggers"
        set OwnerColumn 	= "v.Owner, "
        set OwnerOrder		= ", 2"
        breaksw
      case "-dba":
        set Src_Table		= "Dba_Triggers"
        set OwnerColumn 	= "v.Owner, "
        set OwnerOrder		= ", 2"
        breaksw
      case "-user":
         set Src_Table		= "User_Triggers"
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

start_name:

  if ( $#argv <= 0 ) then
    set msg = "Missing trigger name pattern - expected at least one after options"
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

# Either locate the names or list the sql source for the matching trigger names

  if ( $?list != 0 ) goto list_source

#------------------------------------------------------------------------------

  if ( $?pipe == 0 ) then
    set Set_Commands = "PageSize  999  FeedBack On"
  else
    set Set_Commands = "PageSize    0  FeedBack Off"
  endif

#------------------------------------------------------------------------------

sqlplus -s $connect <<-Sql-Done- | tr -d '\014' | tee $out | list
--
  Set  LineSize 80  Space 2  $Set_Commands
--
  Column      Owner		Format A30
  Column      Trigger_Name	Format A30
--
  Select      $OwnerColumn v.Trigger_Name
    from      $Src_Table v
    where     v.Trigger_Name like Upper('$Name')  $Owner_Clause
    Order by  1 $OwnerOrder
  ;
--
-Sql-Done-

  goto done

#------------------------------------------------------------------------------

list_source:

sqlplus -s $connect <<-Sql-Done- | tr -d '\014' | tee $out | list
--
  Set ServerOutput On Size 100000 FeedBack Off PageSize 0 ;
--
  Create or Replace Package List_Trigger_Source As
    Procedure Run ;
  End List_Trigger_Source ;
/
--  Show Errors ;
--
  Create or Replace Procedure px ( s VarChar2 ) Is
  Begin
    Dbms_Output.Put ( s ) ;
  End px ;
/
--  Show Errors ;
--
  Create or Replace Procedure pl ( s VarChar2 ) Is
  Begin
    Dbms_Output.Put_Line ( s ) ;
  End pl ;
/
--  Show Errors ;
--
  Create or Replace Package Body List_Trigger_Source As

    Procedure Run Is

      Cursor Csr Is
        Select      $OwnerColumn v.Trigger_Name Name, v.Trigger_Body
          from      $Src_Table v
          where     v.Trigger_Name like Upper('$Name')  $Owner_Clause
          Order by  1, 2
        ;

      Text	VarChar2(32767) ;	-- Trigger text
      Line	VarChar2(32767) ;	-- Current line
      Seg	VarChar2(32767) ;	-- Current line segment

      Num	Integer ;		-- Number of Triggers found
      cnt	Integer ;		-- Position with a line
      eol	Integer ;		-- End Of Line
      lsize	Integer := 78 ;		-- Line size

    Begin

      Num := 0 ;

      For Rec in Csr
      Loop
        pl('Trigger:  '||InitCap(Rec.Owner)||'.'||InitCap(Rec.Name)) ;
        pl('--'||Chr(10)) ;
        Text := Rec.Trigger_Body ;
        While ( Length(Text) > 0 ) Loop
          eol := Instr(Text,Chr(10)) ;
	  if ( eol is null or eol = 0 ) then
	    pl ( '. ' || Text ) ;
            exit ;
          end if ;
          Line := Substr(Text,1,eol-1) ;
	  While ( Length(Line) > lsize ) Loop
            seg := Substr(Line,1,lsize) ;
            pl ( '. ' || seg ) ;
	    Line := Substr(Line,lsize+1) ;
          End Loop ;
          pl ( '. ' || Line ) ;
          Text := Substr(Text,eol+1) ;
        End Loop ;
        Num := Num + 1 ;
        pl('--'||Chr(10)) ;
      End Loop ;

      If ( Num <= 0 ) then
        pl('* No Triggers found matching "$Name"') ;
      End If ;

    End Run ;

  End List_Trigger_Source ;
/
--
  Show Errors ;
--
  Set ServerOutput On Size 10000 ;
--
  prompt
  Exec List_Trigger_Source.Run ;
--
--  Drop package List_Trigger_Source ;
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
  echo "Usage:  s-trigger [options] <name-pattern> [ [options] <name-pattern> ... ]"
  echo ""
  echo "Options:"
  echo ""
  echo "  -c <connect>    Connection string user/password"
  echo ""
  echo "  -list           List Trigger SQL source"
  echo ""
  echo "  -dba            Search all Triggers in the database"
  echo ""
  echo "  -all            Search all Triggers accessible by the user"
  echo ""
  echo "  -user           Search all Triggers owned by the user"
  echo ""
  echo "  -p              Print table names listing"
  echo ""
  echo "  -s              Run silently, useful just to print listing"
  echo ""

  rm -f $out

  exit -1

#------------------------------------------------------------------------------
