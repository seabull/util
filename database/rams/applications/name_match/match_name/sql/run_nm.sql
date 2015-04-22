-- $Id: run_nm.sql,v 1.1 2005/04/20 21:21:21 yangl Exp $
--
set newpage none
set space 0
--set feedback off
set linesize 400
set heading off
set echo off
--set termout off
set trimspool on
set define off

whenever sqlerror exit failure rollback
whenever oserror exit failure rollback

set define on
set termout on

execute hostdb.matchnames_pkg.&1;
commit;

prompt Procedure matchnames_pkg.&1 completed successfully and committed.

exit

