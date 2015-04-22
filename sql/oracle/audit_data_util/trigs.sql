-- $Id: trigs.sql,v 1.3 2005/05/09 18:04:14 yangl Exp $
--
-- This script will generate triggers to audit table
-- data changes using the general audit table and audit package
-- defined in audit_tbl.sql and audit_pkg.sql
-- usage:
--	SQL>@trigs <owner> <tablename>
-- e.g.
-- 	SQL>@trigs dept
-- The following trigger will be generated.
--	create or replace trigger aud#dept
--	after update on dept
--	for each row
--	begin
--		audit_pkg.check_val( 'dept', 'DEPTNO', :new.DEPTNO, :old.DEPTNO);
--		audit_pkg.check_val( 'dept', 'DNAME', :new.DNAME, :old.DNAME);
--		audit_pkg.check_val( 'dept', 'LOC', :new.LOC, :old.LOC);
--	end;
--	/

set serveroutput on
set feedback off
set verify off
set embedded on
set heading off

spool tmp.sql
prompt create or replace trigger &1..aud#&2
prompt after update or insert or delete on &1..&2
prompt for each row
prompt declare

select '   ops	pls_integer := 1;' from dual;

prompt begin

select '      if DELETING then' 		from dual;
select '         ops := 1;'			from dual;
select '      else if inserting then'		from dual;
select '              ops := 2;'		from dual;
select '           else if updating then'	from dual;
select '                   ops := 3;'		from dual;
select '                end if;'		from dual;
select '           end if;'			from dual;
select '       end if;'				from dual;
 
select '    audit_pkg.check_val( user, ops, ''&1'', ''&2'', ''' || column_name ||
          ''', ' || ':new.' || column_name || ', :old.' || 
             column_name || ');'
 from dba_tab_columns 
where owner= upper('&1')
  and table_name = upper('&2')
/
prompt end;;
prompt /
 
spool off
set feedback on
set embedded off
set heading on
set verify on
 
@tmp
