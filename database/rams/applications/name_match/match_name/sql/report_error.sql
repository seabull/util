-- $Id: report_error.sql,v 1.3 2005/04/21 14:34:38 yangl Exp $
--
set newpage none
set space 0
set feedback off
set linesize 400
set heading off
set echo off
--set termout off
set trimspool on
set define on

-- whenever sqlerror exit failure rollback
-- whenever oserror exit failure rollback

VARIABLE l_bid NUMBER;

begin
	select max(id)
	  into :l_bid
	  from hostdb.name_error_bids;
end;
.

run

spool &1
select 'SCS_ID'
	||','||'SCS_Name'
	||','||'Campus_Name'
	||','||'Hris_ID'
	||','||'Andrew_Id'
from dual
/

select 
        princ
        ||',"'||lname||'"'
        ||',"'||emp_name||'"'
        ||','||emp_num
        ||','||andrew_id
from hostdb.name_error 
where 
	bid=:l_bid
/
spool off
quit

