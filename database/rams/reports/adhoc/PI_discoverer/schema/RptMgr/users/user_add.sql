-- $Id: user_add.sql,v 1.1 2006/12/06 17:22:29 yangl Exp $
--


	-- IDENTIFIED BY "&Random_Password"
CREATE USER pireport  
	PROFILE "DEFAULT" 
	IDENTIFIED BY "pireport"
	DEFAULT TABLESPACE "REPORT01" 
	TEMPORARY TABLESPACE "TEMP2" 
	QUOTA UNLIMITED 
	ON "REPORT01" 
	QUOTA UNLIMITED 
	ON "INDX" 
	QUOTA UNLIMITED 
	ON "TEMP2" 
	ACCOUNT UNLOCK
/

--set TERMOUT OFF ECHO OFF FEEDBACK OFF VERIFY OFF
--
--column Random_String New_Value Random_Password NoPrint ;
--
--select dbms_random.string('a',30) Random_String from dual 
--/
--
--set TERMOUT On VERIFY OFF

-- select '&Random_Password' from dual ;
--alter user ccreport 
	-- IDENTIFIED BY "&Random_Password";
