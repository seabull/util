#!/bin/csh -f
#------------------------------------------------------------------------------

  set out = /usr/tmp/.ar-loc.$$.tmp
  set sql = /usr/tmp/.ar-loc.$$.sql

  alias list ' cat '

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

  if ( $#argv != 0 ) then
    set msg = "Too many arguments - expected none after options"
    goto usage
  endif

#------------------------------------------------------------------------------

cat <<-Sql-Done- > $sql
--
  Set ServerOutput On FeedBack Off
--
Declare
  Utl_Dirs	VarChar2(32767) ;
  comma		Integer ;
Begin
--
  Select	value
    into	Utl_Dirs
    from	v\$parameter
    where	name = 'utl_file_dir'
  ;
--
  Utl_Dirs := Replace(Utl_Dirs,' ','') ;
--
  while ( length(Utl_Dirs) > 0 ) loop
    comma := instr(Utl_Dirs,',') ;
    if ( comma <> 0 ) then
      Dbms_Output.Put_Line ( Substr ( Utl_Dirs, 1, comma - 1 ) ) ;
      Utl_Dirs := Substr ( Utl_Dirs, comma + 1 ) ;
    else
      Dbms_Output.Put_Line ( Utl_Dirs ) ;
      Utl_Dirs := '' ;
    end if ;
  end loop ;
--
Exception
  When No_Data_Found then
    Dbms_Output.Put_Line ( '*** not utl_file directories defined' ) ;
End ;
/
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
  echo "Usage:  utl-file [options]"
  echo ""
  echo "Options:"
  echo ""
  echo "  -c <connect>    Connection string user/password"
  echo ""
  echo "  -pipe           Output piped - no headings or feedback"
  echo ""
  echo "  -sql            Show generated SQL - do not run."
  echo ""
  echo "  -p              Print listing"
  echo ""
  echo "  -s              Run silently, useful just to print listing"
  echo ""

  rm -f $out $sql

  exit -1

#------------------------------------------------------------------------------
