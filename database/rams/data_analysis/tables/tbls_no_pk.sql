-- $Id: tbls_no_pk.sql,v 1.1 2005/04/18 18:03:33 yangl Exp $
--
-- Get all the tables that do not have promary key constraint.
--
set termout off
set feedback off
set heading off

spool tables_no_pk.txt
select 'owner'
	||','||'table_name'
  from dual
/

SELECT 
	owner
	||','||table_name
  FROM dba_tables
 WHERE owner IN ('HOSTDB', 'COSTING', 'COSTING@CS.CMU.EDU','ACCOUNTING')
MINUS
SELECT 
	owner
	||','||table_name
  FROM dba_constraints
 WHERE owner IN ('HOSTDB', 'COSTING', 'COSTING@CS.CMU.EDU','ACCOUNTING')
   AND constraint_type = 'P'
/
spool off

set termout on
set feedback on
set heading on
