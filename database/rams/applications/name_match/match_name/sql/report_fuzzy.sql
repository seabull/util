-- $Id: report_fuzzy.sql,v 1.3 2006/11/28 16:16:25 yangl Exp $
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

whenever sqlerror exit failure rollback
whenever oserror exit failure rollback

VARIABLE l_bid NUMBER;

begin
	select max(id)
	  into :l_bid
	  from hostdb.name_error_bids;
end;
.

run

spool &1
select 
	'Id'
	||','||'SCS_Princ'
        ||','||'CS_pri'
        ||','||'SCS_Empnum'
	||','||'SCS_Name'
	||','||'Campus_Name'
        ||','||'Hris_Id'
	||','||'Andrew_Id'
        ||','||'Eid'
from dual
/

select 
	candidate_id
        ||','||cs_princ
        ||','||cs_pri
        ||','||cs_empnum
        ||',"'||cs_name||'"'
        ||',"'||andrew_name||'"'
        ||','||emp_num
        ||','||andrew_princ
        ||','||eid
from hostdb.name_candidates_v
where 
	bid=:l_bid
/

select
        e.id
        ||','||n.princ
        ||','||n.pri
        ||','||n.emp_num
        ||',"'||n.name||'"'
        ||',"'||e.full_name||'"'
        ||','||e.emp_num
        ||','||e.andrew_uid
        ||','||e.id
  from hostdb.nameprinc_v n
        ,hostdb.emp_tbl e
 where n.emp_num is null
   and n.pri=0
   and n.princ=e.andrew_uid
/
spool off
quit

