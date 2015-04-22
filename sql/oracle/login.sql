REM login sql script for sqlplus. This should be put in the 
REM SQL path directory so that sqlplus can load it at start up.
REM $Header: c:\\Repository/sql/oracle/login.sql,v 1.6 2006/11/17 17:33:02 yangl Exp $
REM prompt new login.sql loaded...
define _editor=vi

set serveroutput on size 1000000

set trimspool on
set long 5000
set linesize 100
set pagesize 9999

column plan_plus_exp format a80

column global_name new_value gname
set termout off
set feedback off
define gname=idle
column global_name new_value gname

select 
	lower(user) 
            || '@' 
            || substr( global_name, 1,
                        decode( dot, 0, length(global_name), dot-1)
                    ) global_name
  from (select global_name, instr(global_name, '.', 1, 2) dot from global_name);
            
--select 
--	substr(lower(user) || '@' ||
--		decode(global_name, 
--			'ORACLE8.WORLD', '8.0' , 
--			'ORA8I.WORLD', '8i', 
--			global_name ), 1, 48
--		) global_name 
--  from global_name;

set sqlprompt '&gname> '

set termout on
set feedback on
alter session set timed_statistics=true;

REM set timing on
REM set linesize 80
REM set pagesize 50000
