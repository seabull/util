-- $Id: report_error.sql,v 1.1 2005/04/04 19:27:23 yangl Exp $
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

spool &1

select max(id)
  into :l_bid
  from hostdb.name_error_ids
/

select 'SCS_ID'
	||'|'||'SCS_Name'
	||'|'||'Campus_Name'
	||'|'||'Hris_ID'
	||'|'||'Andrew_Id'
from dual
/

select 
        princ
        ||'|'||lname
        ||'|'||emp_name
        ||'|'||emp_num
        ||'|'||andrew_id
from hostdb.name_error 
where 
	bid=:l_bid
/
spool off

/*
hostdb@FAC_02.APOGEE.FAC.CS.CMU.EDU> desc name_error
 Name                                                  Null?    Type
 ----------------------------------------------------- -------- ------------------------------------
 BID                                                            NUMBER(4)
 PRINC                                                          VARCHAR2(50)
 LNAME                                                          VARCHAR2(50)
 EMP_NAME                                                       VARCHAR2(50)
 EMP_NUM                                                        VARCHAR2(50)
 ANDREW_ID                                                      VARCHAR2(100)

*/
