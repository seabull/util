
/*
Stop SQL service, rename DbLive.mdf to DbBad.mdf.
started SQL service, created fake DbLive db (with log etc)
Stopped SQL service
Deleted DbLIve.mdf 
Renamed DbBad.MDF to DbLive.MDF
Started SQL service.
Ran following script:
*/
ALTER DATABASE DbLive SET EMERGENCY
sp_dboption 'DbLive', 'single user', 'true' 
DBCC CHECKDB ('DbLive', REPAIR_ALLOW_DATA_LOSS)
sp_dboption 'DbLive', 'single user', 'false' 

