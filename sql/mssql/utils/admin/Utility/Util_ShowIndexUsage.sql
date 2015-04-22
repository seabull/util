CREATE PROC [dbo].[Util_ShowIndexUsage]
    @SQLToRun	VARCHAR(MAX)
    , @Debug	BIT = 0
AS
/*-------------------------------------------------------------------------------------------------
 
Purpose: Identify what indexes/tables are used by a given batch of SQL or stored procedure. 

Parameters: @SQLToRun - SQL you want to know the index access for.
		    @Debug - Outputs debug info, when set to 1.

Example Usage:
    1. EXEC dbo.Util_ShowIndexUsage @SQLToRun = 'select * from dbo.FortVault'
    
    2. EXEC dbo.Util_ShowIndexUsage @SQLToRun = 'dbo.sp_FORTVault_GetChildCount', @Debug = 1
    
    3. To run a sproc with parameters, either create a wrapper sproc with the parameters hardcoded or
       DECLARE @SQLToRun VARCHAR(50) = 'EXEC dbo.sp_XXX @Param1 = ' + '''' + '04-APR-27' + ''''
    
    4. To see what indexes are used between a given time period, use the below: 
       DECLARE @DelayBetweenSnapshots VARCHAR(24) = 'WAITFOR DELAY ' + '''' + '00:00:01' + ''''
       EXEC dbo.Util_ShowIndexUsage @DelayBetweenSnapshots 

-------------------------------------------------------------------------------------------------*/
BEGIN
    -- Do not lock anything, and do not get held up by any locks. 
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON
    
    -- Get index usage counter values, pre running SQL.
    SELECT
            SchemaName = ss.name
            , TableName = st.name
            , IndexName = ISNULL(si.name, '')
            , IndexType = si.type_desc   
            , user_updates = ISNULL(ius.user_updates, 0) -- If absent in sys.dm_db_index_usage_stats.
            , user_seeks = ISNULL(ius.user_seeks, 0) 
            , user_scans = ISNULL(ius.user_scans, 0) 
            , user_lookups = ISNULL(ius.user_lookups, 0)
            , ssi.rowcnt 
            , ssi.rowmodctr				
    INTO #IndexStatsPre		
    FROM   sys.dm_db_index_usage_stats ius 
    -- RIGHT OUTER JOIN because all indexes may not be present in the sys.dm_db_index_usage_stats DMV. 
    RIGHT OUTER JOIN sys.indexes si     ON  ius.[object_id] = si.[object_id] 
                                        AND ius.index_id = si.index_id
    INNER JOIN sys.sysindexes ssi       ON si.object_id = ssi.id AND si.name = ssi.name
    INNER JOIN sys.tables st            ON st.[object_id] = si.[object_id]
    INNER JOIN sys.schemas ss           ON ss.[schema_id] = st.[schema_id]
    WHERE ius.database_id = DB_ID() 
      AND OBJECTPROPERTY(ius.[object_id], 'IsMsShipped') = 0
    
    -- Execute passed SQL.
    EXEC (@SQLToRun)
    
    -- Get index usage counter values, post running SQL.
    SELECT
            SchemaName = ss.name
            , TableName = st.name
            , IndexName = ISNULL(si.name, '')
            , IndexType = si.type_desc   
            , user_updates = ISNULL(ius.user_updates, 0) 
            , user_seeks = ISNULL(ius.user_seeks, 0) 
            , user_scans = ISNULL(ius.user_scans, 0)
            , user_lookups = ISNULL(ius.user_lookups, 0)
            , ssi.rowcnt 
            , ssi.rowmodctr				
    INTO #IndexStatsPost		
    FROM   sys.dm_db_index_usage_stats ius
    RIGHT OUTER JOIN sys.indexes si ON  ius.[object_id] = si.[object_id] 
                                    AND ius.index_id = si.index_id
    INNER JOIN sys.sysindexes ssi   ON si.object_id = ssi.id AND si.name = ssi.name	
    INNER JOIN sys.tables st        ON st.[object_id] = si.[object_id]
    INNER JOIN sys.schemas ss       ON ss.[schema_id] = st.[schema_id]
    WHERE ius.database_id = DB_ID() 
    	AND OBJECTPROPERTY(ius.[object_id], 'IsMsShipped') = 0
    
    -- Compare. What index usage counts have changed?
    SELECT
        DatabaseName = DB_NAME()
        , po.[SchemaName] 
        , po.[TableName]
        , po.[IndexName]
        , po.[IndexType]
        , [User Updates] = po.user_updates - ISNULL(pr.user_updates, 0) -- Absent in sys.dm_db_index_usage_stats. 
        , [User Seeks] = po.user_seeks - ISNULL(pr.user_seeks, 0)
        , [User Scans] = po.user_scans - ISNULL(pr.user_scans, 0)
        , [User Lookups] = po.user_lookups - ISNULL(pr.user_lookups , 0)
        , [Rows Inserted] = po.rowcnt - pr.rowcnt -- If row not present will give null.
        , [Updates I/U/D] = po.rowmodctr - pr.rowmodctr 
    FROM #IndexStatsPost po 
    LEFT OUTER JOIN #IndexStatsPre pr   ON pr.SchemaName = po.SchemaName 	
                                        AND pr.TableName = po.TableName 	
                                        AND pr.IndexName = po.IndexName 	
                                        AND pr.IndexType = po.IndexType 	
    WHERE ISNULL(pr.user_updates, 0) != po.user_updates
    OR      ISNULL(pr.user_seeks, 0) != po.user_seeks
    OR      ISNULL(pr.user_scans, 0) != po.user_scans
    OR      ISNULL(pr.user_lookups, 0) != po.user_lookups
    ORDER BY po.[SchemaName], po.[TableName], po.[IndexName];
    
    -- Display debug info if required.
    IF @Debug = 1
    BEGIN
        SELECT * FROM #IndexStatsPre ORDER BY [SchemaName], [TableName], [IndexName]
        SELECT * FROM #IndexStatsPost ORDER BY [SchemaName], [TableName], [IndexName]
    END
    
    -- Tidy up.
    DROP TABLE #IndexStatsPre
    DROP TABLE #IndexStatsPost
END

declare @owner          nvarchar(256),
        @objType        nvarchar(128),
        @objName        nvarchar(256),
        @requestedBy    nvarchar(2000),
        @tag		    nvarchar(2000),
        @description    nvarchar(2000)

set @objType = N'Procedure'
set @objName = N'Util_ShowIndexUsage'
set @owner = N'LJ Yang'
set @tag = N'DBA'
set @description = N'Utility to show index usage of a specific SQL'
set @requestedBy = N'LJ Yang'

--declare @columnName nvarchar(256),
--		@columnDescription nvarchar(2000)
--
--set @columnName = N''
--set @columnDescription = N''
	
EXEC sys.sp_addextendedproperty @name=N'Owner', 
								@value=@owner, 
								@level0type=N'SCHEMA',
								@level0name=N'dbo', 
								@level1type=@objType,
								@level1name=@objName
EXEC sys.sp_addextendedproperty @name=N'RequestedBy', 
								@value=@requestedBy, 
								@level0type=N'SCHEMA',
								@level0name=N'dbo', 
								@level1type=@objType,
								@level1name=@objName
EXEC sys.sp_addextendedproperty @name=N'Description', 
								@value=@description, 
								@level0type=N'SCHEMA',
								@level0name=N'dbo', 
								@level1type=@objType,
								@level1name=@objName
EXEC sys.sp_addextendedproperty @name=N'Tag', 
								@value=@tag, 
								@level0type=N'SCHEMA',
								@level0name=N'dbo', 
								@level1type=@objType,
								@level1name=@objName
