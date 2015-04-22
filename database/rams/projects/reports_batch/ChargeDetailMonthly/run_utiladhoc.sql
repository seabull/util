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

execute ramsreport.util_adhoc.&1;
commit;

prompt Procedure util_adhoc.&1 completed successfully and committed.

exit
