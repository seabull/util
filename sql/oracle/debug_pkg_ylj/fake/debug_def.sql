create or replace package traceit as

  type Argv is table of varchar2(4000);
  emptyDebugArgv Argv;

  procedure init(
    p_dlevel	  in number   default 1,
    p_modules     in varchar2 default 'ALL',
    p_file        in varchar2 default '/tmp/' || user || '.dbg',
    p_user        in varchar2 default user,
    p_show_date   in varchar2 default 'YES',
    p_date_format in varchar2 default 'MMDDYYYY HH24MISS',
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
