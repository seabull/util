##################################################################################
#	This content is from the trace file after executing 
#	"alter database backup controlfile to trace"
#	Some changes are made to be used to change SID
#
##################################################################################
# The following commands will create a new control file and use it
# to open the database.
# Data used by the recovery manager will be lost. Additional logs may
# be required for media recovery of offline data files. Use this
# only if the current version of all online logs are available.
STARTUP NOMOUNT
CREATE CONTROLFILE REUSE SET DATABASE "FACX" RESETLOGS ARCHIVELOG
    MAXLOGFILES 32
    MAXLOGMEMBERS 2
    MAXDATAFILES 30
    MAXINSTANCES 8
    MAXLOGHISTORY 7421
LOGFILE
  GROUP 1 (
    '/usr2/oradata/fac/redofac01.log',
    '/usr3/oradata/fac/redofac01.log'
  ) SIZE 500K,
  GROUP 2 (
    '/usr3/oradata/fac/redofac02.log',
    '/usr4/oradata/fac/redofac02.log'
  ) SIZE 500K,
  GROUP 3 (
    '/usr4/oradata/fac/redofac03.log',
    '/usr2/oradata/fac/redofac03.log'
  ) SIZE 500K
DATAFILE
  '/usr2/oradata/fac/system01.dbf',
  '/usr3/oradata/fac/rbs01.dbf',
  '/usr2/oradata/fac/temp01.dbf',
  '/usr2/oradata/fac/tools01.dbf',
  '/usr3/oradata/fac/user01.dbf',
  '/usr3/oradata/fac/apps01.dbf',
  '/usr2/oradata/fac/repository01.dbf',
  '/usr3/oradata/fac/temp201.dbf',
  '/usr2/oradata/fac/oem_repository.dbf',
  '/usr3/oradata/fac/costing01.dbf'
;
# Recovery is required if any of the datafiles are restored backups,
# or if the last shutdown was not normal or immediate.
#RECOVER DATABASE
# All logs need archiving and a log switch is needed.
ALTER SYSTEM ARCHIVE LOG ALL;
# Database can now be opened normally.
ALTER DATABASE OPEN RESETLOGS;

