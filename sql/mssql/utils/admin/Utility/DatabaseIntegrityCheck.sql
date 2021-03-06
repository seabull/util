SET ANSI_NULLS ON਍䜀伀ഀഀ
SET QUOTED_IDENTIFIER ON਍䜀伀ഀഀ
CREATE PROCEDURE [dbo].[DatabaseIntegrityCheck]਍ഀഀ
@Databases nvarchar(max),਍䀀倀栀礀猀椀挀愀氀伀渀氀礀 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀ 㴀 ✀一✀Ⰰഀഀ
@NoIndex nvarchar(max) = 'N',਍䀀䔀砀琀攀渀搀攀搀䰀漀最椀挀愀氀䌀栀攀挀欀猀 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀ 㴀 ✀一✀Ⰰഀഀ
@Execute nvarchar(max) = 'Y'਍ഀഀ
AS਍ഀഀ
BEGIN਍ഀഀ
  ----------------------------------------------------------------------------------------------------਍  ⴀⴀ⼀⼀ 匀攀琀 漀瀀琀椀漀渀猀                                                                                ⼀⼀ⴀⴀഀഀ
  ----------------------------------------------------------------------------------------------------਍ഀഀ
  SET NOCOUNT ON਍ഀഀ
  ----------------------------------------------------------------------------------------------------਍  ⴀⴀ⼀⼀ 䐀攀挀氀愀爀攀 瘀愀爀椀愀戀氀攀猀                                                                          ⼀⼀ⴀⴀഀഀ
  ----------------------------------------------------------------------------------------------------਍ഀഀ
  DECLARE @StartMessage nvarchar(max)਍  䐀䔀䌀䰀䄀刀䔀 䀀䔀渀搀䴀攀猀猀愀最攀 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀ഀഀ
  DECLARE @DatabaseMessage nvarchar(max)਍  䐀䔀䌀䰀䄀刀䔀 䀀䔀爀爀漀爀䴀攀猀猀愀最攀 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀ഀഀ
਍  䐀䔀䌀䰀䄀刀䔀 䀀䌀甀爀爀攀渀琀䤀䐀 椀渀琀ഀഀ
  DECLARE @CurrentDatabase nvarchar(max)਍  䐀䔀䌀䰀䄀刀䔀 䀀䌀甀爀爀攀渀琀䤀猀䐀愀琀愀戀愀猀攀䄀挀挀攀猀猀椀戀氀攀 戀椀琀ഀഀ
  DECLARE @CurrentMirroringRole nvarchar(max)਍ഀഀ
  DECLARE @CurrentCommand01 nvarchar(max)਍ഀഀ
  DECLARE @CurrentCommandOutput01 int਍ഀഀ
  DECLARE @tmpDatabases TABLE (ID int IDENTITY PRIMARY KEY,਍                               䐀愀琀愀戀愀猀攀一愀洀攀 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀Ⰰഀഀ
                               Completed bit)਍ഀഀ
  DECLARE @Error int਍ഀഀ
  SET @Error = 0਍ഀഀ
  ----------------------------------------------------------------------------------------------------਍  ⴀⴀ⼀⼀ 䰀漀最 椀渀椀琀椀愀氀 椀渀昀漀爀洀愀琀椀漀渀                                                                    ⼀⼀ⴀⴀഀഀ
  ----------------------------------------------------------------------------------------------------਍ഀഀ
  SET @StartMessage = 'DateTime: ' + CONVERT(nvarchar,GETDATE(),120) + CHAR(13) + CHAR(10)਍  匀䔀吀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 㴀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 ⬀ ✀匀攀爀瘀攀爀㨀 ✀ ⬀ 䌀䄀匀吀⠀匀䔀刀嘀䔀刀倀刀伀倀䔀刀吀夀⠀✀匀攀爀瘀攀爀一愀洀攀✀⤀ 䄀匀 渀瘀愀爀挀栀愀爀⤀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
  SET @StartMessage = @StartMessage + 'Version: ' + CAST(SERVERPROPERTY('ProductVersion') AS nvarchar) + CHAR(13) + CHAR(10)਍  匀䔀吀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 㴀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 ⬀ ✀䔀搀椀琀椀漀渀㨀 ✀ ⬀ 䌀䄀匀吀⠀匀䔀刀嘀䔀刀倀刀伀倀䔀刀吀夀⠀✀䔀搀椀琀椀漀渀✀⤀ 䄀匀 渀瘀愀爀挀栀愀爀⤀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
  SET @StartMessage = @StartMessage + 'Procedure: ' + QUOTENAME(DB_NAME(DB_ID())) + '.' + (SELECT QUOTENAME(sys.schemas.name) FROM sys.schemas INNER JOIN sys.objects ON sys.schemas.[schema_id] = sys.objects.[schema_id] WHERE [object_id] = @@PROCID) + '.' + QUOTENAME(OBJECT_NAME(@@PROCID)) + CHAR(13) + CHAR(10)਍  匀䔀吀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 㴀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 ⬀ ✀倀愀爀愀洀攀琀攀爀猀㨀 䀀䐀愀琀愀戀愀猀攀猀 㴀 ✀ ⬀ 䤀匀一唀䰀䰀⠀✀✀✀✀ ⬀ 刀䔀倀䰀䄀䌀䔀⠀䀀䐀愀琀愀戀愀猀攀猀Ⰰ✀✀✀✀Ⰰ✀✀✀✀✀✀⤀ ⬀ ✀✀✀✀Ⰰ✀一唀䰀䰀✀⤀ഀഀ
  SET @StartMessage = @StartMessage + ', @PhysicalOnly = ' + ISNULL('''' + REPLACE(@PhysicalOnly,'''','''''') + '''','NULL')਍  匀䔀吀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 㴀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 ⬀ ✀Ⰰ 䀀一漀䤀渀搀攀砀 㴀 ✀ ⬀ 䤀匀一唀䰀䰀⠀✀✀✀✀ ⬀ 刀䔀倀䰀䄀䌀䔀⠀䀀一漀䤀渀搀攀砀Ⰰ✀✀✀✀Ⰰ✀✀✀✀✀✀⤀ ⬀ ✀✀✀✀Ⰰ✀一唀䰀䰀✀⤀ഀഀ
  SET @StartMessage = @StartMessage + ', @ExtendedLogicalChecks = ' + ISNULL('''' + REPLACE(@ExtendedLogicalChecks,'''','''''') + '''','NULL')਍  匀䔀吀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 㴀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 ⬀ ✀Ⰰ 䀀䔀砀攀挀甀琀攀 㴀 ✀ ⬀ 䤀匀一唀䰀䰀⠀✀✀✀✀ ⬀ 刀䔀倀䰀䄀䌀䔀⠀䀀䔀砀攀挀甀琀攀Ⰰ✀✀✀✀Ⰰ✀✀✀✀✀✀⤀ ⬀ ✀✀✀✀Ⰰ✀一唀䰀䰀✀⤀ഀഀ
  SET @StartMessage = @StartMessage + CHAR(13) + CHAR(10)਍  匀䔀吀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 㴀 刀䔀倀䰀䄀䌀䔀⠀䀀匀琀愀爀琀䴀攀猀猀愀最攀Ⰰ✀─✀Ⰰ✀──✀⤀ഀഀ
  RAISERROR(@StartMessage,10,1) WITH NOWAIT਍ഀഀ
  ----------------------------------------------------------------------------------------------------਍  ⴀⴀ⼀⼀ 匀攀氀攀挀琀 搀愀琀愀戀愀猀攀猀                                                                           ⼀⼀ⴀⴀഀഀ
  ----------------------------------------------------------------------------------------------------਍ഀഀ
  IF @Databases IS NULL OR @Databases = ''਍  䈀䔀䜀䤀一ഀഀ
    SET @ErrorMessage = 'The value for parameter @Databases is not supported.' + CHAR(13) + CHAR(10)਍    刀䄀䤀匀䔀刀刀伀刀⠀䀀䔀爀爀漀爀䴀攀猀猀愀最攀Ⰰ㄀㘀Ⰰ㄀⤀ 圀䤀吀䠀 一伀圀䄀䤀吀ഀഀ
    SET @Error = @@ERROR਍  䔀一䐀ഀഀ
਍  䤀一匀䔀刀吀 䤀一吀伀 䀀琀洀瀀䐀愀琀愀戀愀猀攀猀 ⠀䐀愀琀愀戀愀猀攀一愀洀攀Ⰰ 䌀漀洀瀀氀攀琀攀搀⤀ഀഀ
  SELECT DatabaseName AS DatabaseName,਍         　 䄀匀 䌀漀洀瀀氀攀琀攀搀ഀഀ
  FROM dbo.DatabaseSelect (@Databases)਍  伀刀䐀䔀刀 䈀夀 䐀愀琀愀戀愀猀攀一愀洀攀 䄀匀䌀ഀഀ
਍  䤀䘀 䀀䀀䔀刀刀伀刀 㰀㸀 　 伀刀 ⠀䀀䀀刀伀圀䌀伀唀一吀 㴀 　 䄀一䐀 䀀䐀愀琀愀戀愀猀攀猀 㰀㸀 ✀唀匀䔀刀开䐀䄀吀䄀䈀䄀匀䔀匀✀⤀ഀഀ
  BEGIN਍    匀䔀吀 䀀䔀爀爀漀爀䴀攀猀猀愀最攀 㴀 ✀䔀爀爀漀爀 猀攀氀攀挀琀椀渀最 搀愀琀愀戀愀猀攀猀⸀✀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT਍    匀䔀吀 䀀䔀爀爀漀爀 㴀 䀀䀀䔀刀刀伀刀ഀഀ
  END਍ഀഀ
  ----------------------------------------------------------------------------------------------------਍  ⴀⴀ⼀⼀ 䌀栀攀挀欀 椀渀瀀甀琀 瀀愀爀愀洀攀琀攀爀猀                                                                     ⼀⼀ⴀⴀഀഀ
  ----------------------------------------------------------------------------------------------------਍ഀഀ
  IF @PhysicalOnly NOT IN ('Y','N') OR @PhysicalOnly IS NULL਍  䈀䔀䜀䤀一ഀഀ
    SET @ErrorMessage = 'The value for parameter @PhysicalOnly is not supported.' + CHAR(13) + CHAR(10)਍    刀䄀䤀匀䔀刀刀伀刀⠀䀀䔀爀爀漀爀䴀攀猀猀愀最攀Ⰰ㄀㘀Ⰰ㄀⤀ 圀䤀吀䠀 一伀圀䄀䤀吀ഀഀ
    SET @Error = @@ERROR਍  䔀一䐀ഀഀ
਍  䤀䘀 䀀一漀䤀渀搀攀砀 一伀吀 䤀一 ⠀✀夀✀Ⰰ✀一✀⤀ 伀刀 䀀一漀䤀渀搀攀砀 䤀匀 一唀䰀䰀ഀഀ
  BEGIN਍    匀䔀吀 䀀䔀爀爀漀爀䴀攀猀猀愀最攀 㴀 ✀吀栀攀 瘀愀氀甀攀 昀漀爀 瀀愀爀愀洀攀琀攀爀 䀀一漀䤀渀搀攀砀 椀猀 渀漀琀 猀甀瀀瀀漀爀琀攀搀⸀✀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT਍    匀䔀吀 䀀䔀爀爀漀爀 㴀 䀀䀀䔀刀刀伀刀ഀഀ
  END਍ഀഀ
  IF @ExtendedLogicalChecks NOT IN ('Y','N') OR @ExtendedLogicalChecks IS NULL OR (@ExtendedLogicalChecks = 'Y' AND NOT (CAST(LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar), CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS nvarchar)) - 1) AS int) >= 10))਍  䈀䔀䜀䤀一ഀഀ
    SET @ErrorMessage = 'The value for parameter @ExtendedLogicalChecks is not supported.' + CHAR(13) + CHAR(10)਍    刀䄀䤀匀䔀刀刀伀刀⠀䀀䔀爀爀漀爀䴀攀猀猀愀最攀Ⰰ㄀㘀Ⰰ㄀⤀ 圀䤀吀䠀 一伀圀䄀䤀吀ഀഀ
    SET @Error = @@ERROR਍  䔀一䐀ഀഀ
਍  䤀䘀 ⠀䀀䔀砀琀攀渀搀攀搀䰀漀最椀挀愀氀䌀栀攀挀欀猀 㴀 ✀夀✀ 䄀一䐀 一伀吀 ⠀䌀䄀匀吀⠀䰀䔀䘀吀⠀䌀䄀匀吀⠀匀䔀刀嘀䔀刀倀刀伀倀䔀刀吀夀⠀✀倀爀漀搀甀挀琀嘀攀爀猀椀漀渀✀⤀ 䄀匀 渀瘀愀爀挀栀愀爀⤀Ⰰ 䌀䠀䄀刀䤀一䐀䔀堀⠀✀⸀✀Ⰰ䌀䄀匀吀⠀匀䔀刀嘀䔀刀倀刀伀倀䔀刀吀夀⠀✀倀爀漀搀甀挀琀嘀攀爀猀椀漀渀✀⤀ 䄀匀 渀瘀愀爀挀栀愀爀⤀⤀ ⴀ ㄀⤀ 䄀匀 椀渀琀⤀ 㸀㴀 ㄀　⤀⤀ഀഀ
  BEGIN਍    匀䔀吀 䀀䔀爀爀漀爀䴀攀猀猀愀最攀 㴀 ✀䔀砀琀攀渀搀攀搀 氀漀最椀挀愀氀 挀栀攀挀欀猀 愀爀攀 漀渀氀礀 猀甀瀀瀀漀爀琀攀搀 椀渀 匀儀䰀 匀攀爀瘀攀爀 ㈀　　㠀⸀✀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
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
    BEGIN਍      匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㄀ 㴀 ✀䐀䈀䌀䌀 䌀䠀䔀䌀䬀䐀䈀 ⠀✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ഀഀ
      IF @NoIndex = 'Y' SET @CurrentCommand01 = @CurrentCommand01 + ', NOINDEX'਍      匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㄀ 㴀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㄀ ⬀ ✀⤀ 圀䤀吀䠀 一伀开䤀一䘀伀䴀匀䜀匀Ⰰ 䄀䰀䰀开䔀刀刀伀刀䴀匀䜀匀✀ഀഀ
      IF @PhysicalOnly = 'N' SET @CurrentCommand01 = @CurrentCommand01 + ', DATA_PURITY'਍      䤀䘀 䀀倀栀礀猀椀挀愀氀伀渀氀礀 㴀 ✀夀✀ 匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㄀ 㴀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㄀ ⬀ ✀Ⰰ 倀䠀夀匀䤀䌀䄀䰀开伀一䰀夀✀ഀഀ
      IF @ExtendedLogicalChecks = 'Y' SET @CurrentCommand01 = @CurrentCommand01 + ', EXTENDED_LOGICAL_CHECKS'਍ഀഀ
      EXECUTE @CurrentCommandOutput01 = [dbo].[CommandExecute] @CurrentCommand01, '', 1, @Execute਍      匀䔀吀 䀀䔀爀爀漀爀 㴀 䀀䀀䔀刀刀伀刀ഀഀ
      IF @Error <> 0 SET @CurrentCommandOutput01 = @Error਍    䔀一䐀ഀഀ
਍    ⴀⴀ 唀瀀搀愀琀攀 琀栀愀琀 琀栀攀 搀愀琀愀戀愀猀攀 椀猀 挀漀洀瀀氀攀琀攀搀ഀഀ
    UPDATE @tmpDatabases਍    匀䔀吀 䌀漀洀瀀氀攀琀攀搀 㴀 ㄀ഀഀ
    WHERE ID = @CurrentID਍ഀഀ
    -- Clear variables਍    匀䔀吀 䀀䌀甀爀爀攀渀琀䤀䐀 㴀 一唀䰀䰀ഀഀ
    SET @CurrentDatabase = NULL਍    匀䔀吀 䀀䌀甀爀爀攀渀琀䤀猀䐀愀琀愀戀愀猀攀䄀挀挀攀猀猀椀戀氀攀 㴀 一唀䰀䰀ഀഀ
    SET @CurrentMirroringRole = NULL਍ഀഀ
    SET @CurrentCommand01 = NULL਍ഀഀ
    SET @CurrentCommandOutput01 = NULL਍ഀഀ
  END਍ഀഀ
  ----------------------------------------------------------------------------------------------------਍  ⴀⴀ⼀⼀ 䰀漀最 挀漀洀瀀氀攀琀椀渀最 椀渀昀漀爀洀愀琀椀漀渀                                                                 ⼀⼀ⴀⴀഀഀ
  ----------------------------------------------------------------------------------------------------਍ഀഀ
  Logging:਍  匀䔀吀 䀀䔀渀搀䴀攀猀猀愀最攀 㴀 ✀䐀愀琀攀吀椀洀攀㨀 ✀ ⬀ 䌀伀一嘀䔀刀吀⠀渀瘀愀爀挀栀愀爀Ⰰ䜀䔀吀䐀䄀吀䔀⠀⤀Ⰰ㄀㈀　⤀ഀഀ
  SET @EndMessage = REPLACE(@EndMessage,'%','%%')਍  刀䄀䤀匀䔀刀刀伀刀⠀䀀䔀渀搀䴀攀猀猀愀最攀Ⰰ㄀　Ⰰ㄀⤀ 圀䤀吀䠀 一伀圀䄀䤀吀ഀഀ
਍  ⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀഀഀ
਍䔀一䐀ഀഀ
GO਍�