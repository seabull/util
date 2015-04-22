-- $Header: c:\\Repository/database/rams/projects/reports_batch/ChargeChangeBatch/schema/users/user_passwd.sql,v 1.1 2006/04/11 20:47:36 yangl Exp $

set TERMOUT OFF ECHO OFF FEEDBACK OFF VERIFY OFF

column RANDOM_STRING NEW_VALUE RANDOM_PASSWORD NOPRINT ;

select dbms_random.string('a',30) RANDOM_STRING from dual 
/

set TERMOUT On VERIFY OFF

select '&RANDOM_PASSWORD' from dual;

alter user ccreport 
	IDENTIFIED BY "&RANDOM_PASSWORD";

set termout on feedback on verify on
prompt 'Change password for User ccreport'
