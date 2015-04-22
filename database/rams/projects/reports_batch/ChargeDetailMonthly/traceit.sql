-- $Id: traceit.sql,v 1.1 2005/10/11 14:08:49 yangl Exp $
--
create or replace package utility.traceit as

  constDEBUGLEVEL_A           pls_integer := 2;
  constDEBUGLEVEL_B           pls_integer := 4;
  constDEBUGLEVEL_C           pls_integer := 8;
  constDEBUGLEVEL_D           pls_integer := 16;
  constDEBUGLEVEL_E           pls_integer := 32;

  type Argv is table of varchar2(4000);
  emptyDebugArgv Argv;

  procedure init(
    p_dlevel      in number   ,
    p_modules     in varchar2 ,
    p_file        in varchar2 ,
    p_user        in varchar2 ,
    p_show_date   in varchar2 ,
    p_date_format in varchar2 ,
    p_name_len    in number   ,
    p_show_sesid  in varchar2  );

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
    p_arg10   in varchar2 default null);

  procedure loga(
    p_dlevel  in number,
    p_message in varchar2,
    p_args    in Argv );

  procedure status(
    p_user in varchar2 ,
    p_file in varchar2 );

  procedure clear(
    p_user in varchar2 ,
    p_file in varchar2 );

end traceit;
/

create or replace package body utility.traceit as
	g_session_id varchar2(2000);

	procedure init(
  		p_dlevel      in number ,
  		p_modules     in varchar2 ,
  		p_file    in varchar2 ,
  		p_user        in varchar2 ,
  		p_show_date   in varchar2 ,
  		p_date_format in varchar2 ,
  		p_name_len    in number   ,
  		p_show_sesid  in varchar2  ) is
		--
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
  		p_arg10   in varchar2 default null) is
	begin
		null;
	end log;

	procedure loga(
  		p_dlevel  in number,
  		p_message in varchar2,
  		p_args    in Argv ) is
	begin
  		null;
	end loga;

	procedure clear( p_user in varchar2 ,
  		p_file in varchar2 ) is
	begin
  		null;
	end clear;

	procedure status(
  		p_user in varchar2 ,
  		p_file in varchar2 ) is
		--
	begin
  		null;
	end status;

begin
	g_session_id := userenv('SESSIONID');
end traceit;
/

