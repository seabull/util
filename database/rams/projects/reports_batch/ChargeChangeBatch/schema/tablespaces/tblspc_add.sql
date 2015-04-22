-- $Header: c:\\Repository/database/rams/projects/reports_batch/ChargeChangeBatch/schema/tablespaces/tblspc_add.sql,v 1.2 2006/05/18 16:28:21 yangl Exp $
--
	--LOGGING DATAFILE '/usr20/oradata/fac_03/report01.dbf' SIZE 1024M REUSE 
CREATE TABLESPACE REPORT01
	LOGGING DATAFILE '/usr20/oradata/fac/report01.dbf' SIZE 1024M REUSE 
	AUTOEXTEND 
	ON NEXT 2048K MAXSIZE 8191M EXTENT MANAGEMENT LOCAL
/

prompt tablespace report01 added
