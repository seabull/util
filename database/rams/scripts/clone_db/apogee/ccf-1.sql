REM *** SESSION ID:(12.32) 2005-03-01 20:48:09.254
REM *** 2005-03-01 20:48:09.253
REM # The following are current System-scope REDO Log Archival related
REM # parameters and can be included in the database initialization file.
REM #
REM # LOG_ARCHIVE_DEST=''
REM # LOG_ARCHIVE_DUPLEX_DEST=''
REM #
REM # LOG_ARCHIVE_FORMAT=fac_02_%t_%s.log
REM # REMOTE_ARCHIVE_ENABLE=TRUE
REM # LOG_ARCHIVE_START=TRUE
REM # LOG_ARCHIVE_MAX_PROCESSES=2
REM # STANDBY_FILE_MANAGEMENT=MANUAL
REM # STANDBY_ARCHIVE_DEST=?/dbs/arch
REM # FAL_CLIENT=''
REM # FAL_SERVER=''
REM #
REM # LOG_ARCHIVE_DEST_2='LOCATION=/usr22/oralogs/arch/fac_02'
REM # LOG_ARCHIVE_DEST_2='OPTIONAL REOPEN=300 NODELAY'
REM # LOG_ARCHIVE_DEST_2='ARCH NOAFFIRM SYNC'
REM # LOG_ARCHIVE_DEST_2='REGISTER NOALTERNATE NODEPENDENCY'
REM # LOG_ARCHIVE_DEST_2='NOMAX_FAILURE NOQUOTA_SIZE NOQUOTA_USED'
REM # LOG_ARCHIVE_DEST_STATE_2=ENABLE
REM #
REM # LOG_ARCHIVE_DEST_1='LOCATION=/usr12/oralogs/arch/fac_02'
REM # LOG_ARCHIVE_DEST_1='OPTIONAL REOPEN=300 NODELAY'
REM # LOG_ARCHIVE_DEST_1='ARCH NOAFFIRM SYNC'
REM # LOG_ARCHIVE_DEST_1='REGISTER NOALTERNATE NODEPENDENCY'
REM # LOG_ARCHIVE_DEST_1='NOMAX_FAILURE NOQUOTA_SIZE NOQUOTA_USED'
REM # LOG_ARCHIVE_DEST_STATE_1=ENABLE
REM #
REM # Below are two sets of SQL statements, each of which creates a new
REM # control file and uses it to open the database. The first set opens
REM # the database with the NORESETLOGS option and should be used only if
REM # the current versions of all online logs are available. The second
REM # set opens the database with the RESETLOGS option and should be used
REM # if online logs are unavailable.
REM # The appropriate set of statements can be copied from the trace into
REM # a script file, edited as necessary, and executed when there is a
REM # need to re-create the control file.
REM #
REM #     Set #1. NORESETLOGS case
REM #
REM # The following commands will create a new control file and use it
REM # to open the database.
REM # Data used by the recovery manager will be lost. Additional logs may
REM # be required for media recovery of offline data files. Use this
REM # only if the current version of all online logs are available.
STARTUP NOMOUNT
-- CREATE CONTROLFILE REUSE DATABASE "FAC" NORESETLOGS  ARCHIVELOG
CREATE CONTROLFILE set DATABASE "FAC_02" RESETLOGS  ARCHIVELOG
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
RECOVER DATABASE
REM # All logs need archiving and a log switch is needed.
ALTER SYSTEM ARCHIVE LOG ALL;

REM # Database can now be opened normally.
ALTER DATABASE OPEN;

REM # Commands to add tempfiles to temporary tablespaces.
REM # Online tempfiles have complete space information.
REM # Other tempfiles may require adjustment.

ALTER TABLESPACE TEMP ADD TEMPFILE '/usr10/oradata/fac_02/temp01.dbf'
     SIZE 162529280  REUSE AUTOEXTEND ON NEXT 655360  MAXSIZE 32767M;
ALTER TABLESPACE TEMP2 ADD TEMPFILE '/usr10/oradata/fac_02/temp2.dbf'
     SIZE 1660M REUSE AUTOEXTEND ON NEXT 524288  MAXSIZE 9216M;

REM # End of tempfile additions.
