set heading off
set echo off
set termout off

spool nm_1
select 
	'CS_USERID'
	||'|'||'CS_Name'
	||'|'||'CAMPUS_Name'
	||'|'||'First'
	||'|'||'Last'
	||'|'||'Hris_ID'
	||'|'||'Andrew_ID'
from dual
/
	
-- match the last name and the first N letters of the first name.
select 
	unique
	n.princ
	||'|'||n.lname
	||'|'||e.emp_name
	||'|'||e.first
	||'|'||e.last
	||'|'||e.emp_num
	||'|'||e.andrew_id
from
	hostdb.name n
	,hostdb.emp e
where 
	n.emp_num is null
	and lower(concat(substr(n.lname, 1, instr(n.lname, ',', 1)-1), substr(n.lname, instr(n.lname,',', 1)+2,1)))=lower(concat(e.last, substr(e.first,1,1)))
/
spool off
spool nm_2
select 
	'CS_USERID'
	||'|'||'CS_Name'
	||'|'||'CAMPUS_Name'
	||'|'||'First'
	||'|'||'Last'
	||'|'||'Hris_ID'
	||'|'||'Andrew_ID'
from dual
/
	
-- match the last name and the first N letters of the first name.
select 
	unique
	n.princ
	||'|'||n.lname
	||'|'||e.emp_name
	||'|'||e.first
	||'|'||e.last
	||'|'||e.emp_num
	||'|'||e.andrew_id
from
	hostdb.name n
	,hostdb.emp e
where 
	n.emp_num is null
	and lower(concat(substr(n.lname, 1, instr(n.lname, ',', 1)-1), substr(n.lname, instr(n.lname,',', 1)+2,2)))=lower(concat(e.last, substr(e.first,1,2)))
/
spool off
spool nm_3
select 
	'CS_USERID'
	||'|'||'CS_Name'
	||'|'||'CAMPUS_Name'
	||'|'||'First'
	||'|'||'Last'
	||'|'||'Hris_ID'
	||'|'||'Andrew_ID'
from dual
/
	
-- match the last name and the first N letters of the first name.
select 
	unique
	n.princ
	||'|'||n.lname
	||'|'||e.emp_name
	||'|'||e.first
	||'|'||e.last
	||'|'||e.emp_num
	||'|'||e.andrew_id
from
	hostdb.name n
	,hostdb.emp e
where 
	n.emp_num is null
	and lower(concat(substr(n.lname, 1, instr(n.lname, ',', 1)-1), substr(n.lname, instr(n.lname,',', 1)+2,3)))=lower(concat(e.last, substr(e.first,1,3)))
/
spool off
spool nm_4
select 
	'CS_USERID'
	||'|'||'CS_Name'
	||'|'||'CAMPUS_Name'
	||'|'||'First'
	||'|'||'Last'
	||'|'||'Hris_ID'
	||'|'||'Andrew_ID'
from dual
/
	
-- match the last name and the first N letters of the first name.
select 
	unique
	n.princ
	||'|'||n.lname
	||'|'||e.emp_name
	||'|'||e.first
	||'|'||e.last
	||'|'||e.emp_num
	||'|'||e.andrew_id
from
	hostdb.name n
	,hostdb.emp e
where 
	n.emp_num is null
	and lower(concat(substr(n.lname, 1, instr(n.lname, ',', 1)-1), substr(n.lname, instr(n.lname,',', 1)+2,4)))=lower(concat(e.last, substr(e.first,1,4)))
/
spool off
spool nm_5
select 
	'CS_USERID'
	||'|'||'CS_Name'
	||'|'||'CAMPUS_Name'
	||'|'||'First'
	||'|'||'Last'
	||'|'||'Hris_ID'
	||'|'||'Andrew_ID'
from dual
/
	
-- match the last name and the first N letters of the first name.
select 
	unique
	n.princ
	||'|'||n.lname
	||'|'||e.emp_name
	||'|'||e.first
	||'|'||e.last
	||'|'||e.emp_num
	||'|'||e.andrew_id
from
	hostdb.name n
	,hostdb.emp e
where 
	n.emp_num is null
	and lower(concat(substr(n.lname, 1, instr(n.lname, ',', 1)-1), substr(n.lname, instr(n.lname,',', 1)+2,5)))=lower(concat(e.last, substr(e.first,1,5)))
/
spool off
