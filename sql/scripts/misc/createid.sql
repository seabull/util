REM (log in as Oracle)
REM
REM Script to create a new schema for authentication only not belonging to
REM a user
REM
REM        sqlplus / @createid id
REM
REM Author: yangl@cs.cmu.edu

PROMPT Name to be created should be upper case and not include @CS.CMU.EDU
define name="&&1"

CREATE USER "&&name@CS.CMU.EDU" IDENTIFIED EXTERNALLY 
	DEFAULT TABLESPACE "USERS" 
	TEMPORARY TABLESPACE "TEMP" 
	QUOTA 100 K ON TEMP
	QUOTA 1000 K ON USERS
	PROFILE DEFAULT 
	ACCOUNT UNLOCK
/

GRANT "CONNECT" TO "&&name@CS.CMU.EDU";
GRANT "EQUIP_VIEW" TO "&&name@CS.CMU.EDU";
GRANT CREATE SESSION TO "&&name@CS.CMU.EDU";
REM
REM GRANT "COSTING_CHANGE" TO "&&name@CS.CMU.EDU";
REM GRANT "COSTING_ADMIN" TO "&&name@CS.CMU.EDU";
REM GRANT CREATE PROCEDURE TO "&&name@CS.CMU.EDU"
REM GRANT CREATE ROLE TO "&&name@CS.CMU.EDU"
REM GRANT CREATE SEQUENCE TO "&&name@CS.CMU.EDU"
REM GRANT CREATE SESSION TO "&&name@CS.CMU.EDU"
REM GRANT CREATE TABLE TO "&&name@CS.CMU.EDU"
REM GRANT CREATE TRIGGER TO "&&name@CS.CMU.EDU"
REM GRANT CREATE TYPE TO "&&name@CS.CMU.EDU"
REM GRANT CREATE USER TO "&&name@CS.CMU.EDU"
REM GRANT CREATE VIEW TO "&&name@CS.CMU.EDU"
REM GRANT DROP USER TO "&&name@CS.CMU.EDU"
REM
ALTER USER "&&name@CS.CMU.EDU" DEFAULT ROLE ALL;
exit

