-- $Id: user_passwd.sql,v 1.1 2006/12/06 17:22:29 yangl Exp $

set TERMOUT OFF ECHO OFF FEEDBACK OFF VERIFY OFF

column RANDOM_STRING NEW_VALUE RANDOM_PASSWORD NOPRINT ;

select dbms_random.string('a',30) RANDOM_STRING from dual 
/

set TERMOUT On VERIFY OFF

select '&RANDOM_PASSWORD' from dual;

alter user pireport 
	IDENTIFIED BY "&RANDOM_PASSWORD";

set termout on feedback on verify on
prompt 'Change password for User pireport'
