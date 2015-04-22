-- $Id: sync_pireport.sql,v 1.2 2007/04/26 20:24:59 yangl Exp $

set newpage none
set space 0
set feedback off
set linesize 400
set heading off
set echo off
set termout off
set trimspool on
set define on

whenever sqlerror exit failure rollback
whenever oserror exit failure rollback

--set define on
set termout on

--alter session set timed_statistics=true;
--alter session set max_dump_file_size=unlimited;
--alter session set tracefile_identifier='JE';
--alter session set events '10046 trace name context forever, level 12';
execute pireport.sync_pi_rpt.&1;
--alter session set events '10046 trace name context off';
commit;

prompt Procedure pireport.sync_pi_rpt.&1 completed successfully and committed.

exit
