--CREATE TABLESPACE REPORT01
--	LOGGING DATAFILE '/usr20/oradata/fac_03/report01.dbf' SIZE 1024M REUSE 
--	AUTOEXTEND 
--	ON NEXT  2048K MAXSIZE  8191M EXTENT MANAGEMENT LOCAL
--/


	-- IDENTIFIED BY "&Random_Password"
CREATE USER ccreport  
	PROFILE "DEFAULT" 
	IDENTIFIED BY "ccreport"
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
