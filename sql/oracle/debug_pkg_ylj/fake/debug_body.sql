create or replace package body traceit as
-- This is the package body for traceit
-- Usage DEBUG.INIT(...);DEBUG.LOG("Message");
-- $Header: c:\\Repository/sql/oracle/debug_pkg_ylj/fake/debug_body.sql,v 1.1 2005/02/07 21:00:25 yangl Exp $
-- $Author: yangl $
g_session_id varchar2(2000);

procedure who_called_me(
  o_owner  out varchar2,
  o_object out varchar2,
  o_lineno out number ) is
--
  l_call_stack long default dbms_utility.format_call_stack;
  l_line varchar2(4000);
begin
  null;
end who_called_me;

function build_it(
  p_debug_row in debugtab%rowtype,
  p_owner     in varchar2,
  p_object    in varchar2,
  p_lineno number ) return varchar2 is
--
  l_header long := null;
begin
  return '';
end build_it;

function parse_it(
  p_message       in varchar2,
  p_argv          in argv,
  p_header_length in number ) return varchar2 is
--
  l_message long := null;
  l_str long := p_message;
  l_idx number := 1;
  l_ptr number := 1;
begin
  return '';
end parse_it;

function file_it(
  p_file    in debugtab.filename%type,
  p_message in varchar2 ) return boolean is
--
  l_handle utl_file.file_type;
  l_file long;
  l_location long;
begin
  return false;
end file_it;

procedure debug_it(
  p_dlevel  in number,
  p_message in varchar2,
  p_argv    in argv ) is
--
  l_message long := null;
  l_header long := null;
  call_who_called_me boolean := true;
  l_owner varchar2(255);
  l_object varchar2(255);
  l_lineno number;
  l_dummy boolean;
begin
  null;
end debug_it;

procedure init(
  p_dlevel	in number default 1,
  p_modules     in varchar2 default 'ALL',
  p_file    in varchar2 default '/tmp/' || user || '.dbg',
  p_user        in varchar2 default user,
  p_show_date   in varchar2 default 'YES',
  p_date_format in varchar2 default 'MMDDYYYY HH24MISS',
  p_name_len    in number   default 30,
  p_show_sesid  in varchar2 default 'NO' ) is
--
  pragma autonomous_transaction;
  debugtab_rec debugtab%rowtype;
  l_message long;
begin
  null;
end init;

procedure log(
  p_dlevel  in number,
  p_message in varchar2,
  p_arg1    in varchar2 default null,
  p_arg2    in varchar2 default null,
  p_arg3    in varchar2 default null,
  p_arg4    in varchar2 default null,
  p_arg5    in varchar2 default null,
  p_arg6    in varchar2 default null,
  p_arg7    in varchar2 default null,
  p_arg8    in varchar2 default null,
  p_arg9    in varchar2 default null,
  p_arg10   in varchar2 default null ) is
begin
  -- return;

  debug_it( p_dlevel, p_message,
            argv( substr( p_arg1, 1, 4000 ),
                  substr( p_arg2, 1, 4000 ),
                  substr( p_arg3, 1, 4000 ),
                  substr( p_arg4, 1, 4000 ),
                  substr( p_arg5, 1, 4000 ),
                  substr( p_arg6, 1, 4000 ),
                  substr( p_arg7, 1, 4000 ),
                  substr( p_arg8, 1, 4000 ),
                  substr( p_arg9, 1, 4000 ),
                  substr( p_arg10, 1, 4000 ) ) );
end log;

procedure loga(
  p_dlevel  in number,
  p_message in varchar2,
  p_args    in Argv default emptyDebugArgv ) is
begin
  -- return;
  debug_it( p_dlevel, p_message, p_args );
end loga;

procedure clear( p_user in varchar2 default user,
  p_file in varchar2 default null ) is
  pragma autonomous_transaction;
begin
  null;
end clear; 

procedure status(
  p_user in varchar2 default user,
  p_file in varchar2 default null ) is
--
  l_found boolean := false;
begin
  null;
end status;

begin
  g_session_id := userenv('SESSIONID');
end traceit;
/
