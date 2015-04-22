-- $Id: ccf-2.sql,v 1.2 2005/03/04 19:28:47 yangl Exp $
REM #     Set #2. RESETLOGS case
REM #
REM # The following commands will create a new control file and use it
REM # to open the database.
REM # The contents of online logs will be lost and all backups will
REM # be invalidated. Use this only if online logs are damaged.
STARTUP NOMOUNT
CREATE CONTROLFILE SET DATABASE "FAC_02" RESETLOGS  ARCHIVELOG
--  SET STANDBY TO MAXIMIZE PERFORMANCE
    MAXLOGFILES 5
    MAXLOGMEMBERS 5
    MAXDATAFILES 100
    MAXINSTANCES 1
    MAXLOGHISTORY 226
LOGFILE
  GROUP 1 (
    '/usr11/oralogs/fac_02/redo01.log',
    '/usr23/oralogs/fac_02/redo01.log'
  ) SIZE 100M,
  GROUP 2 (
    '/usr11/oralogs/fac_02/redo02.log',
    '/usr23/oralogs/fac_02/redo02.log'
  ) SIZE 100M,
  GROUP 3 (
    '/usr11/oralogs/fac_02/redo03.log',
    '/usr23/oralogs/fac_02/redo03.log'
  ) SIZE 100M,
  GROUP 4 (
    '/usr11/oralogs/fac_02/redo04.log',
    '/usr23/oralogs/fac_02/redo04.log'
  ) SIZE 100M
-- STANDBY LOGFILE
DATAFILE
  '/usr10/oradata/fac_02/system01.dbf',
  '/usr13/oradata/fac_02/undotbs01.dbf',
  '/usr20/oradata/fac_02/apps.dbf',
  '/usr20/oradata/fac_02/costing.dbf',
  '/usr20/oradata/fac_02/costing_lg.dbf',
  '/usr20/oradata/fac_02/cwmlite01.dbf',
  '/usr20/oradata/fac_02/drsys01.dbf',
  '/usr21/oradata/fac_02/indx01.dbf',
  '/usr20/oradata/fac_02/odm01.dbf',
  '/usr10/oradata/fac_02/tools01.dbf',
  '/usr20/oradata/fac_02/users01.dbf',
  '/usr20/oradata/fac_02/xdb01.dbf'
CHARACTER SET WE8ISO8859P1
;
REM # Recovery is required if any of the datafiles are restored backups,
REM # or if the last shutdown was not normal or immediate.
REM RECOVER DATABASE USING BACKUP CONTROLFILE

REM # Database can now be opened zeroing the online logs.
ALTER DATABASE OPEN RESETLOGS;

REM # Commands to add tempfiles to temporary tablespaces.
REM # Online tempfiles have complete space information.
REM # Other tempfiles may require adjustment.
ALTER TABLESPACE TEMP ADD TEMPFILE '/usr10/oradata/fac_02/temp01.dbf'
     SIZE 162529280  REUSE AUTOEXTEND ON NEXT 655360  MAXSIZE 32767M;

ALTER TABLESPACE TEMP2 ADD TEMPFILE '/usr10/oradata/fac_02/temp2.dbf'
     SIZE 1660M REUSE AUTOEXTEND ON NEXT 524288  MAXSIZE 9216M;
REM # End of tempfile additions.
REM #
