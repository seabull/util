-- $Header: c:\\Repository/database/rams/applications/name_match/match_name/sql/exec_sqlproc.sql,v 1.2 2005/10/18 15:16:18 yangl Exp $
--
/*
 *  Script used to run an arbitrary procedure from shell.  
 *  Procedure and any arguments are supplied as parameter(s).
 */
set newpage none
set space 0
set feedback off
set linesize 400
set heading off
set echo off
set termout off
set trimspool on
set define off

whenever sqlerror exit failure rollback
whenever oserror exit failure rollback

set define on
set termout on

--alter session set timed_statistics=true;
--alter session set max_dump_file_size=unlimited;
--alter session set tracefile_identifier='JE';
--alter session set events '10046 trace name context forever, level 12';

execute &1;

--alter session set events '10046 trace name context off';

commit;

prompt Procedure &1 completed successfully and committed.

exit

