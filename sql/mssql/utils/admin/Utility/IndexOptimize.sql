SET ANSI_NULLS ON਍䜀伀ഀഀ
SET QUOTED_IDENTIFIER ON਍䜀伀ഀഀ
CREATE PROCEDURE [dbo].[IndexOptimize]਍ഀഀ
@Databases nvarchar(max),਍䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䠀椀最栀开䰀伀䈀 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀ 㴀 ✀䤀一䐀䔀堀开刀䔀䈀唀䤀䰀䐀开伀䘀䘀䰀䤀一䔀✀Ⰰഀഀ
@FragmentationHigh_NonLOB nvarchar(max) = 'INDEX_REBUILD_OFFLINE',਍䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䴀攀搀椀甀洀开䰀伀䈀 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀ 㴀 ✀䤀一䐀䔀堀开刀䔀伀刀䜀䄀一䤀娀䔀✀Ⰰഀഀ
@FragmentationMedium_NonLOB nvarchar(max) = 'INDEX_REORGANIZE',਍䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䰀漀眀开䰀伀䈀 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀ 㴀 ✀一伀吀䠀䤀一䜀✀Ⰰഀഀ
@FragmentationLow_NonLOB nvarchar(max) = 'NOTHING',਍䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䰀攀瘀攀氀㄀ 琀椀渀礀椀渀琀 㴀 㔀Ⰰഀഀ
@FragmentationLevel2 tinyint = 30,਍䀀倀愀最攀䌀漀甀渀琀䰀攀瘀攀氀 椀渀琀 㴀 ㄀　　　Ⰰഀഀ
@SortInTempdb nvarchar(max) = 'N',਍䀀䴀愀砀䐀伀倀 琀椀渀礀椀渀琀 㴀 一唀䰀䰀Ⰰഀഀ
@FillFactor tinyint = NULL,਍䀀䰀伀䈀䌀漀洀瀀愀挀琀椀漀渀 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀ 㴀 ✀夀✀Ⰰഀഀ
@StatisticsSample tinyint = NULL,਍䀀倀愀爀琀椀琀椀漀渀䰀攀瘀攀氀 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀ 㴀 ✀一✀Ⰰഀഀ
@TimeLimit int = NULL,਍䀀䔀砀攀挀甀琀攀 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀ 㴀 ✀夀✀ഀഀ
਍䄀匀ഀഀ
਍䈀䔀䜀䤀一ഀഀ
਍  ⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀഀഀ
  --// Set options                                                                                //--਍  ⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀഀഀ
਍  匀䔀吀 一伀䌀伀唀一吀 伀一ഀഀ
਍  匀䔀吀 䰀伀䌀䬀开吀䤀䴀䔀伀唀吀 ㌀㘀　　　　　ഀഀ
਍  ⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀഀഀ
  --// Declare variables                                                                          //--਍  ⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀഀഀ
਍  䐀䔀䌀䰀䄀刀䔀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀ഀഀ
  DECLARE @EndMessage nvarchar(max)਍  䐀䔀䌀䰀䄀刀䔀 䀀䐀愀琀愀戀愀猀攀䴀攀猀猀愀最攀 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀ഀഀ
  DECLARE @ErrorMessage nvarchar(max)਍ഀഀ
  DECLARE @StartTime datetime਍ഀഀ
  DECLARE @CurrentID int਍  䐀䔀䌀䰀䄀刀䔀 䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀ഀഀ
  DECLARE @CurrentIsDatabaseAccessible bit਍  䐀䔀䌀䰀䄀刀䔀 䀀䌀甀爀爀攀渀琀䴀椀爀爀漀爀椀渀最刀漀氀攀 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀ഀഀ
਍  䐀䔀䌀䰀䄀刀䔀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀匀攀氀攀挀琀　㄀ 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀ഀഀ
  DECLARE @CurrentCommandSelect02 nvarchar(max)਍  䐀䔀䌀䰀䄀刀䔀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀匀攀氀攀挀琀　㌀ 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀ഀഀ
  DECLARE @CurrentCommandSelect04 nvarchar(max)਍  䐀䔀䌀䰀䄀刀䔀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀匀攀氀攀挀琀　㔀 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀ഀഀ
਍  䐀䔀䌀䰀䄀刀䔀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㄀ 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀ഀഀ
  DECLARE @CurrentCommand02 nvarchar(max)਍ഀഀ
  DECLARE @CurrentCommandOutput01 int਍  䐀䔀䌀䰀䄀刀䔀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀伀甀琀瀀甀琀　㈀ 椀渀琀ഀഀ
਍  䐀䔀䌀䰀䄀刀䔀 䀀䌀甀爀爀攀渀琀䤀砀䤀䐀 椀渀琀ഀഀ
  DECLARE @CurrentSchemaID int਍  䐀䔀䌀䰀䄀刀䔀 䀀䌀甀爀爀攀渀琀匀挀栀攀洀愀一愀洀攀 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀ഀഀ
  DECLARE @CurrentObjectID int਍  䐀䔀䌀䰀䄀刀䔀 䀀䌀甀爀爀攀渀琀伀戀樀攀挀琀一愀洀攀 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀ഀഀ
  DECLARE @CurrentObjectType nvarchar(max)਍  䐀䔀䌀䰀䄀刀䔀 䀀䌀甀爀爀攀渀琀䤀渀搀攀砀䤀䐀 椀渀琀ഀഀ
  DECLARE @CurrentIndexName nvarchar(max)਍  䐀䔀䌀䰀䄀刀䔀 䀀䌀甀爀爀攀渀琀䤀渀搀攀砀吀礀瀀攀 椀渀琀ഀഀ
  DECLARE @CurrentPartitionID bigint਍  䐀䔀䌀䰀䄀刀䔀 䀀䌀甀爀爀攀渀琀倀愀爀琀椀琀椀漀渀一甀洀戀攀爀 椀渀琀ഀഀ
  DECLARE @CurrentPartitionCount int਍  䐀䔀䌀䰀䄀刀䔀 䀀䌀甀爀爀攀渀琀䤀猀倀愀爀琀椀琀椀漀渀 戀椀琀ഀഀ
  DECLARE @CurrentIndexExists bit਍  䐀䔀䌀䰀䄀刀䔀 䀀䌀甀爀爀攀渀琀䤀猀䰀伀䈀 戀椀琀ഀഀ
  DECLARE @CurrentAllowPageLocks bit਍  䐀䔀䌀䰀䄀刀䔀 䀀䌀甀爀爀攀渀琀伀渀刀攀愀搀伀渀氀礀䘀椀氀攀䜀爀漀甀瀀 戀椀琀ഀഀ
  DECLARE @CurrentFragmentationLevel float਍  䐀䔀䌀䰀䄀刀䔀 䀀䌀甀爀爀攀渀琀倀愀最攀䌀漀甀渀琀 戀椀最椀渀琀ഀഀ
  DECLARE @CurrentAction nvarchar(max)਍  䐀䔀䌀䰀䄀刀䔀 䀀䌀甀爀爀攀渀琀䌀漀洀洀攀渀琀 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀ഀഀ
਍  䐀䔀䌀䰀䄀刀䔀 䀀琀洀瀀䐀愀琀愀戀愀猀攀猀 吀䄀䈀䰀䔀 ⠀䤀䐀 椀渀琀 䤀䐀䔀一吀䤀吀夀 倀刀䤀䴀䄀刀夀 䬀䔀夀Ⰰഀഀ
                               DatabaseName nvarchar(max),਍                               䌀漀洀瀀氀攀琀攀搀 戀椀琀⤀ഀഀ
਍  䐀䔀䌀䰀䄀刀䔀 䀀琀洀瀀䤀渀搀攀砀攀猀 吀䄀䈀䰀䔀 ⠀䤀砀䤀䐀 椀渀琀 䤀䐀䔀一吀䤀吀夀 倀刀䤀䴀䄀刀夀 䬀䔀夀Ⰰഀഀ
                             SchemaID int,਍                             匀挀栀攀洀愀一愀洀攀 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀Ⰰഀഀ
                             ObjectID int,਍                             伀戀樀攀挀琀一愀洀攀 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀Ⰰഀഀ
                             ObjectType nvarchar(max),਍                             䤀渀搀攀砀䤀䐀 椀渀琀Ⰰഀഀ
                             IndexName nvarchar(max),਍                             䤀渀搀攀砀吀礀瀀攀 椀渀琀Ⰰഀഀ
                             PartitionID bigint,਍                             倀愀爀琀椀琀椀漀渀一甀洀戀攀爀 椀渀琀Ⰰഀഀ
                             PartitionCount int,਍                             䌀漀洀瀀氀攀琀攀搀 戀椀琀⤀ഀഀ
਍  䐀䔀䌀䰀䄀刀䔀 䀀琀洀瀀䤀渀搀攀砀䔀砀椀猀琀猀 吀䄀䈀䰀䔀 ⠀嬀䌀漀甀渀琀崀 椀渀琀⤀ഀഀ
਍  䐀䔀䌀䰀䄀刀䔀 䀀琀洀瀀䤀猀䰀伀䈀 吀䄀䈀䰀䔀 ⠀嬀䌀漀甀渀琀崀 椀渀琀⤀ഀഀ
਍  䐀䔀䌀䰀䄀刀䔀 䀀琀洀瀀䄀氀氀漀眀倀愀最攀䰀漀挀欀猀 吀䄀䈀䰀䔀 ⠀嬀䌀漀甀渀琀崀 椀渀琀⤀ഀഀ
਍  䐀䔀䌀䰀䄀刀䔀 䀀琀洀瀀伀渀刀攀愀搀伀渀氀礀䘀椀氀攀䜀爀漀甀瀀 吀䄀䈀䰀䔀 ⠀嬀䌀漀甀渀琀崀 椀渀琀⤀ഀഀ
਍  䐀䔀䌀䰀䄀刀䔀 䀀䄀挀琀椀漀渀猀 吀䄀䈀䰀䔀 ⠀嬀䄀挀琀椀漀渀崀 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀⤀ഀഀ
਍  䤀一匀䔀刀吀 䤀一吀伀 䀀䄀挀琀椀漀渀猀⠀嬀䄀挀琀椀漀渀崀⤀ 嘀䄀䰀唀䔀匀⠀✀䤀一䐀䔀堀开刀䔀䈀唀䤀䰀䐀开伀一䰀䤀一䔀✀⤀ഀഀ
  INSERT INTO @Actions([Action]) VALUES('INDEX_REBUILD_OFFLINE')਍  䤀一匀䔀刀吀 䤀一吀伀 䀀䄀挀琀椀漀渀猀⠀嬀䄀挀琀椀漀渀崀⤀ 嘀䄀䰀唀䔀匀⠀✀䤀一䐀䔀堀开刀䔀伀刀䜀䄀一䤀娀䔀✀⤀ഀഀ
  INSERT INTO @Actions([Action]) VALUES('STATISTICS_UPDATE')਍  䤀一匀䔀刀吀 䤀一吀伀 䀀䄀挀琀椀漀渀猀⠀嬀䄀挀琀椀漀渀崀⤀ 嘀䄀䰀唀䔀匀⠀✀䤀一䐀䔀堀开刀䔀伀刀䜀䄀一䤀娀䔀开匀吀䄀吀䤀匀吀䤀䌀匀开唀倀䐀䄀吀䔀✀⤀ഀഀ
  INSERT INTO @Actions([Action]) VALUES('NOTHING')਍ഀഀ
  DECLARE @Error int਍ഀഀ
  SET @Error = 0਍ഀഀ
  ----------------------------------------------------------------------------------------------------਍  ⴀⴀ⼀⼀ 䰀漀最 椀渀椀琀椀愀氀 椀渀昀漀爀洀愀琀椀漀渀                                                                    ⼀⼀ⴀⴀഀഀ
  ----------------------------------------------------------------------------------------------------਍ഀഀ
  SET @StartTime = CONVERT(datetime,CONVERT(nvarchar,GETDATE(),120),120)਍ഀഀ
  SET @StartMessage = 'DateTime: ' + CONVERT(nvarchar,@StartTime,120) + CHAR(13) + CHAR(10)਍  匀䔀吀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 㴀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 ⬀ ✀匀攀爀瘀攀爀㨀 ✀ ⬀ 䌀䄀匀吀⠀匀䔀刀嘀䔀刀倀刀伀倀䔀刀吀夀⠀✀匀攀爀瘀攀爀一愀洀攀✀⤀ 䄀匀 渀瘀愀爀挀栀愀爀⤀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
  SET @StartMessage = @StartMessage + 'Version: ' + CAST(SERVERPROPERTY('ProductVersion') AS nvarchar) + CHAR(13) + CHAR(10)਍  匀䔀吀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 㴀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 ⬀ ✀䔀搀椀琀椀漀渀㨀 ✀ ⬀ 䌀䄀匀吀⠀匀䔀刀嘀䔀刀倀刀伀倀䔀刀吀夀⠀✀䔀搀椀琀椀漀渀✀⤀ 䄀匀 渀瘀愀爀挀栀愀爀⤀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
  SET @StartMessage = @StartMessage + 'Procedure: ' + QUOTENAME(DB_NAME(DB_ID())) + '.' + (SELECT QUOTENAME(sys.schemas.name) FROM sys.schemas INNER JOIN sys.objects ON sys.schemas.[schema_id] = sys.objects.[schema_id] WHERE [object_id] = @@PROCID) + '.' + QUOTENAME(OBJECT_NAME(@@PROCID)) + CHAR(13) + CHAR(10)਍  匀䔀吀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 㴀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 ⬀ ✀倀愀爀愀洀攀琀攀爀猀㨀 䀀䐀愀琀愀戀愀猀攀猀 㴀 ✀ ⬀ 䤀匀一唀䰀䰀⠀✀✀✀✀ ⬀ 刀䔀倀䰀䄀䌀䔀⠀䀀䐀愀琀愀戀愀猀攀猀Ⰰ✀✀✀✀Ⰰ✀✀✀✀✀✀⤀ ⬀ ✀✀✀✀Ⰰ✀一唀䰀䰀✀⤀ഀഀ
  SET @StartMessage = @StartMessage + ', @FragmentationHigh_LOB = ' + ISNULL('''' + REPLACE(@FragmentationHigh_LOB,'''','''''') + '''','NULL')਍  匀䔀吀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 㴀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 ⬀ ✀Ⰰ 䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䠀椀最栀开一漀渀䰀伀䈀 㴀 ✀ ⬀ 䤀匀一唀䰀䰀⠀✀✀✀✀ ⬀ 刀䔀倀䰀䄀䌀䔀⠀䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䠀椀最栀开一漀渀䰀伀䈀Ⰰ✀✀✀✀Ⰰ✀✀✀✀✀✀⤀ ⬀ ✀✀✀✀Ⰰ✀一唀䰀䰀✀⤀ഀഀ
  SET @StartMessage = @StartMessage + ', @FragmentationMedium_LOB = ' + ISNULL('''' + REPLACE(@FragmentationMedium_LOB,'''','''''') + '''','NULL')਍  匀䔀吀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 㴀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 ⬀ ✀Ⰰ 䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䴀攀搀椀甀洀开一漀渀䰀伀䈀 㴀 ✀ ⬀ 䤀匀一唀䰀䰀⠀✀✀✀✀ ⬀ 刀䔀倀䰀䄀䌀䔀⠀䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䴀攀搀椀甀洀开一漀渀䰀伀䈀Ⰰ✀✀✀✀Ⰰ✀✀✀✀✀✀⤀ ⬀ ✀✀✀✀Ⰰ✀一唀䰀䰀✀⤀ഀഀ
  SET @StartMessage = @StartMessage + ', @FragmentationLow_LOB = ' + ISNULL('''' + REPLACE(@FragmentationLow_LOB,'''','''''') + '''','NULL')਍  匀䔀吀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 㴀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 ⬀ ✀Ⰰ 䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䰀漀眀开一漀渀䰀伀䈀 㴀 ✀ ⬀ 䤀匀一唀䰀䰀⠀✀✀✀✀ ⬀ 刀䔀倀䰀䄀䌀䔀⠀䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䰀漀眀开一漀渀䰀伀䈀Ⰰ✀✀✀✀Ⰰ✀✀✀✀✀✀⤀ ⬀ ✀✀✀✀Ⰰ✀一唀䰀䰀✀⤀ഀഀ
  SET @StartMessage = @StartMessage + ', @FragmentationLevel1 = ' + ISNULL(CAST(@FragmentationLevel1 AS nvarchar),'NULL')਍  匀䔀吀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 㴀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 ⬀ ✀Ⰰ 䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䰀攀瘀攀氀㈀ 㴀 ✀ ⬀ 䤀匀一唀䰀䰀⠀䌀䄀匀吀⠀䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䰀攀瘀攀氀㈀ 䄀匀 渀瘀愀爀挀栀愀爀⤀Ⰰ✀一唀䰀䰀✀⤀ഀഀ
  SET @StartMessage = @StartMessage + ', @PageCountLevel = ' + ISNULL(CAST(@PageCountLevel AS nvarchar),'NULL')਍  匀䔀吀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 㴀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 ⬀ ✀Ⰰ 䀀匀漀爀琀䤀渀吀攀洀瀀搀戀 㴀 ✀ ⬀ 䤀匀一唀䰀䰀⠀✀✀✀✀ ⬀ 刀䔀倀䰀䄀䌀䔀⠀䀀匀漀爀琀䤀渀吀攀洀瀀搀戀Ⰰ✀✀✀✀Ⰰ✀✀✀✀✀✀⤀ ⬀ ✀✀✀✀Ⰰ✀一唀䰀䰀✀⤀ഀഀ
  SET @StartMessage = @StartMessage + ', @MaxDOP = ' + ISNULL(CAST(@MaxDOP AS nvarchar),'NULL')਍  匀䔀吀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 㴀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 ⬀ ✀Ⰰ 䀀䘀椀氀氀䘀愀挀琀漀爀 㴀 ✀ ⬀ 䤀匀一唀䰀䰀⠀䌀䄀匀吀⠀䀀䘀椀氀氀䘀愀挀琀漀爀 䄀匀 渀瘀愀爀挀栀愀爀⤀Ⰰ✀一唀䰀䰀✀⤀ഀഀ
  SET @StartMessage = @StartMessage + ', @LOBCompaction = ' + ISNULL('''' + REPLACE(@LOBCompaction,'''','''''') + '''','NULL')਍  匀䔀吀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 㴀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 ⬀ ✀Ⰰ 䀀匀琀愀琀椀猀琀椀挀猀匀愀洀瀀氀攀 㴀 ✀ ⬀ 䤀匀一唀䰀䰀⠀䌀䄀匀吀⠀䀀匀琀愀琀椀猀琀椀挀猀匀愀洀瀀氀攀 䄀匀 渀瘀愀爀挀栀愀爀⤀Ⰰ✀一唀䰀䰀✀⤀ഀഀ
  SET @StartMessage = @StartMessage + ', @PartitionLevel = ' + ISNULL('''' + REPLACE(@PartitionLevel,'''','''''') + '''','NULL')਍  匀䔀吀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 㴀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 ⬀ ✀Ⰰ 䀀吀椀洀攀䰀椀洀椀琀 㴀 ✀ ⬀ 䤀匀一唀䰀䰀⠀䌀䄀匀吀⠀䀀吀椀洀攀䰀椀洀椀琀 䄀匀 渀瘀愀爀挀栀愀爀⤀Ⰰ✀一唀䰀䰀✀⤀ഀഀ
  SET @StartMessage = @StartMessage + ', @Execute = ' + ISNULL('''' + REPLACE(@Execute,'''','''''') + '''','NULL')਍  匀䔀吀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 㴀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
  SET @StartMessage = REPLACE(@StartMessage,'%','%%')਍  刀䄀䤀匀䔀刀刀伀刀⠀䀀匀琀愀爀琀䴀攀猀猀愀最攀Ⰰ㄀　Ⰰ㄀⤀ 圀䤀吀䠀 一伀圀䄀䤀吀ഀഀ
਍  ⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀഀഀ
  --// Select databases                                                                           //--਍  ⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀഀഀ
਍  䤀䘀 䀀䐀愀琀愀戀愀猀攀猀 䤀匀 一唀䰀䰀 伀刀 䀀䐀愀琀愀戀愀猀攀猀 㴀 ✀✀ഀഀ
  BEGIN਍    匀䔀吀 䀀䔀爀爀漀爀䴀攀猀猀愀最攀 㴀 ✀吀栀攀 瘀愀氀甀攀 昀漀爀 瀀愀爀愀洀攀琀攀爀 䀀䐀愀琀愀戀愀猀攀猀 椀猀 渀漀琀 猀甀瀀瀀漀爀琀攀搀⸀✀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT਍    匀䔀吀 䀀䔀爀爀漀爀 㴀 䀀䀀䔀刀刀伀刀ഀഀ
  END਍ഀഀ
  INSERT INTO @tmpDatabases (DatabaseName, Completed)਍  匀䔀䰀䔀䌀吀 䐀愀琀愀戀愀猀攀一愀洀攀 䄀匀 䐀愀琀愀戀愀猀攀一愀洀攀Ⰰഀഀ
         0 AS Completed਍  䘀刀伀䴀 搀戀漀⸀䐀愀琀愀戀愀猀攀匀攀氀攀挀琀 ⠀䀀䐀愀琀愀戀愀猀攀猀⤀ഀഀ
  ORDER BY DatabaseName ASC਍ഀഀ
  IF @@ERROR <> 0 OR (@@ROWCOUNT = 0 AND @Databases <> 'USER_DATABASES')਍  䈀䔀䜀䤀一ഀഀ
    SET @ErrorMessage = 'Error selecting databases.' + CHAR(13) + CHAR(10)਍    刀䄀䤀匀䔀刀刀伀刀⠀䀀䔀爀爀漀爀䴀攀猀猀愀最攀Ⰰ㄀㘀Ⰰ㄀⤀ 圀䤀吀䠀 一伀圀䄀䤀吀ഀഀ
    SET @Error = @@ERROR਍  䔀一䐀ഀഀ
਍  ⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀഀഀ
  --// Check input parameters                                                                     //--਍  ⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀഀഀ
਍  䤀䘀 䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䠀椀最栀开䰀伀䈀 一伀吀 䤀一⠀匀䔀䰀䔀䌀吀 嬀䄀挀琀椀漀渀崀 䘀刀伀䴀 䀀䄀挀琀椀漀渀猀 圀䠀䔀刀䔀 嬀䄀挀琀椀漀渀崀 㰀㸀 ✀䤀一䐀䔀堀开刀䔀䈀唀䤀䰀䐀开伀一䰀䤀一䔀✀⤀ഀഀ
  BEGIN਍    匀䔀吀 䀀䔀爀爀漀爀䴀攀猀猀愀最攀 㴀 ✀吀栀攀 瘀愀氀甀攀 昀漀爀 瀀愀爀愀洀攀琀攀爀 䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䠀椀最栀开䰀伀䈀 椀猀 渀漀琀 猀甀瀀瀀漀爀琀攀搀⸀✀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT਍    匀䔀吀 䀀䔀爀爀漀爀 㴀 䀀䀀䔀刀刀伀刀ഀഀ
  END਍ഀഀ
  IF @FragmentationHigh_NonLOB NOT IN(SELECT [Action] FROM @Actions WHERE [Action] <> 'INDEX_REBUILD_ONLINE' OR SERVERPROPERTY('EngineEdition') = 3)਍  䈀䔀䜀䤀一ഀഀ
    SET @ErrorMessage = 'The value for parameter @FragmentationHigh_NonLOB is not supported.' + CHAR(13) + CHAR(10)਍    刀䄀䤀匀䔀刀刀伀刀⠀䀀䔀爀爀漀爀䴀攀猀猀愀最攀Ⰰ㄀㘀Ⰰ㄀⤀ 圀䤀吀䠀 一伀圀䄀䤀吀ഀഀ
    SET @Error = @@ERROR਍  䔀一䐀ഀഀ
਍  䤀䘀 䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䴀攀搀椀甀洀开䰀伀䈀 一伀吀 䤀一⠀匀䔀䰀䔀䌀吀 嬀䄀挀琀椀漀渀崀 䘀刀伀䴀 䀀䄀挀琀椀漀渀猀 圀䠀䔀刀䔀 嬀䄀挀琀椀漀渀崀 㰀㸀 ✀䤀一䐀䔀堀开刀䔀䈀唀䤀䰀䐀开伀一䰀䤀一䔀✀⤀ഀഀ
  BEGIN਍    匀䔀吀 䀀䔀爀爀漀爀䴀攀猀猀愀最攀 㴀 ✀吀栀攀 瘀愀氀甀攀 昀漀爀 瀀愀爀愀洀攀琀攀爀 䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䴀攀搀椀甀洀开䰀伀䈀 椀猀 渀漀琀 猀甀瀀瀀漀爀琀攀搀⸀✀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT਍    匀䔀吀 䀀䔀爀爀漀爀 㴀 䀀䀀䔀刀刀伀刀ഀഀ
  END਍ഀഀ
  IF @FragmentationMedium_NonLOB NOT IN(SELECT [Action] FROM @Actions WHERE [Action] <> 'INDEX_REBUILD_ONLINE' OR SERVERPROPERTY('EngineEdition') = 3)਍  䈀䔀䜀䤀一ഀഀ
    SET @ErrorMessage = 'The value for parameter @FragmentationMedium_NonLOB is not supported.' + CHAR(13) + CHAR(10)਍    刀䄀䤀匀䔀刀刀伀刀⠀䀀䔀爀爀漀爀䴀攀猀猀愀最攀Ⰰ㄀㘀Ⰰ㄀⤀ 圀䤀吀䠀 一伀圀䄀䤀吀ഀഀ
    SET @Error = @@ERROR਍  䔀一䐀ഀഀ
਍  䤀䘀 䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䰀漀眀开䰀伀䈀 一伀吀 䤀一⠀匀䔀䰀䔀䌀吀 嬀䄀挀琀椀漀渀崀 䘀刀伀䴀 䀀䄀挀琀椀漀渀猀 圀䠀䔀刀䔀 嬀䄀挀琀椀漀渀崀 㰀㸀 ✀䤀一䐀䔀堀开刀䔀䈀唀䤀䰀䐀开伀一䰀䤀一䔀✀⤀ഀഀ
  BEGIN਍    匀䔀吀 䀀䔀爀爀漀爀䴀攀猀猀愀最攀 㴀 ✀吀栀攀 瘀愀氀甀攀 昀漀爀 瀀愀爀愀洀攀琀攀爀 䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䰀漀眀开䰀伀䈀 椀猀 渀漀琀 猀甀瀀瀀漀爀琀攀搀⸀✀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT਍    匀䔀吀 䀀䔀爀爀漀爀 㴀 䀀䀀䔀刀刀伀刀ഀഀ
  END਍ഀഀ
  IF @FragmentationLow_NonLOB NOT IN(SELECT [Action] FROM @Actions WHERE [Action] <> 'INDEX_REBUILD_ONLINE' OR SERVERPROPERTY('EngineEdition') = 3)਍  䈀䔀䜀䤀一ഀഀ
    SET @ErrorMessage = 'The value for parameter @FragmentationLow_NonLOB is not supported.' + CHAR(13) + CHAR(10)਍    刀䄀䤀匀䔀刀刀伀刀⠀䀀䔀爀爀漀爀䴀攀猀猀愀最攀Ⰰ㄀㘀Ⰰ㄀⤀ 圀䤀吀䠀 一伀圀䄀䤀吀ഀഀ
    SET @Error = @@ERROR਍  䔀一䐀ഀഀ
਍  䤀䘀 ✀䤀一䐀䔀堀开刀䔀䈀唀䤀䰀䐀开伀一䰀䤀一䔀✀ 䤀一⠀䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䠀椀最栀开一漀渀䰀伀䈀Ⰰ 䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䴀攀搀椀甀洀开一漀渀䰀伀䈀Ⰰ 䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䰀漀眀开一漀渀䰀伀䈀⤀ 䄀一䐀 匀䔀刀嘀䔀刀倀刀伀倀䔀刀吀夀⠀✀䔀渀最椀渀攀䔀搀椀琀椀漀渀✀⤀ 㰀㸀 ㌀ഀഀ
  BEGIN਍    匀䔀吀 䀀䔀爀爀漀爀䴀攀猀猀愀最攀 㴀 ✀伀渀氀椀渀攀 爀攀戀甀椀氀搀 椀猀 漀渀氀礀 猀甀瀀瀀漀爀琀攀搀 椀渀 䔀渀琀攀爀瀀爀椀猀攀 愀渀搀 䐀攀瘀攀氀漀瀀攀爀 䔀搀椀琀椀漀渀⸀✀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT਍    匀䔀吀 䀀䔀爀爀漀爀 㴀 䀀䀀䔀刀刀伀刀ഀഀ
  END਍ഀഀ
  IF 'INDEX_REBUILD_ONLINE' IN(@FragmentationHigh_LOB, @FragmentationMedium_LOB, @FragmentationLow_LOB)਍  䈀䔀䜀䤀一ഀഀ
    SET @ErrorMessage = 'Online rebuild is only supported on indexes with no LOB columns.' + CHAR(13) + CHAR(10)਍    刀䄀䤀匀䔀刀刀伀刀⠀䀀䔀爀爀漀爀䴀攀猀猀愀最攀Ⰰ㄀㘀Ⰰ㄀⤀ 圀䤀吀䠀 一伀圀䄀䤀吀ഀഀ
    SET @Error = @@ERROR਍  䔀一䐀ഀഀ
਍  䤀䘀 䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䰀攀瘀攀氀㄀ 㰀㴀 　 伀刀 䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䰀攀瘀攀氀㄀ 㸀㴀 ㄀　　 伀刀 䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䰀攀瘀攀氀㄀ 㸀㴀 䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䰀攀瘀攀氀㈀ 伀刀 䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䰀攀瘀攀氀㄀ 䤀匀 一唀䰀䰀ഀഀ
  BEGIN਍    匀䔀吀 䀀䔀爀爀漀爀䴀攀猀猀愀最攀 㴀 ✀吀栀攀 瘀愀氀甀攀 昀漀爀 瀀愀爀愀洀攀琀攀爀 䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䰀攀瘀攀氀㄀ 椀猀 渀漀琀 猀甀瀀瀀漀爀琀攀搀⸀✀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT਍    匀䔀吀 䀀䔀爀爀漀爀 㴀 䀀䀀䔀刀刀伀刀ഀഀ
  END਍ഀഀ
  IF @FragmentationLevel2 <= 0 OR @FragmentationLevel2 >= 100 OR @FragmentationLevel2 <= @FragmentationLevel1 OR @FragmentationLevel2 IS NULL਍  䈀䔀䜀䤀一ഀഀ
    SET @ErrorMessage = 'The value for parameter @FragmentationLevel2 is not supported.' + CHAR(13) + CHAR(10)਍    刀䄀䤀匀䔀刀刀伀刀⠀䀀䔀爀爀漀爀䴀攀猀猀愀最攀Ⰰ㄀㘀Ⰰ㄀⤀ 圀䤀吀䠀 一伀圀䄀䤀吀ഀഀ
    SET @Error = @@ERROR਍  䔀一䐀ഀഀ
਍  䤀䘀 䀀倀愀最攀䌀漀甀渀琀䰀攀瘀攀氀 㰀 　 伀刀 䀀倀愀最攀䌀漀甀渀琀䰀攀瘀攀氀 䤀匀 一唀䰀䰀ഀഀ
  BEGIN਍    匀䔀吀 䀀䔀爀爀漀爀䴀攀猀猀愀最攀 㴀 ✀吀栀攀 瘀愀氀甀攀 昀漀爀 瀀愀爀愀洀攀琀攀爀 䀀倀愀最攀䌀漀甀渀琀䰀攀瘀攀氀 椀猀 渀漀琀 猀甀瀀瀀漀爀琀攀搀⸀✀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT਍    匀䔀吀 䀀䔀爀爀漀爀 㴀 䀀䀀䔀刀刀伀刀ഀഀ
  END਍ഀഀ
  IF @SortInTempdb NOT IN('Y','N') OR @SortInTempdb IS NULL਍  䈀䔀䜀䤀一ഀഀ
    SET @ErrorMessage = 'The value for parameter @SortInTempdb is not supported.' + CHAR(13) + CHAR(10)਍    刀䄀䤀匀䔀刀刀伀刀⠀䀀䔀爀爀漀爀䴀攀猀猀愀最攀Ⰰ㄀㘀Ⰰ㄀⤀ 圀䤀吀䠀 一伀圀䄀䤀吀ഀഀ
    SET @Error = @@ERROR਍  䔀一䐀ഀഀ
਍  䤀䘀 䀀䴀愀砀䐀伀倀 㰀 　 伀刀 䀀䴀愀砀䐀伀倀 㸀 㘀㐀 伀刀 䀀䴀愀砀䐀伀倀 㸀 ⠀匀䔀䰀䔀䌀吀 挀瀀甀开挀漀甀渀琀 䘀刀伀䴀 猀礀猀⸀搀洀开漀猀开猀礀猀开椀渀昀漀⤀ 伀刀 ⠀䀀䴀愀砀䐀伀倀 㸀 ㄀ 䄀一䐀 匀䔀刀嘀䔀刀倀刀伀倀䔀刀吀夀⠀✀䔀渀最椀渀攀䔀搀椀琀椀漀渀✀⤀ 㰀㸀 ㌀⤀ഀഀ
  BEGIN਍    匀䔀吀 䀀䔀爀爀漀爀䴀攀猀猀愀最攀 㴀 ✀吀栀攀 瘀愀氀甀攀 昀漀爀 瀀愀爀愀洀攀琀攀爀 䀀䴀愀砀䐀伀倀 椀猀 渀漀琀 猀甀瀀瀀漀爀琀攀搀⸀✀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT਍    匀䔀吀 䀀䔀爀爀漀爀 㴀 䀀䀀䔀刀刀伀刀ഀഀ
  END਍ഀഀ
  IF @MaxDOP > 1 AND SERVERPROPERTY('EngineEdition') <> 3਍  䈀䔀䜀䤀一ഀഀ
    SET @ErrorMessage = 'Parallel index operations are only supported in Enterprise and Developer Edition.' + CHAR(13) + CHAR(10)਍    刀䄀䤀匀䔀刀刀伀刀⠀䀀䔀爀爀漀爀䴀攀猀猀愀最攀Ⰰ㄀㘀Ⰰ㄀⤀ 圀䤀吀䠀 一伀圀䄀䤀吀ഀഀ
    SET @Error = @@ERROR਍  䔀一䐀ഀഀ
਍  䤀䘀 䀀䘀椀氀氀䘀愀挀琀漀爀 㰀㴀 　 伀刀 䀀䘀椀氀氀䘀愀挀琀漀爀 㸀 ㄀　　ഀഀ
  BEGIN਍    匀䔀吀 䀀䔀爀爀漀爀䴀攀猀猀愀最攀 㴀 ✀吀栀攀 瘀愀氀甀攀 昀漀爀 瀀愀爀愀洀攀琀攀爀 䀀䘀椀氀氀䘀愀挀琀漀爀 椀猀 渀漀琀 猀甀瀀瀀漀爀琀攀搀⸀✀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT਍    匀䔀吀 䀀䔀爀爀漀爀 㴀 䀀䀀䔀刀刀伀刀ഀഀ
  END਍ഀഀ
  IF @LOBCompaction NOT IN('Y','N') OR @LOBCompaction IS NULL਍  䈀䔀䜀䤀一ഀഀ
    SET @ErrorMessage = 'The value for parameter @LOBCompaction is not supported.' + CHAR(13) + CHAR(10)਍    刀䄀䤀匀䔀刀刀伀刀⠀䀀䔀爀爀漀爀䴀攀猀猀愀最攀Ⰰ㄀㘀Ⰰ㄀⤀ 圀䤀吀䠀 一伀圀䄀䤀吀ഀഀ
    SET @Error = @@ERROR਍  䔀一䐀ഀഀ
਍  䤀䘀 䀀匀琀愀琀椀猀琀椀挀猀匀愀洀瀀氀攀 㰀㴀 　 伀刀 䀀匀琀愀琀椀猀琀椀挀猀匀愀洀瀀氀攀  㸀 ㄀　　ഀഀ
  OR (@StatisticsSample IS NOT NULL AND 'INDEX_REORGANIZE_STATISTICS_UPDATE' NOT IN(@FragmentationHigh_LOB, @FragmentationHigh_NonLOB, @FragmentationMedium_LOB, @FragmentationMedium_NonLOB, @FragmentationLow_LOB, @FragmentationLow_NonLOB) AND 'STATISTICS_UPDATE' NOT IN(@FragmentationHigh_LOB, @FragmentationHigh_NonLOB, @FragmentationMedium_LOB, @FragmentationMedium_NonLOB, @FragmentationLow_LOB, @FragmentationLow_NonLOB))਍  䈀䔀䜀䤀一ഀഀ
    SET @ErrorMessage = 'The value for parameter @StatisticsSample is not supported.' + CHAR(13) + CHAR(10)਍    刀䄀䤀匀䔀刀刀伀刀⠀䀀䔀爀爀漀爀䴀攀猀猀愀最攀Ⰰ㄀㘀Ⰰ㄀⤀ 圀䤀吀䠀 一伀圀䄀䤀吀ഀഀ
    SET @Error = @@ERROR਍  䔀一䐀ഀഀ
਍  䤀䘀 䀀倀愀爀琀椀琀椀漀渀䰀攀瘀攀氀 一伀吀 䤀一⠀✀夀✀Ⰰ✀一✀⤀ 伀刀 䀀倀愀爀琀椀琀椀漀渀䰀攀瘀攀氀 䤀匀 一唀䰀䰀 伀刀 ⠀䀀倀愀爀琀椀琀椀漀渀䰀攀瘀攀氀 㴀 ✀夀✀ 䄀一䐀 匀䔀刀嘀䔀刀倀刀伀倀䔀刀吀夀⠀✀䔀渀最椀渀攀䔀搀椀琀椀漀渀✀⤀ 㰀㸀 ㌀⤀ഀഀ
  BEGIN਍    匀䔀吀 䀀䔀爀爀漀爀䴀攀猀猀愀最攀 㴀 ✀吀栀攀 瘀愀氀甀攀 昀漀爀 瀀愀爀愀洀攀琀攀爀 䀀倀愀爀琀椀琀椀漀渀䰀攀瘀攀氀 椀猀 渀漀琀 猀甀瀀瀀漀爀琀攀搀⸀✀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT਍    匀䔀吀 䀀䔀爀爀漀爀 㴀 䀀䀀䔀刀刀伀刀ഀഀ
  END਍ഀഀ
  IF @PartitionLevel = 'Y' AND SERVERPROPERTY('EngineEdition') <> 3਍  䈀䔀䜀䤀一ഀഀ
    SET @ErrorMessage = 'Table partitioning is only supported in Enterprise and Developer Edition.' + CHAR(13) + CHAR(10)਍    刀䄀䤀匀䔀刀刀伀刀⠀䀀䔀爀爀漀爀䴀攀猀猀愀最攀Ⰰ㄀㘀Ⰰ㄀⤀ 圀䤀吀䠀 一伀圀䄀䤀吀ഀഀ
    SET @Error = @@ERROR਍  䔀一䐀ഀഀ
਍  䤀䘀 䀀吀椀洀攀䰀椀洀椀琀 㰀 　ഀഀ
  BEGIN਍    匀䔀吀 䀀䔀爀爀漀爀䴀攀猀猀愀最攀 㴀 ✀吀栀攀 瘀愀氀甀攀 昀漀爀 瀀愀爀愀洀攀琀攀爀 䀀吀椀洀攀䰀椀洀椀琀 椀猀 渀漀琀 猀甀瀀瀀漀爀琀攀搀⸀✀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT਍    匀䔀吀 䀀䔀爀爀漀爀 㴀 䀀䀀䔀刀刀伀刀ഀഀ
  END਍ഀഀ
  IF @Execute NOT IN('Y','N') OR @Execute IS NULL਍  䈀䔀䜀䤀一ഀഀ
    SET @ErrorMessage = 'The value for parameter @Execute is not supported.' + CHAR(13) + CHAR(10)਍    刀䄀䤀匀䔀刀刀伀刀⠀䀀䔀爀爀漀爀䴀攀猀猀愀最攀Ⰰ㄀㘀Ⰰ㄀⤀ 圀䤀吀䠀 一伀圀䄀䤀吀ഀഀ
    SET @Error = @@ERROR਍  䔀一䐀ഀഀ
਍  ⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀഀഀ
  --// Check error variable                                                                       //--਍  ⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀഀഀ
਍  䤀䘀 䀀䔀爀爀漀爀 㰀㸀 　 䜀伀吀伀 䰀漀最最椀渀最ഀഀ
਍  ⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀഀഀ
  --// Execute commands                                                                           //--਍  ⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀഀഀ
਍  圀䠀䤀䰀䔀 䔀堀䤀匀吀匀 ⠀匀䔀䰀䔀䌀吀 ⨀ 䘀刀伀䴀 䀀琀洀瀀䐀愀琀愀戀愀猀攀猀 圀䠀䔀刀䔀 䌀漀洀瀀氀攀琀攀搀 㴀 　⤀ഀഀ
  BEGIN਍ഀഀ
    SELECT TOP 1 @CurrentID = ID,਍                 䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀 㴀 䐀愀琀愀戀愀猀攀一愀洀攀ഀഀ
    FROM @tmpDatabases਍    圀䠀䔀刀䔀 䌀漀洀瀀氀攀琀攀搀 㴀 　ഀഀ
    ORDER BY ID ASC਍ഀഀ
    IF EXISTS (SELECT * FROM sys.database_recovery_status WHERE database_id = DB_ID(@CurrentDatabase) AND database_guid IS NOT NULL)਍    䈀䔀䜀䤀一ഀഀ
      SET @CurrentIsDatabaseAccessible = 1਍    䔀一䐀ഀഀ
    ELSE਍    䈀䔀䜀䤀一ഀഀ
      SET @CurrentIsDatabaseAccessible = 0਍    䔀一䐀ഀഀ
਍    匀䔀䰀䔀䌀吀 䀀䌀甀爀爀攀渀琀䴀椀爀爀漀爀椀渀最刀漀氀攀 㴀 洀椀爀爀漀爀椀渀最开爀漀氀攀开搀攀猀挀ഀഀ
    FROM sys.database_mirroring਍    圀䠀䔀刀䔀 搀愀琀愀戀愀猀攀开椀搀 㴀 䐀䈀开䤀䐀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ഀഀ
਍    ⴀⴀ 匀攀琀 搀愀琀愀戀愀猀攀 洀攀猀猀愀最攀ഀഀ
    SET @DatabaseMessage = 'DateTime: ' + CONVERT(nvarchar,GETDATE(),120) + CHAR(13) + CHAR(10)਍    匀䔀吀 䀀䐀愀琀愀戀愀猀攀䴀攀猀猀愀最攀 㴀 䀀䐀愀琀愀戀愀猀攀䴀攀猀猀愀最攀 ⬀ ✀䐀愀琀愀戀愀猀攀㨀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
    SET @DatabaseMessage = @DatabaseMessage + 'Status: ' + CAST(DATABASEPROPERTYEX(@CurrentDatabase,'Status') AS nvarchar) + CHAR(13) + CHAR(10)਍    匀䔀吀 䀀䐀愀琀愀戀愀猀攀䴀攀猀猀愀最攀 㴀 䀀䐀愀琀愀戀愀猀攀䴀攀猀猀愀最攀 ⬀ ✀䴀椀爀爀漀爀椀渀最 爀漀氀攀㨀 ✀ ⬀ 䤀匀一唀䰀䰀⠀䀀䌀甀爀爀攀渀琀䴀椀爀爀漀爀椀渀最刀漀氀攀Ⰰ✀一漀渀攀✀⤀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
    SET @DatabaseMessage = @DatabaseMessage + 'Standby: ' + CASE WHEN DATABASEPROPERTYEX(@CurrentDatabase,'IsInStandBy') = 1 THEN 'Yes' ELSE 'No' END + CHAR(13) + CHAR(10)਍    匀䔀吀 䀀䐀愀琀愀戀愀猀攀䴀攀猀猀愀最攀 㴀 䀀䐀愀琀愀戀愀猀攀䴀攀猀猀愀最攀 ⬀ ✀唀瀀搀愀琀攀愀戀椀氀椀琀礀㨀 ✀ ⬀ 䌀䄀匀吀⠀䐀䄀吀䄀䈀䄀匀䔀倀刀伀倀䔀刀吀夀䔀堀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀Ⰰ✀唀瀀搀愀琀攀愀戀椀氀椀琀礀✀⤀ 䄀匀 渀瘀愀爀挀栀愀爀⤀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
    SET @DatabaseMessage = @DatabaseMessage + 'User access: ' + CAST(DATABASEPROPERTYEX(@CurrentDatabase,'UserAccess') AS nvarchar) + CHAR(13) + CHAR(10)਍    匀䔀吀 䀀䐀愀琀愀戀愀猀攀䴀攀猀猀愀最攀 㴀 䀀䐀愀琀愀戀愀猀攀䴀攀猀猀愀最攀 ⬀ ✀䤀猀 愀挀挀攀猀猀椀戀氀攀㨀 ✀ ⬀ 䌀䄀匀䔀 圀䠀䔀一 䀀䌀甀爀爀攀渀琀䤀猀䐀愀琀愀戀愀猀攀䄀挀挀攀猀猀椀戀氀攀 㴀 ㄀ 吀䠀䔀一 ✀夀攀猀✀ 䔀䰀匀䔀 ✀一漀✀ 䔀一䐀 ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
    SET @DatabaseMessage = @DatabaseMessage + 'Recovery model: ' + CAST(DATABASEPROPERTYEX(@CurrentDatabase,'Recovery') AS nvarchar) + CHAR(13) + CHAR(10)਍    匀䔀吀 䀀䐀愀琀愀戀愀猀攀䴀攀猀猀愀最攀 㴀 刀䔀倀䰀䄀䌀䔀⠀䀀䐀愀琀愀戀愀猀攀䴀攀猀猀愀最攀Ⰰ✀─✀Ⰰ✀──✀⤀ഀഀ
    RAISERROR(@DatabaseMessage,10,1) WITH NOWAIT਍ഀഀ
    IF DATABASEPROPERTYEX(@CurrentDatabase,'Status') = 'ONLINE'਍    䄀一䐀 一伀吀 ⠀䐀䄀吀䄀䈀䄀匀䔀倀刀伀倀䔀刀吀夀䔀堀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀Ⰰ✀唀猀攀爀䄀挀挀攀猀猀✀⤀ 㴀 ✀匀䤀一䜀䰀䔀开唀匀䔀刀✀ 䄀一䐀 䀀䌀甀爀爀攀渀琀䤀猀䐀愀琀愀戀愀猀攀䄀挀挀攀猀猀椀戀氀攀 㴀 　⤀ഀഀ
    AND DATABASEPROPERTYEX(@CurrentDatabase,'Updateability') = 'READ_WRITE'਍    䈀䔀䜀䤀一ഀഀ
਍      ⴀⴀ 匀攀氀攀挀琀 椀渀搀攀砀攀猀 椀渀 琀栀攀 挀甀爀爀攀渀琀 搀愀琀愀戀愀猀攀ഀഀ
      IF @PartitionLevel = 'N' SET @CurrentCommandSelect01 = 'SELECT ' + QUOTENAME(@CurrentDatabase) + '.sys.schemas.[schema_id], ' + QUOTENAME(@CurrentDatabase) + '.sys.schemas.[name], ' + QUOTENAME(@CurrentDatabase) + '.sys.objects.[object_id], ' + QUOTENAME(@CurrentDatabase) + '.sys.objects.[name], RTRIM(' + QUOTENAME(@CurrentDatabase) + '.sys.objects.[type]), ' + QUOTENAME(@CurrentDatabase) + '.sys.indexes.index_id, ' + QUOTENAME(@CurrentDatabase) + '.sys.indexes.[name], ' + QUOTENAME(@CurrentDatabase) + '.sys.indexes.[type], NULL AS partition_id, NULL AS partition_number, NULL AS partition_count, 0 AS completed FROM ' + QUOTENAME(@CurrentDatabase) + '.sys.indexes INNER JOIN ' + QUOTENAME(@CurrentDatabase) + '.sys.objects ON ' + QUOTENAME(@CurrentDatabase) + '.sys.indexes.[object_id] = ' + QUOTENAME(@CurrentDatabase) + '.sys.objects.[object_id] INNER JOIN ' + QUOTENAME(@CurrentDatabase) + '.sys.schemas ON ' + QUOTENAME(@CurrentDatabase) + '.sys.objects.[schema_id] = ' + QUOTENAME(@CurrentDatabase) + '.sys.schemas.[schema_id] WHERE ' + QUOTENAME(@CurrentDatabase) + '.sys.objects.[type] IN(''U'',''V'') AND ' + QUOTENAME(@CurrentDatabase) + '.sys.objects.is_ms_shipped = 0 AND ' + QUOTENAME(@CurrentDatabase) + '.sys.indexes.[type] IN(1,2,3,4) AND ' + QUOTENAME(@CurrentDatabase) + '.sys.indexes.is_disabled = 0 AND ' + QUOTENAME(@CurrentDatabase) + '.sys.indexes.is_hypothetical = 0 ORDER BY ' + QUOTENAME(@CurrentDatabase) + '.sys.schemas.[schema_id] ASC, ' + QUOTENAME(@CurrentDatabase) + '.sys.objects.[object_id] ASC, ' + QUOTENAME(@CurrentDatabase) + '.sys.indexes.index_id ASC'਍      䤀䘀 䀀倀愀爀琀椀琀椀漀渀䰀攀瘀攀氀 㴀 ✀夀✀ 匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀匀攀氀攀挀琀　㄀ 㴀 ✀匀䔀䰀䔀䌀吀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀猀挀栀攀洀愀猀⸀嬀猀挀栀攀洀愀开椀搀崀Ⰰ ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀猀挀栀攀洀愀猀⸀嬀渀愀洀攀崀Ⰰ ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀漀戀樀攀挀琀猀⸀嬀漀戀樀攀挀琀开椀搀崀Ⰰ ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀漀戀樀攀挀琀猀⸀嬀渀愀洀攀崀Ⰰ 刀吀刀䤀䴀⠀✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀漀戀樀攀挀琀猀⸀嬀琀礀瀀攀崀⤀Ⰰ ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀攀猀⸀椀渀搀攀砀开椀搀Ⰰ ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀攀猀⸀嬀渀愀洀攀崀Ⰰ ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀攀猀⸀嬀琀礀瀀攀崀Ⰰ ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀瀀愀爀琀椀琀椀漀渀猀⸀瀀愀爀琀椀琀椀漀渀开椀搀Ⰰ ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀瀀愀爀琀椀琀椀漀渀猀⸀瀀愀爀琀椀琀椀漀渀开渀甀洀戀攀爀Ⰰ 䤀渀搀攀砀倀愀爀琀椀琀椀漀渀猀⸀瀀愀爀琀椀琀椀漀渀开挀漀甀渀琀Ⰰ 　 䄀匀 挀漀洀瀀氀攀琀攀搀 䘀刀伀䴀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀攀猀 䤀一一䔀刀 䨀伀䤀一 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀漀戀樀攀挀琀猀 伀一 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀攀猀⸀嬀漀戀樀攀挀琀开椀搀崀 㴀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀漀戀樀攀挀琀猀⸀嬀漀戀樀攀挀琀开椀搀崀 䤀一一䔀刀 䨀伀䤀一 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀猀挀栀攀洀愀猀 伀一 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀漀戀樀攀挀琀猀⸀嬀猀挀栀攀洀愀开椀搀崀 㴀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀猀挀栀攀洀愀猀⸀嬀猀挀栀攀洀愀开椀搀崀 䰀䔀䘀吀 伀唀吀䔀刀 䨀伀䤀一 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀瀀愀爀琀椀琀椀漀渀猀 伀一 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀攀猀⸀嬀漀戀樀攀挀琀开椀搀崀 㴀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀瀀愀爀琀椀琀椀漀渀猀⸀嬀漀戀樀攀挀琀开椀搀崀 䄀一䐀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀攀猀⸀椀渀搀攀砀开椀搀 㴀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀瀀愀爀琀椀琀椀漀渀猀⸀椀渀搀攀砀开椀搀 䰀䔀䘀吀 伀唀吀䔀刀 䨀伀䤀一 ⠀匀䔀䰀䔀䌀吀 嬀漀戀樀攀挀琀开椀搀崀Ⰰ 椀渀搀攀砀开椀搀Ⰰ 䌀伀唀一吀⠀⨀⤀ 䄀匀 瀀愀爀琀椀琀椀漀渀开挀漀甀渀琀 䘀刀伀䴀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀瀀愀爀琀椀琀椀漀渀猀 䜀刀伀唀倀 䈀夀 嬀漀戀樀攀挀琀开椀搀崀Ⰰ 椀渀搀攀砀开椀搀⤀ 䤀渀搀攀砀倀愀爀琀椀琀椀漀渀猀 伀一 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀瀀愀爀琀椀琀椀漀渀猀⸀嬀漀戀樀攀挀琀开椀搀崀 㴀 䤀渀搀攀砀倀愀爀琀椀琀椀漀渀猀⸀嬀漀戀樀攀挀琀开椀搀崀 䄀一䐀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀瀀愀爀琀椀琀椀漀渀猀⸀嬀椀渀搀攀砀开椀搀崀 㴀 䤀渀搀攀砀倀愀爀琀椀琀椀漀渀猀⸀嬀椀渀搀攀砀开椀搀崀 圀䠀䔀刀䔀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀漀戀樀攀挀琀猀⸀嬀琀礀瀀攀崀 䤀一⠀✀✀唀✀✀Ⰰ✀✀嘀✀✀⤀ 䄀一䐀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀漀戀樀攀挀琀猀⸀椀猀开洀猀开猀栀椀瀀瀀攀搀 㴀 　 䄀一䐀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀攀猀⸀嬀琀礀瀀攀崀 䤀一⠀㄀Ⰰ㈀Ⰰ㌀Ⰰ㐀⤀ 䄀一䐀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀攀猀⸀椀猀开搀椀猀愀戀氀攀搀 㴀 　 䄀一䐀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀攀猀⸀椀猀开栀礀瀀漀琀栀攀琀椀挀愀氀 㴀 　 伀刀䐀䔀刀 䈀夀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀猀挀栀攀洀愀猀⸀嬀猀挀栀攀洀愀开椀搀崀 䄀匀䌀Ⰰ ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀漀戀樀攀挀琀猀⸀嬀漀戀樀攀挀琀开椀搀崀 䄀匀䌀Ⰰ ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀攀猀⸀椀渀搀攀砀开椀搀 䄀匀䌀Ⰰ ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀瀀愀爀琀椀琀椀漀渀猀⸀瀀愀爀琀椀琀椀漀渀开渀甀洀戀攀爀 䄀匀䌀✀ഀഀ
਍      䤀一匀䔀刀吀 䤀一吀伀 䀀琀洀瀀䤀渀搀攀砀攀猀 ⠀匀挀栀攀洀愀䤀䐀Ⰰ 匀挀栀攀洀愀一愀洀攀Ⰰ 伀戀樀攀挀琀䤀䐀Ⰰ 伀戀樀攀挀琀一愀洀攀Ⰰ 伀戀樀攀挀琀吀礀瀀攀Ⰰ 䤀渀搀攀砀䤀䐀Ⰰ 䤀渀搀攀砀一愀洀攀Ⰰ 䤀渀搀攀砀吀礀瀀攀Ⰰ 倀愀爀琀椀琀椀漀渀䤀䐀Ⰰ 倀愀爀琀椀琀椀漀渀一甀洀戀攀爀Ⰰ 倀愀爀琀椀琀椀漀渀䌀漀甀渀琀Ⰰ 䌀漀洀瀀氀攀琀攀搀⤀ഀഀ
      EXECUTE(@CurrentCommandSelect01)਍ഀഀ
      WHILE EXISTS (SELECT * FROM @tmpIndexes WHERE Completed = 0)਍      䈀䔀䜀䤀一ഀഀ
਍        匀䔀䰀䔀䌀吀 吀伀倀 ㄀ 䀀䌀甀爀爀攀渀琀䤀砀䤀䐀 㴀 䤀砀䤀䐀Ⰰഀഀ
                     @CurrentSchemaID = SchemaID,਍                     䀀䌀甀爀爀攀渀琀匀挀栀攀洀愀一愀洀攀 㴀 匀挀栀攀洀愀一愀洀攀Ⰰഀഀ
                     @CurrentObjectID = ObjectID,਍                     䀀䌀甀爀爀攀渀琀伀戀樀攀挀琀一愀洀攀 㴀 伀戀樀攀挀琀一愀洀攀Ⰰഀഀ
                     @CurrentObjectType = ObjectType,਍                     䀀䌀甀爀爀攀渀琀䤀渀搀攀砀䤀䐀 㴀 䤀渀搀攀砀䤀䐀Ⰰഀഀ
                     @CurrentIndexName = IndexName,਍                     䀀䌀甀爀爀攀渀琀䤀渀搀攀砀吀礀瀀攀 㴀 䤀渀搀攀砀吀礀瀀攀Ⰰഀഀ
                     @CurrentPartitionID = PartitionID,਍                     䀀䌀甀爀爀攀渀琀倀愀爀琀椀琀椀漀渀一甀洀戀攀爀 㴀 倀愀爀琀椀琀椀漀渀一甀洀戀攀爀Ⰰഀഀ
                     @CurrentPartitionCount = PartitionCount਍        䘀刀伀䴀 䀀琀洀瀀䤀渀搀攀砀攀猀ഀഀ
        WHERE Completed = 0਍        伀刀䐀䔀刀 䈀夀 䤀砀䤀䐀 䄀匀䌀ഀഀ
਍        ⴀⴀ 䤀猀 琀栀攀 椀渀搀攀砀 愀 瀀愀爀琀椀琀椀漀渀㼀ഀഀ
        IF @CurrentPartitionNumber IS NULL OR @CurrentPartitionCount = 1 BEGIN SET @CurrentIsPartition = 0 END ELSE BEGIN SET @CurrentIsPartition = 1 END਍ഀഀ
        -- Does the index exist?਍        䤀䘀 䀀䌀甀爀爀攀渀琀䤀猀倀愀爀琀椀琀椀漀渀 㴀 　 匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀匀攀氀攀挀琀　㈀ 㴀 ✀匀䔀䰀䔀䌀吀 䌀伀唀一吀⠀⨀⤀ 䘀刀伀䴀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀攀猀 䤀一一䔀刀 䨀伀䤀一 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀漀戀樀攀挀琀猀 伀一 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀攀猀⸀嬀漀戀樀攀挀琀开椀搀崀 㴀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀漀戀樀攀挀琀猀⸀嬀漀戀樀攀挀琀开椀搀崀 䤀一一䔀刀 䨀伀䤀一 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀猀挀栀攀洀愀猀 伀一 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀漀戀樀攀挀琀猀⸀嬀猀挀栀攀洀愀开椀搀崀 㴀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀猀挀栀攀洀愀猀⸀嬀猀挀栀攀洀愀开椀搀崀 圀䠀䔀刀䔀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀漀戀樀攀挀琀猀⸀嬀琀礀瀀攀崀 䤀一⠀✀✀唀✀✀Ⰰ✀✀嘀✀✀⤀ 䄀一䐀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀漀戀樀攀挀琀猀⸀椀猀开洀猀开猀栀椀瀀瀀攀搀 㴀 　 䄀一䐀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀攀猀⸀嬀琀礀瀀攀崀 䤀一⠀㄀Ⰰ㈀Ⰰ㌀Ⰰ㐀⤀ 䄀一䐀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀攀猀⸀椀猀开搀椀猀愀戀氀攀搀 㴀 　 䄀一䐀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀攀猀⸀椀猀开栀礀瀀漀琀栀攀琀椀挀愀氀 㴀 　 䄀一䐀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀猀挀栀攀洀愀猀⸀嬀猀挀栀攀洀愀开椀搀崀 㴀 ✀ ⬀ 䌀䄀匀吀⠀䀀䌀甀爀爀攀渀琀匀挀栀攀洀愀䤀䐀 䄀匀 渀瘀愀爀挀栀愀爀⤀ ⬀ ✀ 䄀一䐀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀猀挀栀攀洀愀猀⸀嬀渀愀洀攀崀 㴀 一✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀匀挀栀攀洀愀一愀洀攀Ⰰ✀✀✀✀⤀ ⬀ ✀ 䄀一䐀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀漀戀樀攀挀琀猀⸀嬀漀戀樀攀挀琀开椀搀崀 㴀 ✀ ⬀ 䌀䄀匀吀⠀䀀䌀甀爀爀攀渀琀伀戀樀攀挀琀䤀䐀 䄀匀 渀瘀愀爀挀栀愀爀⤀ ⬀ ✀ 䄀一䐀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀漀戀樀攀挀琀猀⸀嬀渀愀洀攀崀 㴀 一✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀伀戀樀攀挀琀一愀洀攀Ⰰ✀✀✀✀⤀ ⬀ ✀ 䄀一䐀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀漀戀樀攀挀琀猀⸀嬀琀礀瀀攀崀 㴀 一✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀伀戀樀攀挀琀吀礀瀀攀Ⰰ✀✀✀✀⤀ ⬀ ✀ 䄀一䐀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀攀猀⸀椀渀搀攀砀开椀搀 㴀 ✀ ⬀ 䌀䄀匀吀⠀䀀䌀甀爀爀攀渀琀䤀渀搀攀砀䤀䐀 䄀匀 渀瘀愀爀挀栀愀爀⤀ ⬀ ✀ 䄀一䐀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀攀猀⸀嬀渀愀洀攀崀 㴀 一✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䤀渀搀攀砀一愀洀攀Ⰰ✀✀✀✀⤀ ⬀ ✀ 䄀一䐀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀攀猀⸀嬀琀礀瀀攀崀 㴀 ✀ ⬀ 䌀䄀匀吀⠀䀀䌀甀爀爀攀渀琀䤀渀搀攀砀吀礀瀀攀 䄀匀 渀瘀愀爀挀栀愀爀⤀ഀഀ
        IF @CurrentIsPartition = 1 SET @CurrentCommandSelect02 = 'SELECT COUNT(*) FROM ' + QUOTENAME(@CurrentDatabase) + '.sys.indexes INNER JOIN ' + QUOTENAME(@CurrentDatabase) + '.sys.objects ON ' + QUOTENAME(@CurrentDatabase) + '.sys.indexes.[object_id] = ' + QUOTENAME(@CurrentDatabase) + '.sys.objects.[object_id] INNER JOIN ' + QUOTENAME(@CurrentDatabase) + '.sys.schemas ON ' + QUOTENAME(@CurrentDatabase) + '.sys.objects.[schema_id] = ' + QUOTENAME(@CurrentDatabase) + '.sys.schemas.[schema_id] INNER JOIN ' + QUOTENAME(@CurrentDatabase) + '.sys.partitions ON ' + QUOTENAME(@CurrentDatabase) + '.sys.indexes.[object_id] = ' + QUOTENAME(@CurrentDatabase) + '.sys.partitions.[object_id] AND ' + QUOTENAME(@CurrentDatabase) + '.sys.indexes.index_id = ' + QUOTENAME(@CurrentDatabase) + '.sys.partitions.index_id WHERE ' + QUOTENAME(@CurrentDatabase) + '.sys.objects.[type] IN(''U'',''V'') AND ' + QUOTENAME(@CurrentDatabase) + '.sys.objects.is_ms_shipped = 0 AND ' + QUOTENAME(@CurrentDatabase) + '.sys.indexes.[type] IN(1,2,3,4) AND ' + QUOTENAME(@CurrentDatabase) + '.sys.indexes.is_disabled = 0 AND ' + QUOTENAME(@CurrentDatabase) + '.sys.indexes.is_hypothetical = 0 AND ' + QUOTENAME(@CurrentDatabase) + '.sys.schemas.[schema_id] = ' + CAST(@CurrentSchemaID AS nvarchar) + ' AND ' + QUOTENAME(@CurrentDatabase) + '.sys.schemas.[name] = N' + QUOTENAME(@CurrentSchemaName,'''') + ' AND ' + QUOTENAME(@CurrentDatabase) + '.sys.objects.[object_id] = ' + CAST(@CurrentObjectID AS nvarchar) + ' AND ' + QUOTENAME(@CurrentDatabase) + '.sys.objects.[name] = N' + QUOTENAME(@CurrentObjectName,'''') + ' AND ' + QUOTENAME(@CurrentDatabase) + '.sys.objects.[type] = N' + QUOTENAME(@CurrentObjectType,'''') + ' AND ' + QUOTENAME(@CurrentDatabase) + '.sys.indexes.index_id = ' + CAST(@CurrentIndexID AS nvarchar) + ' AND ' + QUOTENAME(@CurrentDatabase) + '.sys.indexes.[name] = N' + QUOTENAME(@CurrentIndexName,'''') + ' AND ' + QUOTENAME(@CurrentDatabase) + '.sys.indexes.[type] = ' + CAST(@CurrentIndexType AS nvarchar) + ' AND ' + QUOTENAME(@CurrentDatabase) + '.sys.partitions.partition_id = ' + CAST(@CurrentPartitionID AS nvarchar) + ' AND ' + QUOTENAME(@CurrentDatabase) + '.sys.partitions.partition_number = ' + CAST(@CurrentPartitionNumber AS nvarchar)਍ഀഀ
        INSERT INTO @tmpIndexExists ([Count])਍        䔀堀䔀䌀唀吀䔀⠀䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀匀攀氀攀挀琀　㈀⤀ഀഀ
਍        䤀䘀 ⠀匀䔀䰀䔀䌀吀 嬀䌀漀甀渀琀崀 䘀刀伀䴀 䀀琀洀瀀䤀渀搀攀砀䔀砀椀猀琀猀⤀ 㸀 　 䈀䔀䜀䤀一 匀䔀吀 䀀䌀甀爀爀攀渀琀䤀渀搀攀砀䔀砀椀猀琀猀 㴀 ㄀ 䔀一䐀 䔀䰀匀䔀 䈀䔀䜀䤀一 匀䔀吀 䀀䌀甀爀爀攀渀琀䤀渀搀攀砀䔀砀椀猀琀猀 㴀 　 䔀一䐀ഀഀ
਍        䤀䘀 䀀䌀甀爀爀攀渀琀䤀渀搀攀砀䔀砀椀猀琀猀 㴀 　 䜀伀吀伀 一漀䄀挀琀椀漀渀ഀഀ
਍        ⴀⴀ 䐀漀攀猀 琀栀攀 椀渀搀攀砀 挀漀渀琀愀椀渀 愀 䰀伀䈀㼀ഀഀ
        IF @CurrentIndexType = 1 SET @CurrentCommandSelect03 = 'SELECT COUNT(*) FROM ' + QUOTENAME(@CurrentDatabase) + '.sys.columns INNER JOIN ' + QUOTENAME(@CurrentDatabase) + '.sys.types ON ' + QUOTENAME(@CurrentDatabase) + '.sys.columns.system_type_id = ' + QUOTENAME(@CurrentDatabase) + '.sys.types.user_type_id OR (' + QUOTENAME(@CurrentDatabase) + '.sys.columns.user_type_id = ' + QUOTENAME(@CurrentDatabase) + '.sys.types.user_type_id AND '+ QUOTENAME(@CurrentDatabase) + '.sys.types.is_assembly_type = 1) WHERE ' + QUOTENAME(@CurrentDatabase) + '.sys.columns.[object_id] = ' + CAST(@CurrentObjectID AS nvarchar) + ' AND (' + QUOTENAME(@CurrentDatabase) + '.sys.types.name IN(''xml'',''image'',''text'',''ntext'') OR (' + QUOTENAME(@CurrentDatabase) + '.sys.types.name IN(''varchar'',''nvarchar'',''varbinary'') AND ' + QUOTENAME(@CurrentDatabase) + '.sys.columns.max_length = -1) OR (' + QUOTENAME(@CurrentDatabase) + '.sys.types.is_assembly_type = 1 AND ' + QUOTENAME(@CurrentDatabase) + '.sys.columns.max_length = -1))'਍        䤀䘀 䀀䌀甀爀爀攀渀琀䤀渀搀攀砀吀礀瀀攀 㴀 ㈀ 匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀匀攀氀攀挀琀　㌀ 㴀 ✀匀䔀䰀䔀䌀吀 䌀伀唀一吀⠀⨀⤀ 䘀刀伀䴀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀开挀漀氀甀洀渀猀 䤀一一䔀刀 䨀伀䤀一 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀挀漀氀甀洀渀猀 伀一 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀开挀漀氀甀洀渀猀⸀嬀漀戀樀攀挀琀开椀搀崀 㴀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀挀漀氀甀洀渀猀⸀嬀漀戀樀攀挀琀开椀搀崀 䄀一䐀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀开挀漀氀甀洀渀猀⸀挀漀氀甀洀渀开椀搀 㴀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀挀漀氀甀洀渀猀⸀挀漀氀甀洀渀开椀搀 䤀一一䔀刀 䨀伀䤀一 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀琀礀瀀攀猀 伀一 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀挀漀氀甀洀渀猀⸀猀礀猀琀攀洀开琀礀瀀攀开椀搀 㴀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀琀礀瀀攀猀⸀甀猀攀爀开琀礀瀀攀开椀搀 伀刀 ⠀✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀挀漀氀甀洀渀猀⸀甀猀攀爀开琀礀瀀攀开椀搀 㴀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀琀礀瀀攀猀⸀甀猀攀爀开琀礀瀀攀开椀搀 䄀一䐀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀琀礀瀀攀猀⸀椀猀开愀猀猀攀洀戀氀礀开琀礀瀀攀 㴀 ㄀⤀ 圀䠀䔀刀䔀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀开挀漀氀甀洀渀猀⸀嬀漀戀樀攀挀琀开椀搀崀 㴀 ✀ ⬀ 䌀䄀匀吀⠀䀀䌀甀爀爀攀渀琀伀戀樀攀挀琀䤀䐀 䄀匀 渀瘀愀爀挀栀愀爀⤀ ⬀ ✀ 䄀一䐀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀开挀漀氀甀洀渀猀⸀椀渀搀攀砀开椀搀 㴀 ✀ ⬀ 䌀䄀匀吀⠀䀀䌀甀爀爀攀渀琀䤀渀搀攀砀䤀䐀 䄀匀 渀瘀愀爀挀栀愀爀⤀ ⬀ ✀ 䄀一䐀 ⠀✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀琀礀瀀攀猀⸀嬀渀愀洀攀崀 䤀一⠀✀✀砀洀氀✀✀Ⰰ✀✀椀洀愀最攀✀✀Ⰰ✀✀琀攀砀琀✀✀Ⰰ✀✀渀琀攀砀琀✀✀⤀ 伀刀 ⠀✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀琀礀瀀攀猀⸀嬀渀愀洀攀崀 䤀一⠀✀✀瘀愀爀挀栀愀爀✀✀Ⰰ✀✀渀瘀愀爀挀栀愀爀✀✀Ⰰ✀✀瘀愀爀戀椀渀愀爀礀✀✀⤀ 䄀一䐀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀挀漀氀甀洀渀猀⸀洀愀砀开氀攀渀最琀栀 㴀 ⴀ㄀⤀ 伀刀 ⠀✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀琀礀瀀攀猀⸀椀猀开愀猀猀攀洀戀氀礀开琀礀瀀攀 㴀 ㄀ 䄀一䐀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀挀漀氀甀洀渀猀⸀洀愀砀开氀攀渀最琀栀 㴀 ⴀ㄀⤀⤀✀ഀഀ
        IF @CurrentIndexType = 3 SET @CurrentCommandSelect03 = 'SELECT 1'਍        䤀䘀 䀀䌀甀爀爀攀渀琀䤀渀搀攀砀吀礀瀀攀 㴀 㐀 匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀匀攀氀攀挀琀　㌀ 㴀 ✀匀䔀䰀䔀䌀吀 ㄀✀ഀഀ
਍        䤀一匀䔀刀吀 䤀一吀伀 䀀琀洀瀀䤀猀䰀伀䈀 ⠀嬀䌀漀甀渀琀崀⤀ഀഀ
        EXECUTE(@CurrentCommandSelect03)਍ഀഀ
        IF (SELECT [Count] FROM @tmpIsLOB) > 0 BEGIN SET @CurrentIsLOB = 1 END ELSE BEGIN SET @CurrentIsLOB = 0 END਍ഀഀ
        -- Is Allow_Page_Locks set to On?਍        匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀匀攀氀攀挀琀　㐀 㴀 ✀匀䔀䰀䔀䌀吀 䌀伀唀一吀⠀⨀⤀ 䘀刀伀䴀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀攀猀 圀䠀䔀刀䔀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀攀猀⸀嬀漀戀樀攀挀琀开椀搀崀 㴀 ✀ ⬀ 䌀䄀匀吀⠀䀀䌀甀爀爀攀渀琀伀戀樀攀挀琀䤀䐀 䄀匀 渀瘀愀爀挀栀愀爀⤀ ⬀ ✀ 䄀一䐀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀攀猀⸀嬀椀渀搀攀砀开椀搀崀 㴀 ✀ ⬀ 䌀䄀匀吀⠀䀀䌀甀爀爀攀渀琀䤀渀搀攀砀䤀䐀 䄀匀 渀瘀愀爀挀栀愀爀⤀ ⬀ ✀ 䄀一䐀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀攀猀⸀嬀愀氀氀漀眀开瀀愀最攀开氀漀挀欀猀崀 㴀 ㄀✀ഀഀ
਍        䤀一匀䔀刀吀 䤀一吀伀 䀀琀洀瀀䄀氀氀漀眀倀愀最攀䰀漀挀欀猀 ⠀嬀䌀漀甀渀琀崀⤀ഀഀ
        EXECUTE(@CurrentCommandSelect04)਍ഀഀ
        IF (SELECT [Count] FROM @tmpAllowPageLocks) > 0 BEGIN SET @CurrentAllowPageLocks = 1 END ELSE BEGIN SET @CurrentAllowPageLocks = 0 END਍ഀഀ
        -- Is the index on a read-only filegroup?਍        匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀匀攀氀攀挀琀　㔀 㴀 ✀匀䔀䰀䔀䌀吀 䌀伀唀一吀⠀⨀⤀ 䘀刀伀䴀 ⠀匀䔀䰀䔀䌀吀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀昀椀氀攀最爀漀甀瀀猀⸀搀愀琀愀开猀瀀愀挀攀开椀搀 䘀刀伀䴀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀攀猀 䤀一一䔀刀 䨀伀䤀一 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀搀攀猀琀椀渀愀琀椀漀渀开搀愀琀愀开猀瀀愀挀攀猀 伀一 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀攀猀⸀搀愀琀愀开猀瀀愀挀攀开椀搀 㴀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀搀攀猀琀椀渀愀琀椀漀渀开搀愀琀愀开猀瀀愀挀攀猀⸀瀀愀爀琀椀琀椀漀渀开猀挀栀攀洀攀开椀搀 䤀一一䔀刀 䨀伀䤀一 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀昀椀氀攀最爀漀甀瀀猀 伀一 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀搀攀猀琀椀渀愀琀椀漀渀开搀愀琀愀开猀瀀愀挀攀猀⸀搀愀琀愀开猀瀀愀挀攀开椀搀 㴀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀昀椀氀攀最爀漀甀瀀猀⸀搀愀琀愀开猀瀀愀挀攀开椀搀 圀䠀䔀刀䔀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀昀椀氀攀最爀漀甀瀀猀⸀椀猀开爀攀愀搀开漀渀氀礀 㴀 ㄀ 䄀一䐀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀攀猀⸀嬀漀戀樀攀挀琀开椀搀崀 㴀 ✀ ⬀ 䌀䄀匀吀⠀䀀䌀甀爀爀攀渀琀伀戀樀攀挀琀䤀䐀 䄀匀 渀瘀愀爀挀栀愀爀⤀ ⬀ ✀ 䄀一䐀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀攀猀⸀嬀椀渀搀攀砀开椀搀崀 㴀 ✀ ⬀ 䌀䄀匀吀⠀䀀䌀甀爀爀攀渀琀䤀渀搀攀砀䤀䐀 䄀匀 渀瘀愀爀挀栀愀爀⤀ഀഀ
        IF @CurrentIsPartition = 1 SET @CurrentCommandSelect05 = @CurrentCommandSelect05 + ' AND ' + QUOTENAME(@CurrentDatabase) + '.sys.destination_data_spaces.destination_id = ' + CAST(@CurrentPartitionNumber AS nvarchar)਍        匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀匀攀氀攀挀琀　㔀 㴀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀匀攀氀攀挀琀　㔀 ⬀ ✀ 唀一䤀伀一 匀䔀䰀䔀䌀吀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀昀椀氀攀最爀漀甀瀀猀⸀搀愀琀愀开猀瀀愀挀攀开椀搀 䘀刀伀䴀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀攀猀 䤀一一䔀刀 䨀伀䤀一 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀昀椀氀攀最爀漀甀瀀猀 伀一 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀攀猀⸀搀愀琀愀开猀瀀愀挀攀开椀搀 㴀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀昀椀氀攀最爀漀甀瀀猀⸀搀愀琀愀开猀瀀愀挀攀开椀搀 圀䠀䔀刀䔀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀昀椀氀攀最爀漀甀瀀猀⸀椀猀开爀攀愀搀开漀渀氀礀 㴀 ㄀ 䄀一䐀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀攀猀⸀嬀漀戀樀攀挀琀开椀搀崀 㴀 ✀ ⬀ 䌀䄀匀吀⠀䀀䌀甀爀爀攀渀琀伀戀樀攀挀琀䤀䐀 䄀匀 渀瘀愀爀挀栀愀爀⤀ ⬀ ✀ 䄀一䐀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀猀礀猀⸀椀渀搀攀砀攀猀⸀嬀椀渀搀攀砀开椀搀崀 㴀 ✀ ⬀ 䌀䄀匀吀⠀䀀䌀甀爀爀攀渀琀䤀渀搀攀砀䤀䐀 䄀匀 渀瘀愀爀挀栀愀爀⤀ഀഀ
        IF @CurrentIndexType = 1 SET @CurrentCommandSelect05 = @CurrentCommandSelect05 + ' UNION SELECT ' + QUOTENAME(@CurrentDatabase) + '.sys.filegroups.data_space_id FROM ' + QUOTENAME(@CurrentDatabase) + '.sys.tables INNER JOIN ' + QUOTENAME(@CurrentDatabase) + '.sys.filegroups ON ' + QUOTENAME(@CurrentDatabase) + '.sys.tables.lob_data_space_id = ' + QUOTENAME(@CurrentDatabase) + '.sys.filegroups.data_space_id WHERE ' + QUOTENAME(@CurrentDatabase) + '.sys.filegroups.is_read_only = 1 AND ' + QUOTENAME(@CurrentDatabase) + '.sys.tables.[object_id] = ' + CAST(@CurrentObjectID AS nvarchar)਍        匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀匀攀氀攀挀琀　㔀 㴀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀匀攀氀攀挀琀　㔀 ⬀ ✀⤀ 刀攀愀搀伀渀氀礀䘀椀氀攀䜀爀漀甀瀀猀✀ഀഀ
਍        䤀一匀䔀刀吀 䤀一吀伀 䀀琀洀瀀伀渀刀攀愀搀伀渀氀礀䘀椀氀攀䜀爀漀甀瀀 ⠀嬀䌀漀甀渀琀崀⤀ഀഀ
        EXECUTE(@CurrentCommandSelect05)਍ഀഀ
        IF (SELECT [Count] FROM @tmpOnReadOnlyFileGroup) > 0 BEGIN SET @CurrentOnReadOnlyFileGroup = 1 END ELSE BEGIN SET @CurrentOnReadOnlyFileGroup = 0 END਍ഀഀ
        -- Is the index fragmented?਍        匀䔀䰀䔀䌀吀 䀀䌀甀爀爀攀渀琀䘀爀愀最洀攀渀琀愀琀椀漀渀䰀攀瘀攀氀 㴀 䴀䄀堀⠀愀瘀最开昀爀愀最洀攀渀琀愀琀椀漀渀开椀渀开瀀攀爀挀攀渀琀⤀Ⰰഀഀ
               @CurrentPageCount = SUM(page_count)਍        䘀刀伀䴀 猀礀猀⸀搀洀开搀戀开椀渀搀攀砀开瀀栀礀猀椀挀愀氀开猀琀愀琀猀⠀䐀䈀开䤀䐀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀Ⰰ 䀀䌀甀爀爀攀渀琀伀戀樀攀挀琀䤀䐀Ⰰ 䀀䌀甀爀爀攀渀琀䤀渀搀攀砀䤀䐀Ⰰ 䀀䌀甀爀爀攀渀琀倀愀爀琀椀琀椀漀渀一甀洀戀攀爀Ⰰ ✀䰀䤀䴀䤀吀䔀䐀✀⤀ഀഀ
        WHERE alloc_unit_type_desc = 'IN_ROW_DATA'਍        䄀一䐀 椀渀搀攀砀开氀攀瘀攀氀 㴀 　ഀഀ
        SET @Error = @@ERROR਍        䤀䘀 䀀䔀爀爀漀爀 㴀 ㄀㈀㈀㈀ഀഀ
        BEGIN਍          匀䔀吀 䀀䔀爀爀漀爀䴀攀猀猀愀最攀 㴀 ✀吀栀攀 搀礀渀愀洀椀挀 洀愀渀愀最攀洀攀渀琀 瘀椀攀眀 猀礀猀⸀搀洀开搀戀开椀渀搀攀砀开瀀栀礀猀椀挀愀氀开猀琀愀琀猀 椀猀 氀漀挀欀攀搀 漀渀 琀栀攀 椀渀搀攀砀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀匀挀栀攀洀愀一愀洀攀⤀ ⬀ ✀⸀✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀伀戀樀攀挀琀一愀洀攀⤀ ⬀ ✀⸀✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䤀渀搀攀砀一愀洀攀⤀ ⬀ ✀⸀✀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
          SET @ErrorMessage = REPLACE(@ErrorMessage,'%','%%')਍          刀䄀䤀匀䔀刀刀伀刀⠀䀀䔀爀爀漀爀䴀攀猀猀愀最攀Ⰰ㄀㘀Ⰰ㄀⤀ 圀䤀吀䠀 一伀圀䄀䤀吀ഀഀ
          GOTO NoAction਍        䔀一䐀ഀഀ
਍        ⴀⴀ 䐀攀挀椀搀攀 愀挀琀椀漀渀ഀഀ
        SELECT @CurrentAction = CASE਍        圀䠀䔀一 ⠀䀀䌀甀爀爀攀渀琀䤀猀䰀伀䈀 㴀 ㄀ 伀刀 䀀䌀甀爀爀攀渀琀䤀猀倀愀爀琀椀琀椀漀渀 㴀 ㄀⤀ 䄀一䐀 䀀䌀甀爀爀攀渀琀䘀爀愀最洀攀渀琀愀琀椀漀渀䰀攀瘀攀氀 㸀㴀 䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䰀攀瘀攀氀㈀ 䄀一䐀 䀀䌀甀爀爀攀渀琀倀愀最攀䌀漀甀渀琀 㸀㴀 䀀倀愀最攀䌀漀甀渀琀䰀攀瘀攀氀 吀䠀䔀一 䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䠀椀最栀开䰀伀䈀ഀഀ
        WHEN (@CurrentIsLOB = 0 AND @CurrentIsPartition = 0) AND @CurrentFragmentationLevel >= @FragmentationLevel2 AND @CurrentPageCount >= @PageCountLevel THEN @FragmentationHigh_NonLOB਍        圀䠀䔀一 ⠀䀀䌀甀爀爀攀渀琀䤀猀䰀伀䈀 㴀 ㄀ 伀刀 䀀䌀甀爀爀攀渀琀䤀猀倀愀爀琀椀琀椀漀渀 㴀 ㄀⤀ 䄀一䐀 䀀䌀甀爀爀攀渀琀䘀爀愀最洀攀渀琀愀琀椀漀渀䰀攀瘀攀氀 㸀㴀 䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䰀攀瘀攀氀㄀ 䄀一䐀 䀀䌀甀爀爀攀渀琀䘀爀愀最洀攀渀琀愀琀椀漀渀䰀攀瘀攀氀 㰀 䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䰀攀瘀攀氀㈀ 䄀一䐀 䀀䌀甀爀爀攀渀琀倀愀最攀䌀漀甀渀琀 㸀㴀 䀀倀愀最攀䌀漀甀渀琀䰀攀瘀攀氀 吀䠀䔀一 䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䴀攀搀椀甀洀开䰀伀䈀ഀഀ
        WHEN (@CurrentIsLOB = 0 AND @CurrentIsPartition = 0) AND @CurrentFragmentationLevel >= @FragmentationLevel1 AND @CurrentFragmentationLevel < @FragmentationLevel2 AND @CurrentPageCount >= @PageCountLevel THEN @FragmentationMedium_NonLOB਍        圀䠀䔀一 ⠀䀀䌀甀爀爀攀渀琀䤀猀䰀伀䈀 㴀 ㄀ 伀刀 䀀䌀甀爀爀攀渀琀䤀猀倀愀爀琀椀琀椀漀渀 㴀 ㄀⤀ 䄀一䐀 ⠀䀀䌀甀爀爀攀渀琀䘀爀愀最洀攀渀琀愀琀椀漀渀䰀攀瘀攀氀 㰀 䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䰀攀瘀攀氀㄀ 伀刀 䀀䌀甀爀爀攀渀琀倀愀最攀䌀漀甀渀琀 㰀 䀀倀愀最攀䌀漀甀渀琀䰀攀瘀攀氀⤀ 吀䠀䔀一 䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䰀漀眀开䰀伀䈀ഀഀ
        WHEN (@CurrentIsLOB = 0 AND @CurrentIsPartition = 0) AND (@CurrentFragmentationLevel < @FragmentationLevel1 OR @CurrentPageCount < @PageCountLevel) THEN @FragmentationLow_NonLOB਍        䔀一䐀ഀഀ
਍        ⴀⴀ 刀攀漀爀最愀渀椀稀椀渀最 愀渀 椀渀搀攀砀 椀猀 漀渀氀礀 愀氀氀漀眀攀搀 椀昀 䄀氀氀漀眀开倀愀最攀开䰀漀挀欀猀 椀猀 猀攀琀 琀漀 伀渀ഀഀ
        IF @CurrentAction IN('INDEX_REORGANIZE','INDEX_REORGANIZE_STATISTICS_UPDATE') AND @CurrentAllowPageLocks = 0਍        䈀䔀䜀䤀一ഀഀ
          SELECT @CurrentAction = CASE਍          圀䠀䔀一 ⠀䀀䌀甀爀爀攀渀琀䤀猀䰀伀䈀 㴀 　 䄀一䐀 䀀䌀甀爀爀攀渀琀䤀猀倀愀爀琀椀琀椀漀渀 㴀 　⤀ 䄀一䐀 ✀䤀一䐀䔀堀开刀䔀䈀唀䤀䰀䐀开伀一䰀䤀一䔀✀ 䤀一⠀䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䠀椀最栀开一漀渀䰀伀䈀Ⰰ 䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䴀攀搀椀甀洀开一漀渀䰀伀䈀Ⰰ 䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䰀漀眀开一漀渀䰀伀䈀⤀ 吀䠀䔀一 ✀䤀一䐀䔀堀开刀䔀䈀唀䤀䰀䐀开伀一䰀䤀一䔀✀ഀഀ
          WHEN (@CurrentIsLOB = 0 AND @CurrentIsPartition = 0) AND 'INDEX_REBUILD_OFFLINE' IN(@FragmentationHigh_NonLOB, @FragmentationMedium_NonLOB, @FragmentationLow_NonLOB) THEN 'INDEX_REBUILD_OFFLINE'਍          圀䠀䔀一 ⠀䀀䌀甀爀爀攀渀琀䤀猀䰀伀䈀 㴀 ㄀ 伀刀 䀀䌀甀爀爀攀渀琀䤀猀倀愀爀琀椀琀椀漀渀 㴀 ㄀⤀ 䄀一䐀 ✀䤀一䐀䔀堀开刀䔀䈀唀䤀䰀䐀开伀䘀䘀䰀䤀一䔀✀ 䤀一⠀䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䠀椀最栀开䰀伀䈀Ⰰ 䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䴀攀搀椀甀洀开䰀伀䈀Ⰰ 䀀䘀爀愀最洀攀渀琀愀琀椀漀渀䰀漀眀开䰀伀䈀⤀ 吀䠀䔀一 ✀䤀一䐀䔀堀开刀䔀䈀唀䤀䰀䐀开伀䘀䘀䰀䤀一䔀✀ഀഀ
          ELSE 'NOTHING'਍          䔀一䐀ഀഀ
        END਍ഀഀ
        -- Create comment਍        匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀攀渀琀 㴀 ✀伀戀樀攀挀琀吀礀瀀攀㨀 ✀ ⬀ 䌀䄀匀䔀 圀䠀䔀一 䀀䌀甀爀爀攀渀琀伀戀樀攀挀琀吀礀瀀攀 㴀 ✀唀✀ 吀䠀䔀一 ✀吀愀戀氀攀✀ 圀䠀䔀一 䀀䌀甀爀爀攀渀琀伀戀樀攀挀琀吀礀瀀攀 㴀 ✀嘀✀ 吀䠀䔀一 ✀嘀椀攀眀✀ 䔀䰀匀䔀 ✀一⼀䄀✀ 䔀一䐀 ⬀ ✀Ⰰ ✀ഀഀ
        SET @CurrentComment = @CurrentComment + 'IndexType: ' + CASE WHEN @CurrentIndexType = 1 THEN 'Clustered' WHEN @CurrentIndexType = 2 THEN 'NonClustered' WHEN @CurrentIndexType = 3 THEN 'XML' WHEN @CurrentIndexType = 4 THEN 'Spatial' ELSE 'N/A' END + ', '਍        匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀攀渀琀 㴀 䀀䌀甀爀爀攀渀琀䌀漀洀洀攀渀琀 ⬀ ✀䰀伀䈀㨀 ✀ ⬀ 䌀䄀匀䔀 圀䠀䔀一 䀀䌀甀爀爀攀渀琀䤀猀䰀伀䈀 㴀 ㄀ 吀䠀䔀一 ✀夀攀猀✀ 圀䠀䔀一 䀀䌀甀爀爀攀渀琀䤀猀䰀伀䈀 㴀 　 吀䠀䔀一 ✀一漀✀ 䔀䰀匀䔀 ✀一⼀䄀✀ 䔀一䐀 ⬀ ✀Ⰰ ✀ഀഀ
        SET @CurrentComment = @CurrentComment + 'AllowPageLocks: ' + CASE WHEN @CurrentAllowPageLocks = 1 THEN 'Yes' WHEN @CurrentAllowPageLocks = 0 THEN 'No' ELSE 'N/A' END + ', '਍        匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀攀渀琀 㴀 䀀䌀甀爀爀攀渀琀䌀漀洀洀攀渀琀 ⬀ ✀倀愀最攀䌀漀甀渀琀㨀 ✀ ⬀ 䌀䄀匀吀⠀䀀䌀甀爀爀攀渀琀倀愀最攀䌀漀甀渀琀 䄀匀 渀瘀愀爀挀栀愀爀⤀ ⬀ ✀Ⰰ ✀ഀഀ
        SET @CurrentComment = @CurrentComment + 'Fragmentation: ' + CAST(@CurrentFragmentationLevel AS nvarchar)਍ഀഀ
        -- Check time limit਍        䤀䘀 䜀䔀吀䐀䄀吀䔀⠀⤀ 㸀㴀 䐀䄀吀䔀䄀䐀䐀⠀猀猀Ⰰ䀀吀椀洀攀䰀椀洀椀琀Ⰰ䀀匀琀愀爀琀吀椀洀攀⤀ഀഀ
        BEGIN਍          匀䔀吀 䀀䔀砀攀挀甀琀攀 㴀 ✀一✀ഀഀ
        END਍ഀഀ
        IF @CurrentAction IN('INDEX_REBUILD_ONLINE','INDEX_REBUILD_OFFLINE','INDEX_REORGANIZE','INDEX_REORGANIZE_STATISTICS_UPDATE') AND @CurrentOnReadOnlyFileGroup = 0਍        䈀䔀䜀䤀一ഀഀ
          SET @CurrentCommand01 = 'ALTER INDEX ' + QUOTENAME(@CurrentIndexName) + ' ON ' + QUOTENAME(@CurrentDatabase) + '.' + QUOTENAME(@CurrentSchemaName) + '.' + QUOTENAME(@CurrentObjectName)਍ഀഀ
          IF @CurrentAction IN('INDEX_REBUILD_ONLINE','INDEX_REBUILD_OFFLINE')਍          䈀䔀䜀䤀一ഀഀ
            SET @CurrentCommand01 = @CurrentCommand01 + ' REBUILD'਍            䤀䘀 䀀䌀甀爀爀攀渀琀䤀猀倀愀爀琀椀琀椀漀渀 㴀 ㄀ 匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㄀ 㴀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㄀ ⬀ ✀ 倀䄀刀吀䤀吀䤀伀一 㴀 ✀ ⬀ 䌀䄀匀吀⠀䀀䌀甀爀爀攀渀琀倀愀爀琀椀琀椀漀渀一甀洀戀攀爀 䄀匀 渀瘀愀爀挀栀愀爀⤀ഀഀ
            SET @CurrentCommand01 = @CurrentCommand01 + ' WITH ('਍            䤀䘀 䀀匀漀爀琀䤀渀吀攀洀瀀搀戀 㴀 ✀夀✀ 匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㄀ 㴀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㄀ ⬀ ✀匀伀刀吀开䤀一开吀䔀䴀倀䐀䈀 㴀 伀一✀ഀഀ
            IF @SortInTempdb = 'N' SET @CurrentCommand01 = @CurrentCommand01 + 'SORT_IN_TEMPDB = OFF'਍            䤀䘀 䀀䌀甀爀爀攀渀琀䄀挀琀椀漀渀 㴀 ✀䤀一䐀䔀堀开刀䔀䈀唀䤀䰀䐀开伀一䰀䤀一䔀✀ 䄀一䐀 䀀䌀甀爀爀攀渀琀䤀猀倀愀爀琀椀琀椀漀渀 㴀 　 匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㄀ 㴀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㄀ ⬀ ✀Ⰰ 伀一䰀䤀一䔀 㴀 伀一✀ഀഀ
            IF @CurrentAction = 'INDEX_REBUILD_OFFLINE' AND @CurrentIsPartition = 0 SET @CurrentCommand01 = @CurrentCommand01 + ', ONLINE = OFF'਍            䤀䘀 䀀䴀愀砀䐀伀倀 䤀匀 一伀吀 一唀䰀䰀 匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㄀ 㴀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㄀ ⬀ ✀Ⰰ 䴀䄀堀䐀伀倀 㴀 ✀ ⬀ 䌀䄀匀吀⠀䀀䴀愀砀䐀伀倀 䄀匀 渀瘀愀爀挀栀愀爀⤀ഀഀ
            IF @FillFactor IS NOT NULL AND @CurrentIsPartition = 0 SET @CurrentCommand01 = @CurrentCommand01 + ', FILLFACTOR = ' + CAST(@FillFactor AS nvarchar)਍            匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㄀ 㴀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㄀ ⬀ ✀⤀✀ഀഀ
          END਍ഀഀ
          IF @CurrentAction IN('INDEX_REORGANIZE','INDEX_REORGANIZE_STATISTICS_UPDATE')਍          䈀䔀䜀䤀一ഀഀ
            SET @CurrentCommand01 = @CurrentCommand01 + ' REORGANIZE'਍            䤀䘀 䀀䌀甀爀爀攀渀琀䤀猀倀愀爀琀椀琀椀漀渀 㴀 ㄀ 匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㄀ 㴀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㄀ ⬀ ✀ 倀䄀刀吀䤀吀䤀伀一 㴀 ✀ ⬀ 䌀䄀匀吀⠀䀀䌀甀爀爀攀渀琀倀愀爀琀椀琀椀漀渀一甀洀戀攀爀 䄀匀 渀瘀愀爀挀栀愀爀⤀ഀഀ
            SET @CurrentCommand01 = @CurrentCommand01 + ' WITH ('਍            䤀䘀 䀀䰀伀䈀䌀漀洀瀀愀挀琀椀漀渀 㴀 ✀夀✀ 匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㄀ 㴀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㄀ ⬀ ✀䰀伀䈀开䌀伀䴀倀䄀䌀吀䤀伀一 㴀 伀一✀ഀഀ
            IF @LOBCompaction = 'N' SET @CurrentCommand01 = @CurrentCommand01 + 'LOB_COMPACTION = OFF'਍            匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㄀ 㴀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㄀ ⬀ ✀⤀✀ഀഀ
          END਍ഀഀ
          EXECUTE @CurrentCommandOutput01 = [dbo].[CommandExecute] @CurrentCommand01, @CurrentComment, 2, @Execute਍          匀䔀吀 䀀䔀爀爀漀爀 㴀 䀀䀀䔀刀刀伀刀ഀഀ
          IF @Error <> 0 SET @CurrentCommandOutput01 = @Error਍        䔀一䐀ഀഀ
਍        䤀䘀 䀀䌀甀爀爀攀渀琀䄀挀琀椀漀渀 䤀一⠀✀䤀一䐀䔀堀开刀䔀伀刀䜀䄀一䤀娀䔀开匀吀䄀吀䤀匀吀䤀䌀匀开唀倀䐀䄀吀䔀✀Ⰰ✀匀吀䄀吀䤀匀吀䤀䌀匀开唀倀䐀䄀吀䔀✀⤀ 䄀一䐀 䀀䌀甀爀爀攀渀琀伀渀刀攀愀搀伀渀氀礀䘀椀氀攀䜀爀漀甀瀀 㴀 　 䄀一䐀 䀀䌀甀爀爀攀渀琀䤀渀搀攀砀吀礀瀀攀 䤀一⠀㄀Ⰰ㈀⤀ 䄀一䐀 䀀䌀甀爀爀攀渀琀䤀猀倀愀爀琀椀琀椀漀渀 㴀 　ഀഀ
        BEGIN਍          匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㈀ 㴀 ✀唀倀䐀䄀吀䔀 匀吀䄀吀䤀匀吀䤀䌀匀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀⸀✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀匀挀栀攀洀愀一愀洀攀⤀ ⬀ ✀⸀✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀伀戀樀攀挀琀一愀洀攀⤀ ⬀ ✀ ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䤀渀搀攀砀一愀洀攀⤀ഀഀ
          IF @StatisticsSample = 100 SET @CurrentCommand02 = @CurrentCommand02 + ' WITH FULLSCAN'਍          䤀䘀 䀀匀琀愀琀椀猀琀椀挀猀匀愀洀瀀氀攀 䤀匀 一伀吀 一唀䰀䰀 䄀一䐀 䀀匀琀愀琀椀猀琀椀挀猀匀愀洀瀀氀攀 㰀㸀 ㄀　　 匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㈀ 㴀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㈀ ⬀ ✀ 圀䤀吀䠀 匀䄀䴀倀䰀䔀 ✀ ⬀ 䌀䄀匀吀⠀䀀匀琀愀琀椀猀琀椀挀猀匀愀洀瀀氀攀 䄀匀 渀瘀愀爀挀栀愀爀⤀ ⬀ ✀ 倀䔀刀䌀䔀一吀✀ഀഀ
਍          䔀堀䔀䌀唀吀䔀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀伀甀琀瀀甀琀　㈀ 㴀 嬀搀戀漀崀⸀嬀䌀漀洀洀愀渀搀䔀砀攀挀甀琀攀崀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㈀Ⰰ ✀✀Ⰰ ㈀Ⰰ 䀀䔀砀攀挀甀琀攀ഀഀ
          SET @Error = @@ERROR਍          䤀䘀 䀀䔀爀爀漀爀 㰀㸀 　 匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀伀甀琀瀀甀琀　㈀ 㴀 䀀䔀爀爀漀爀ഀഀ
        END਍ഀഀ
        NoAction:਍ഀഀ
        -- Update that the index is completed਍        唀倀䐀䄀吀䔀 䀀琀洀瀀䤀渀搀攀砀攀猀ഀഀ
        SET Completed = 1਍        圀䠀䔀刀䔀 䤀砀䤀䐀 㴀 䀀䌀甀爀爀攀渀琀䤀砀䤀䐀ഀഀ
਍        ⴀⴀ 䌀氀攀愀爀 瘀愀爀椀愀戀氀攀猀ഀഀ
        SET @CurrentCommandSelect02 = NULL਍        匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀匀攀氀攀挀琀　㌀ 㴀 一唀䰀䰀ഀഀ
        SET @CurrentCommandSelect04 = NULL਍        匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀匀攀氀攀挀琀　㔀 㴀 一唀䰀䰀ഀഀ
਍        匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㄀ 㴀 一唀䰀䰀ഀഀ
        SET @CurrentCommand02 = NULL਍ഀഀ
        SET @CurrentCommandOutput01 = NULL਍        匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀伀甀琀瀀甀琀　㈀ 㴀 一唀䰀䰀ഀഀ
਍        匀䔀吀 䀀䌀甀爀爀攀渀琀䤀砀䤀䐀 㴀 一唀䰀䰀ഀഀ
        SET @CurrentSchemaID = NULL਍        匀䔀吀 䀀䌀甀爀爀攀渀琀匀挀栀攀洀愀一愀洀攀 㴀 一唀䰀䰀ഀഀ
        SET @CurrentObjectID = NULL਍        匀䔀吀 䀀䌀甀爀爀攀渀琀伀戀樀攀挀琀一愀洀攀 㴀 一唀䰀䰀ഀഀ
        SET @CurrentObjectType = NULL਍        匀䔀吀 䀀䌀甀爀爀攀渀琀䤀渀搀攀砀䤀䐀 㴀 一唀䰀䰀ഀഀ
        SET @CurrentIndexName = NULL਍        匀䔀吀 䀀䌀甀爀爀攀渀琀䤀渀搀攀砀吀礀瀀攀 㴀 一唀䰀䰀ഀഀ
        SET @CurrentPartitionID = NULL਍        匀䔀吀 䀀䌀甀爀爀攀渀琀倀愀爀琀椀琀椀漀渀一甀洀戀攀爀 㴀 一唀䰀䰀ഀഀ
        SET @CurrentPartitionCount = NULL਍        匀䔀吀 䀀䌀甀爀爀攀渀琀䤀猀倀愀爀琀椀琀椀漀渀 㴀 一唀䰀䰀ഀഀ
        SET @CurrentIndexExists = NULL਍        匀䔀吀 䀀䌀甀爀爀攀渀琀䤀猀䰀伀䈀 㴀 一唀䰀䰀ഀഀ
        SET @CurrentAllowPageLocks = NULL਍        匀䔀吀 䀀䌀甀爀爀攀渀琀伀渀刀攀愀搀伀渀氀礀䘀椀氀攀䜀爀漀甀瀀 㴀 一唀䰀䰀ഀഀ
        SET @CurrentFragmentationLevel = NULL਍        匀䔀吀 䀀䌀甀爀爀攀渀琀倀愀最攀䌀漀甀渀琀 㴀 一唀䰀䰀ഀഀ
        SET @CurrentAction = NULL਍        匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀攀渀琀 㴀 一唀䰀䰀ഀഀ
਍        䐀䔀䰀䔀吀䔀 䘀刀伀䴀 䀀琀洀瀀䤀渀搀攀砀䔀砀椀猀琀猀ഀഀ
        DELETE FROM @tmpIsLOB਍        䐀䔀䰀䔀吀䔀 䘀刀伀䴀 䀀琀洀瀀䄀氀氀漀眀倀愀最攀䰀漀挀欀猀ഀഀ
        DELETE FROM @tmpOnReadOnlyFileGroup਍ഀഀ
      END਍ഀഀ
    END਍ഀഀ
    -- Update that the database is completed਍    唀倀䐀䄀吀䔀 䀀琀洀瀀䐀愀琀愀戀愀猀攀猀ഀഀ
    SET Completed = 1਍    圀䠀䔀刀䔀 䤀䐀 㴀 䀀䌀甀爀爀攀渀琀䤀䐀ഀഀ
਍    ⴀⴀ 䌀氀攀愀爀 瘀愀爀椀愀戀氀攀猀ഀഀ
    SET @CurrentID = NULL਍    匀䔀吀 䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀 㴀 一唀䰀䰀ഀഀ
    SET @CurrentIsDatabaseAccessible = NULL਍    匀䔀吀 䀀䌀甀爀爀攀渀琀䴀椀爀爀漀爀椀渀最刀漀氀攀 㴀 一唀䰀䰀ഀഀ
਍    匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀匀攀氀攀挀琀　㄀ 㴀 一唀䰀䰀ഀഀ
਍    䐀䔀䰀䔀吀䔀 䘀刀伀䴀 䀀琀洀瀀䤀渀搀攀砀攀猀ഀഀ
਍  䔀一䐀ഀഀ
਍  ⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀഀഀ
  --// Log completing information                                                                 //--਍  ⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀഀഀ
਍  䰀漀最最椀渀最㨀ഀഀ
  SET @EndMessage = 'DateTime: ' + CONVERT(nvarchar,GETDATE(),120)਍  匀䔀吀 䀀䔀渀搀䴀攀猀猀愀最攀 㴀 刀䔀倀䰀䄀䌀䔀⠀䀀䔀渀搀䴀攀猀猀愀最攀Ⰰ✀─✀Ⰰ✀──✀⤀ഀഀ
  RAISERROR(@EndMessage,10,1) WITH NOWAIT਍ഀഀ
  ----------------------------------------------------------------------------------------------------਍ഀഀ
END਍䜀伀ഀഀ
