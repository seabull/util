REM alter system set user_dump_dest='/usr/oracle/debug';=
alter session set timed_statistics=true
/
alter session set max_dump_file_size=unlimited
/
alter session set tracefile_identifier='Hello'
/
alter session set events '10046 trace name context forever, level 12'
/
REM Code to be traced goes here
alter session set events '10046 trace name context off'
/

REM Alternative
REM dbms_support.start_trace(waits=>true, binds=>true);
REM dbms_support.stop_trace();
