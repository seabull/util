create or replace package traceit as
/* 
  Note that this package was developed by Longjiang Yang 
  and has been modified according to TGT standard.
  
  Author: Longjiang Yang
  Name : traceit definition 
  Application Name: ERX (Healthcare) 
  Database Name(s): 
  Purpose:  instrumentation utility for PLSQL stored procedure (packages)
  Created Date:  April 14, 2015
  Last Updated: April 14, 2015
  Special instructions: None 
  Known Dependencies: debug table 

*/ 



  /*
   * constants
   */ 
  constDEBUGLEVEL_A           pls_integer := 2;
  constDEBUGLEVEL_B           pls_integer := 4;
  constDEBUGLEVEL_C           pls_integer := 8;
  constDEBUGLEVEL_D           pls_integer := 16;
  constDEBUGLEVEL_E           pls_integer := 32;

  type Argv is table of varchar2(4000);
  emptyDebugArgv Argv;

  procedure init(
    p_dlevel	  in number   default 1,
    p_modules     in varchar2 default 'ALL',
    p_file        in varchar2 default '/tmp/' || user || '.dbg',
    p_user        in varchar2 default user,
    p_show_date   in varchar2 default 'YES',
    p_date_format in varchar2 default 'YYYYMMDD HH24MISS',
    p_name_len    in number   default 30,
    p_show_sesid  in varchar2 default 'NO' );

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
    p_arg10   in varchar2 default null );

  procedure loga(
    p_dlevel  in number,
    p_message in varchar2,
    p_args    in Argv default emptyDebugArgv );

  procedure status(
    p_user in varchar2 default user,
    p_file in varchar2 default null );

  procedure clear(
    p_user in varchar2 default user,
    p_file in varchar2 default null );

end traceit;
/

/* vim: set ts=4 sw=4 tw=0 noet : */
