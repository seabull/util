-- Since I have been spending some time cleaning up some databases in preparation for some server consolidation work, I thought I would share some useful queries for determining things like how large your database is, how full the files are, which tables and indexes use the most space, which tables might be dormant, etc.

--As I have noted, some of the queries are SQL Server 2008 specific, and some can be resource intensive and time consuming. Have fun with these!

--We can use the sp_spaceused stored procedure to find out exactly how much disk space is currently 
--being used by a database. If we simply execute this stored procedure without passing any parameters, 
--it returns the following 2 result sets:
--Result Set 1:

--database_name: Name of the current database.
--database_size: Size of the current database in megabytes. 
--               database_size includes both data and log files.
--unallocated space: Space in the database that has not been reserved for database objects.
--
--Result Set 2:
--
--reserved: Total amount of space allocated by objects in the database.
--data: Total amount of space used by data.
--index_size: Total amount of space used by indexes.
--unused: Total amount of space reserved for objects in the database, but not yet used.
--

For more info on the sp_spaceused stored procedure, click here.

    USE YourDatabaseName;
    GO

    -- Individual File Size query for a database
    SELECT name AS [File Name] , file_id, physical_name AS [Physical Name], 
    size/128 AS [Total Size in MB],
    size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0 
    AS [Available Space In MB]
    FROM sys.database_files;
    
    
    -- Total File Size query for a database
    SELECT SUM(size/128)AS [Total Database Space Allocated], 
    SUM(size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0) 
    AS [Total Available Space In MB]
    FROM sys.database_files;
    
    -- Get space used for entire database
    EXEC sp_spaceused;
    
    -- Get space used for entire database 
    --(update usage information, may take some time, and affect server)
    EXEC sp_spaceused @updateusage = N'TRUE';
    
    
    -- Get total number of rows in a table (much less cost than SELECT COUNT(*))
    SELECT OBJECT_NAME(object_id) AS [Table Name], SUM(Rows) AS [Row Count] 
    FROM sys.partitions 
    WHERE index_id < 2 --ignore the partitions from the non-clustered index if any
    GROUP BY object_id
    ORDER BY SUM(Rows) DESC;
    
    -- Get Table names, row counts, and compression type (SQL 2008 Only)
    SELECT OBJECT_NAME(object_id) AS [Table Name], SUM(Rows) AS [Row Count], 
           data_compression_desc AS [Compression]
    FROM sys.partitions 
    WHERE index_id < 2 --ignore the partitions from the non-clustered index if any
    AND OBJECT_NAME(object_id) NOT LIKE 'sys%'
    AND OBJECT_NAME(object_id) NOT LIKE 'queue_%' 
    AND OBJECT_NAME(object_id) NOT LIKE 'filestream_tombstone%' 
    GROUP BY object_id, data_compression_desc
    ORDER BY SUM(Rows) DESC;
    
    
    -- Unused tables & indexes. 
    -- Tables have index_id’s of either 0 = Heap table or 1 = Clustered Index
    SELECT  OBJECT_NAME(i.OBJECT_ID) AS [Table Name], i.NAME AS [Index Name], i.INDEX_ID
    FROM sys.indexes AS i
    INNER JOIN sys.objects AS o
    ON i.OBJECT_ID = o.OBJECT_ID
    WHERE OBJECTPROPERTY(o.OBJECT_ID,'IsUserTable') = 1
    AND i.INDEX_ID 
    NOT IN (SELECT s.INDEX_ID
            FROM SYS.DM_DB_INDEX_USAGE_STATS AS s
            WHERE s.OBJECT_ID = i.OBJECT_ID
            AND i.INDEX_ID = s.INDEX_ID
            AND DATABASE_ID = DB_ID(db_name()))
    ORDER BY [Table Name], i.INDEX_ID, [Index Name] ASC;
    
    
    -- Index Size Used for all tables (can be very slow on a large database)
    SELECT OBJECT_NAME(P.object_id) AS [Table_Name], [name] AS [Index Name], 
           type_desc AS [Index Type], 
           (page_count * 8.0) AS [Space Used (KB)],  
           (page_count * 8.0 / 1024.0) AS [Space Used (MB)] 
    FROM sys.indexes AS I
    INNER JOIN sys.dm_db_index_physical_stats(db_id(), 
    object_id('.'), null, null, null) AS P 
    ON I.[object_id] = P.[object_id] 
    AND I.[index_id] = P.[index_id]
    ORDER BY OBJECT_NAME(P.object_id);

/*
	vwTableInfo - Table Information View

 This view display space and storage information for every table in a
SQL Server 2005 database.
Columns are:
	Schema
	Name
	Owner		may be different from Schema)
	Columns		count of the max number of columns ever used)
	HasClusIdx	1 if table has a clustered index, 0 otherwise
	RowCount
	IndexKB		space used by the table's indexes
	DataKB		space used by the table's data

 16-March-2008, RBarryYoung@gmail.com
 31-January-2009, Edited for better formatting
*/
CREATE VIEW dbo.MyTableInfoV
AS
SELECT SCHEMA_NAME(tbl.schema_id) as [Schema]
, tbl.Name
, Coalesce((Select pr.name 
        From sys.database_principals pr 
        Where pr.principal_id = tbl.principal_id)
    , SCHEMA_NAME(tbl.schema_id)) as [Owner]
, tbl.max_column_id_used as [Columns]
, CAST(CASE idx.index_id WHEN 1 THEN 1 ELSE 0 END AS bit) AS [HasClusIdx]
, Coalesce( (Select sum (spart.rows) from sys.partitions spart 
    Where spart.object_id = tbl.object_id and spart.index_id < 2), 0) AS [RowCount]

, Coalesce( (Select Cast(v.low/1024.0 as float) 
    * SUM(a.used_pages - CASE WHEN a.type <> 1 THEN a.used_pages WHEN p.index_id < 2 THEN a.data_pages ELSE 0 END) 
        FROM sys.indexes as i
         JOIN sys.partitions as p ON p.object_id = i.object_id and p.index_id = i.index_id
         JOIN sys.allocation_units as a ON a.container_id = p.partition_id
        Where i.object_id = tbl.object_id  )
    , 0.0) AS [IndexKB]

, Coalesce( (Select Cast(v.low/1024.0 as float)
    * SUM(CASE WHEN a.type <> 1 THEN a.used_pages WHEN p.index_id < 2 THEN a.data_pages ELSE 0 END) 
        FROM sys.indexes as i
         JOIN sys.partitions as p ON p.object_id = i.object_id and p.index_id = i.index_id
         JOIN sys.allocation_units as a ON a.container_id = p.partition_id
        Where i.object_id = tbl.object_id)
    , 0.0) AS [DataKB]
, tbl.create_date, tbl.modify_date

 FROM sys.tables AS tbl
  INNER JOIN sys.indexes AS idx ON (idx.object_id = tbl.object_id and idx.index_id < 2)
  INNER JOIN master.dbo.spt_values v ON (v.number=1 and v.type='E')
GO

EXEC sys.sp_addextendedproperty @name=N'Owner', 
								@value=N'LJ Yang' , 
								@level0type=N'SCHEMA',
								@level0name=N'dbo', 
								@level1type=N'VIEW',
								@level1name=N'MyTableInfoV'
GO
EXEC sys.sp_addextendedproperty @name=N'RequestedBy', 
								@value=N'LJ Yang' , 
								@level0type=N'SCHEMA',
								@level0name=N'dbo', 
								@level1type=N'VIEW',
								@level1name=N'MyTableInfoV'
GO
EXEC sys.sp_addextendedproperty @name=N'Description', 
								@value=N'display space and storage information for every table' , 
								@level0type=N'SCHEMA',
								@level0name=N'dbo', 
								@level1type=N'VIEW',
								@level1name=N'MyTableInfoV'
GO
EXEC sys.sp_addextendedproperty @name=N'Tag', 
								@value=N'Admin' , 
								@level0type=N'SCHEMA',
								@level0name=N'dbo', 
								@level1type=N'VIEW',
								@level1name=N'MyTableInfoV'
GO

---------------------------------------
-- schema summary
begin try 
    SELECT
        (row_number() over(order by a3.name, a2.name))%2 as l1,
        a3.name AS [schemaname],
        a2.name AS [tablename],
        a1.rows as row_count,
        (a1.reserved + ISNULL(a4.reserved,0))* 8 AS reserved, 
        a1.data * 8 AS data,
        (CASE WHEN (a1.used + ISNULL(a4.used,0)) > a1.data THEN 
          (a1.used + ISNULL(a4.used,0)) - a1.data ELSE 0 END) * 8 AS index_size,
        (CASE WHEN (a1.reserved + ISNULL(a4.reserved,0)) > a1.used THEN 
          (a1.reserved + ISNULL(a4.reserved,0)) - a1.used ELSE 0 END) * 8 AS unused
    FROM
     (
        SELECT 
            ps.object_id,
            SUM ( CASE WHEN (ps.index_id < 2) THEN row_count ELSE 0 END) AS [rows],
            SUM (ps.reserved_page_count) AS reserved,
            SUM ( CASE WHEN (ps.index_id < 2) THEN 
                        (ps.in_row_data_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count)
                    ELSE (ps.lob_used_page_count + ps.row_overflow_used_page_count)
                END) AS data,
            SUM (ps.used_page_count) AS used
         FROM sys.dm_db_partition_stats ps
         GROUP BY ps.object_id
    ) AS a1
    LEFT OUTER JOIN 
     (
        SELECT 
            it.parent_id,
            SUM(ps.reserved_page_count) AS reserved,
            SUM(ps.used_page_count) AS used
         FROM sys.dm_db_partition_stats ps
       INNER JOIN sys.internal_tables it 
            ON (it.object_id = ps.object_id)
        WHERE it.internal_type IN (202,204)
       GROUP BY it.parent_id
    ) AS a4 
        ON (a4.parent_id = a1.object_id)
    INNER JOIN sys.all_objects a2  
        ON ( a1.object_id = a2.object_id ) 
    INNER JOIN sys.schemas a3 
        ON (a2.schema_id = a3.schema_id)
    WHERE a2.type <> 'S' and a2.type <> 'IT'
    ORDER BY a3.name, a2.name
end try 
begin catch 
    select 
         -100 as l1
        , 1 as schemaname 
        ,       ERROR_NUMBER() as tablename
        ,       ERROR_SEVERITY() as row_count
        ,       ERROR_STATE() as reserved
        ,       ERROR_MESSAGE() as data
        ,       1 as index_size
        ,   1 as unused 
end catch


---------------------------------------
-- schema summary
begin try 
    SELECT
        --(row_number() over(order by a3.name, a2.name))%2 as l1,
        a3.name AS [schemaname],
        count(a2.name ) as NumberOftables,
        sum(a1.rows) as row_count,
        sum((a1.reserved + ISNULL(a4.reserved,0))* 8) AS reserved, 
        sum(a1.data * 8) AS data,
        sum((CASE WHEN (a1.used + ISNULL(a4.used,0)) > a1.data THEN 
          (a1.used + ISNULL(a4.used,0)) - a1.data ELSE 0 END) * 8 )AS index_size,
        sum((CASE WHEN (a1.reserved + ISNULL(a4.reserved,0)) > a1.used THEN 
          (a1.reserved + ISNULL(a4.reserved,0)) - a1.used ELSE 0 END) * 8) AS unused
    FROM
     (
        SELECT 
            ps.object_id,
            SUM (
             CASE
              WHEN (ps.index_id < 2) THEN row_count
              ELSE 0
             END
             ) AS [rows],
            SUM (ps.reserved_page_count) AS reserved,
            SUM (
             CASE
              WHEN (ps.index_id < 2) THEN 
               (ps.in_row_data_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count)
              ELSE (ps.lob_used_page_count + ps.row_overflow_used_page_count)
             END
             ) AS data,
            SUM (ps.used_page_count) AS used
         FROM sys.dm_db_partition_stats ps
         GROUP BY ps.object_id
    ) AS a1
    LEFT OUTER JOIN 
         (SELECT 
                it.parent_id,
                SUM(ps.reserved_page_count) AS reserved,
                SUM(ps.used_page_count) AS used
            FROM sys.dm_db_partition_stats ps
          INNER JOIN sys.internal_tables it ON (it.object_id = ps.object_id)
           WHERE it.internal_type IN (202,204)
          GROUP BY it.parent_id
        ) AS a4 
            ON (a4.parent_id = a1.object_id)
    INNER JOIN sys.all_objects a2  
            ON ( a1.object_id = a2.object_id ) 
    INNER JOIN sys.schemas a3 
            ON (a2.schema_id = a3.schema_id)
     WHERE a2.type <> 'S' and a2.type <> 'IT'
    group by a3.name 
    ORDER BY a3.name
end try 

begin catch 
    select 
     -100 as l1
    , 1 as schemaname 
    ,       ERROR_NUMBER() as tablename
    ,       ERROR_SEVERITY() as row_count
    ,       ERROR_STATE() as reserved
    ,       ERROR_MESSAGE() as data
    ,       1 as index_size
    ,   1 as unused 
end catch

