-- $Header: c:\\Repository/database/rams/applications/name_match/match_name/sql/grants_new.sql,v 1.4 2006/08/10 20:35:08 costing Exp $

grant execute on hostdb.names to names_change;
grant select, insert, update on hostdb.emp_tbl to names_change;
grant select on hostdb.employee_xt to names_change;
grant select on hostdb.name_candidates_v to names_change;

grant select on hostdb.emp_tbl to names_view;
grant select on hostdb.name_candidates_v to names_view;
grant select on hostdb.emp_v to costing_change;

grant select, insert, update, delete on hostdb.emp_tbl to costing_change;
grant select on hostdb.emp to costing_change;
grant select on hostdb.emp to web_view;


-- use the following query to find out privs should be granted for emp_tbl.
--
-- set heading off
-- set feedback off
-- select 
-- 	'grant '
-- 	||privilege
-- 	||' on '||owner||'.'||'emp_tbl'
-- 	||' to '||grantee
-- 	||';'
--   from dba_tab_privs 
--  where table_name='EMP' 
--    and owner='HOSTDB';
-- set heading on
-- set feedback on
@./privs_emp.sql
