select 
        BackupDate = convert(varchar(10),backup_start_date, 111) 
        ,SizeInGigs=floor( backup_size/1024000000) 
  from msdb..backupset 
 where database_name = 'PRFDB001'
   and type = 'd'
order by backup_start_date desc

-------------------------------------------------
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET ANSI_PADDING ON
GO

--Create Admin schema if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name='Admin') EXECUTE ('CREATE SCHEMA Admin')

IF OBJECT_ID('Admin.Util_BuildSpaceLogLite', 'P') IS NOT NULL DROP PROCEDURE Admin.Util_BuildSpaceLogLite
GO

/*
*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
Util_BuildSpaceLogLite
By Jesse Roberge - YeshuaAgapao@Yahoo.com

The SpaceLog builder
Records database space usage and buffer cache usage statistics into the SpaceLog_* tables.
Keeps a record of database and table growth for reporting of growth trends.
Stats include Reserved, Used, Data, and buffer cache page counts for row, lob (VarChar-Max, text etc), and overflow data (data rows with varchar columns going over 8000 bytes).
Stats also include some computed columns such as BTree (Used-Data), unused (Reserved-Used), and sums of row+lob+overflow for each of reserved, used, data, and buffer.
The database, dataspace, schema, and table levels give stats for the nonclustered index and the table itself (heap or clustered index).
The lite version does not require VIEW_SERVER_STATE permission and can be used in environments where the user has only dbo access.  The columns for buffer cache stats will be all zeroes.
It does require the VIEW_DATABASE_STATE permission, which a user in the db_owner database role automatically has.

Required Input Parameters
	None

Optional Input Parameters
	@UpdateUsage tinyint=0			Default and recommended to be off.  Use only if you must have the most accurate and up to date numbers.  Will run DBCC UpdateUsage to scan every table in the database to re-count all allocations and rows, which can hog disk IO for serveral hours.

Usage
	EXECUTE Admin.Util_BuildSpaceLogLite @UpdateUsage=0

*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
*/

--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

IF OBJECT_ID('Admin.SpaceLog_Database', 'U') IS NULL
BEGIN
	CREATE TABLE Admin.SpaceLog_Database
	(
		Date DateTime NOT NULL,
		DatabaseID int NOT NULL,
		DatabaseName sysname NOT NULL,
		Rows BigInt NOT NULL,
		RowReserved BigInt NOT NULL,
		RowUsed BigInt NOT NULL,
		RowData BigInt NOT NULL,
		RowBTree AS RowUsed-RowData,
		RowUnused AS RowReserved-RowUsed,
		RowBuffer BigInt NOT NULL,
		IndexReserved BigInt NOT NULL,
		IndexUsed BigInt NOT NULL,
		IndexData BigInt NOT NULL,
		IndexBuffer BigInt NOT NULL,
		IndexBTree AS IndexUsed-IndexData,
		IndexUnused AS IndexReserved-IndexUsed,
		LOBReserved BigInt NOT NULL,
		LOBUsed BigInt NOT NULL,
		LOBUnused AS LOBReserved-LOBUsed,
		LOBBuffer BigInt NOT NULL,
		OverflowReserved BigInt NOT NULL,
		OverflowUsed BigInt NOT NULL,
		OverflowUnused AS OverflowReserved-OverflowUsed,
		OverflowBuffer BigInt NOT NULL,
		TotalReserved AS RowReserved+LOBReserved+OverflowReserved,
		TotalUsed AS RowUsed+LOBUsed+OverflowUsed,
		TotalBuffer AS RowBuffer+LOBBuffer+OverflowBuffer,
		TotalUnused AS (RowReserved+LOBReserved+OverflowReserved+IndexReserved)-(RowUsed+LOBUsed+OverflowUsed+IndexUsed),
		CONSTRAINT PK_C_IX__Admin__SpaceLog_DataBase__Date_DatabaseID PRIMARY KEY NONCLUSTERED (Date, DatabaseID) WITH FILLFACTOR=90,
		CONSTRAINT U_UX__Admin__SpaceLog_Database__Date_DatabaseName UNIQUE CLUSTERED (Date, DatabaseName) WITH FillFactor=90
	)
END

--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

IF OBJECT_ID('Admin.SpaceLog_DataSpace', 'U') IS NULL
BEGIN
	CREATE TABLE Admin.SpaceLog_DataSpace
	(
		Date DateTime NOT NULL,
		DatabaseID int NOT NULL,
		DatabaseName sysname NOT NULL,
		DataSpaceID int NOT NULL,
		DataSpaceName sysname NOT NULL,
		DataSpaceType Char(2) NOT NULL,
		DataSpaceTypeDesc AS CASE DataSpaceType WHEN 'FG' THEN 'Filegroup' WHEN 'PS' THEN 'Partition Scheme' WHEN 'FD' THEN 'FILESTREAM data filegroup' ELSE '' END,
		Rows BigInt NOT NULL,
		RowReserved BigInt NOT NULL,
		RowUsed BigInt NOT NULL,
		RowData BigInt NOT NULL,
		RowBTree AS RowUsed-RowData,
		RowUnused AS RowReserved-RowUsed,
		RowBuffer BigInt NOT NULL,
		IndexReserved BigInt NOT NULL,
		IndexUsed BigInt NOT NULL,
		IndexData BigInt NOT NULL,
		IndexBTree AS IndexUsed-IndexData,
		IndexUnused AS IndexReserved-IndexUsed,
		IndexBuffer BigInt NOT NULL,
		LOBReserved BigInt NOT NULL,
		LOBUsed BigInt NOT NULL,
		LOBBuffer BigInt NOT NULL,
		LOBUnused AS LOBReserved-LOBUsed,
		OverflowReserved BigInt NOT NULL,
		OverflowUsed BigInt NOT NULL,
		OverflowUnused AS OverflowReserved-OverflowUsed,
		OverflowBuffer BigInt NOT NULL,
		TotalReserved AS RowReserved+LOBReserved+OverflowReserved+IndexReserved,
		TotalUsed AS RowUsed+LOBUsed+OverflowUsed+IndexUsed,
		TotalBuffer AS RowBuffer+LOBBuffer+OverflowBuffer+IndexBuffer,
		TotalUnused AS (RowReserved+LOBReserved+OverflowReserved+IndexReserved)-(RowUsed+LOBUsed+OverflowUsed+IndexUsed),
		CONSTRAINT PK_C_IX__Admin__SpaceLog_DataSpace__Date_DatabaseID_DataSpaceID PRIMARY KEY NONCLUSTERED (Date, DatabaseID, DataSpaceID) WITH FILLFACTOR=90,
		CONSTRAINT U_UX__Admin__SpaceLog_DataSpace__Date_DatabaseName_DataSpaceName UNIQUE CLUSTERED (Date, DatabaseName, DataSpaceName) WITH FillFactor=90
	)
END

--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

IF OBJECT_ID('Admin.SpaceLog_Schema', 'U') IS NULL
BEGIN
	CREATE TABLE Admin.SpaceLog_Schema
	(
		Date DateTime NOT NULL,
		DatabaseID int NOT NULL,
		DatabaseName sysname NOT NULL,
		SchemaID int NOT NULL,
		SchemaName sysname NOT NULL,
		Rows BigInt NOT NULL,
		RowReserved BigInt NOT NULL,
		RowUsed BigInt NOT NULL,
		RowData BigInt NOT NULL,
		RowBTree AS RowUsed-RowData,
		RowUnused AS RowReserved-RowUsed,
		RowBuffer BigInt NOT NULL,
		IndexReserved BigInt NOT NULL,
		IndexUsed BigInt NOT NULL,
		IndexData BigInt NOT NULL,
		IndexBTree AS IndexUsed-IndexData,
		IndexUnused AS IndexReserved-IndexUsed,
		IndexBuffer BigInt NOT NULL,
		LOBReserved BigInt NOT NULL,
		LOBUsed BigInt NOT NULL,
		LOBUnused AS LOBReserved-LOBUsed,
		LOBBuffer BigInt NOT NULL,
		OverflowReserved BigInt NOT NULL,
		OverflowUsed BigInt NOT NULL,
		OverflowUnused AS OverflowReserved-OverflowUsed,
		OverflowBuffer BigInt NOT NULL,
		TotalReserved AS RowReserved+LOBReserved+OverflowReserved+IndexReserved,
		TotalUsed AS RowUsed+LOBUsed+OverflowUsed+IndexUsed,
		TotalBuffer AS RowBuffer+LOBBuffer+OverflowBuffer+IndexBuffer,
		TotalUnused AS (RowReserved+LOBReserved+OverflowReserved+IndexReserved)-(RowUsed+LOBUsed+OverflowUsed+IndexUsed),
		CONSTRAINT PK_C_IX__Admin__SpaceLog_Scehma__Date_DatabaseID_SchemaID PRIMARY KEY NONCLUSTERED (Date, DatabaseID, SchemaID) WITH FILLFACTOR=90,
		CONSTRAINT U_UX__Admin__SpaceLog_Scehma__Date_DatabaseName_SchemaName UNIQUE CLUSTERED (Date, DatabaseName, SchemaName) WITH FillFactor=90
	)
END

--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

IF OBJECT_ID('Admin.SpaceLog_Table', 'U') IS NULL
BEGIN
	CREATE TABLE Admin.SpaceLog_Table
	(
		Date DateTime NOT NULL,
		DatabaseID int NOT NULL,
		DatabaseName sysname NOT NULL,
		SchemaID int NOT NULL,
		SchemaName sysname NOT NULL,
		TableID int NOT NULL,
		TableName sysname NOT NULL,
		TableDataSpaceID int NOT NULL,
		TableDataSpaceName sysname NOT NULL,
		TableDataSpaceType Char(2) NOT NULL,
		TableDataSpaceTypeDesc AS CASE TableDataSpaceType WHEN 'FG' THEN 'Filegroup' WHEN 'PS' THEN 'Partition Scheme' WHEN 'FD' THEN 'FILESTREAM data filegroup' ELSE '' END,
		LOBDataSpaceID int NOT NULL,
		LOBDataSpaceName sysname NOT NULL,
		LOBDataSpaceType Char(2) NOT NULL,
		LOBDataSpaceTypeDesc AS CASE LOBDataSpaceType WHEN 'FG' THEN 'Filegroup' WHEN 'PS' THEN 'Partition Scheme' WHEN 'FD' THEN 'FILESTREAM data filegroup' ELSE '' END,
		Rows BigInt NOT NULL,
		RowReserved BigInt NOT NULL,
		RowUsed BigInt NOT NULL,
		RowData BigInt NOT NULL,
		RowBTree AS RowUsed-RowData,
		RowUnused AS RowReserved-RowUsed,
		RowBuffer BigInt NOT NULL,
		IndexReserved BigInt NOT NULL,
		IndexUsed BigInt NOT NULL,
		IndexData BigInt NOT NULL,
		IndexBTree AS IndexUsed-IndexData,
		IndexUnused AS IndexReserved-IndexUsed,
		IndexBuffer BigInt NOT NULL,
		LOBReserved BigInt NOT NULL,
		LOBUsed BigInt NOT NULL,
		LOBUnused AS LOBReserved-LOBUsed,
		LOBBuffer BigInt NOT NULL,
		OverflowReserved BigInt NOT NULL,
		OverflowUsed BigInt NOT NULL,
		OverflowUnused AS OverflowReserved-OverflowUsed,
		OverflowBuffer BigInt NOT NULL,
		TotalReserved AS RowReserved+LOBReserved+OverflowReserved+IndexReserved,
		TotalUsed AS RowUsed+LOBUsed+OverflowUsed+IndexUsed,
		TotalBuffer AS RowBuffer+LOBBuffer+OverflowBuffer+IndexBuffer,
		TotalUnused AS (RowReserved+LOBReserved+OverflowReserved+IndexReserved)-(RowUsed+LOBUsed+OverflowUsed+IndexUsed),
		CONSTRAINT PK_C_IX__Admin__SpaceLog_Table__Date_DatabaseID_TableID PRIMARY KEY NONCLUSTERED (Date, DatabaseID, TableID) WITH FILLFACTOR=90,
		CONSTRAINT U_UX__Admin__SpaceLog_Table__Date_DatabaseName_TableName_SchemaName UNIQUE CLUSTERED (Date, DatabaseName, TableName, SchemaName) WITH FillFactor=90
	)
END

--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

IF OBJECT_ID('Admin.SpaceLog_Index', 'U') IS NULL
BEGIN
	CREATE TABLE Admin.SpaceLog_Index
	(
		Date DateTime NOT NULL,
		DatabaseID int NOT NULL,
		DatabaseName sysname NOT NULL,
		SchemaID int NOT NULL,
		SchemaName sysname NOT NULL,
		TableID int NOT NULL,
		TableName sysname NOT NULL,
		IndexID int NOT NULL,
		IndexName sysname NOT NULL,
		IndexDataSpaceID int NOT NULL,
		IndexDataSpaceName sysname NOT NULL,
		IndexDataSpaceType Char(2) NOT NULL,
		IndexDataSpaceTypeDesc AS CASE IndexDataSpaceType WHEN 'FG' THEN 'Filegroup' WHEN 'PS' THEN 'Partition Scheme' WHEN 'FD' THEN 'FILESTREAM data filegroup' ELSE '' END,
		PrimaryKey bit NOT NULL,
		UniqueConstraint bit NOT NULL,
		UniqueIndex bit NOT NULL,
		IgnoreDuplicateKey bit NOT NULL,
		IndexFillFactor TinyInt NOT NULL,
		Rows BigInt NOT NULL,
		RowReserved BigInt NOT NULL,
		RowUsed BigInt NOT NULL,
		RowData BigInt NOT NULL,
		RowBTree AS RowUsed-RowData,
		RowUnused AS RowReserved-RowUsed,
		RowBuffer BigInt NOT NULL,
		LOBReserved BigInt NOT NULL,
		LOBUsed BigInt NOT NULL,
		LOBUnused AS LOBReserved-LOBUsed,
		LOBBuffer BigInt NOT NULL,
		OverflowReserved BigInt NOT NULL,
		OverflowUsed BigInt NOT NULL,
		OverflowUnused AS OverflowReserved-OverflowUsed,
		OverflowBuffer BigInt NOT NULL,
		TotalReserved AS RowReserved+LOBReserved+OverflowReserved,
		TotalUsed AS RowUsed+LOBUsed+OverflowUsed,
		TotalBuffer AS RowBuffer+LOBBuffer+OverflowBuffer,
		TotalUnused AS (RowReserved+LOBReserved+OverflowReserved)-(RowUsed+LOBUsed+OverflowUsed),
		CONSTRAINT PK_C_IX__Admin__SpaceLog_Index__Date_DatabaseID_TableID_IndexID PRIMARY KEY NONCLUSTERED (Date, DatabaseID, TableID, IndexID) WITH FILLFACTOR=90,
		CONSTRAINT U_UX__Admin__SpaceLog_Index__Date_DatabaseName_TableName_IndexName_SchemaName UNIQUE CLUSTERED (Date, DatabaseName, TableName, IndexName, SchemaName) WITH FillFactor=90
	)
END

--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

IF OBJECT_ID('Admin.SpaceLog_Partition', 'U') IS NULL
BEGIN
	CREATE TABLE Admin.SpaceLog_Partition
	(
		Date DateTime NOT NULL,
		DatabaseID int NOT NULL,
		DatabaseName sysname NOT NULL,
		SchemaID int NOT NULL,
		SchemaName sysname NOT NULL,
		TableID int NOT NULL,
		TableName sysname NOT NULL,
		IndexID int NOT NULL,
		IndexName sysname NOT NULL,
		PartitionID BigInt NOT NULL,
		HobtID BigInt NOT NULL,
		PartitionNumber int NOT NULL,
		Rows BigInt NOT NULL,
		RowReserved BigInt NOT NULL,
		RowUsed BigInt NOT NULL,
		RowData BigInt NOT NULL,
		RowBTree AS RowUsed-RowData,
		RowUnused AS RowReserved-RowUsed,
		RowBuffer BigInt NOT NULL,
		RowDataSpaceID int NOT NULL,
		RowDataSpaceName sysname NOT NULL,
		LOBReserved BigInt NOT NULL,
		LOBUsed BigInt NOT NULL,
		LOBUnused AS LOBReserved-LOBUsed,
		LOBBuffer BigInt NOT NULL,
		LOBDataSpaceID int NOT NULL,
		LOBDataSpaceName sysname NOT NULL,
		OverflowReserved BigInt NOT NULL,
		OverflowUsed BigInt NOT NULL,
		OverflowUnused AS OverflowReserved-OverflowUsed,
		OverflowBuffer BigInt NOT NULL,
		OverflowDataSpaceID int NOT NULL,
		OverflowDataSpaceName sysname NOT NULL,
		TotalReserved AS RowReserved+LOBReserved+OverflowReserved,
		TotalUsed AS RowUsed+LOBUsed+OverflowUsed,
		TotalBuffer AS RowBuffer+LOBBuffer+OverflowBuffer,
		TotalUnused AS (RowReserved+LOBReserved+OverflowReserved)-(RowUsed+LOBUsed+OverflowUsed),
		CONSTRAINT PK_C_IX__SpaceLog_SpaceLog_Partition__Date_DatabaseID_TableID_IndexID_PartitionID PRIMARY KEY NONCLUSTERED (Date, DatabaseID, TableID, IndexID, PartitionID) WITH FILLFACTOR=90,
		CONSTRAINT U_IX__Admin__SpaceLog_SpaceLog_Partition__Date_DatabaseID_PartitionID UNIQUE NONCLUSTERED (Date, DatabaseID, PartitionID) WITH FILLFACTOR=90,
		CONSTRAINT U_IX__Admin__SpaceLog_SpaceLog_Partition__Date_DatabaseName_TableName_IndexName_PartitionID_SchemaName UNIQUE CLUSTERED (Date, DatabaseName, TableName, IndexName, PartitionID, SchemaName) WITH FILLFACTOR=90
	)
END
GO

--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

CREATE PROCEDURE Admin.Util_BuildSpaceLogLite
	@UpdateUsage tinyint=0
AS

DECLARE @Date DateTime
DECLARE @DatabaseID int

--SET @Date=dbo.fn_DateRound_Hour(GetDate())
SELECT @DatabaseID=DB_ID(), @Date=GetDate()

IF @UpdateUsage=1 DBCC UpdateUsage(0) WITH NO_INFOMSGS, COUNT_ROWS

--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

--Partition
INSERT INTO Admin.SpaceLog_Partition
	(
		Date, DatabaseID, DatabaseName,
		SchemaID, SchemaName, TableID, TableName,
		IndexID, IndexName, PartitionID, HobtID,
		PartitionNumber, Rows,
		RowReserved, RowUsed,
		RowData, RowBuffer,
		RowDataSpaceID, RowDataSpaceName,
		LOBReserved, LOBUsed,
		LOBBuffer,
		LOBDataSpaceID, LOBDataSpaceName,
		OverflowReserved, OverflowUsed,
		OverflowBuffer,
		OverflowDataSpaceID, OverflowDataSpaceName
	)
SELECT
	@Date AS Date, @DatabaseID AS DatabaseID, databases.name AS DatabaseName,
	schemas.schema_id, schemas.name AS SchemaName, dm_db_partition_stats.object_id AS TableID, tables.name AS TableName,
	dm_db_partition_stats.index_id AS IndexID, ISNULL(indexes.name,'[HEAP]') AS IndexID, partitions.partition_id AS PartitionID, partitions.hobt_id AS HOBTID,
	dm_db_partition_stats.partition_number AS PartitionNumber, dm_db_partition_stats.row_count AS Rows,
	CONVERT(bigint, in_row_reserved_page_count)*8 AS RowReserved, CONVERT(bigint, in_row_used_page_count)*8 AS RowUsed,
	CONVERT(bigint, in_row_data_page_count)*8 AS RowData, CONVERT(bigint, ISNULL(in_row_buffer_pages,0))*8 AS RowBuffer,
	ISNULL(in_row_data_space_id,0) AS RowDataSpaceID, in_row_data_space_name AS RowDataSpaceName,
	CONVERT(bigint, lob_reserved_page_count)*8 AS LOBReserved, CONVERT(bigint, lob_used_page_count)*8 AS LOBUsed,
	CONVERT(bigint, ISNULL(lob_buffer_pages,0))*8 AS LOBBuffer,
	ISNULL(partitions.lob_data_space_id,0) AS LOBDataSpaceID, lob_data_space_name AS LOBDataSpaceName,
	CONVERT(bigint, row_overflow_reserved_page_count)*8 AS OverflowReserved, CONVERT(bigint, row_overflow_used_page_count)*8 AS OverflowUsed,
	CONVERT(bigint, ISNULL(row_overflow_buffer_pages,0))*8 AS OverflowBuffer,
	ISNULL(row_overflow_data_space_id,0) AS OverflowDataSpaceID, row_overflow_data_space_name AS OverflowDataSpaceName
FROM
	(
		SELECT
			partitions.partition_id, MAX(partitions.partition_number) AS partition_number, MAX(partitions.hobt_id) AS hobt_id,
			MAX(partitions.object_id) AS object_id, MAX(partitions.index_id) AS index_id,
			0 AS in_row_buffer_pages,
			0 AS lob_buffer_pages,
			0 AS row_overflow_buffer_pages,
			MAX(CASE WHEN allocation_units.type=1 THEN ISNULL(data_spaces.data_space_id,0) ELSE 0 END) AS in_row_data_space_id,
			MAX(CASE WHEN allocation_units.type=2 THEN ISNULL(data_spaces.data_space_id,0) ELSE 0 END) AS lob_data_space_id,
			MAX(CASE WHEN allocation_units.type=3 THEN ISNULL(data_spaces.data_space_id,0) ELSE 0 END) AS row_overflow_data_space_id,
			MAX(CASE WHEN allocation_units.type=1 THEN ISNULL(data_spaces.name,'') ELSE '' END) AS in_row_data_space_name,
			MAX(CASE WHEN allocation_units.type=2 THEN ISNULL(data_spaces.name,'') ELSE '' END) AS lob_data_space_name,
			MAX(CASE WHEN allocation_units.type=3 THEN ISNULL(data_spaces.name,'') ELSE '' END) AS row_overflow_data_space_name
		FROM
			sys.partitions
			JOIN sys.allocation_units ON
				partitions.partition_id=allocation_units.container_id AND allocation_units.type IN (1,3) OR
				partitions.hobt_id=allocation_units.container_id AND allocation_units.type=2
			JOIN sys.data_spaces ON allocation_units.data_space_id=data_spaces.data_space_id
		GROUP BY partitions.partition_id
	) AS partitions
	JOIN sys.dm_db_partition_stats ON partitions.partition_id=dm_db_partition_stats.partition_id
	JOIN sys.indexes ON partitions.object_id=indexes.object_id AND partitions.index_id=indexes.index_id
	JOIN sys.databases ON databases.database_id=@DatabaseID
	JOIN sys.tables ON dm_db_partition_stats.object_id=tables.object_id
	JOIN sys.schemas ON tables.schema_id=schemas.schema_id
WHERE tables.type='U'

--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

--Index
INSERT INTO Admin.SpaceLog_Index
	(
		Date, DatabaseID, DatabaseName, SchemaID, SchemaName, TableID, TableName,
		IndexID, IndexName, IndexDataSpaceID, IndexDataSpaceName, IndexDataSpaceType,
		PrimaryKey, UniqueConstraint, UniqueIndex, IgnoreDuplicateKey, IndexFillFactor,
		Rows, RowReserved, RowUsed, RowData, RowBuffer, LOBReserved, LOBUsed, LOBBuffer, OverflowReserved, OverflowUsed, OverflowBuffer
	)
SELECT
	Date, @DatabaseID AS DatabaseID, databases.name AS DatabaseName, tables.schema_id AS SchemaID, schemas.name AS SchemaName, TableID, tables.name AS TableName,
	IndexID, ISNULL(indexes.name,'[HEAP]') AS IndexName, indexes.data_space_id AS IndexDataSpaceID, data_spaces.name AS IndexDataSpaceName, data_spaces.type AS IndexDataSpaceType,
	is_primary_key AS PrimaryKey, is_unique_constraint AS UniqueConstraint, is_unique AS UniqueIndex, ignore_dup_key AS IngoreDuplicateKey, fill_factor AS IndexFillFactor,
	Rows, RowReserved, RowUsed, RowData, RowBuffer, LOBReserved, LOBUsed, LOBBuffer, OverflowReserved, OverflowUsed, OverflowBuffer
FROM
	(
		SELECT
			@Date AS Date, TableID, IndexID, SUM(Rows) AS Rows,
			SUM(RowData) AS RowData, SUM(RowUsed) AS RowUsed, SUM(RowReserved) AS RowReserved, SUM(RowBuffer) AS RowBuffer,
			SUM(LOBUsed) AS LOBUsed, SUM(LOBReserved) AS LOBReserved, SUM(LOBBuffer) AS LOBBuffer,
			SUM(OverflowUsed) AS OverflowUsed, SUM(OverflowReserved) AS OverflowReserved, SUM(OverflowBuffer) AS OverflowBuffer
		FROM Admin.SpaceLog_Partition
		WHERE SpaceLog_Partition.Date=@Date AND SpaceLog_Partition.DatabaseID=@DatabaseID
		GROUP BY TableID, IndexID
	) AS SpaceLog_Partition
	JOIN sys.indexes ON SpaceLog_Partition.TableID=indexes.object_id AND SpaceLog_Partition.IndexID=indexes.index_id
	LEFT OUTER JOIN sys.data_spaces ON indexes.data_space_id=data_spaces.data_space_id
	JOIN sys.tables ON SpaceLog_Partition.TableID=tables.object_id
	JOIN sys.schemas ON tables.schema_id=schemas.schema_id
	JOIN sys.databases ON databases.database_id=@DatabaseID
WHERE tables.type='U'

--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

--Table
INSERT INTO Admin.SpaceLog_Table
	(
		Date, DatabaseID, DatabaseName, SchemaID, SchemaName, TableID, TableName,
		TableDataSpaceID, TableDataSpaceName, TableDataSpaceType,
		LOBDataSpaceID, LOBDataSpaceName, LOBDataSpaceType,
		Rows, RowReserved, RowUsed, RowData, RowBuffer, IndexReserved, IndexUsed, IndexData, IndexBuffer,
		LOBReserved, LOBUsed, LOBBuffer, OverflowReserved, OverflowUsed, OverflowBuffer
	)
SELECT
	Date, @DatabaseID AS DatabaseID, databases.name AS DatabaseName, tables.schema_id AS SchemaID, schemas.name AS SchemaName, TableID, tables.name AS TableName,
	TableDataSpaceID, data_spaces.name AS TableDataSpaceName, data_spaces.type AS TableDataSpaceType,
	tables.lob_data_space_id AS LOBDataSpaceID, ISNULL(data_spaces_lob.name,'') AS LOBDataSpaceName, ISNULL(data_spaces_lob.type,'') AS LOBDataSpaceType,
	Rows, RowReserved, RowUsed, RowData, RowBuffer, IndexReserved, IndexUsed, IndexData, IndexBuffer,
	LOBReserved, LOBUsed, LOBBuffer, OverflowReserved, OverflowUsed, OverflowBuffer
FROM
	(
		SELECT
			@Date AS Date, TableID, MAX(CASE WHEN IndexID<2 THEN IndexDataSpaceID ELSE 0 END) AS TableDataSpaceID, MAX(Rows) AS Rows,
			SUM(CASE WHEN IndexID<2 THEN RowData ELSE 0 END) AS RowData, SUM(CASE WHEN IndexID<2 THEN RowUsed ELSE 0 END) AS RowUsed, SUM(CASE WHEN IndexID<2 THEN RowReserved ELSE 0 END) AS RowReserved, SUM(CASE WHEN IndexID<2 THEN RowBuffer ELSE 0 END) AS RowBuffer,
			SUM(CASE WHEN IndexID>1 THEN RowData ELSE 0 END) AS IndexData, SUM(CASE WHEN IndexID>1 THEN RowUsed ELSE 0 END) AS IndexUsed, SUM(CASE WHEN IndexID>1 THEN RowReserved ELSE 0 END) AS IndexReserved, SUM(CASE WHEN IndexID>1 THEN RowBuffer ELSE 0 END) AS IndexBuffer,
			SUM(CASE WHEN IndexID<2 THEN LOBUsed ELSE 0 END) AS LOBUsed, SUM(CASE WHEN IndexID<2 THEN LOBReserved ELSE 0 END) AS LOBReserved, SUM(CASE WHEN IndexID<2 THEN LOBBuffer ELSE 0 END) AS LOBBuffer,
			SUM(CASE WHEN IndexID<2 THEN OverflowUsed ELSE 0 END) AS OverflowUsed, SUM(CASE WHEN IndexID<2 THEN OverflowReserved ELSE 0 END) AS OverflowReserved, SUM(CASE WHEN IndexID<2 THEN OverflowBuffer ELSE 0 END) AS OverflowBuffer
		FROM Admin.SpaceLog_Index
		WHERE SpaceLog_Index.Date=@Date AND SpaceLog_Index.DatabaseID=@DatabaseID
		GROUP BY TableID
	) AS SpaceLog_Index
	JOIN sys.tables ON SpaceLog_Index.TableID=tables.object_id
	JOIN sys.schemas ON tables.schema_id=schemas.schema_id
	LEFT OUTER JOIN sys.data_spaces ON SpaceLog_Index.TableDataSpaceID=data_spaces.data_space_id
	LEFT OUTER JOIN sys.data_spaces AS data_spaces_lob ON tables.lob_data_space_id=data_spaces_lob.data_space_id
	JOIN sys.databases ON databases.database_id=@DatabaseID
WHERE tables.type='U'

--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

--Schema
INSERT INTO Admin.SpaceLog_Schema
	(
		Date, DatabaseID, DatabaseName, SchemaID, SchemaName,
		Rows, RowReserved, RowUsed, RowData, RowBuffer, IndexReserved, IndexUsed, IndexData, IndexBuffer,
		LOBReserved, LOBUsed, LOBBuffer, OverflowReserved, OverflowUsed, OverflowBuffer
	)
SELECT
	Date, @DatabaseID AS DatabaseID, databases.name AS DatabaseName, SchemaID, schemas.name AS SchemaName,
	Rows, RowReserved, RowUsed, RowData, RowBuffer, IndexReserved, IndexUsed, IndexData, IndexBuffer, LOBReserved,
	LOBUsed, LOBBuffer, OverflowReserved, OverflowUsed, OverflowBuffer
FROM
	(
		SELECT
			@Date AS Date, SchemaID, SUM(Rows) AS Rows,
			SUM(RowData) AS RowData, SUM(RowUsed) AS RowUsed, SUM(RowReserved) AS RowReserved, SUM(RowBuffer) AS RowBuffer,
			SUM(IndexData) AS IndexData, SUM(IndexUsed) AS IndexUsed, SUM(IndexReserved) AS IndexReserved, SUM(IndexBuffer) AS IndexBuffer,
			SUM(LOBUsed) AS LOBUsed, SUM(LOBReserved) AS LOBReserved, SUM(LOBBuffer) AS LOBBuffer,
			SUM(OverflowUsed) AS OverflowUsed, SUM(OverflowReserved) AS OverflowReserved, SUM(OverflowBuffer) AS OverflowBuffer
		FROM Admin.SpaceLog_Table
		WHERE SpaceLog_Table.Date=@Date AND SpaceLog_Table.DatabaseID=@DatabaseID
		GROUP BY SchemaID
	) AS SpaceLog_Table
	JOIN sys.schemas ON SpaceLog_Table.SchemaID=schemas.schema_id
	JOIN sys.databases ON databases.database_id=@DatabaseID

--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

--Database
INSERT INTO Admin.SpaceLog_Database
	(
		Date, DatabaseID, DatabaseName,
		Rows, RowReserved, RowUsed, RowData, RowBuffer, IndexReserved, IndexUsed, IndexData, IndexBuffer,
		LOBReserved, LOBUsed, LOBBuffer, OverflowReserved, OverflowUsed, OverflowBuffer
	)
SELECT
	Date, @DatabaseID AS DatabaseID, databases.name AS DatabaseName,
	Rows, RowReserved, RowUsed, RowData, RowBuffer, IndexReserved, IndexUsed, IndexData, IndexBuffer,
	LOBReserved, LOBUsed, LOBBuffer, OverflowReserved, OverflowUsed, OverflowBuffer
FROM
	(
		SELECT
			@Date AS Date, SUM(Rows) AS Rows,
			SUM(RowData) AS RowData, SUM(RowUsed) AS RowUsed, SUM(RowReserved) AS RowReserved, SUM(RowBuffer) AS RowBuffer,
			SUM(IndexData) AS IndexData, SUM(IndexUsed) AS IndexUsed, SUM(IndexReserved) AS IndexReserved, SUM(IndexBuffer) AS IndexBuffer,
			SUM(LOBUsed) AS LOBUsed, SUM(LOBReserved) AS LOBReserved, SUM(LOBBuffer) AS LOBBuffer,
			SUM(OverflowUsed) AS OverflowUsed, SUM(OverflowReserved) AS OverflowReserved, SUM(OverflowBuffer) AS OverflowBuffer
		FROM Admin.SpaceLog_Table
		WHERE SpaceLog_Table.Date=@Date AND SpaceLog_Table.DatabaseID=@DatabaseID
	) AS SpaceLog_Table
	JOIN sys.databases ON databases.database_id=@DatabaseID

--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

--Data Space (Filegroup)
INSERT INTO Admin.SpaceLog_DataSpace
	(
		Date, DatabaseID, DatabaseName,
		DataSpaceID, DataSpaceName, DataSpaceType,
		Rows, RowReserved, RowUsed, RowData, RowBuffer, IndexReserved, IndexUsed, IndexData, IndexBuffer,
		LOBReserved, LOBUsed, LOBBuffer, OverflowReserved, OverflowUsed, OverflowBuffer
	)
SELECT
	@Date AS Date, @DatabaseID AS DatabaseID, databases.name AS DatabaseName,
	DataSpaceID, data_spaces.name AS DataSpaceName, data_spaces.type AS DataSpaceType,
	Rows, RowReserved, RowUsed, RowData, RowBuffer, IndexReserved, IndexUsed, IndexData, IndexBuffer,
	LOBReserved, LOBUsed, LOBBuffer, OverflowReserved, OverflowUsed, OverflowBuffer
FROM
	(
		SELECT
			CASE WHEN Row.DataSpaceID IS NOT NULL THEN Row.DataSpaceID WHEN LOB.DataSpaceID IS NOT NULL THEN LOB.DataSpaceID ELSE Overflow.DataSpaceID END AS DataSpaceID, ISNULL(Rows,0) AS Rows,
			ISNULL(RowReserved,0) AS RowReserved, ISNULL(RowUsed,0) AS RowUsed, ISNULL(RowData,0) AS RowData, ISNULL(RowBuffer,0) AS RowBuffer,
			ISNULL(IndexReserved,0) AS IndexReserved, ISNULL(IndexUsed,0) AS IndexUsed, ISNULL(IndexData,0) AS IndexData, ISNULL(IndexBuffer,0) AS IndexBuffer,
			ISNULL(LOBReserved,0) AS LOBReserved, ISNULL(LOBUsed,0) AS LOBUsed, ISNULL(LOBBuffer,0) AS LOBBuffer,
			ISNULL(OverflowReserved,0) AS OverflowReserved, ISNULL(OverflowUsed,0) AS OverflowUsed, ISNULL(OverflowBuffer,0) AS OverflowBuffer
		FROM
			(
				SELECT
					RowDataSpaceID AS DataSpaceID, SUM(CASE WHEN IndexID<2 THEN Rows ELSE 0 END) AS Rows,
					SUM(CASE WHEN IndexID<2 THEN RowReserved ELSE 0 END) AS RowReserved, SUM(CASE WHEN IndexID<2 THEN RowUsed ELSE 0 END) AS RowUsed,
					SUM(CASE WHEN IndexID<2 THEN RowData ELSE 0 END) AS RowData, SUM(CASE WHEN IndexID<2 THEN RowBuffer ELSE 0 END) AS RowBuffer,
					SUM(CASE WHEN IndexID>1 THEN RowReserved ELSE 0 END) AS IndexReserved, SUM(CASE WHEN IndexID>1 THEN RowUsed ELSE 0 END) AS IndexUsed,
					SUM(CASE WHEN IndexID>1 THEN RowData ELSE 0 END) AS IndexData, SUM(CASE WHEN IndexID>1 THEN RowBuffer ELSE 0 END) AS IndexBuffer
				FROM Admin.SpaceLog_Partition
				WHERE RowDataSpaceID>0 AND Date=@Date AND DatabaseID=@DatabaseID
				GROUP BY RowDataSpaceID
			) AS Row
			FULL OUTER JOIN (
				SELECT
					LOBDataSpaceID AS DataSpaceID,
					SUM(LOBReserved) AS LOBReserved, SUM(LOBUsed) AS LOBUsed, SUM(LOBBuffer) AS LOBBuffer
				FROM Admin.SpaceLog_Partition
				WHERE LOBDataSpaceID>0 AND Date=@Date AND DatabaseID=@DatabaseID
				GROUP BY LOBDataSpaceID
			) AS LOB ON Row.DataSpaceID=LOB.DataSpaceID
			FULL OUTER JOIN (
				SELECT
					OverflowDataSpaceID AS DataSpaceID,
					SUM(OverflowReserved) AS OverflowReserved, SUM(OverflowUsed) AS OverflowUsed, SUM(OverflowBuffer) AS OverflowBuffer
				FROM Admin.SpaceLog_Partition
				WHERE OverflowDataSpaceID>0 AND Date=@Date AND DatabaseID=@DatabaseID
				GROUP BY OverflowDataSpaceID
			) AS Overflow ON Row.DataSpaceID=Overflow.DataSpaceID
	) AS DataSpaces
	JOIN sys.data_spaces ON DataSpaces.DataSpaceID=data_spaces.data_space_id
	JOIN sys.databases ON databases.database_id=@DatabaseID
GO

--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=



SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET ANSI_PADDING ON
GO

--Create Util schema if it doesn't exist
--IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name='Util') EXECUTE ('CREATE SCHEMA Util')

IF OBJECT_ID('dbo.Util_Report_SpaceLog_LargestIndexesByBufferCache', 'P') IS NOT NULL DROP PROCEDURE dbo.Util_Report_SpaceLog_LargestIndexesByBufferCache
IF OBJECT_ID('dbo.Util_Report_SpaceLog_LargestTablesByReserved', 'P') IS NOT NULL DROP PROCEDURE dbo.Util_Report_SpaceLog_LargestTablesByReserved
IF OBJECT_ID('dbo.Util_Report_SpaceLog_TableSizeRunningGrowth', 'P') IS NOT NULL DROP PROCEDURE dbo.Util_Report_SpaceLog_TableSizeRunningGrowth
GO

/**
*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
Util_Report_SpaceLog_LargestIndexesByBufferCache
Util_Report_SpaceLog_LargestTablesByReserved
Util_Report_SpaceLog_TableSizeRunningGrowth
By Jesse Roberge - YeshuaAgapao@Yahoo.com

Sample reports for the Automated DBA: Space Usage SnapShotter
Report 1: Gets the 100 largest indexes by total buffer cache space usage
Report 2: Gets the 100 largest tables by total reserved pages
Report 3: Gets the largest tables in each database (optionally limiting to a single database) and provides a running total of space usage as well as the growth from the previous snapshot.
			Size sorting is by the most recent date sample.
These procs should go into the same database as the SpaceLog_* tables
There are many more potential reports that can be created from the data captured by the Space Usage SnapShotter.

Required Input Parameters
	none

Optional Input Parameters
	@MinPrime=1				The minimum prime value to generate.  You will usually want this at 1
	@MaxPrime=2097152		The maximum prime value to generate.
								The default value should use all of the values for most peoples' table of numbers
								(622^2=386884 for mine to completely fill 2-level deep clustered index).

Usage:
	EXECUTE dbo.Util_Report_SpaceLog_LargestIndexesByBufferCache @Days=1
	EXECUTE dbo.Util_Report_SpaceLog_LargestTablesByReserved @Days=1
	EXECUTE dbo.Util_Report_SpaceLog_TableSizeRunningGrowth @Days=7, @DatabaseName='CalvaryHelps'

Copyright:
	Licensed under the L-GPL - a weak copyleft license - you are permitted to use this as a component of a proprietary database and call this from proprietary software.
	Copyleft lets you do anything you want except plagarize, conceal the source, proprietarize modifications, or prohibit copying & re-distribution of this script/proc.

	This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    see <http://www.fsf.org/licensing/licenses/lgpl.html> for the license text.

*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
**/

CREATE PROCEDURE dbo.Util_Report_SpaceLog_LargestIndexesByBufferCache
	@Days int
AS

--Top list of indexes by buffer cache usage
SELECT TOP 100
	SpaceLog_Index.Date, SpaceLog_Index.DatabaseName, SpaceLog_Index.SchemaName, SpaceLog_Index.TableName
    , SpaceLog_Index.IndexID, SpaceLog_Index.IndexName,
	Rows, SpaceLog_Index.TotalReserved AS TotalReserved_KB, CONVERT(numeric(19,6)
    , CONVERT(numeric(19,6), SpaceLog_Index.TotalReserved)/1024.0) AS TotalReserved_MB,
	SpaceLog_Index.TotalBuffer AS TotalBuffer_KB
    , CONVERT(numeric(19,6), CONVERT(numeric(19,6), SpaceLog_Index.TotalBuffer)/1024.0) AS TotalBuffer_MB
FROM
	(
		SELECT Date, DatabaseName, ROW_NUMBER() OVER (PARTITION BY DatabaseName ORDER BY Date DESC) AS RowNumber
		FROM Admin.SpaceLog_Database
		WHERE Date>DateAdd(dd, @Days*-1, GETDATE())
	) AS DateSort
	JOIN Admin.SpaceLog_Index ON DateSort.Date=SpaceLog_Index.Date AND DateSort.DatabaseName=SpaceLog_Index.DatabaseName
WHERE DateSort.RowNumber=1
ORDER BY TotalBuffer DESC, DatabaseName, IndexID, SchemaName, TableName
GO

--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

CREATE PROCEDURE dbo.Util_Report_SpaceLog_LargestTablesByReserved
	@Days int
AS

--Top list of tables by total reserved
SELECT TOP 100
	SpaceLog_Table.Date, SpaceLog_Table.DatabaseName, SpaceLog_Table.SchemaName, SpaceLog_Table.TableName, Rows,
	Rows, SpaceLog_Table.TotalReserved AS TotalReserved_KB, CONVERT(numeric(19,6), CONVERT(numeric(19,6), SpaceLog_Table.TotalReserved)/1024.0) AS TotalReserved_MB,
	SpaceLog_Table.TotalBuffer AS TotalBuffer_KB, CONVERT(numeric(19,6), CONVERT(numeric(19,6), SpaceLog_Table.TotalBuffer)/1024.0) AS TotalBuffer_MB
FROM
	(
		SELECT Date, DatabaseName, ROW_NUMBER() OVER (PARTITION BY DatabaseName ORDER BY Date DESC) AS RowNumber
		FROM Admin.SpaceLog_Database
		WHERE Date>DateAdd(dd, @Days*-1, GETDATE())
	) AS DateSort
	JOIN Admin.SpaceLog_Table ON DateSort.Date=SpaceLog_Table.Date AND DateSort.DatabaseName=SpaceLog_Table.DatabaseName
WHERE DateSort.RowNumber=1
ORDER BY TotalReserved DESC, DatabaseName, SchemaName, TableName
GO

--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

CREATE PROCEDURE dbo.Util_Report_SpaceLog_TableSizeRunningGrowth
	@DatabaseName sysname='',
	@Days int
AS

--Current Size, Current Percentage, Growth from prior date, Running Total, Running Percentage
WITH
	SpaceLog_Table AS
	(
		SELECT
			ROW_NUMBER() OVER (PARTITION BY SpaceLog_Table.DatabaseName, SpaceLog_Table.SchemaName, SpaceLog_Table.TableName ORDER BY SpaceLog_Table.Date DESC) AS Date_RowNumber,
			ROW_NUMBER() OVER (PARTITION BY SpaceLog_Table.DatabaseName, SpaceLog_Table.Date ORDER BY SpaceLog_Table.TotalReserved DESC, SpaceLog_Table.SchemaName, SpaceLog_Table.TableName) AS Running_RowNumber,
			SpaceLog_Table.Date, SpaceLog_Table.DatabaseName, SpaceLog_Table.SchemaName, SpaceLog_Table.TableName, SpaceLog_Table.TotalReserved, SpaceLog_Table.Rows AS TotalRows,
			CASE WHEN SpaceLog_Table_Sum.sum_TotalReserved=0 THEN 0 ELSE CONVERT(Numeric(19,6), 100)*CONVERT(Numeric(19,6), SpaceLog_Table.TotalReserved)/CONVERT(Numeric(19,6), SpaceLog_Table_Sum.sum_TotalReserved) END AS PercentReserved,
			CASE WHEN SpaceLog_Table_Sum.sum_TotalRows=0 THEN 0 ELSE CONVERT(Numeric(19,6), 100)*CONVERT(Numeric(19,6), SpaceLog_Table.Rows)/CONVERT(Numeric(19,6), SpaceLog_Table_Sum.sum_TotalRows) END AS PercentRows
		FROM
			Admin.SpaceLog_Table
			JOIN (
				SELECT Date, DatabaseName, SUM(TotalReserved) AS sum_TotalReserved, SUM(Rows) AS sum_TotalRows FROM Admin.SpaceLog_Table GROUP BY Date, DatabaseName
			) AS SpaceLog_Table_Sum ON SpaceLog_Table.date=SpaceLog_Table_Sum.date AND SpaceLog_Table.DatabaseName=SpaceLog_Table_Sum.DatabaseName
		WHERE
			SpaceLog_Table.Date>DateAdd(dd, -90, GetDate())
			--AND SpaceLog_Table.DatabaseName LIKE CASE WHEN @DatabaseName='' THEN SpaceLog_Table.DatabaseName ELSE @DatabaseName END
	)
SELECT
	SpaceLog_Table1.Date, SpaceLog_Table1.DatabaseName, SpaceLog_Table1.SchemaName, SpaceLog_Table1.TableName,
	CONVERT(Numeric(19,6), CONVERT(Numeric(19,6), MAX(SpaceLog_Table1.TotalReserved))/1024.0) AS Reserved_MB,
	MAX(SpaceLog_Table1.TotalRows) AS Rows,
	CONVERT(Numeric(19,6), CONVERT(Numeric(19,6), MAX(SpaceLog_Table1.TotalReserved-SpaceLog_Table3.TotalReserved))/1024.0) AS GrowthFromPriorDate_MB,
	MAX(SpaceLog_Table1.TotalRows-SpaceLog_Table3.TotalRows) AS GrowthFromPriorDate_Rows,
	CONVERT(numeric(9,6), MAX(SpaceLog_Table1.PercentReserved)) AS ReservedPercentage,
	CONVERT(numeric(9,6), MAX(SpaceLog_Table1.PercentRows)) AS RowsPercentage,
	CONVERT(Numeric(19,6), CONVERT(Numeric(19,6), SUM(SpaceLog_Table2.TotalReserved))/1048576.0) AS Running_Reserved_GB,
	CONVERT(numeric(9,6), SUM(SpaceLog_Table2.PercentReserved)) AS Running_Reserved_Percentage--,
	--CONVERT(Numeric(19,6), CONVERT(Numeric(19,6), SUM(SpaceLog_Table2.TotalRows))/1048576.0) AS Running_Rows,
	--CONVERT(numeric(9,6), SUM(SpaceLog_Table2.PercentRows)) AS Running_Rows_Percentage
FROM
	--CTE
	SpaceLog_Table AS SpaceLog_Table1
	--Sorting, using only most recent date sample
	JOIN (
		SELECT
			ROW_NUMBER() OVER (ORDER BY SpaceLog_Table.DatabaseName, SpaceLog_Table.Date, SpaceLog_Table.TotalReserved DESC, SpaceLog_Table.SchemaName, SpaceLog_Table.TableName) AS Sort_RowNumber,
			SpaceLog_Table.DatabaseName, SpaceLog_Table.Date, SpaceLog_Table.SchemaName, SpaceLog_Table.TableName
		FROM
			(
				SELECT ROW_NUMBER() OVER(PARTITION BY DatabaseName ORDER BY Date DESC) AS RowNumber, Date, DatabaseName
				FROM Admin.SpaceLog_Database
			) AS TopDate
			JOIN Admin.SpaceLog_Table ON TopDate.Date=SpaceLog_Table.Date AND TopDate.DatabaseName=SpaceLog_Table.DatabaseName
		WHERE TopDate.RowNumber=1
	) AS SpaceLog_Table_Sort ON
		SpaceLog_Table1.DatabaseName=SpaceLog_Table_Sort.DatabaseName
		AND SpaceLog_Table1.SchemaName=SpaceLog_Table_Sort.SchemaName AND SpaceLog_Table1.TableName=SpaceLog_Table_Sort.TableName
	--Growth From Prior Date
	LEFT OUTER JOIN SpaceLog_Table AS SpaceLog_Table3 ON
		SpaceLog_Table3.Date_RowNumber=SpaceLog_Table1.Date_RowNumber+1 AND SpaceLog_Table3.DatabaseName=SpaceLog_Table1.DatabaseName
		AND SpaceLog_Table3.SchemaName=SpaceLog_Table1.SchemaName AND SpaceLog_Table3.TableName=SpaceLog_Table1.TableName
	--Running Aggregates
	INNER JOIN SpaceLog_Table AS SpaceLog_Table2 ON
		SpaceLog_Table2.Running_RowNumber<=SpaceLog_Table1.Running_RowNumber
		AND SpaceLog_Table2.Date=SpaceLog_Table1.Date AND SpaceLog_Table2.DatabaseName=SpaceLog_Table1.DatabaseName
GROUP BY SpaceLog_Table_Sort.Sort_RowNumber, SpaceLog_Table1.DatabaseName, SpaceLog_Table1.Date, SpaceLog_Table1.SchemaName, SpaceLog_Table1.TableName
ORDER BY SpaceLog_Table_Sort.Sort_RowNumber, SpaceLog_Table1.DatabaseName, SpaceLog_Table1.Date DESC, Running_Reserved_Percentage, SpaceLog_Table1.SchemaName, SpaceLog_Table1.TableName
GO

--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

/*
--Peek at all to space log tables
SELECT TOP 100 * FROM Admin.SpaceLog_Partition ORDER BY DatabaseName, Date DESC, TotalReserved DESC
SELECT TOP 100 * FROM Admin.SpaceLog_Index ORDER BY DatabaseName, Date DESC, TotalReserved DESC
SELECT TOP 100 * FROM Admin.SpaceLog_Table ORDER BY DatabaseName, Date DESC, TotalReserved DESC
SELECT TOP 100 * FROM Admin.SpaceLog_Schema ORDER BY DatabaseName, Date DESC, TotalReserved DESC
SELECT TOP 100 * FROM Admin.SpaceLog_DataSpace ORDER BY DatabaseName, Date DESC, TotalReserved DESC
SELECT TOP 100 * FROM Admin.SpaceLog_Database ORDER BY DatabaseName, Date DESC, TotalReserved DESC
*/
GO

--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=


