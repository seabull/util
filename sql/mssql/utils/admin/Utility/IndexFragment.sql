insert into [dbo].[MetaIndexFragmentHistory]
(
[database_name], [object_name], [index_name], [partition_number], [index_type_desc], 
[alloc_unit_type_desc], [avg_fragmentation_in_percent], [page_count], [index_level]
[recorded_date]
)
SELECT 
        DB_NAME(SDDIPS.[database_id]) AS [database_name], 
        OBJECT_NAME(SDDIPS.[object_id], DB_ID()) AS [object_name], 
        SSI.[name] AS [index_name], 
        SDDIPS.partition_number, 
        SDDIPS.index_type_desc, 
        SDDIPS.alloc_unit_type_desc, 
        SDDIPS.[avg_fragmentation_in_percent], 
        SDDIPS.[page_count],
        index_level,
        getdate()  as recorded_date
  FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID(N'dbo.FORTVault'), NULL, NULL, 'detailed') SDDIPS 
INNER JOIN sys.sysindexes SSI 
    ON SDDIPS.OBJECT_ID = SSI.id 
   AND SDDIPS.index_id = SSI.indid 
WHERE SDDIPS.page_count > 30 
--  AND avg_fragmentation_in_percent > 15 
  AND index_type_desc <> 'HEAP' 
  AND index_level = 0
ORDER BY OBJECT_NAME(SDDIPS.[object_id], DB_ID()), index_id

SELECT 
        DB_NAME(SDDIPS.[database_id]) AS [database_name], 
        OBJECT_NAME(SDDIPS.[object_id], DB_ID()) AS [object_name], 
        SSI.[name] AS [index_name], 
        SDDIPS.partition_number, 
        SDDIPS.index_type_desc, 
        SDDIPS.alloc_unit_type_desc, 
        SDDIPS.[avg_fragmentation_in_percent], 
        SDDIPS.[page_count],
        index_level,
        getdate()  as recorded_date
  FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID(N'dbo.FORTDataStore_POSRev'), NULL, NULL, 'detailed') SDDIPS 
INNER JOIN sys.sysindexes SSI 
    ON SDDIPS.OBJECT_ID = SSI.id 
   AND SDDIPS.index_id = SSI.indid 
WHERE SDDIPS.page_count > 30 
  AND avg_fragmentation_in_percent > 15 
  AND index_type_desc <> 'HEAP' 
  --AND index_level = 0
ORDER BY OBJECT_NAME(SDDIPS.[object_id], DB_ID()), index_id

SELECT 
        DB_NAME(SDDIPS.[database_id]) AS [database_name], 
        OBJECT_NAME(SDDIPS.[object_id], DB_ID()) AS [object_name], 
        SSI.[name] AS [index_name], 
        SDDIPS.partition_number, 
        SDDIPS.index_type_desc, 
        SDDIPS.alloc_unit_type_desc, 
        SDDIPS.[avg_fragmentation_in_percent], 
        SDDIPS.[page_count],
        index_level,
        getdate()  as recorded_date
  FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID(N'dbo.FORTDataStore_POSGM'), NULL, NULL, 'detailed') SDDIPS 
INNER JOIN sys.sysindexes SSI 
    ON SDDIPS.OBJECT_ID = SSI.id 
   AND SDDIPS.index_id = SSI.indid 
WHERE SDDIPS.page_count > 30 
  AND avg_fragmentation_in_percent > 15 
  AND index_type_desc <> 'HEAP' 
  --AND index_level = 0
ORDER BY OBJECT_NAME(SDDIPS.[object_id], DB_ID()), index_id

USE [PRFDB001]
GO
/****** Object:  Table [dbo].[MetaIndexFragmentHistory]    Script Date: 10/12/2009 15:22:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MetaIndexFragmentHistory]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[MetaIndexFragmentHistory](
    [id]                    bigint identity(1,1)    NOT NULL,
    [database_name]         [nvarchar](128)         NOT NULL,
    [object_name]           [nvarchar](128)         NOT NULL,
    [index_name]            [sysname]               NULL,
    [partition_number]      [int]                   NULL,
    [index_type_desc]       [nvarchar](60)          NULL,
    [alloc_unit_type_desc]  [nvarchar](60)          NULL,
    [avg_fragmentation_in_percent] [float]          NULL,
    [page_count]            [bigint]                NULL,
    [index_level]           [tinyint]               NULL,
    [recorded_date]         [datetime]              NOT NULL,
    constraint [PK_MetaIndexFragmentHistory] primary key nonclustered
    (
        id
    )
) ON [Group00]
END

CREATE CLUSTERED INDEX [IX_MetaIndexFragmentHistory_recorded_date] ON dbo.[MetaIndexFragmentHistory] 
(
    [recorded_date] ASC
) WITH (PAD_INDEX  = OFF, FILLFACTOR=90, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [Group00]

----------------------
ALTER INDEX IX_FORTvault                    on dbo.FORTVault REBUILD
ALTER INDEX IX_FORTvault_PIDOrderStartEndDT on dbo.FORTVault REBUILD
ALTER INDEX IX_FORTVault_TypeName           on dbo.FORTVault REBUILD
ALTER INDEX IX_FORTvault_PIDTypeStartEndDT  on dbo.FORTVault REBUILD

ALTER INDEX DataStorePOSRev_TimeIdx         on dbo.FORTDataStore_POSRev         REBUILD
ALTER INDEX PK_VaultDataPOSRev              on dbo.FORTDataStore_POSRev         REBUILD
ALTER INDEX DataStorePOSGM_TimeIdx          on dbo.FORTDataStore_POSGM          REBUILD
ALTER INDEX PK_VaultDataPOSGM               on dbo.FORTDataStore_POSGM          REBUILD
ALTER INDEX DataStorePOSOrganic_TimeIdx     on dbo.FORTDataStore_POSOrganic     REBUILD
ALTER INDEX PK_VaultDataPOSOrganic          on dbo.FORTDataStore_POSOrganic     REBUILD
ALTER INDEX DataStoreLabor_TimeIdx          on dbo.FORTDataStore_Labor          REBUILD
ALTER INDEX PK_VaultDataLabor               on dbo.FORTDataStore_Labor          REBUILD
ALTER INDEX DataStoreAllChannel_TimeIdx     on dbo.FORTDataStore_AllChannel     REBUILD
ALTER INDEX PK_VaultDataAllChannel          on dbo.FORTDataStore_AllChannel     REBUILD
ALTER INDEX DataStoreMultiChannel_TimeIdx   on dbo.FORTDataStore_MultiChannel   REBUILD
ALTER INDEX PK_VaultDataMultiChannel        on dbo.FORTDataStore_MultiChannel   REBUILD
