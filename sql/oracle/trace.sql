REM turn on trace

alter session set timed_statistics=true;
alter session set max_dump_file_size=unlimited;
alter session set tracefile_identifier='ylj';
sys.dbms_support.start_trace(true, true);
REM or alter session set events '10046 trace name context forever, level 12';

REM code to be diagnosed goes here

REM sys.dbms_support.stop_trace();
REM or alter session set event '10046 trace name context off';

REM To found out the name of the default trace file
REM select rtrim(c.value, '/')||'/'||d.instance_name||'_ora'||ltrim(to_char(a.spid))||'.trc'
REM from v$process a, v$session b, v$parameter c, v$instance d
REM where a.addr=b.paddr
REM   and b.audsid=sys_context('usr_env', 'sessionid')
REM   and c.name='user_dump_dest'
