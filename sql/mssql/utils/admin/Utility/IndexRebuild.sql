USE master
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
IF OBJECT_ID('spX_RebuildIndexes_Main') IS NOT NULL
        DROP PROCEDURE dbo.spX_RebuildIndexes_Main
GO

-------------------------------------------------------------------------------------------
-- This SP rebuilds and reorganizes all indexes in the specified database or all databases. 
-- You can run code or generate code. Database will be set in bulk logged mode during processing 
-- and set back to normal when finished.
-- Different SQL Editions are handled. LOB indexes, row and page locking options, number of processors, 
-- concurrent users and more are handled. Max processing time, fragmentation and density are 
-- some of the parameters for this procedure.
-- 
-------------------------------------------------------------------------------------------
CREATE PROCEDURE dbo.spX_RebuildIndexes_Main 
         @databasename 		nvarchar(256) = N''	-- If you only want to rebuild/reorganize a particular database
        ,@maxfrag		float			-- Only indexes with an avg fragmentation in percent > @maxfrag are inluded,	    
        ,@maxdensity		float			-- OR tables with an avg page space used in percent < @maxdensity are included
        ,@online		bit			-- If 1, REBUILD WITH ONLINE = ON (Enterpise or Developer) or REORGANIZE, else REORGANIZE IF @currentfrag < 30 ELSE REBUILD (IF no users)
        ,@runrebuild		bit			-- If 1, REBUILD/REORGANIZE is executed, else code script is generated only 
        ,@LogUsedThresholdGB	int			-- Max size allowed for loggdb for current database in GB
        ,@maxruntime 		int			-- Max runtime in seconds, else run until ready
        ,@disklimit 		char(4)='0.19'		-- Disk space limit for disks included in check
        ,@notdisk1 		char(1)='C'		-- Disk not included when checking disk space (no DBs should be on C)
        ,@notdisk2 		char(1)=''		-- Disk not included when checking disk space
        ,@notdisk3 		char(1)=''		-- Disk not included when checking disk space
        ,@notdisk4 		char(1)=''		-- Disk not included when checking disk space
        ,@maxdop		int = 0			-- Max degree of parallellism. 
						-- Note: Parallel index operations are available only in SQL Server 2005 Enterprise Edition.
						-- Manually configure the number of processors that are used to run the index statement by 
						-- specifying the MAXDOP index option and limiting the number of processors to use for the index operation.
						-- 0 uses the actual number of available CPUs depending on the current system workload. 
						-- This is the default value and recommended setting.		    
						-- 1 suppresses parallel plan generation. The operation will be executed serially.
						-- 2-64 limits the number of processors to the specified value. Fewer processors may be used depending on 
                        -- the current workload. If a value larger than the number of available CPUs is specified, the actual 
                        -- number of available CPUs is used. 
AS
/*---------------------------------------------------------------------------------------------
        NOTE (see BOL): The defragmentation process is always fully logged, 
        regardless of the database recovery model setting (see ALTER DATABASE). 
        @databasename is database to defrag indexes for.
        @maxruntime is total allowed runtime in seconds for this job, which is checked after each db and each index has been processed.
        
        -- Example how to rebuild ALL database
        EXEC master.dbo.spX_RebuildIndexes_Main 
        @databasename ='',
        @maxfrag = 10.0,
        @maxdensity = 75.0,
        @online = 1,
        @runrebuild = 1,
        @LogUsedThresholdGB = 6,
        @maxruntime = 3600,
        @disklimit = '0.19',
        @notdisk1 = 'C',
        @notdisk2 = '',
        @notdisk3 = '',
        @notdisk4 = '',
        @maxdop	= 1
        The SP master.dbo.spX_RebuildIndexes is called by this main SP for each database.
        spX_RebuildIndexes will process one index at a time and then check if there is still
        time left based on the input parameter @maxruntime (in seconds) before processing the
        next index.
        
        The SP only runs on SQL 2005. 
        This SP rebuild and/or reorganizes all indexexs in the specified database or all databases.
        You can run this SP while users are using the database, if you specify @online = 1.
        If ONLINE, REBUILD WITH (ONLINE = ON, FILLFACTOR = 90) will be run if possible, else REORGANIZE. 
        These online options does not hold locks long term and thus will 
        not block running queries or updates. A relatively unfragmented index can be defragmented 
        faster than a new index can be built because the time to defragment is related to the amount 
        of fragmentation. A very fragmented index might take considerably longer to defragment than 
        to rebuild.  In addition, the defragmentation is always fully logged, regardless of the 
        database recovery model setting (see ALTER DATABASE). The defragmentation of a very 
        fragmented index can generate more log than even a fully logged index creation. 
        The defragmentation, however, is performed as a series of short transactions and thus does 
        not require a large log if log backups are taken frequently or if the recovery model setting
        is SIMPLE.
---------------------------------------------------------------------------------------------*/

DECLARE 
    @SSQLDEFRAG		VARCHAR(1024),
    @SSQLUSAGE 		VARCHAR(1024),
    @DBMode 		varchar(50),
    @StatusMsg 		nvarchar(max),
    @StatusSubject		nvarchar(255),
    @myresult 		int, 		--- Return value after check of disk space.
    @createshrinklog 	VARCHAR(1024),
    @runshrinklog 		VARCHAR(1024),
    @ifexists		INT,
    @startmain		datetime,
    @endmain		datetime,
    @mainduration		VARCHAR(200),
    @starteddate		datetime,
    @endeddate		datetime,
    @stepduration		VARCHAR(200),
    @estimatedready		datetime,
    @runtimecounter		INT,
    @returncode		int,
    @totalsecondspassed	int,
    @totalsecondsremaining	int,
    @myedition		varchar(50)

    SELECT @myedition = CONVERT(VARCHAR(50), SERVERPROPERTY('Edition'))
    PRINT '/*' + CHAR(13) + 'Current SQL Edition is ' + @myedition + ', ' + @@version + CHAR(13) + '*/'
    PRINT ''
    
    SELECT @totalsecondspassed = 0
    SELECT @totalsecondsremaining = @maxruntime
    SELECT @returncode = 0

BEGIN;
	IF @databasename <> '' -- Rebuild/reorganize one database
	BEGIN;
	    SELECT @ifexists = COUNT(name) FROM sys.sysdatabases where name = @databasename
	    IF @ifexists = 0
	    BEGIN;
		PRINT 'Database ' + @databasename + ' does not exist!'
		RETURN
	    END;
	    ELSE
		DECLARE  RebuildIndexes_Main_Cursor  CURSOR  FOR 
		SELECT name FROM sys.sysdatabases where name = @databasename
	END;
	ELSE		 
	    -- Rebuild/reorganize all databases
	    DECLARE  RebuildIndexes_Main_Cursor  CURSOR  FOR 
	    SELECT name FROM sys.sysdatabases 
	    where name not in('tempdb','master','model','msdb')
	    Order BY name ASC
END;

--- Print END time and duration time for main job.
BEGIN;
	SELECT @startmain = getdate()
	SELECT @estimatedready = DATEADD (ss ,@maxruntime,@startmain)
	PRINT '-- START OF INDEX DEFRAG FOR SERVER ' + @@SERVERNAME + ' AT ' + CONVERT (VARCHAR(20), getdate(), 120)
	PRINT '-- =========================================================================================='
	PRINT '-- MAX processing time allowed for all DBs is ' + CAST(@totalsecondsremaining AS VARCHAR(20)) + ' secs.'
	PRINT '-- Estimated time ready is no later than ' + CONVERT (VARCHAR(20), @estimatedready, 120) + '.'
	PRINT '-- MAX disk space limit set for transaction logg on processed DB is ' + cast((@LogUsedThresholdGB) AS VARCHAR(2)) + ' GB!'
	PRINT '-- MAXDOP used is ' + CAST(@maxdop AS VARCHAR(2))
END;

OPEN RebuildIndexes_Main_Cursor
FETCH NEXT FROM RebuildIndexes_Main_Cursor INTO @databasename
WHILE @@FETCH_STATUS=0
BEGIN;
	--Check Database Accessibility
	SELECT @DBMode = 'OK'
	IF (DATABASEPROPERTYEX(@databasename, 'Status') = N'ONLINE' 
	    AND DATABASEPROPERTYEX(@databasename, 'Updateability') = N'READ_WRITE'
	    AND DATABASEPROPERTYEX(@databasename, 'UserAccess') = N'MULTI_USER')
	    SELECT @DBMode = 'OK'
	ELSE
	    SELECT @DBMode = 'NOT AVAILABLE'
	
	IF @DBMode <> 'OK'
	BEGIN;			
	    SELECT @StatusSubject = N'Unable to rebuild/reorganize indexes'
	    SELECT @StatusMsg =  @StatusSubject + N' on ' + @databasename + N' on SQL Server ' + @@servername + CHAR(13) 
	    + N'The database is '  + @DBMode + N'!' + CHAR(13) 
	    + N'No rebuild/reorganize can be done on this database (not ONLINE, not READ_WRITE or not MULTI_USER).'
	    PRINT '-- ' + @StatusMsg
	    EXEC master.dbo.spX_SendDBMailOperator @StatusMsg, @StatusSubject
	END;
	ELSE
	BEGIN;			
		BEGIN;
			SELECT @starteddate = getdate()
			PRINT ''
			PRINT '-- START OF INDEX DEFRAG FOR DATABASE ' + @databasename + ' AT ' + CONVERT (VARCHAR(20), getdate(), 120)
			PRINT '-- ============================================================================================'
		END;

		BEGIN;
			-- Update table T_Disksize with info on currently available disk space.
			-- CODE SKIPPED IN ORDER TO KEEP IT SHORT: EXEC master.dbo.spF_check_size_server
			-- Check if disk space is low, i.e. space is < @disklimit on any disk but those exempted.
			-- CODE SKIPPED IN ORDER TO KEEP IT SHORT: EXEC master.dbo.spF_check_size_ok @disklimit,@notdisk1,@notdisk2,@notdisk3,@notdisk4,@ok = @myresult OUTPUT
			
			-- Quit if there is low disk space and send db mail to SQL operator(s).
			IF @myresult > 0 
			BEGIN;
				SELECT @StatusSubject = N'Index defrag processing stopped'
				SET @StatusMsg =  @StatusSubject + N' on ' + @@SERVERNAME + N', server is running out of disk space!'
				PRINT '-- ' + @StatusMsg
				EXEC master.dbo.spX_SendDBMailOperator @StatusMsg, @StatusSubject
				GOTO MAXTIMEOUT
			END;
		END;

		-- Return codes (@outparm): 0=OK, 1=Exit on Log Space Limit, 2=Exit on Time Limit, 3=Exit on Disk Space < 19% FREE, 4=Exit on Other Error
		EXEC master.dbo.spX_RebuildIndexes 
		@databasename, 
		@maxfrag, 
		@maxdensity, 
		@online, 
		@runrebuild, 
		@LogUsedThresholdGB, 
		@maxruntime, 
		@startmain, 
		@disklimit,
		@notdisk1,
		@notdisk2,
		@notdisk3,
		@notdisk4, 
		@maxdop, 
		@outparm = @returncode OUTPUT

		BEGIN;
			---Calculate time remaining in seconds
			SELECT @totalsecondsremaining = @maxruntime - DATEDIFF(ss, @startmain, getdate())
			SELECT @totalsecondspassed = DATEDIFF(ss, @startmain, getdate())
			SELECT @endeddate = getdate()
			PRINT '-- END OF INDEX DEFRAG FOR DATABASE ' + @databasename + ' AT ' + CONVERT (VARCHAR(20), getdate(), 120)
			PRINT '-- ============================================================================================'
			PRINT ''
			PRINT '-- Processing time for database ' + @databasename + ' was ' + Cast((DATEDIFF(ss, @starteddate, getdate())) as varchar(20)) + ' seconds.'
			PRINT '-- Total passed processing time is    ' + cast(@totalsecondspassed as varchar(20)) + ' seconds.'
			PRINT '-- Total estimated remaining max processing time is ' + cast(@totalsecondsremaining as varchar(20)) + ' seconds.'
			PRINT '-- Return code = ' + cast(@returncode as varchar(2))
		END;

		-- Return codes (@outparm): 0=OK, 1=Exit on Log Space Limit, 2=Exit on Time Limit, 3=Exit on Disk Space < 19% FREE, 4=Exit on Other Error
		IF 	@returncode = 0
			BEGIN;
				SELECT @StatusSubject = N'Index rebuild OK'
				SET @StatusMsg = N'Returned execution status for master.dbo.spX_RebuildIndexes after processing '  
				+ @databasename + N' on SQL Server ' + @@servername +  N' is ' + @StatusSubject + N'!'
				PRINT '-- ' + @StatusMsg
				-- EXEC master.dbo.spX_SendDBMailOperator @StatusMsg, @StatusSubject
			END;
		ELSE IF @returncode = 1
			BEGIN;
				SELECT @StatusSubject = 'Exit on Log Space Limit'
				SET @StatusMsg = N'Returned execution status for master.dbo.spX_RebuildIndexes after processing '  
				+ @databasename + N' on SQL Server ' + @@servername +  N' is ' + @StatusSubject + N'!'
				PRINT '-- ' + @StatusMsg
				EXEC master.dbo.spX_SendDBMailOperator @StatusMsg, @StatusSubject
			END;
		ELSE IF @returncode = 2
			BEGIN;  	
				SELECT @StatusSubject = 'Exit on Time Limit'
				SET @StatusMsg = N'Returned execution status for master.dbo.spX_RebuildIndexes after processing '  
				+ @databasename + N' on SQL Server ' + @@servername +  N' is ' + @StatusSubject + N'!'
				PRINT '-- ' + @StatusMsg
				EXEC master.dbo.spX_SendDBMailOperator @StatusMsg, @StatusSubject
				GOTO MAXTIMEOUT
			END;
		ELSE IF @returncode = 3
			BEGIN;  
				SELECT @StatusSubject = 'Exit on Disk Space'
				SET @StatusMsg = N'Returned execution status for master.dbo.spX_RebuildIndexes after processing '  
				+ @databasename + N' on SQL Server ' + @@servername +  N' is ' + @StatusSubject + N'!'
				PRINT '-- ' + @StatusMsg
				EXEC master.dbo.spX_SendDBMailOperator @StatusMsg, @StatusSubject
				GOTO MAXTIMEOUT
			END;
		ELSE IF @returncode = 4
			BEGIN;  
				SELECT @StatusSubject = 'Exit on Other Error'
				SET @StatusMsg = N'Returned execution status for master.dbo.spX_RebuildIndexes after processing '  
				+ @databasename + N' on SQL Server ' + @@servername +  N' is ' + @StatusSubject + N'!'
				PRINT '-- ' + @StatusMsg
				EXEC master.dbo.spX_SendDBMailOperator @StatusMsg, @StatusSubject
				GOTO MAXTIMEOUT
			END;
		ELSE
			BEGIN;  
				SELECT @StatusSubject = 'Unknown Exit Code'
				SET @StatusMsg = N'Returned execution status for master.dbo.spX_RebuildIndexes after processing '  
				+ @databasename + N' on SQL Server ' + @@servername +  N' is ' + @StatusSubject + N'!'
				PRINT '-- ' + @StatusMsg
				EXEC master.dbo.spX_SendDBMailOperator @StatusMsg, @StatusSubject
				GOTO MAXTIMEOUT
			END;

		IF @totalsecondsremaining <= 0
		BEGIN;
			SELECT @StatusSubject = 'Exit on Time Limit'
			SET @StatusMsg = N'Max time limit for master.dbo.spX_RebuildIndexes was exceeded' 
			+ N' on SQL Server ' + @@servername +  N', max time set is ' + RTRIM(CAST(@maxruntime AS VARCHAR(20))) + N' seconds!'
			PRINT '-- ' + @StatusMsg
			EXEC master.dbo.spX_SendDBMailOperator @StatusMsg, @StatusSubject
			GOTO MAXTIMEOUT
		END;
    	END;
    	FETCH NEXT FROM RebuildIndexes_Main_Cursor INTO @databasename
END;
MAXTIMEOUT:
CLOSE RebuildIndexes_Main_Cursor
DEALLOCATE RebuildIndexes_Main_Cursor

--- Print END; time and duration time for main job.
BEGIN;
	SELECT @endmain = getdate()
	PRINT ''
	SELECT @mainduration = '-- Total duration of index defrag for server ' + @@SERVERNAME + ' was '
		+ rtrim(cast(DATEDIFF(ss,@startmain,@endmain) as varchar(10))) + ' seconds.' 
	PRINT @mainduration
	PRINT '-- END OF INDEX DEFRAG FOR SERVER ' + @@SERVERNAME + ' AT ' + CONVERT (VARCHAR(20), getdate(), 120)
	PRINT '-- ============================================================================================'
END;
GO
USE master
GO
IF OBJECT_ID('spX_RebuildIndexes') IS NOT NULL
        DROP PROCEDURE dbo.spX_RebuildIndexes
GO
CREATE PROCEDURE dbo.spX_RebuildIndexes 
 @databasename		varchar(255)		-- The name of the database where indexes are to be processed
,@maxfrag		float			-- Only indexes with an avg fragmentation in percent > @maxfrag are inluded,    
,@maxdensity		float			-- OR tables with an avg page space used in percent < @maxdensity are included
,@online		bit			-- If 1, REBUILD WITH ONLINE = ON (Enterpise or Developer) or REORGANIZE, else REORGANIZE IF @currentfrag < 30 ELSE REBUILD
,@runrebuild		bit			-- If 1, REBUILD/REORGANIZE is executed, else code script is generated only 
,@LogUsedThresholdGB	int			-- Max size allowed for loggdb for current database in GB
,@maxruntime 		int			-- Max runtime in seconds for tho whole job
,@startmain 		datetime		-- datetime when the main job was started
,@disklimit 		char(4)='0.19'		-- Disk space limit for disks included in check
,@notdisk1 		char(1)='C'		-- Disk not included when checking disk space (no DBs should be on C)
,@notdisk2 		char(1)=''		-- Disk not included when checking disk space
,@notdisk3 		char(1)=''		-- Disk not included when checking disk space
,@notdisk4 		char(1)=''		-- Disk not included when checking disk space
,@maxdop		int = 0			-- Max degree of parallellism. 
						-- Note: Parallel index operations are available only in SQL Server 2005 Enterprise Edition.
						-- Manually configure the number of processors that are used to run the index statement by 
						-- specifying the MAXDOP index option and limiting the number of processors to use for the index operation.
						-- 0 uses the actual number of available CPUs depending on the current system workload. 
						-- This is the default value and recommended setting.		    
						-- 1 suppresses parallel plan generation. The operation will be executed serially.
						-- 2-64 limits the number of processors to the specified value. Fewer processors may be used depending on the current workload. If a value larger than the number of available CPUs is specified, the actual number of available CPUs is used. 
,@outparm 		int OUTPUT		-- Return codes (@outparm): 0=OK, 1=Exit on Log Space Limit, 2=Exit on Time Limit, 3=Exit on Disk Space < 19% FREE, 4=Exit on Other Error
AS
/*
NOTE: Only tables with more than 8 pages are considered for processing 
Examples:

DECLARE @returncode INT
EXEC master.dbo.spX_RebuildIndexes 'Order', 10.0, 75.0, 1, 1, 6, 10800, '2007-01-02 13:00', '0.19','C','','','', @outparm = @returncode OUTPUT
PRINT 'Return Code: ' + CAST(@returncode AS varchar(20))

DECLARE @returncode INT
EXEC master.dbo.spX_RebuildIndexes 'F0105', 10.0, 75.0, 1, 1, 4, 10800, '2007-01-02 13:00', '0.19','C','','','', @outparm = @returncode OUTPUT
PRINT 'Return Code: ' + CAST(@returncode AS varchar(20))

DECLARE @returncode INT
EXEC master.dbo.spX_RebuildIndexes 'master', 10.0, 75.0, 1, 1, 4, 10800, '2007-01-02 11:33', '0.19','C','','','', @outparm = @returncode OUTPUT
PRINT 'Return Code: ' + CAST(@returncode AS varchar(20))
*/
SET NOCOUNT ON;
DECLARE 
 @schemaname		    sysname
,@objectname		    sysname
,@indexname		    sysname
,@tableid		    int
,@indexid		    int
,@currentfrag		    float
,@currentdensity	    float
,@partitionnum		    varchar(10)
,@partitioncount	    bigint
,@indextype		    varchar(18)
,@command		    nvarchar(4000)
,@myedition		    varchar(50)
,@myrebuildoption	    nvarchar(500)
,@myreorganizeoption	    nvarchar(500)
,@lob_count		    int
,@sqllob_count		    nvarchar(500)
,@parmlob_count		    nvarchar(50)
,@mydisabledindex	    bit
,@parmmydisabledindex	    nvarchar(50)
,@sqlmydisabledindex	    nvarchar(500)
,@pagelocksnotallowedcount	    int
,@parmmyallowpagelocks	    nvarchar(50)
,@sqlmyallowpagelocks	    nvarchar(500)
,@rowlocksnotallowedcount	    int
,@parmmyallowrowlocks	    nvarchar(50)
,@sqlmyallowrowlocks	    nvarchar(500)
,@myindexishypotetical	    bit
,@parmmyindexishypotetical  nvarchar(50)
,@sqlmyindexishypotetical   nvarchar(500)
,@countprocessed	    int
,@onofflinemess		    varchar(50)
,@myservicename		    varchar(100)
,@returncode		    int
,@runtimecounter 	    int
,@myresult 		    int
,@myoutputmessage	    nvarchar(4000)
,@rc			    int
,@StatusMsg 		    nvarchar(max)
,@StatusSubject		    nvarchar(255)
,@mycode		    nvarchar(max)
,@activeconnectionsindb	    smallint
,@onlineedition		    bit
,@RecoveryMode 		    varchar(128)
,@RecoveryModeOld 	    varchar(128)
,@altdbbefore		    nvarchar(200)
,@altdbafter		    nvarchar(200)
,@dbStatusMsg 		    varchar(1024)

-- Alter recovery model from FULL (full recovery model) to BULK_LOGGED (bulk logged model).
-- This is done BEFORE reindexing in order to minimize growth of the transaction log.
-- Check database recovery model and change it to BULK_LOGGED if FULL or SIMPLE.
SELECT @RecoveryMode = cast(DATABASEPROPERTYEX(@databasename, 'Recovery') as varchar(20))
SELECT @RecoveryModeOld = @RecoveryMode
IF @RecoveryMode <> 'BULK_LOGGED'
BEGIN;
	SELECT @altdbbefore = N'ALTER DATABASE [' + @databasename + N'] SET RECOVERY BULK_LOGGED; '
	IF @runrebuild = 1
	BEGIN; 
	    EXEC(@altdbbefore)
	    SELECT @dbStatusMsg = '-- Recovery model for database ' + @databasename + ' was changed to BULK_LOGGED from '  + @RecoveryModeOld + ' recovery mode.'
	    PRINT @dbStatusMsg
	END;
	ELSE
	BEGIN;
	    SELECT @dbStatusMsg = '-- Recovery model for database ' + @databasename + ' is now changed to BULK_LOGGED from '  + @RecoveryModeOld + ' recovery mode.'
	    PRINT @dbStatusMsg
	END;		
END;
ELSE SELECT @altdbbefore = N''

-- Check SQL Edition in order to set possible rebuild options
SELECT @myedition = CONVERT(VARCHAR(50), SERVERPROPERTY('Edition'))
IF (@myedition LIKE 'Developer Edition%' OR @myedition LIKE 'Enterprise Edition%') 
SET @onlineedition = 1 ELSE SET @onlineedition = 0

-- Get service name of current SQL Server - used for getting performance counter.
SELECT @myservicename = 'MSSQL$' + @@SERVICENAME + ':Databases'

-- Print On- or offline message
IF  @online = 1 SET @onofflinemess = 'ONLINE (users allowed)'
ELSE SET @onofflinemess = 'OFFLINE (no users allowed)'
-- Notify if code is generated only or executed.
IF @runrebuild = 0 PRINT '-- Execute the following code ' + @onofflinemess + ' to rebuild and/or reorganize indexes in database ' 
		    + @databasename + ' for better performance!'
ELSE PRINT '-- Rebuild and/or reorganization ' + @onofflinemess + ' of indexes in database ' + @databasename + ' will now be executed!'

SET @lob_count = 0
SET @mydisabledindex = 0
SET @pagelocksnotallowedcount = 0
SET @myindexishypotetical = 0
SET @countprocessed = 0
SET @outparm = 0
SET @myresult = 0
SET @rc = 0
SET @currentfrag = 0.0
SET @mycode = N''

-- Ensure the temporary work table does not exist, then create it.
IF EXISTS (SELECT name FROM sys.objects WHERE name = '#work_to_do')
    DROP TABLE #work_to_do;

CREATE TABLE #work_to_do(
 IndexID		int not null
,IndexName		varchar(255) null
,TableName		varchar(255) null
,TableID		int not null
,SchemaName		varchar(255) null
,IndexType		varchar(18) not null
,PartitionNumber	varchar(18) not null
,PartitionCount		int null
,CurrentDensity		float not null
,CurrentFragmentation	float not null
);

INSERT INTO #work_to_do(
	IndexID, TableID, IndexType, PartitionNumber, CurrentDensity, CurrentFragmentation
	)
	SELECT
		fi.index_id 
		,fi.object_id 
		,fi.index_type_desc AS IndexType
		,cast(fi.partition_number as varchar(10)) AS PartitionNumber
		,fi.avg_page_space_used_in_percent AS CurrentDensity
		,fi.avg_fragmentation_in_percent AS CurrentFragmentation
	FROM sys.dm_db_index_physical_stats(db_id(@databasename), NULL, NULL, NULL, 'SAMPLED') AS fi -- Ändra ev till LIMITED
	WHERE	(fi.avg_fragmentation_in_percent > @maxfrag 
	OR	fi.avg_page_space_used_in_percent < @maxdensity)
	AND	page_count> 8
	AND	fi.index_id > 0

-- Assign the index names, schema names, table names and partition counts.
EXEC ('UPDATE #work_to_do SET TableName = t.name, SchemaName = s.name, IndexName = i.Name 
	,PartitionCount = (SELECT COUNT(*) pcount
	FROM [' 
	+ @databasename + '].sys.partitions p
	where  p.object_id = w.TableID 
	AND p.index_id = w.Indexid)
	FROM [' 
	+ @databasename + '].sys.tables t INNER JOIN ['
	+ @databasename + '].sys.schemas s ON t.schema_id = s.schema_id 
	INNER JOIN #work_to_do w ON t.object_id = w.tableid INNER JOIN ['
	+ @databasename + '].sys.indexes i ON w.tableid = i.object_id and w.indexid = i.index_id');

-- Declare the cursor for the list of tables, indexes and partitions to be processed.
-- If the index is a clustered index, rebuild all of the nonclustered indexes for the table.
-- If we are rebuilding the clustered indexes for a table, we can exclude the nonclustered and specify ALL instead on the table.

IF Cursor_Status('LOCAL', 'Local_Rebuildindex_Cursor') >= 0
BEGIN
	CLOSE Local_Rebuildindex_Cursor
	DEALLOCATE Local_Rebuildindex_Cursor
END

DECLARE Local_Rebuildindex_Cursor CURSOR LOCAL FOR 
	SELECT 
	 IndexID
	,TableID	
	,CASE WHEN IndexType = 'Clustered Index' THEN 'ALL' ELSE IndexName END AS IndexName
	,TableName
	,SchemaName
	,IndexType
	,PartitionNumber
	,PartitionCount
	,CurrentDensity
	,CurrentFragmentation
	FROM	#work_to_do i 
	WHERE	NOT EXISTS(
			SELECT	1 
			FROM	#work_to_do iw 
			WHERE	iw.TableName = i.TableName 
			AND	iw.IndexType = 'CLUSTERED INDEX' 
			AND	i.IndexType = 'NONCLUSTERED INDEX')
	ORDER BY TableName, IndexID;

-- Open the cursor.
OPEN Local_Rebuildindex_Cursor;

-- Loop through the tables, indexes and partitions.
FETCH NEXT
   FROM Local_Rebuildindex_Cursor
   INTO @indexid, @tableid, @indexname, @objectname, @schemaname, @indextype, @partitionnum, @partitioncount, @currentdensity, @currentfrag;

WHILE @@FETCH_STATUS = 0
BEGIN;
    -- Check if there has been any activity (reads and/or writes) in this database for the last 15 minutes.
    EXEC master.dbo.spX_check_activeconnections
     @inputdb = @databasename
    ,@activelastminutes = 15
    ,@outparm = @activeconnectionsindb OUTPUT

    -- SET INDEX OPTIONS FOR CURRENT INDEX DEPENDING ON IF REBUILD ON LINE IS POSSIBLE OR NOT.
    -- Only Developer and Enterprise allows REBUILD WITH (ONLINE = ON).
    -- SET REBUILD AND REORGANIZE OPTION:
    -- ======================================================================================
    IF @online = 1
    BEGIN;
	-- If online is required for Std Ed, reorganize is the only option
	IF @onlineedition = 1
	BEGIN;
	    SET @myrebuildoption = N' REBUILD WITH (ONLINE = ON, FILLFACTOR = 90, MAXDOP = ' + CAST(@maxdop AS VARCHAR(2)) + N') '
	    -- Changed ONLINE to always mean REBUILD WITH ONLINE, if needed, except for LOBs.
	    -- LOBS are REORGANIZED, if ONLINE is specified.
	    -- SET @myrebuildoption = N' REORGANIZE '
	    SET @myreorganizeoption = N' REORGANIZE '
	END;
	ELSE
	BEGIN; 
	    SET @myrebuildoption =   N' REORGANIZE '
	    SET @myreorganizeoption = N' REORGANIZE '
	END;
    END;
    ELSE
    BEGIN;
	-- Even if offline is specified, this code checks if there has been active connections for the last 15 minutes
	-- and if this is the case and code execution is specified, the options used will be adapted to what is possible.
	IF @activeconnectionsindb > 0
	BEGIN;
	    IF (@onlineedition = 0 AND @runrebuild = 1) 
		SET @myrebuildoption =   N' REORGANIZE '
	    IF (@onlineedition = 0 AND @runrebuild = 1)
		SET @myreorganizeoption = N' REORGANIZE '
	    IF (@onlineedition = 0 AND @runrebuild = 0) 
		SET @myrebuildoption = N' REBUILD WITH (FILLFACTOR = 90) '
	    IF (@onlineedition = 0 AND @runrebuild = 0) 
		SET @myreorganizeoption = N' REORGANIZE '

	    IF (@onlineedition = 1 AND @runrebuild = 1) 
		SET @myrebuildoption = N' REBUILD WITH (ONLINE = ON, FILLFACTOR = 90, MAXDOP = ' + CAST(@maxdop AS VARCHAR(2)) + N') '
	    IF (@onlineedition = 1 AND @runrebuild = 1) 
		SET @myreorganizeoption = N' REORGANIZE '
	    IF (@onlineedition = 1 AND @runrebuild = 0) 
		SET @myrebuildoption = N' REBUILD WITH (FILLFACTOR = 90, MAXDOP = ' + CAST(@maxdop AS VARCHAR(2)) + N') '
	    IF (@onlineedition = 1 AND @runrebuild = 0) 
		SET @myreorganizeoption = N' REORGANIZE '
	END;
	ELSE
	BEGIN; 
	    SET @myrebuildoption =  N' REBUILD WITH (FILLFACTOR = 90, MAXDOP = ' + CAST(@maxdop AS VARCHAR(2)) + N') '
	    SET @myreorganizeoption = N' REORGANIZE '
	END;
    END;

    -- Check size of loggdb in GB for current database - if low, RETURN.
    IF
    (SELECT cntr_value/1000000 from sys.dm_os_performance_counters
    WHERE
    object_name = @myservicename
    AND instance_name = @databasename
    AND counter_name = 'Log File(s) Used Size (KB)'
    ) 
    > @LogUsedThresholdGB
    BEGIN;
	SELECT @outparm = 1
	PRINT 'Stopped index rebuild/reorganize for database ' + @databasename 
	+ ' on SQL Server ' + @@SERVERNAME +  CHAR(13) 
	+ ', exit on log space limit ' + cast(@LogUsedThresholdGB as varchar(10)) + ' GB!'
	GOTO CODEEXIT
    END;
    ELSE SELECT @outparm = 0

    -- Now check timer restrictions IN SECONDS set on job by the call from the main SP.	
    SELECT @runtimecounter = DATEDIFF(ss, @startmain, getdate())
    -- Return codes (@outparm): 0=OK, 1=Exit on Log Space Limit, 2=Exit on Time Limit, 3=Exit on Disk Space < 19% FREE, 4=Exit on Other Error
    IF (@runtimecounter > @maxruntime)
    BEGIN;
	SELECT @outparm = 2
	PRINT 'Processing stopped for SQL Server ' + @@SERVERNAME + CHAR(13) 
	+ ', time limit reached was ' + RTRIM(CAST(@runtimecounter AS VARCHAR(20))) 
	+ ', time allowed was ' + RTRIM(CAST(@maxruntime AS VARCHAR(20)))
	GOTO CODEEXIT
    END;
    ELSE SELECT @outparm = 0

    -- Update table T_Disksize with info on currently available disk space.
    -- CODE SKIPPED IN ORDER TO KEEP IT SHORT: EXEC master.dbo.spF_check_size_server
    -- Check if disk space is low, i.e. space is < @disklimit on any disk but those exempted.
    -- CODE SKIPPED IN ORDER TO KEEP IT SHORT: EXEC master.dbo.spF_check_size_ok @disklimit,@notdisk1,@notdisk2,@notdisk3,@notdisk4,@ok = @myresult OUTPUT
    -- EXIT IF DISK SPACE IS LOW!
    IF @myresult > 0 
    BEGIN;
	-- Return codes (@outparm): 0=OK, 1=Exit on Log Space Limit, 2=Exit on Time Limit, 3=Exit on Disk Space < 19% FREE, 4=Exit on Other Error
	SELECT @outparm = 3
	PRINT 'Processing stopped for SQL Server ' + @@SERVERNAME + CHAR(13) 
	+ ', exit on disk space limit < ' +  CAST(@disklimit as varchar(10)) +  ' % free!'
	GOTO CODEEXIT
    END;
    ELSE SELECT @outparm = 0

    -- Check if index is DISABLED, then do not process it, print message.
    SET @parmmydisabledindex = N'@pmydisabledindex bit output'
    SET @sqlmydisabledindex = N'SELECT @pmydisabledindex = is_disabled '
    + N' FROM [' + @databasename + '].sys.indexes '
    + N' WHERE object_id = ' + cast(@tableid as varchar(50)) 
    + N' AND index_id = ' + cast(@indexid as varchar(50))
    EXECUTE sp_executesql @sqlmydisabledindex, @parmmydisabledindex, @pmydisabledindex = @mydisabledindex output

    -- Check if ANY table index exists that does not allow ROW LOCKS, 
    -- including only those not hypothetical and not disabled,
    -- Do not process ANY INDEX FOR THIS TABLE IF ROW LOCKS IS NOT ALLOWED.
    -- Print message and proceed to next.
    -- This SP requires that you always allow row-level locking!
    -- MS: "By default, SQL Server makes a choice of page-level, row-level, or table-level locking. 
    -- When cleared, the index does not use row-level locking. By default, this check box is selected. 
    -- This option is only available for SQL Server 2005 indexes. 
    -- This option will reduce the chance of temporarily blocking other users, but it can slow down index maintenance actions."
    -- It is usually better to let SQL Server manage the locking behavior.
    SET @parmmyallowrowlocks = N'@xrowlocksnotallowedcount int output'
    SET @sqlmyallowrowlocks = N'SELECT @xrowlocksnotallowedcount = COUNT(allow_row_locks) '
    + N' FROM [' + @databasename + '].sys.indexes '
    + N' WHERE object_id = ' + cast(@tableid as varchar(50)) 
    + N' AND allow_row_locks = 0 '
    + N' AND is_hypothetical = 0 '
    + N' AND is_disabled = 0 '
    EXECUTE sp_executesql @sqlmyallowrowlocks, @parmmyallowrowlocks, @xrowlocksnotallowedcount = @rowlocksnotallowedcount output
    IF @rowlocksnotallowedcount > 0 PRINT N'-- NOTE: Row locks not allowed on object_id = ' + cast(@tableid as varchar(50)) + N', table ' + @objectname + N', index ' + @indexname

    -- Check if ANY table index exists that does not allow PAGE LOCKS, 
    -- including only those not hypothetical and not disabled.
    -- Do not process ANY INDEX FOR THIS TABLE IF PAGE LOCKS IS NOT ALLOWED.
    -- Print message and proceed to next.
    -- This SP requires that you always allow page-level locking!
    -- MS: "By default, SQL Server makes a choice of page-level, row-level, or table-level locking. 
    -- By default, SQL Server makes a choice of page-level, row-level, or table-level locking. 
    -- When cleared, the index does not use page-level locking. By default, this check box is selected. 
    -- This option is only available for SQL Server 2005 indexes. 
    -- This option will reduce the chance of temporarily blocking other users, but it can slow down index maintenance actions."
    -- It is usually better to let SQL Server manage the locking behavior.
    SET @parmmyallowpagelocks = N'@xpagelocksnotallowedcount int output'
    SET @sqlmyallowpagelocks = N'SELECT @xpagelocksnotallowedcount = COUNT(allow_page_locks) '
    + N' FROM [' + @databasename + '].sys.indexes '
    + N' WHERE object_id = ' + cast(@tableid as varchar(50)) 
    + N' AND allow_page_locks = 0 '
    + N' AND is_hypothetical = 0 '
    + N' AND is_disabled = 0 '
    EXECUTE sp_executesql @sqlmyallowpagelocks, @parmmyallowpagelocks, @xpagelocksnotallowedcount = @pagelocksnotallowedcount output
    IF @pagelocksnotallowedcount > 0 PRINT N'-- NOTE: Page locks not allowed on object_id = ' + cast(@tableid as varchar(50)) + N', table ' + @objectname + N', index ' + @indexname

    -- Check if index is hypotetical, then do not process it
    SET @parmmyindexishypotetical = N'@pmyindexishypotetical bit output'
    SET @sqlmyindexishypotetical = N'SELECT @pmyindexishypotetical = is_hypothetical '
    + N' FROM [' + @databasename + '].sys.indexes '
    + N' WHERE object_id = ' + cast(@tableid as varchar(50)) 
    + N' AND index_id = ' + cast(@indexid as varchar(50))
    EXECUTE sp_executesql @sqlmyindexishypotetical, @parmmyindexishypotetical, @pmyindexishypotetical = @myindexishypotetical output
 
    -- Check if this table contains LOB_DATA; if so, always do a REORGANIZE; REBUILD WITH (ONLINE = ON) is not allowed
    SET @parmlob_count = N'@plob_count INT output'
    SET @sqllob_count = N'SELECT @plob_count = COUNT(alloc_unit_type_desc) '
    + N' FROM sys.dm_db_index_physical_stats (DB_ID(''' + @databasename + '''), NULL, NULL , NULL, ''LIMITED'') '
    + N' WHERE object_id = ' + cast(@tableid as varchar(50)) 
    + N' AND alloc_unit_type_desc = ''LOB_DATA'''
    EXECUTE sp_executesql @sqllob_count, @parmlob_count, @plob_count = @lob_count output

    -- ALWAYS SET TO REORGANIZE option for LOBs, if ONLINE IS REQUIRED - they can not be rebuilt online.
    -- LOB Online:
    IF (@lob_count > 0 AND @online = 1)
	SET @myrebuildoption = N' REORGANIZE '
    -- LOB Offline specified, but active users
    IF (@lob_count > 0 AND @online = 0 AND @runrebuild = 1 AND @activeconnectionsindb > 0) 
	SET @myrebuildoption = N' REORGANIZE '
    -- SQL Enterprise Edition,LOB Offline specified and no active users
    IF (@lob_count > 0 AND @online = 0 AND @runrebuild = 1 AND @activeconnectionsindb = 0 AND @onlineedition = 1) 
	SET @myrebuildoption = N' REBUILD WITH (FILLFACTOR = 90, MAXDOP = ' + CAST(@maxdop AS VARCHAR(2)) + N') '
    -- SQL Standard Edition,LOB Offline specified and no active users
    IF (@lob_count > 0 AND @online = 0 AND @runrebuild = 1 AND @activeconnectionsindb = 0 AND @onlineedition = 0) 
	SET @myrebuildoption = N' REBUILD WITH (FILLFACTOR = 90) '

    -- If index is disabled (1) OR pagelocks is not allowed (0) OR index is hypotetical (1), then do not process!
    IF (@mydisabledindex = 1 OR @rowlocksnotallowedcount > 0 OR @pagelocksnotallowedcount > 0 OR @myindexishypotetical = 1)
     -- Send a message for indexes not processed! 
    BEGIN;
	PRINT '-- Index ' + @indexname + ' for table ' + @schemaname + '.' + @objectname + ' is disabled or hypotetical or has index row/page locking disabled!'
	SELECT @StatusMsg = N'Skipped index for table ' + @schemaname + '.' + @objectname + N', index ' + @indexname
		+ N' partition ' + cast(@partitionnum as varchar(10)) + N', avg frag in percent ' + cast(@currentfrag as varchar(50)) 
		+ N', avg page space used in percent ' + cast(@currentdensity as varchar(50)) + N'.' 
		+ N' Index ' + @indexname + N' is disabled or hypotetical or has index row/page locking disabled!'
	SELECT @StatusSubject = N'Skipped index on ' + @@servername
	EXEC master.dbo.spX_SendDBMailOperator @StatusMsg, @StatusSubject
	GOTO NEXTINDEX
    END;
    ELSE
    BEGIN;
	-- If the index is more heavily fragmented, issue a REBUILD, if ONLINE is required and possible.  
	-- Otherwise, REORGANIZE.
	IF @currentfrag < 30
	BEGIN;
		IF @indexname = 'ALL' SELECT @command = N'ALTER INDEX ' + @indexname + N' ON [' + @databasename + N'].[' + @schemaname + N'].[' + @objectname + N']' + @myreorganizeoption;
		ELSE SELECT @command = N'ALTER INDEX [' + @indexname + N'] ON [' + @databasename + N'].[' + @schemaname + N'].[' + @objectname + N']' + @myreorganizeoption;
		IF @partitioncount > 1 AND @indexname <> 'ALL'  SELECT @command = @command + N' PARTITION = ' + @partitionnum  + ';';
		ELSE SET @command = @command  + ';'
		IF @runrebuild = 1 exec @rc = sp_executesql @command
		IF @runrebuild = 0 SET @mycode = @mycode + N' ' + @command
		IF @rc <> 0
		BEGIN;
		    SELECT @outparm = 4
		    PRINT 'Stopped index rebuild/reorganize for database ' + @databasename + ' on SQL Server ' + @@SERVERNAME +  CHAR(13) 
		    + ', exit on error when executing command ' + @command + ' !'
		    GOTO CODEEXIT
		END;
		ELSE SELECT @outparm = 0
	END;

	IF @currentfrag >= 30
	BEGIN;
		IF @indexname = 'ALL' SELECT @command = N'ALTER INDEX ' + @indexname + N' ON [' + @databasename + N'].[' + @schemaname + N'].[' + @objectname + N']' + @myreorganizeoption;
		ELSE SELECT @command = N'ALTER INDEX [' + @indexname + N'] ON [' + @databasename + N'].[' + @schemaname + N'].[' + @objectname + N']' + @myreorganizeoption;
		IF @partitioncount > 1 AND @indexname <> 'ALL'  SELECT @command = @command + N' PARTITION = ' + @partitionnum;
		ELSE SET @command = @command  + ';'
		IF @runrebuild = 1 exec @rc = sp_executesql @command
		IF @runrebuild = 0 SET @mycode =  @mycode + N' ' + @command
		IF @rc <> 0
		BEGIN;
		    SELECT @outparm = 4
		    PRINT 'Stopped index rebuild/reorganize for database ' + @databasename + ' on SQL Server ' + @@SERVERNAME +  CHAR(13) 
		    + ', exit on error when executing command ' + @command + ' !'
		    GOTO CODEEXIT
		END;
		ELSE SELECT @outparm = 0
	END;
	PRINT ''

	IF @lob_count > 0
	BEGIN;
	    IF @indexid = 1 PRINT '-- Processing LOB table ' + @schemaname + '.' + @objectname + ', CLUSTERED index ' + @indexname + ', ' + CHAR(13) 
			    + '-- partition ' + cast(@partitionnum as varchar(10)) + ', avg frag in percent ' + cast(@currentfrag as varchar(50)) 
			    + ', avg page space used in percent ' + cast(@currentdensity as varchar(50))
	    ELSE PRINT '-- Processing LOB table ' + @schemaname + '.' + @objectname + ', STANDARD index ' + @indexname + ', ' + CHAR(13) 
			    + '-- partition ' + cast(@partitionnum as varchar(10)) + ', avg frag in percent ' + cast(@currentfrag as varchar(50)) 
			    + ', avg page space used in percent ' + cast(@currentdensity as varchar(50))
	END;
	ELSE
	BEGIN;
	    IF @indexid = 1 PRINT '-- Processing STANDARD table ' + @schemaname + '.' + @objectname + ', CLUSTERED index ' + @indexname + ', ' + CHAR(13) 
			    + '-- partition ' + cast(@partitionnum as varchar(10)) + ', avg frag in percent ' + cast(@currentfrag as varchar(50)) 
			    + ', avg page space used in percent ' + cast(@currentdensity as varchar(50))
	    ELSE PRINT '-- Processing STANDARD table ' + @schemaname + '.' + @objectname + ', STANDARD index ' + @indexname + ', ' + CHAR(13) 
			    + '-- partition ' + cast(@partitionnum as varchar(10)) + ', avg frag in percent ' + cast(@currentfrag as varchar(50)) 
			    + ', avg page space used in percent ' + cast(@currentdensity as varchar(50))
	END;
	SET @countprocessed = @countprocessed + 1
	IF @runrebuild = 1 PRINT '-- Executed: ' + @command;
	ELSE PRINT '-- Code to be executed: ' + CHAR(13) + @command;
    END;
    NEXTINDEX:
    FETCH NEXT FROM Local_Rebuildindex_Cursor INTO @indexid, @tableid, @indexname, @objectname, @schemaname, @indextype, @partitionnum, @partitioncount, @currentdensity, @currentfrag;
END;
PRINT ''

IF @countprocessed = 0 
BEGIN;
    SET @StatusMsg = N'No indexes needed rebuilding in database ' + @databasename
    SET @StatusSubject = N'Index rebuild on ' + @@servername
    IF @runrebuild = 0 EXEC master.dbo.spX_SendDBMailOperator @StatusMsg, @StatusSubject
    PRINT '-- No indexes needed rebuilding in database ' + @databasename
END;
ELSE
BEGIN;
    SET @StatusSubject = N'Code for index rebuild '  + @onofflinemess + ' on ' + @@servername + N' in database ' + @databasename
    IF @runrebuild = 0
    BEGIN;
	SELECT @RecoveryMode = cast(DATABASEPROPERTYEX(@databasename, 'Recovery') as varchar(20))
	IF @RecoveryMode <> 'BULK_LOGGED' SELECT @altdbafter = N' ALTER DATABASE [' + @databasename + N'] SET RECOVERY ' + @RecoveryModeOld + N'; ' 
	ELSE SELECT @altdbafter = N''
	SELECT @mycode = @altdbbefore + @mycode + @altdbafter
	EXEC master.dbo.spX_SendDBMailOperator @mycode, @StatusSubject
    END;
    IF @runrebuild = 1 PRINT '-- ' + cast(@countprocessed as varchar(20)) + ' indexes where reorganized or rebuilt!'
    ELSE	PRINT '-- Code for reorganize and/or rebuild of ' + cast(@countprocessed as varchar(20)) + ' indexes was generated!'
END;

CODEEXIT:

--- Alter recovery model BACK TO original after reindexing.
--- Check database recovery model and change it to original if needed.
SELECT @RecoveryMode = cast(DATABASEPROPERTYEX(@databasename, 'Recovery') as varchar(20))
IF @RecoveryMode <> @RecoveryModeOld
BEGIN;
	SELECT @altdbafter = N'ALTER DATABASE [' + @databasename + N'] SET RECOVERY ' + @RecoveryModeOld + N'; '
	IF @runrebuild = 1
	BEGIN; 
	    EXEC(@altdbafter)
	    SELECT @dbStatusMsg =  '-- Recovery model for database ' + @databasename + ' was set back to original ' + @RecoveryModeOld + ' from ' + @RecoveryMode + ' recovery mode.'
	    PRINT @dbStatusMsg
	END;
	ELSE
	BEGIN;
	    SELECT @dbStatusMsg = '-- Recovery model for database ' + @databasename + ' is now set back to original ' + @RecoveryModeOld + ' from ' + @RecoveryMode + ' recovery mode.'
	    PRINT @dbStatusMsg
	END;		
END;
ELSE SELECT @altdbafter = N''
-- Close and deallocate the cursor.
CLOSE Local_Rebuildindex_Cursor;
DEALLOCATE Local_Rebuildindex_Cursor;
GO
USE master
GO

IF OBJECT_ID('spX_SendDBMailOperator') IS NOT NULL
        DROP PROCEDURE spX_SendDBMailOperator
GO
CREATE procedure dbo.spX_SendDBMailOperator 
 @inputmessage 	nvarchar(max) 	= N''
,@mysubject 	nvarchar(255)	= N''
as
--- SQL 2005 only!
--- This SP sends DB Mail to all SQL Server Operators on a server.
--- Message can be very large.
--- Default subject is 'Message from SQL Server ' + @@SERVERNAME
--- Default message is 'This is a test message!'
--- Exemple:
--- EXEC master.dbo.spX_SendDBMailOperator 'Test - message from SQL Server!','My test'

if @mysubject = '' set @mysubject = N'Message from SQL Server ' + @@SERVERNAME
if @inputmessage = '' set @inputmessage = N'This is a test message!'

DECLARE 
 @rc 			int
,@myfromname 		nvarchar(500)
,@mytoname 		nvarchar(4000)
,@myrecipients		VARCHAR(100)
,@mycurrentaddres 	VARCHAR(1024)
,@alladdresses 		NVARCHAR(1024)
,@mailaddress 		varchar (200)
,@mylogmessage		nvarchar(255)

SET NOCOUNT ON

-- Name of current sender
SET @myfromname = N'Message from SQL Server ' + @@servername

-- Get e-mail adresses of operators
BEGIN
	SET @alladdresses = N''
	DECLARE  MAILResults_CURSOR CURSOR FORWARD_ONLY READ_ONLY FOR 
		 SELECT email_address FROM msdb.dbo.sysoperators WITH (NOLOCK) where email_address IS NOT NULL
	OPEN MAILResults_CURSOR
	FETCH NEXT FROM MAILResults_CURSOR INTO @myrecipients
	WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @mycurrentaddres = @myrecipients + CHAR(59)
			SET @alladdresses = @alladdresses + @mycurrentaddres
			FETCH NEXT FROM MAILResults_CURSOR INTO @myrecipients
		END
	CLOSE MAILResults_CURSOR
	DEALLOCATE MAILResults_CURSOR
	IF @alladdresses = N'' SET @alladdresses = N'dba@mycompany.com'
END

EXEC @rc = msdb.dbo.sp_send_dbmail
 @profile_name = NULL
,@recipients = @alladdresses
,@copy_recipients = NULL
,@blind_copy_recipients = NULL
,@subject = @mysubject
,@body = @inputmessage
,@body_format = 'TEXT'
,@importance = 'Normal'
,@sensitivity = 'Normal'
,@file_attachments = NULL
,@query = NULL
,@execute_query_database = 'master'
,@attach_query_result_as_file = 0
,@query_attachment_filename = NULL
,@query_result_header = 0
,@query_result_width = 256
,@query_result_separator = ' '
,@exclude_query_output = 0
,@append_query_error = 1
,@query_no_truncate = 0

-- Logga till eventloggen om mail har skickats eller inte!
IF @rc = 0 	
BEGIN 
	PRINT 'Mail ' + CHAR(39) + @mysubject + CHAR(39) + ' was sent to ' 
	+ @alladdresses + ' at ' + convert(varchar(30),getdate(),120)
	GOTO normalEXIT 
END
ELSE 
BEGIN 
	PRINT 'Mail ' + CHAR(39) + @mysubject + CHAR(39) + ' to ' 
	+ @alladdresses + ' failed delivery at ' + convert(varchar(30),getdate(),120)
	GOTO failureEXIT 
END

failureEXIT:
BEGIN
	SET @mylogmessage = 
	N'Error - database mail (sp_send_dbmail) could not be sent from SQL Server ' 
	+ @@servername + ' at ' + convert(varchar(30),getdate(),120) + 
	N'. This is an error message!' 
	exec master..sp_addmessage
	 @msgnum = 65556 
   	,@severity = 16
    	,@msgtext = @mylogmessage
        ,@with_log = 'true' 
        ,@replace = 'replace' 
	EXEC master..xp_logevent 65556, @mylogmessage, 'ERROR'
	RAISERROR(65556,16,1)
	RETURN -1
END

normalEXIT:
BEGIN
	SET @mylogmessage = 
	N'Informational - database mail (sp_send_dbmail) was sent from SQL Server ' 
	+ @@servername + ' at ' + convert(varchar(30),getdate(),120) + 
	N'. This is an information message.' 
	EXEC master..xp_logevent 65555, @mylogmessage, 'INFORMATIONAL'
	RETURN
END
GO
use master
go
IF OBJECT_ID('spX_check_activeconnections') IS NOT NULL
        DROP PROCEDURE dbo.spX_check_activeconnections
GO
CREATE PROCEDURE dbo.spX_check_activeconnections 
 @inputdb		varchar(100)
,@activelastminutes	int 
,@outparm		int OUTPUT
AS
/*
Get number of currently active connections.
0 means no active connections in selected database!
This sp is used to check active conenctions in SQL 2005, before running maintenance operations.
Example:
DECLARE @returncode smallint
EXEC master.dbo.spX_check_activeconnections
 @inputdb = 'AdventureWorks'
,@activelastminutes = 10
,@outparm = @returncode OUTPUT
*/
SET QUOTED_IDENTIFIER OFF

DECLARE 
 @sqlstring	    nvarchar (512)
,@database_name	    varchar(100)
,@mydbid	    smallint
,@sqlparm	    nvarchar(100)
,@numproc	    int

SET @database_name = @inputdb
SELECT @mydbid = DB_ID(@database_name)
SET NOCOUNT ON
SET @sqlparm = N'@pnumproc INT output'
SET @numproc = 0

-- Do an active conenctions count on server for this database
SELECT @sqlstring = N'select @pnumproc = count(session_id) 
from sys.dm_exec_connections as ec with (nolock) inner join
sys.sysprocesses as sp with (nolock) on ec.session_id = sp.spid
where ec.session_id <> ' + cast(@@SPID as varchar(10)) +
N' and DATEDIFF(minute, ec.last_read, GETDATE()) < ' + cast(@activelastminutes as varchar(10)) +
N' and DATEDIFF(minute, ec.last_write, GETDATE()) < ' + cast(@activelastminutes as varchar(10)) +
N' and sp.dbid = ' + cast(@mydbid as varchar(10))

EXECUTE sp_executesql @sqlstring, @sqlparm, @pnumproc = @numproc output
--Return the results.
SET @outparm = @numproc
PRINT '-- No of processes with connections active for the last ' + cast(@activelastminutes as varchar(10)) + ' minutes in DB ' + @inputdb + ' is ' + CAST(@numproc AS VARCHAR(10))
GO







