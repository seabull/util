-- $Header: c:\\Repository/sql/oracle/dba/utils/createuser.sql,v 1.1 2005/12/20 20:13:25 yangl Exp $
--
-- Script to create a new user schema for Kerberos authenticated user.
--
--        sqlplus / @createuser
--
-- (logged in as Oracle)
--
PROMPT Name to be created should not include @CS.CMU.EDU and must be all caps
CREATE USER "&&name@CS.CMU.EDU" IDENTIFIED EXTERNALLY 
	DEFAULT TABLESPACE "USERS" 
	TEMPORARY TABLESPACE "TEMP" 
	PROFILE DEFAULT
	QUOTA 1024 K ON TEMP 
	QUOTA 1024 K ON USERS 
	ACCOUNT UNLOCK;

--ALTER USER "&&name@CS.CMU.EDU" QUOTA 100 K ON "TEMP" QUOTA 1000 K ON "USERS";
GRANT "CONNECT" TO "&&name@CS.CMU.EDU";
GRANT "EQUIP_VIEW" TO "&&name@CS.CMU.EDU";

GRANT CREATE PROCEDURE TO "&&name@CS.CMU.EDU";
GRANT CREATE SEQUENCE TO "&&name@CS.CMU.EDU";
GRANT CREATE SESSION TO "&&name@CS.CMU.EDU";
GRANT CREATE TABLE TO "&&name@CS.CMU.EDU";
GRANT CREATE TRIGGER TO "&&name@CS.CMU.EDU";
ALTER USER "&&name@CS.CMU.EDU" DEFAULT ROLE ALL;

quit
