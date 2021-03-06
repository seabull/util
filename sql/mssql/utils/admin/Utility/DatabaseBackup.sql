SET ANSI_NULLS ON਍䜀伀ഀഀ
SET QUOTED_IDENTIFIER ON਍䜀伀ഀഀ
CREATE PROCEDURE [dbo].[DatabaseBackup]਍ഀഀ
@Databases nvarchar(max),਍䀀䐀椀爀攀挀琀漀爀礀 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀ 㴀 一唀䰀䰀Ⰰഀഀ
@BackupType nvarchar(max),਍䀀嘀攀爀椀昀礀 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀ 㴀 ✀一✀Ⰰഀഀ
@CleanupTime int = NULL,਍䀀䌀漀洀瀀爀攀猀猀 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀ 㴀 ✀一✀Ⰰഀഀ
@CopyOnly nvarchar(max) = 'N',਍䀀䌀栀愀渀最攀䈀愀挀欀甀瀀吀礀瀀攀 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀ 㴀 ✀一✀Ⰰഀഀ
@BackupSoftware nvarchar(max) = NULL,਍䀀䌀栀攀挀欀匀甀洀 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀ 㴀 ✀一✀Ⰰഀഀ
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
਍  䐀䔀䌀䰀䄀刀䔀 䀀䐀攀昀愀甀氀琀䐀椀爀攀挀琀漀爀礀 渀瘀愀爀挀栀愀爀⠀㐀　　　⤀ഀഀ
਍  䐀䔀䌀䰀䄀刀䔀 䀀䌀甀爀爀攀渀琀䤀䐀 椀渀琀ഀഀ
  DECLARE @CurrentDatabase nvarchar(max)਍  䐀䔀䌀䰀䄀刀䔀 䀀䌀甀爀爀攀渀琀䈀愀挀欀甀瀀吀礀瀀攀 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀ഀഀ
  DECLARE @CurrentFileExtension nvarchar(max)਍  䐀䔀䌀䰀䄀刀䔀 䀀䌀甀爀爀攀渀琀䐀椀昀昀攀爀攀渀琀椀愀氀䰀匀一 渀甀洀攀爀椀挀⠀㈀㔀Ⰰ　⤀ഀഀ
  DECLARE @CurrentLogLSN numeric(25,0)਍  䐀䔀䌀䰀䄀刀䔀 䀀䌀甀爀爀攀渀琀䰀愀琀攀猀琀䈀愀挀欀甀瀀 搀愀琀攀琀椀洀攀ഀഀ
  DECLARE @CurrentDatabaseFS nvarchar(max)਍  䐀䔀䌀䰀䄀刀䔀 䀀䌀甀爀爀攀渀琀䐀椀爀攀挀琀漀爀礀 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀ഀഀ
  DECLARE @CurrentDate datetime਍  䐀䔀䌀䰀䄀刀䔀 䀀䌀甀爀爀攀渀琀䘀椀氀攀一愀洀攀 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀ഀഀ
  DECLARE @CurrentFilePath nvarchar(max)਍  䐀䔀䌀䰀䄀刀䔀 䀀䌀甀爀爀攀渀琀䌀氀攀愀渀甀瀀䐀愀琀攀 搀愀琀攀琀椀洀攀ഀഀ
  DECLARE @CurrentIsDatabaseAccessible bit਍  䐀䔀䌀䰀䄀刀䔀 䀀䌀甀爀爀攀渀琀䴀椀爀爀漀爀椀渀最刀漀氀攀 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀ഀഀ
਍  䐀䔀䌀䰀䄀刀䔀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㄀ 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀ഀഀ
  DECLARE @CurrentCommand02 nvarchar(max)਍  䐀䔀䌀䰀䄀刀䔀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㌀ 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀ഀഀ
  DECLARE @CurrentCommand04 nvarchar(max)਍ഀഀ
  DECLARE @CurrentCommandOutput01 int਍  䐀䔀䌀䰀䄀刀䔀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀伀甀琀瀀甀琀　㈀ 椀渀琀ഀഀ
  DECLARE @CurrentCommandOutput03 int਍  䐀䔀䌀䰀䄀刀䔀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀伀甀琀瀀甀琀　㐀 椀渀琀ഀഀ
਍  䐀䔀䌀䰀䄀刀䔀 䀀䐀椀爀攀挀琀漀爀礀䤀渀昀漀䌀漀洀洀愀渀搀 渀瘀愀爀挀栀愀爀⠀洀愀砀⤀ഀഀ
਍  䐀䔀䌀䰀䄀刀䔀 䀀䐀椀爀攀挀琀漀爀礀䤀渀昀漀 吀䄀䈀䰀䔀 ⠀䘀椀氀攀䔀砀椀猀琀猀 戀椀琀Ⰰഀഀ
                                FileIsADirectory bit,਍                                倀愀爀攀渀琀䐀椀爀攀挀琀漀爀礀䔀砀椀猀琀猀 戀椀琀⤀ഀഀ
਍  䐀䔀䌀䰀䄀刀䔀 䀀琀洀瀀䐀愀琀愀戀愀猀攀猀 吀䄀䈀䰀䔀 ⠀䤀䐀 椀渀琀 䤀䐀䔀一吀䤀吀夀 倀刀䤀䴀䄀刀夀 䬀䔀夀Ⰰഀഀ
                               DatabaseName nvarchar(max),਍                               䌀漀洀瀀氀攀琀攀搀 戀椀琀⤀ഀഀ
਍  䐀䔀䌀䰀䄀刀䔀 䀀䔀爀爀漀爀 椀渀琀ഀഀ
਍  匀䔀吀 䀀䔀爀爀漀爀 㴀 　ഀഀ
਍  ⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀഀഀ
  --// Log initial information                                                                    //--਍  ⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀഀഀ
਍  匀䔀吀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 㴀 ✀䐀愀琀攀吀椀洀攀㨀 ✀ ⬀ 䌀伀一嘀䔀刀吀⠀渀瘀愀爀挀栀愀爀Ⰰ䜀䔀吀䐀䄀吀䔀⠀⤀Ⰰ㄀㈀　⤀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
  SET @StartMessage = @StartMessage + 'Server: ' + CAST(SERVERPROPERTY('ServerName') AS nvarchar) + CHAR(13) + CHAR(10)਍  匀䔀吀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 㴀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 ⬀ ✀嘀攀爀猀椀漀渀㨀 ✀ ⬀ 䌀䄀匀吀⠀匀䔀刀嘀䔀刀倀刀伀倀䔀刀吀夀⠀✀倀爀漀搀甀挀琀嘀攀爀猀椀漀渀✀⤀ 䄀匀 渀瘀愀爀挀栀愀爀⤀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
  SET @StartMessage = @StartMessage + 'Edition: ' + CAST(SERVERPROPERTY('Edition') AS nvarchar) + CHAR(13) + CHAR(10)਍  匀䔀吀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 㴀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 ⬀ ✀倀爀漀挀攀搀甀爀攀㨀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䐀䈀开一䄀䴀䔀⠀䐀䈀开䤀䐀⠀⤀⤀⤀ ⬀ ✀⸀✀ ⬀ ⠀匀䔀䰀䔀䌀吀 儀唀伀吀䔀一䄀䴀䔀⠀猀礀猀⸀猀挀栀攀洀愀猀⸀渀愀洀攀⤀ 䘀刀伀䴀 猀礀猀⸀猀挀栀攀洀愀猀 䤀一一䔀刀 䨀伀䤀一 猀礀猀⸀漀戀樀攀挀琀猀 伀一 猀礀猀⸀猀挀栀攀洀愀猀⸀嬀猀挀栀攀洀愀开椀搀崀 㴀 猀礀猀⸀漀戀樀攀挀琀猀⸀嬀猀挀栀攀洀愀开椀搀崀 圀䠀䔀刀䔀 嬀漀戀樀攀挀琀开椀搀崀 㴀 䀀䀀倀刀伀䌀䤀䐀⤀ ⬀ ✀⸀✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀伀䈀䨀䔀䌀吀开一䄀䴀䔀⠀䀀䀀倀刀伀䌀䤀䐀⤀⤀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
  SET @StartMessage = @StartMessage + 'Parameters: @Databases = ' + ISNULL('''' + REPLACE(@Databases,'''','''''') + '''','NULL')਍  匀䔀吀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 㴀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 ⬀ ✀Ⰰ 䀀䐀椀爀攀挀琀漀爀礀 㴀 ✀ ⬀ 䤀匀一唀䰀䰀⠀✀✀✀✀ ⬀ 刀䔀倀䰀䄀䌀䔀⠀䀀䐀椀爀攀挀琀漀爀礀Ⰰ✀✀✀✀Ⰰ✀✀✀✀✀✀⤀ ⬀ ✀✀✀✀Ⰰ✀一唀䰀䰀✀⤀ഀഀ
  SET @StartMessage = @StartMessage + ', @BackupType = ' + ISNULL('''' + REPLACE(@BackupType,'''','''''') + '''','NULL')਍  匀䔀吀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 㴀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 ⬀ ✀Ⰰ 䀀嘀攀爀椀昀礀 㴀 ✀ ⬀ 䤀匀一唀䰀䰀⠀✀✀✀✀ ⬀ 刀䔀倀䰀䄀䌀䔀⠀䀀嘀攀爀椀昀礀Ⰰ✀✀✀✀Ⰰ✀✀✀✀✀✀⤀ ⬀ ✀✀✀✀Ⰰ✀一唀䰀䰀✀⤀ഀഀ
  SET @StartMessage = @StartMessage + ', @CleanupTime = ' + ISNULL(CAST(@CleanupTime AS nvarchar),'NULL')਍  匀䔀吀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 㴀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 ⬀ ✀Ⰰ 䀀䌀漀洀瀀爀攀猀猀 㴀 ✀ ⬀ 䤀匀一唀䰀䰀⠀✀✀✀✀ ⬀ 刀䔀倀䰀䄀䌀䔀⠀䀀䌀漀洀瀀爀攀猀猀Ⰰ✀✀✀✀Ⰰ✀✀✀✀✀✀⤀ ⬀ ✀✀✀✀Ⰰ✀一唀䰀䰀✀⤀ഀഀ
  SET @StartMessage = @StartMessage + ', @CopyOnly = ' + ISNULL('''' + REPLACE(@CopyOnly,'''','''''') + '''','NULL')਍  匀䔀吀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 㴀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 ⬀ ✀Ⰰ 䀀䌀栀愀渀最攀䈀愀挀欀甀瀀吀礀瀀攀 㴀 ✀ ⬀ 䤀匀一唀䰀䰀⠀✀✀✀✀ ⬀ 刀䔀倀䰀䄀䌀䔀⠀䀀䌀栀愀渀最攀䈀愀挀欀甀瀀吀礀瀀攀Ⰰ✀✀✀✀Ⰰ✀✀✀✀✀✀⤀ ⬀ ✀✀✀✀Ⰰ✀一唀䰀䰀✀⤀ഀഀ
  SET @StartMessage = @StartMessage + ', @BackupSoftware = ' + ISNULL('''' + REPLACE(@BackupSoftware,'''','''''') + '''','NULL')਍  匀䔀吀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 㴀 䀀匀琀愀爀琀䴀攀猀猀愀最攀 ⬀ ✀Ⰰ 䀀䌀栀攀挀欀匀甀洀 㴀 ✀ ⬀ 䤀匀一唀䰀䰀⠀✀✀✀✀ ⬀ 刀䔀倀䰀䄀䌀䔀⠀䀀䌀栀攀挀欀匀甀洀Ⰰ✀✀✀✀Ⰰ✀✀✀✀✀✀⤀ ⬀ ✀✀✀✀Ⰰ✀一唀䰀䰀✀⤀ഀഀ
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
਍  匀䔀吀 䀀䔀爀爀漀爀䴀攀猀猀愀最攀 㴀 ✀✀ഀഀ
  SELECT @ErrorMessage = @ErrorMessage + QUOTENAME(DatabaseName) + ', '਍  䘀刀伀䴀 䀀琀洀瀀䐀愀琀愀戀愀猀攀猀ഀഀ
  WHERE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(DatabaseName,'\',''),'/',''),':',''),'*',''),'?',''),'"',''),'<',''),'>',''),'|',''),' ','') = ''਍  伀刀䐀䔀刀 䈀夀 䐀愀琀愀戀愀猀攀一愀洀攀 䄀匀䌀ഀഀ
  IF @@ROWCOUNT > 0਍  䈀䔀䜀䤀一ഀഀ
    SET @ErrorMessage = 'The names of the following databases are not supported; ' + LEFT(@ErrorMessage,LEN(@ErrorMessage)-1) + '.' + CHAR(13) + CHAR(10)਍    刀䄀䤀匀䔀刀刀伀刀⠀䀀䔀爀爀漀爀䴀攀猀猀愀最攀Ⰰ㄀㘀Ⰰ㄀⤀ 圀䤀吀䠀 一伀圀䄀䤀吀ഀഀ
    SET @Error = @@ERROR਍  䔀一䐀ഀഀ
਍  匀䔀吀 䀀䔀爀爀漀爀䴀攀猀猀愀最攀 㴀 ✀✀㬀ഀഀ
  WITH tmpDatabasesCTE਍  䄀匀ഀഀ
  (਍  匀䔀䰀䔀䌀吀 渀愀洀攀 䄀匀 䐀愀琀愀戀愀猀攀一愀洀攀Ⰰഀഀ
         UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(name,'\',''),'/',''),':',''),'*',''),'?',''),'"',''),'<',''),'>',''),'|',''),' ','')) AS DatabaseNameFS਍  䘀刀伀䴀 猀礀猀⸀搀愀琀愀戀愀猀攀猀ഀഀ
  )਍  匀䔀䰀䔀䌀吀 䀀䔀爀爀漀爀䴀攀猀猀愀最攀 㴀 䀀䔀爀爀漀爀䴀攀猀猀愀最攀 ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䐀愀琀愀戀愀猀攀一愀洀攀⤀ ⬀ ✀Ⰰ ✀ഀഀ
  FROM tmpDatabasesCTE਍  圀䠀䔀刀䔀 䐀愀琀愀戀愀猀攀一愀洀攀䘀匀 䤀一⠀匀䔀䰀䔀䌀吀 䐀愀琀愀戀愀猀攀一愀洀攀䘀匀 䘀刀伀䴀 琀洀瀀䐀愀琀愀戀愀猀攀猀䌀吀䔀 䜀刀伀唀倀 䈀夀 䐀愀琀愀戀愀猀攀一愀洀攀䘀匀 䠀䄀嘀䤀一䜀 䌀伀唀一吀⠀⨀⤀ 㸀 ㄀⤀ഀഀ
  AND DatabaseNameFS IN(SELECT UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(DatabaseName,'\',''),'/',''),':',''),'*',''),'?',''),'"',''),'<',''),'>',''),'|',''),' ','')) FROM @tmpDatabases)਍  䄀一䐀 䐀愀琀愀戀愀猀攀一愀洀攀䘀匀 㰀㸀 ✀✀ഀഀ
  ORDER BY DatabaseNameFS ASC, DatabaseName ASC਍  䤀䘀 䀀䀀刀伀圀䌀伀唀一吀 㸀 　ഀഀ
  BEGIN਍    匀䔀吀 䀀䔀爀爀漀爀䴀攀猀猀愀最攀 㴀 ✀吀栀攀 渀愀洀攀猀 漀昀 琀栀攀 昀漀氀氀漀眀椀渀最 搀愀琀愀戀愀猀攀猀 愀爀攀 渀漀琀 甀渀椀焀甀攀 椀渀 琀栀攀 昀椀氀攀 猀礀猀琀攀洀㬀 ✀ ⬀ 䰀䔀䘀吀⠀䀀䔀爀爀漀爀䴀攀猀猀愀最攀Ⰰ䰀䔀一⠀䀀䔀爀爀漀爀䴀攀猀猀愀最攀⤀ⴀ㄀⤀ ⬀ ✀⸀✀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT਍    匀䔀吀 䀀䔀爀爀漀爀 㴀 䀀䀀䔀刀刀伀刀ഀഀ
  END਍ഀഀ
  ----------------------------------------------------------------------------------------------------਍  ⴀⴀ⼀⼀ 䜀攀琀 搀攀昀愀甀氀琀 戀愀挀欀甀瀀 搀椀爀攀挀琀漀爀礀⸀                                                              ⼀⼀ⴀⴀഀഀ
  ----------------------------------------------------------------------------------------------------਍ഀഀ
  IF @Directory IS NULL਍  䈀䔀䜀䤀一ഀഀ
    EXECUTE [master].dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\MSSQLServer', N'BackupDirectory', @DefaultDirectory OUTPUT਍    匀䔀吀 䀀䐀椀爀攀挀琀漀爀礀 㴀 䀀䐀攀昀愀甀氀琀䐀椀爀攀挀琀漀爀礀ഀഀ
  END਍ഀഀ
  ----------------------------------------------------------------------------------------------------਍  ⴀⴀ⼀⼀ 䌀栀攀挀欀 搀椀爀攀挀琀漀爀礀                                                                            ⼀⼀ⴀⴀഀഀ
  ----------------------------------------------------------------------------------------------------਍ഀഀ
  IF NOT (@Directory LIKE '_:' OR @Directory LIKE '_:\%' OR @Directory LIKE '\\%\%') OR @Directory IS NULL OR LEFT(@Directory,1) = ' ' OR RIGHT(@Directory,1) = ' '਍  䈀䔀䜀䤀一ഀഀ
    SET @ErrorMessage = 'The value for parameter @Directory is not supported.' + CHAR(13) + CHAR(10)਍    刀䄀䤀匀䔀刀刀伀刀⠀䀀䔀爀爀漀爀䴀攀猀猀愀最攀Ⰰ㄀㘀Ⰰ㄀⤀ 圀䤀吀䠀 一伀圀䄀䤀吀ഀഀ
    SET @Error = @@ERROR਍  䔀一䐀ഀഀ
਍  匀䔀吀 䀀䐀椀爀攀挀琀漀爀礀䤀渀昀漀䌀漀洀洀愀渀搀 㴀 ✀䔀堀䔀䌀唀吀䔀 砀瀀开昀椀氀攀攀砀椀猀琀 一✀✀✀ ⬀ 刀䔀倀䰀䄀䌀䔀⠀䀀䐀椀爀攀挀琀漀爀礀Ⰰ✀✀✀✀Ⰰ✀✀✀✀✀✀⤀ ⬀ ✀✀✀✀ഀഀ
਍  䤀一匀䔀刀吀 䤀一吀伀 䀀䐀椀爀攀挀琀漀爀礀䤀渀昀漀 ⠀䘀椀氀攀䔀砀椀猀琀猀Ⰰ 䘀椀氀攀䤀猀䄀䐀椀爀攀挀琀漀爀礀Ⰰ 倀愀爀攀渀琀䐀椀爀攀挀琀漀爀礀䔀砀椀猀琀猀⤀ഀഀ
  EXECUTE(@DirectoryInfoCommand)਍ഀഀ
  IF NOT EXISTS (SELECT * FROM @DirectoryInfo WHERE FileExists = 0 AND FileIsADirectory = 1 AND ParentDirectoryExists = 1)਍  䈀䔀䜀䤀一ഀഀ
    SET @ErrorMessage = 'The directory does not exist.' + CHAR(13) + CHAR(10)਍    刀䄀䤀匀䔀刀刀伀刀⠀䀀䔀爀爀漀爀䴀攀猀猀愀最攀Ⰰ㄀㘀Ⰰ㄀⤀ 圀䤀吀䠀 一伀圀䄀䤀吀ഀഀ
    SET @Error = @@ERROR਍  䔀一䐀ഀഀ
਍  ⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀഀഀ
  --// Check input parameters                                                                     //--਍  ⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀഀഀ
਍  䤀䘀 䀀䈀愀挀欀甀瀀吀礀瀀攀 一伀吀 䤀一 ⠀✀䘀唀䰀䰀✀Ⰰ✀䐀䤀䘀䘀✀Ⰰ✀䰀伀䜀✀⤀ 伀刀 䀀䈀愀挀欀甀瀀吀礀瀀攀 䤀匀 一唀䰀䰀ഀഀ
  BEGIN਍    匀䔀吀 䀀䔀爀爀漀爀䴀攀猀猀愀最攀 㴀 ✀吀栀攀 瘀愀氀甀攀 昀漀爀 瀀愀爀愀洀攀琀攀爀 䀀䈀愀挀欀甀瀀吀礀瀀攀 椀猀 渀漀琀 猀甀瀀瀀漀爀琀攀搀⸀✀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT਍    匀䔀吀 䀀䔀爀爀漀爀 㴀 䀀䀀䔀刀刀伀刀ഀഀ
  END਍ഀഀ
  IF @Verify NOT IN ('Y','N') OR @Verify IS NULL਍  䈀䔀䜀䤀一ഀഀ
    SET @ErrorMessage = 'The value for parameter @Verify is not supported.' + CHAR(13) + CHAR(10)਍    刀䄀䤀匀䔀刀刀伀刀⠀䀀䔀爀爀漀爀䴀攀猀猀愀最攀Ⰰ㄀㘀Ⰰ㄀⤀ 圀䤀吀䠀 一伀圀䄀䤀吀ഀഀ
    SET @Error = @@ERROR਍  䔀一䐀ഀഀ
਍  䤀䘀 䀀䌀氀攀愀渀甀瀀吀椀洀攀 㰀 　ഀഀ
  BEGIN਍    匀䔀吀 䀀䔀爀爀漀爀䴀攀猀猀愀最攀 㴀 ✀吀栀攀 瘀愀氀甀攀 昀漀爀 瀀愀爀愀洀攀琀攀爀 䀀䌀氀攀愀渀甀瀀吀椀洀攀 椀猀 渀漀琀 猀甀瀀瀀漀爀琀攀搀⸀✀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT਍    匀䔀吀 䀀䔀爀爀漀爀 㴀 䀀䀀䔀刀刀伀刀ഀഀ
  END਍ഀഀ
  IF @Compress NOT IN ('Y','N') OR @Compress IS NULL OR (@Compress = 'Y' AND NOT (SERVERPROPERTY('EngineEdition') = 3 AND CAST(LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar), CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS nvarchar)) - 1) AS int) >= 10))਍  䈀䔀䜀䤀一ഀഀ
    SET @ErrorMessage = 'The value for parameter @Compress is not supported.' + CHAR(13) + CHAR(10)਍    刀䄀䤀匀䔀刀刀伀刀⠀䀀䔀爀爀漀爀䴀攀猀猀愀最攀Ⰰ㄀㘀Ⰰ㄀⤀ 圀䤀吀䠀 一伀圀䄀䤀吀ഀഀ
    SET @Error = @@ERROR਍  䔀一䐀ഀഀ
਍  䤀䘀 䀀䌀漀洀瀀爀攀猀猀 㴀 ✀夀✀ 䄀一䐀 一伀吀 ⠀匀䔀刀嘀䔀刀倀刀伀倀䔀刀吀夀⠀✀䔀渀最椀渀攀䔀搀椀琀椀漀渀✀⤀ 㴀 ㌀ 䄀一䐀 䌀䄀匀吀⠀䰀䔀䘀吀⠀䌀䄀匀吀⠀匀䔀刀嘀䔀刀倀刀伀倀䔀刀吀夀⠀✀倀爀漀搀甀挀琀嘀攀爀猀椀漀渀✀⤀ 䄀匀 渀瘀愀爀挀栀愀爀⤀Ⰰ 䌀䠀䄀刀䤀一䐀䔀堀⠀✀⸀✀Ⰰ䌀䄀匀吀⠀匀䔀刀嘀䔀刀倀刀伀倀䔀刀吀夀⠀✀倀爀漀搀甀挀琀嘀攀爀猀椀漀渀✀⤀ 䄀匀 渀瘀愀爀挀栀愀爀⤀⤀ ⴀ ㄀⤀ 䄀匀 椀渀琀⤀ 㸀㴀 ㄀　⤀ഀഀ
  BEGIN਍    匀䔀吀 䀀䔀爀爀漀爀䴀攀猀猀愀最攀 㴀 ✀䈀愀挀欀甀瀀 挀漀洀瀀爀攀猀猀椀漀渀 椀猀 漀渀氀礀 猀甀瀀瀀漀爀琀攀搀 椀渀 匀儀䰀 匀攀爀瘀攀爀 ㈀　　㠀 䔀渀琀攀爀瀀爀椀猀攀 愀渀搀 䐀攀瘀攀氀漀瀀攀爀 䔀搀椀琀椀漀渀⸀✀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT਍    匀䔀吀 䀀䔀爀爀漀爀 㴀 䀀䀀䔀刀刀伀刀ഀഀ
  END਍ഀഀ
  IF @CopyOnly NOT IN ('Y','N') OR @CopyOnly IS NULL਍  䈀䔀䜀䤀一ഀഀ
    SET @ErrorMessage = 'The value for parameter @CopyOnly is not supported.' + CHAR(13) + CHAR(10)਍    刀䄀䤀匀䔀刀刀伀刀⠀䀀䔀爀爀漀爀䴀攀猀猀愀最攀Ⰰ㄀㘀Ⰰ㄀⤀ 圀䤀吀䠀 一伀圀䄀䤀吀ഀഀ
    SET @Error = @@ERROR਍  䔀一䐀ഀഀ
਍  䤀䘀 䀀䌀栀愀渀最攀䈀愀挀欀甀瀀吀礀瀀攀 一伀吀 䤀一 ⠀✀夀✀Ⰰ✀一✀⤀ 伀刀 䀀䌀栀愀渀最攀䈀愀挀欀甀瀀吀礀瀀攀 䤀匀 一唀䰀䰀ഀഀ
  BEGIN਍    匀䔀吀 䀀䔀爀爀漀爀䴀攀猀猀愀最攀 㴀 ✀吀栀攀 瘀愀氀甀攀 昀漀爀 瀀愀爀愀洀攀琀攀爀 䀀䌀栀愀渀最攀䈀愀挀欀甀瀀吀礀瀀攀 椀猀 渀漀琀 猀甀瀀瀀漀爀琀攀搀⸀✀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT਍    匀䔀吀 䀀䔀爀爀漀爀 㴀 䀀䀀䔀刀刀伀刀ഀഀ
  END਍ഀഀ
  IF @BackupSoftware NOT IN ('LITESPEED') OR (@BackupSoftware = 'LITESPEED' AND NOT EXISTS (SELECT * FROM [master].sys.objects WHERE [type] = 'X' AND [name] = 'xp_sqllitespeed_version'))਍  䈀䔀䜀䤀一ഀഀ
    SET @ErrorMessage = 'The value for parameter @BackupSoftware is not supported.' + CHAR(13) + CHAR(10)਍    刀䄀䤀匀䔀刀刀伀刀⠀䀀䔀爀爀漀爀䴀攀猀猀愀最攀Ⰰ㄀㘀Ⰰ㄀⤀ 圀䤀吀䠀 一伀圀䄀䤀吀ഀഀ
    SET @Error = @@ERROR਍  䔀一䐀ഀഀ
਍  䤀䘀 䀀䈀愀挀欀甀瀀匀漀昀琀眀愀爀攀 㴀 ✀䰀䤀吀䔀匀倀䔀䔀䐀✀ 䄀一䐀 一伀吀 䔀堀䤀匀吀匀 ⠀匀䔀䰀䔀䌀吀 ⨀ 䘀刀伀䴀 嬀洀愀猀琀攀爀崀⸀猀礀猀⸀漀戀樀攀挀琀猀 圀䠀䔀刀䔀 嬀琀礀瀀攀崀 㴀 ✀堀✀ 䄀一䐀 嬀渀愀洀攀崀 㴀 ✀砀瀀开猀焀氀氀椀琀攀猀瀀攀攀搀开瘀攀爀猀椀漀渀✀⤀ഀഀ
  BEGIN਍    匀䔀吀 䀀䔀爀爀漀爀䴀攀猀猀愀最攀 㴀 ✀䰀椀琀攀匀瀀攀攀搀 椀猀 渀漀琀 椀渀猀琀愀氀氀攀搀⸀✀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT਍    匀䔀吀 䀀䔀爀爀漀爀 㴀 䀀䀀䔀刀刀伀刀ഀഀ
  END਍ഀഀ
  IF @CheckSum NOT IN ('Y','N') OR @CheckSum IS NULL਍  䈀䔀䜀䤀一ഀഀ
    SET @ErrorMessage = 'The value for parameter @CheckSum is not supported.' + CHAR(13) + CHAR(10)਍    刀䄀䤀匀䔀刀刀伀刀⠀䀀䔀爀爀漀爀䴀攀猀猀愀最攀Ⰰ㄀㘀Ⰰ㄀⤀ 圀䤀吀䠀 一伀圀䄀䤀吀ഀഀ
    SET @Error = @@ERROR਍  䔀一䐀ഀഀ
਍  䤀䘀 䀀䔀砀攀挀甀琀攀 一伀吀 䤀一⠀✀夀✀Ⰰ✀一✀⤀ 伀刀 䀀䔀砀攀挀甀琀攀 䤀匀 一唀䰀䰀ഀഀ
  BEGIN਍    匀䔀吀 䀀䔀爀爀漀爀䴀攀猀猀愀最攀 㴀 ✀吀栀攀 瘀愀氀甀攀 昀漀爀 瀀愀爀愀洀攀琀攀爀 䀀䔀砀攀挀甀琀攀 椀猀 渀漀琀 猀甀瀀瀀漀爀琀攀搀⸀✀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT਍    匀䔀吀 䀀䔀爀爀漀爀 㴀 䀀䀀䔀刀刀伀刀ഀഀ
  END਍ഀഀ
  ----------------------------------------------------------------------------------------------------਍  ⴀⴀ⼀⼀ 䌀栀攀挀欀 攀爀爀漀爀 瘀愀爀椀愀戀氀攀                                                                       ⼀⼀ⴀⴀഀഀ
  ----------------------------------------------------------------------------------------------------਍ഀഀ
  IF @Error <> 0 GOTO Logging਍ഀഀ
  ----------------------------------------------------------------------------------------------------਍  ⴀⴀ⼀⼀ 䔀砀攀挀甀琀攀 戀愀挀欀甀瀀 挀漀洀洀愀渀搀猀                                                                    ⼀⼀ⴀⴀഀഀ
  ----------------------------------------------------------------------------------------------------਍ഀഀ
  WHILE EXISTS (SELECT * FROM @tmpDatabases WHERE Completed = 0)਍  䈀䔀䜀䤀一ഀഀ
਍    匀䔀䰀䔀䌀吀 吀伀倀 ㄀ 䀀䌀甀爀爀攀渀琀䤀䐀 㴀 䤀䐀Ⰰഀഀ
                 @CurrentDatabase = DatabaseName਍    䘀刀伀䴀 䀀琀洀瀀䐀愀琀愀戀愀猀攀猀ഀഀ
    WHERE Completed = 0਍    伀刀䐀䔀刀 䈀夀 䤀䐀 䄀匀䌀ഀഀ
਍    䤀䘀 䔀堀䤀匀吀匀 ⠀匀䔀䰀䔀䌀吀 ⨀ 䘀刀伀䴀 猀礀猀⸀搀愀琀愀戀愀猀攀开爀攀挀漀瘀攀爀礀开猀琀愀琀甀猀 圀䠀䔀刀䔀 搀愀琀愀戀愀猀攀开椀搀 㴀 䐀䈀开䤀䐀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ 䄀一䐀 搀愀琀愀戀愀猀攀开最甀椀搀 䤀匀 一伀吀 一唀䰀䰀⤀ഀഀ
    BEGIN਍      匀䔀吀 䀀䌀甀爀爀攀渀琀䤀猀䐀愀琀愀戀愀猀攀䄀挀挀攀猀猀椀戀氀攀 㴀 ㄀ഀഀ
    END਍    䔀䰀匀䔀ഀഀ
    BEGIN਍      匀䔀吀 䀀䌀甀爀爀攀渀琀䤀猀䐀愀琀愀戀愀猀攀䄀挀挀攀猀猀椀戀氀攀 㴀 　ഀഀ
    END਍ഀഀ
    SELECT @CurrentMirroringRole = mirroring_role_desc਍    䘀刀伀䴀 猀礀猀⸀搀愀琀愀戀愀猀攀开洀椀爀爀漀爀椀渀最ഀഀ
    WHERE database_id = DB_ID(@CurrentDatabase)਍ഀഀ
    SELECT @CurrentDifferentialLSN = differential_base_lsn਍    䘀刀伀䴀 猀礀猀⸀洀愀猀琀攀爀开昀椀氀攀猀ഀഀ
    WHERE database_id = DB_ID(@CurrentDatabase)਍    䄀一䐀 嬀琀礀瀀攀崀 㴀 　ഀഀ
    AND [file_id] = 1਍ഀഀ
    -- Workaround for a bug in SQL Server 2005਍    䤀䘀 䌀䄀匀吀⠀䰀䔀䘀吀⠀䌀䄀匀吀⠀匀䔀刀嘀䔀刀倀刀伀倀䔀刀吀夀⠀✀倀爀漀搀甀挀琀嘀攀爀猀椀漀渀✀⤀ 䄀匀 渀瘀愀爀挀栀愀爀⤀Ⰰ 䌀䠀䄀刀䤀一䐀䔀堀⠀✀⸀✀Ⰰ䌀䄀匀吀⠀匀䔀刀嘀䔀刀倀刀伀倀䔀刀吀夀⠀✀倀爀漀搀甀挀琀嘀攀爀猀椀漀渀✀⤀ 䄀匀 渀瘀愀爀挀栀愀爀⤀⤀ ⴀ ㄀⤀ 䄀匀 椀渀琀⤀ 㴀 㤀ഀഀ
    AND (SELECT differential_base_lsn FROM sys.master_files WHERE database_id = DB_ID(@CurrentDatabase) AND [type] = 0 AND [file_id] = 1) = (SELECT differential_base_lsn FROM sys.master_files WHERE database_id = DB_ID('model') AND [type] = 0 AND [file_id] = 1)਍    䄀一䐀 ⠀匀䔀䰀䔀䌀吀 搀椀昀昀攀爀攀渀琀椀愀氀开戀愀猀攀开最甀椀搀 䘀刀伀䴀 猀礀猀⸀洀愀猀琀攀爀开昀椀氀攀猀 圀䠀䔀刀䔀 搀愀琀愀戀愀猀攀开椀搀 㴀 䐀䈀开䤀䐀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ 䄀一䐀 嬀琀礀瀀攀崀 㴀 　 䄀一䐀 嬀昀椀氀攀开椀搀崀 㴀 ㄀⤀ 㴀 ⠀匀䔀䰀䔀䌀吀 搀椀昀昀攀爀攀渀琀椀愀氀开戀愀猀攀开最甀椀搀 䘀刀伀䴀 猀礀猀⸀洀愀猀琀攀爀开昀椀氀攀猀 圀䠀䔀刀䔀 搀愀琀愀戀愀猀攀开椀搀 㴀 䐀䈀开䤀䐀⠀✀洀漀搀攀氀✀⤀ 䄀一䐀 嬀琀礀瀀攀崀 㴀 　 䄀一䐀 嬀昀椀氀攀开椀搀崀 㴀 ㄀⤀ഀഀ
    AND (SELECT differential_base_time FROM sys.master_files WHERE database_id = DB_ID(@CurrentDatabase) AND [type] = 0 AND [file_id] = 1) IS NULL਍    䈀䔀䜀䤀一ഀഀ
      SET @CurrentDifferentialLSN = NULL਍    䔀一䐀ഀഀ
਍    匀䔀䰀䔀䌀吀 䀀䌀甀爀爀攀渀琀䰀漀最䰀匀一 㴀 氀愀猀琀开氀漀最开戀愀挀欀甀瀀开氀猀渀ഀഀ
    FROM sys.database_recovery_status਍    圀䠀䔀刀䔀 搀愀琀愀戀愀猀攀开椀搀 㴀 䐀䈀开䤀䐀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ഀഀ
਍    匀䔀吀 䀀䌀甀爀爀攀渀琀䈀愀挀欀甀瀀吀礀瀀攀 㴀 䀀䈀愀挀欀甀瀀吀礀瀀攀ഀഀ
਍    䤀䘀 䀀䌀栀愀渀最攀䈀愀挀欀甀瀀吀礀瀀攀 㴀 ✀夀✀ഀഀ
    BEGIN਍      䤀䘀 䀀䌀甀爀爀攀渀琀䈀愀挀欀甀瀀吀礀瀀攀 㴀 ✀䰀伀䜀✀ 䄀一䐀 䐀䄀吀䄀䈀䄀匀䔀倀刀伀倀䔀刀吀夀䔀堀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀Ⰰ✀刀攀挀漀瘀攀爀礀✀⤀ 㰀㸀 ✀匀䤀䴀倀䰀䔀✀ 䄀一䐀 䀀䌀甀爀爀攀渀琀䰀漀最䰀匀一 䤀匀 一唀䰀䰀 䄀一䐀 䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀 㰀㸀 ✀洀愀猀琀攀爀✀ഀഀ
      BEGIN਍        匀䔀吀 䀀䌀甀爀爀攀渀琀䈀愀挀欀甀瀀吀礀瀀攀 㴀 ✀䐀䤀䘀䘀✀ഀഀ
      END਍      䤀䘀 䀀䌀甀爀爀攀渀琀䈀愀挀欀甀瀀吀礀瀀攀 㴀 ✀䐀䤀䘀䘀✀ 䄀一䐀 䀀䌀甀爀爀攀渀琀䐀椀昀昀攀爀攀渀琀椀愀氀䰀匀一 䤀匀 一唀䰀䰀 䄀一䐀 䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀 㰀㸀 ✀洀愀猀琀攀爀✀ഀഀ
      BEGIN਍        匀䔀吀 䀀䌀甀爀爀攀渀琀䈀愀挀欀甀瀀吀礀瀀攀 㴀 ✀䘀唀䰀䰀✀ഀഀ
      END਍    䔀一䐀ഀഀ
਍    匀䔀䰀䔀䌀吀 䀀䌀甀爀爀攀渀琀䰀愀琀攀猀琀䈀愀挀欀甀瀀 㴀 䴀䄀堀⠀戀愀挀欀甀瀀开昀椀渀椀猀栀开搀愀琀攀⤀ഀഀ
    FROM msdb.dbo.backupset਍    圀䠀䔀刀䔀 嬀琀礀瀀攀崀 䤀一⠀✀䐀✀Ⰰ✀䤀✀⤀ഀഀ
    AND database_name = @CurrentDatabase਍ഀഀ
    -- Set database message਍    匀䔀吀 䀀䐀愀琀愀戀愀猀攀䴀攀猀猀愀最攀 㴀 ✀䐀愀琀攀吀椀洀攀㨀 ✀ ⬀ 䌀伀一嘀䔀刀吀⠀渀瘀愀爀挀栀愀爀Ⰰ䜀䔀吀䐀䄀吀䔀⠀⤀Ⰰ㄀㈀　⤀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
    SET @DatabaseMessage = @DatabaseMessage + 'Database: ' + QUOTENAME(@CurrentDatabase) + CHAR(13) + CHAR(10)਍    匀䔀吀 䀀䐀愀琀愀戀愀猀攀䴀攀猀猀愀最攀 㴀 䀀䐀愀琀愀戀愀猀攀䴀攀猀猀愀最攀 ⬀ ✀匀琀愀琀甀猀㨀 ✀ ⬀ 䌀䄀匀吀⠀䐀䄀吀䄀䈀䄀匀䔀倀刀伀倀䔀刀吀夀䔀堀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀Ⰰ✀匀琀愀琀甀猀✀⤀ 䄀匀 渀瘀愀爀挀栀愀爀⤀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
    SET @DatabaseMessage = @DatabaseMessage + 'Mirroring role: ' + ISNULL(@CurrentMirroringRole,'None') + CHAR(13) + CHAR(10)਍    匀䔀吀 䀀䐀愀琀愀戀愀猀攀䴀攀猀猀愀最攀 㴀 䀀䐀愀琀愀戀愀猀攀䴀攀猀猀愀最攀 ⬀ ✀匀琀愀渀搀戀礀㨀 ✀ ⬀ 䌀䄀匀䔀 圀䠀䔀一 䐀䄀吀䄀䈀䄀匀䔀倀刀伀倀䔀刀吀夀䔀堀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀Ⰰ✀䤀猀䤀渀匀琀愀渀搀䈀礀✀⤀ 㴀 ㄀ 吀䠀䔀一 ✀夀攀猀✀ 䔀䰀匀䔀 ✀一漀✀ 䔀一䐀 ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
    SET @DatabaseMessage = @DatabaseMessage + 'Updateability: ' + CAST(DATABASEPROPERTYEX(@CurrentDatabase,'Updateability') AS nvarchar) + CHAR(13) + CHAR(10)਍    匀䔀吀 䀀䐀愀琀愀戀愀猀攀䴀攀猀猀愀最攀 㴀 䀀䐀愀琀愀戀愀猀攀䴀攀猀猀愀最攀 ⬀ ✀唀猀攀爀 愀挀挀攀猀猀㨀 ✀ ⬀ 䌀䄀匀吀⠀䐀䄀吀䄀䈀䄀匀䔀倀刀伀倀䔀刀吀夀䔀堀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀Ⰰ✀唀猀攀爀䄀挀挀攀猀猀✀⤀ 䄀匀 渀瘀愀爀挀栀愀爀⤀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
    SET @DatabaseMessage = @DatabaseMessage + 'Is accessible: ' + CASE WHEN @CurrentIsDatabaseAccessible = 1 THEN 'Yes' ELSE 'No' END + CHAR(13) + CHAR(10)਍    匀䔀吀 䀀䐀愀琀愀戀愀猀攀䴀攀猀猀愀最攀 㴀 䀀䐀愀琀愀戀愀猀攀䴀攀猀猀愀最攀 ⬀ ✀刀攀挀漀瘀攀爀礀 洀漀搀攀氀㨀 ✀ ⬀ 䌀䄀匀吀⠀䐀䄀吀䄀䈀䄀匀䔀倀刀伀倀䔀刀吀夀䔀堀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀Ⰰ✀刀攀挀漀瘀攀爀礀✀⤀ 䄀匀 渀瘀愀爀挀栀愀爀⤀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
    SET @DatabaseMessage = @DatabaseMessage + 'Differential base LSN: ' + ISNULL(CAST(@CurrentDifferentialLSN AS nvarchar),'NULL') + CHAR(13) + CHAR(10)਍    匀䔀吀 䀀䐀愀琀愀戀愀猀攀䴀攀猀猀愀最攀 㴀 䀀䐀愀琀愀戀愀猀攀䴀攀猀猀愀最攀 ⬀ ✀䰀愀猀琀 氀漀最 戀愀挀欀甀瀀 䰀匀一㨀 ✀ ⬀ 䤀匀一唀䰀䰀⠀䌀䄀匀吀⠀䀀䌀甀爀爀攀渀琀䰀漀最䰀匀一 䄀匀 渀瘀愀爀挀栀愀爀⤀Ⰰ✀一唀䰀䰀✀⤀ ⬀ 䌀䠀䄀刀⠀㄀㌀⤀ ⬀ 䌀䠀䄀刀⠀㄀　⤀ഀഀ
    SET @DatabaseMessage = REPLACE(@DatabaseMessage,'%','%%')਍    刀䄀䤀匀䔀刀刀伀刀⠀䀀䐀愀琀愀戀愀猀攀䴀攀猀猀愀最攀Ⰰ㄀　Ⰰ㄀⤀ 圀䤀吀䠀 一伀圀䄀䤀吀ഀഀ
਍    䤀䘀 䐀䄀吀䄀䈀䄀匀䔀倀刀伀倀䔀刀吀夀䔀堀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀Ⰰ✀匀琀愀琀甀猀✀⤀ 㴀 ✀伀一䰀䤀一䔀✀ഀഀ
    AND NOT (DATABASEPROPERTYEX(@CurrentDatabase,'UserAccess') = 'SINGLE_USER' AND @CurrentIsDatabaseAccessible = 0)਍    䄀一䐀 䐀䄀吀䄀䈀䄀匀䔀倀刀伀倀䔀刀吀夀䔀堀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀Ⰰ✀䤀猀䤀渀匀琀愀渀搀䈀礀✀⤀ 㴀 　ഀഀ
    AND NOT (@CurrentBackupType = 'LOG' AND (DATABASEPROPERTYEX(@CurrentDatabase,'Recovery') = 'SIMPLE' OR @CurrentLogLSN IS NULL))਍    䄀一䐀 一伀吀 ⠀䀀䌀甀爀爀攀渀琀䈀愀挀欀甀瀀吀礀瀀攀 㴀 ✀䐀䤀䘀䘀✀ 䄀一䐀 䀀䌀甀爀爀攀渀琀䐀椀昀昀攀爀攀渀琀椀愀氀䰀匀一 䤀匀 一唀䰀䰀⤀ഀഀ
    AND NOT (@CurrentBackupType IN('DIFF','LOG') AND @CurrentDatabase = 'master')਍    䈀䔀䜀䤀一ഀഀ
਍      ⴀⴀ 匀攀琀 瘀愀爀椀愀戀氀攀猀ഀഀ
      SET @CurrentDate = GETDATE()਍ഀഀ
      IF @CleanupTime IS NULL OR (@CurrentBackupType = 'LOG' AND @CurrentLatestBackup IS NULL)਍      䈀䔀䜀䤀一ഀഀ
        SET @CurrentCleanupDate = NULL਍      䔀一䐀ഀഀ
      ELSE਍      䤀䘀 䀀䌀甀爀爀攀渀琀䈀愀挀欀甀瀀吀礀瀀攀 㴀 ✀䰀伀䜀✀ഀഀ
      BEGIN਍        匀䔀吀 䀀䌀甀爀爀攀渀琀䌀氀攀愀渀甀瀀䐀愀琀攀 㴀 ⠀匀䔀䰀䔀䌀吀 䴀䤀一⠀嬀䐀愀琀攀崀⤀ 䘀刀伀䴀⠀匀䔀䰀䔀䌀吀 䐀䄀吀䔀䄀䐀䐀⠀栀栀Ⰰⴀ⠀䀀䌀氀攀愀渀甀瀀吀椀洀攀⤀Ⰰ䀀䌀甀爀爀攀渀琀䐀愀琀攀⤀ 䄀匀 嬀䐀愀琀攀崀 唀一䤀伀一 匀䔀䰀䔀䌀吀 䀀䌀甀爀爀攀渀琀䰀愀琀攀猀琀䈀愀挀欀甀瀀 䄀匀 嬀䐀愀琀攀崀⤀ 䐀愀琀攀猀⤀ഀഀ
      END਍      䔀䰀匀䔀ഀഀ
      BEGIN਍        匀䔀吀 䀀䌀甀爀爀攀渀琀䌀氀攀愀渀甀瀀䐀愀琀攀 㴀 䐀䄀吀䔀䄀䐀䐀⠀栀栀Ⰰⴀ⠀䀀䌀氀攀愀渀甀瀀吀椀洀攀⤀Ⰰ䀀䌀甀爀爀攀渀琀䐀愀琀攀⤀ഀഀ
      END਍ഀഀ
      SET @CurrentDatabaseFS = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@CurrentDatabase,'\',''),'/',''),':',''),'*',''),'?',''),'"',''),'<',''),'>',''),'|',''),' ','')਍ഀഀ
      SELECT @CurrentFileExtension = CASE਍      圀䠀䔀一 䀀䌀甀爀爀攀渀琀䈀愀挀欀甀瀀吀礀瀀攀 㴀 ✀䘀唀䰀䰀✀ 吀䠀䔀一 ✀戀愀欀✀ഀഀ
      WHEN @CurrentBackupType = 'DIFF' THEN 'bak'਍      圀䠀䔀一 䀀䌀甀爀爀攀渀琀䈀愀挀欀甀瀀吀礀瀀攀 㴀 ✀䰀伀䜀✀ 吀䠀䔀一 ✀琀爀渀✀ഀഀ
      END਍ഀഀ
      SET @CurrentFileName = REPLACE(CAST(SERVERPROPERTY('servername') AS nvarchar),'\','$') + '_' + @CurrentDatabaseFS + '_' + UPPER(@CurrentBackupType) + '_' + REPLACE(REPLACE(REPLACE((CONVERT(nvarchar,@CurrentDate,120)),'-',''),' ','_'),':','') + '.' + @CurrentFileExtension਍ഀഀ
      SET @CurrentDirectory = @Directory + CASE WHEN RIGHT(@Directory,1) = '\' THEN '' ELSE '\' END + REPLACE(CAST(SERVERPROPERTY('servername') AS nvarchar),'\','$') + '\' + @CurrentDatabaseFS + '\' + UPPER(@CurrentBackupType)਍ഀഀ
      SET @CurrentFilePath = @CurrentDirectory + '\' + @CurrentFileName਍ഀഀ
      -- Create directory਍      匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㄀ 㴀 ✀䐀䔀䌀䰀䄀刀䔀 䀀刀攀琀甀爀渀䌀漀搀攀 椀渀琀 䔀堀䔀䌀唀吀䔀 䀀刀攀琀甀爀渀䌀漀搀攀 㴀 洀愀猀琀攀爀⸀搀戀漀⸀砀瀀开挀爀攀愀琀攀开猀甀戀搀椀爀 一✀✀✀ ⬀ 刀䔀倀䰀䄀䌀䔀⠀䀀䌀甀爀爀攀渀琀䐀椀爀攀挀琀漀爀礀Ⰰ✀✀✀✀Ⰰ✀✀✀✀✀✀⤀ ⬀ ✀✀✀ 䤀䘀 䀀刀攀琀甀爀渀䌀漀搀攀 㰀㸀 　 刀䄀䤀匀䔀刀刀伀刀⠀✀✀䔀爀爀漀爀 挀爀攀愀琀椀渀最 搀椀爀攀挀琀漀爀礀⸀✀✀Ⰰ ㄀㘀Ⰰ ㄀⤀✀ഀഀ
      EXECUTE @CurrentCommandOutput01 = [dbo].[CommandExecute] @CurrentCommand01, '', 1, @Execute਍      匀䔀吀 䀀䔀爀爀漀爀 㴀 䀀䀀䔀刀刀伀刀ഀഀ
      IF @Error <> 0 SET @CurrentCommandOutput01 = @Error਍ഀഀ
      -- Perform a backup਍      䤀䘀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀伀甀琀瀀甀琀　㄀ 㴀 　ഀഀ
      BEGIN਍        䤀䘀 䀀䈀愀挀欀甀瀀匀漀昀琀眀愀爀攀 䤀匀 一唀䰀䰀ഀഀ
        BEGIN਍          匀䔀䰀䔀䌀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㈀ 㴀 䌀䄀匀䔀ഀഀ
          WHEN @CurrentBackupType IN('DIFF','FULL') THEN 'BACKUP DATABASE ' + QUOTENAME(@CurrentDatabase) + ' TO DISK = N''' + REPLACE(@CurrentFilePath,'''','''''') + ''''਍          圀䠀䔀一 䀀䌀甀爀爀攀渀琀䈀愀挀欀甀瀀吀礀瀀攀 㴀 ✀䰀伀䜀✀ 吀䠀䔀一 ✀䈀䄀䌀䬀唀倀 䰀伀䜀 ✀ ⬀ 儀唀伀吀䔀一䄀䴀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀⤀ ⬀ ✀ 吀伀 䐀䤀匀䬀 㴀 一✀✀✀ ⬀ 刀䔀倀䰀䄀䌀䔀⠀䀀䌀甀爀爀攀渀琀䘀椀氀攀倀愀琀栀Ⰰ✀✀✀✀Ⰰ✀✀✀✀✀✀⤀ ⬀ ✀✀✀✀ഀഀ
          END਍          匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㈀ 㴀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㈀ ⬀ ✀ 圀䤀吀䠀 ✀ഀഀ
          IF @CheckSum = 'Y' SET @CurrentCommand02 = @CurrentCommand02 + 'CHECKSUM'਍          䤀䘀 䀀䌀栀攀挀欀匀甀洀 㴀 ✀一✀ 匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㈀ 㴀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㈀ ⬀ ✀一伀开䌀䠀䔀䌀䬀匀唀䴀✀ഀഀ
          IF @Compress = 'Y' SET @CurrentCommand02 = @CurrentCommand02 + ', COMPRESSION'਍          䤀䘀 䀀䌀漀洀瀀爀攀猀猀 㴀 ✀一✀ 䄀一䐀 䌀䄀匀吀⠀䰀䔀䘀吀⠀䌀䄀匀吀⠀匀䔀刀嘀䔀刀倀刀伀倀䔀刀吀夀⠀✀倀爀漀搀甀挀琀嘀攀爀猀椀漀渀✀⤀ 䄀匀 渀瘀愀爀挀栀愀爀⤀Ⰰ 䌀䠀䄀刀䤀一䐀䔀堀⠀✀⸀✀Ⰰ䌀䄀匀吀⠀匀䔀刀嘀䔀刀倀刀伀倀䔀刀吀夀⠀✀倀爀漀搀甀挀琀嘀攀爀猀椀漀渀✀⤀ 䄀匀 渀瘀愀爀挀栀愀爀⤀⤀ ⴀ ㄀⤀ 䄀匀 椀渀琀⤀ 㸀㴀 ㄀　 匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㈀ 㴀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㈀ ⬀ ✀Ⰰ 一伀开䌀伀䴀倀刀䔀匀匀䤀伀一✀ഀഀ
          IF @CurrentBackupType = 'DIFF' SET @CurrentCommand02 = @CurrentCommand02 + ', DIFFERENTIAL'਍          䤀䘀 䀀䌀漀瀀礀伀渀氀礀 㴀 ✀夀✀ 匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㈀ 㴀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㈀ ⬀ ✀Ⰰ 䌀伀倀夀开伀一䰀夀✀ഀഀ
        END਍ഀഀ
        IF @BackupSoftware = 'LITESPEED'਍        䈀䔀䜀䤀一ഀഀ
          SELECT @CurrentCommand02 = CASE਍          圀䠀䔀一 䀀䌀甀爀爀攀渀琀䈀愀挀欀甀瀀吀礀瀀攀 䤀一⠀✀䐀䤀䘀䘀✀Ⰰ✀䘀唀䰀䰀✀⤀ 吀䠀䔀一 ✀䐀䔀䌀䰀䄀刀䔀 䀀刀攀琀甀爀渀䌀漀搀攀 椀渀琀 䔀堀䔀䌀唀吀䔀 䀀刀攀琀甀爀渀䌀漀搀攀 㴀 洀愀猀琀攀爀⸀搀戀漀⸀砀瀀开戀愀挀欀甀瀀开搀愀琀愀戀愀猀攀 䀀搀愀琀愀戀愀猀攀 㴀 一✀✀✀ ⬀ 刀䔀倀䰀䄀䌀䔀⠀䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀Ⰰ✀✀✀✀Ⰰ✀✀✀✀✀✀⤀ ⬀ ✀✀✀Ⰰ 䀀昀椀氀攀渀愀洀攀 㴀 一✀✀✀ ⬀ 刀䔀倀䰀䄀䌀䔀⠀䀀䌀甀爀爀攀渀琀䘀椀氀攀倀愀琀栀Ⰰ✀✀✀✀Ⰰ✀✀✀✀✀✀⤀ ⬀ ✀✀✀✀ഀഀ
          WHEN @CurrentBackupType = 'LOG' THEN 'DECLARE @ReturnCode int EXECUTE @ReturnCode = master.dbo.xp_backup_log @database = N''' + REPLACE(@CurrentDatabase,'''','''''') + ''', @filename = N''' + REPLACE(@CurrentFilePath,'''','''''') + ''''਍          䔀一䐀ഀഀ
          SET @CurrentCommand02 = @CurrentCommand02 + ', @with = '''਍          䤀䘀 䀀䌀栀攀挀欀匀甀洀 㴀 ✀夀✀ 匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㈀ 㴀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㈀ ⬀ ✀䌀䠀䔀䌀䬀匀唀䴀✀ഀഀ
          IF @CheckSum = 'N' SET @CurrentCommand02 = @CurrentCommand02 + 'NO_CHECKSUM'਍          䤀䘀 䀀䌀甀爀爀攀渀琀䈀愀挀欀甀瀀吀礀瀀攀 㴀 ✀䐀䤀䘀䘀✀ 匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㈀ 㴀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㈀ ⬀ ✀Ⰰ 䐀䤀䘀䘀䔀刀䔀一吀䤀䄀䰀✀ഀഀ
          IF @CopyOnly = 'Y' SET @CurrentCommand02 = @CurrentCommand02 + ', COPY_ONLY'਍          匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㈀ 㴀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㈀ ⬀ ✀✀✀ 䤀䘀 䀀刀攀琀甀爀渀䌀漀搀攀 㰀㸀 　 刀䄀䤀匀䔀刀刀伀刀⠀✀✀䔀爀爀漀爀 瀀攀爀昀漀爀洀椀渀最 䰀椀琀攀匀瀀攀攀搀 戀愀挀欀甀瀀⸀✀✀Ⰰ ㄀㘀Ⰰ ㄀⤀✀ഀഀ
        END਍ഀഀ
        EXECUTE @CurrentCommandOutput02 = [dbo].[CommandExecute] @CurrentCommand02, '', 1, @Execute਍        匀䔀吀 䀀䔀爀爀漀爀 㴀 䀀䀀䔀刀刀伀刀ഀഀ
        IF @Error <> 0 SET @CurrentCommandOutput02 = @Error਍      䔀一䐀ഀഀ
਍      ⴀⴀ 嘀攀爀椀昀礀 琀栀攀 戀愀挀欀甀瀀ഀഀ
      IF @CurrentCommandOutput02 = 0 AND @Verify = 'Y'਍      䈀䔀䜀䤀一ഀഀ
        IF @BackupSoftware IS NULL਍        䈀䔀䜀䤀一ഀഀ
          SET @CurrentCommand03 = 'RESTORE VERIFYONLY FROM DISK = ''' + REPLACE(@CurrentFilePath,'''','''''') + ''''਍        䔀一䐀ഀഀ
਍        䤀䘀 䀀䈀愀挀欀甀瀀匀漀昀琀眀愀爀攀 㴀 ✀䰀䤀吀䔀匀倀䔀䔀䐀✀ഀഀ
        BEGIN਍          匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㌀ 㴀 ✀䐀䔀䌀䰀䄀刀䔀 䀀刀攀琀甀爀渀䌀漀搀攀 椀渀琀 䔀堀䔀䌀唀吀䔀 䀀刀攀琀甀爀渀䌀漀搀攀 㴀 洀愀猀琀攀爀⸀搀戀漀⸀砀瀀开爀攀猀琀漀爀攀开瘀攀爀椀昀礀漀渀氀礀 䀀昀椀氀攀渀愀洀攀 㴀 一✀✀✀ ⬀ 刀䔀倀䰀䄀䌀䔀⠀䀀䌀甀爀爀攀渀琀䘀椀氀攀倀愀琀栀Ⰰ✀✀✀✀Ⰰ✀✀✀✀✀✀⤀ ⬀ ✀✀✀ 䤀䘀 䀀刀攀琀甀爀渀䌀漀搀攀 㰀㸀 　 刀䄀䤀匀䔀刀刀伀刀⠀✀✀䔀爀爀漀爀 瘀攀爀椀昀礀椀渀最 䰀椀琀攀匀瀀攀攀搀 戀愀挀欀甀瀀⸀✀✀Ⰰ ㄀㘀Ⰰ ㄀⤀✀ഀഀ
        END਍ഀഀ
        EXECUTE @CurrentCommandOutput03 = [dbo].[CommandExecute] @CurrentCommand03, '', 1, @Execute਍        匀䔀吀 䀀䔀爀爀漀爀 㴀 䀀䀀䔀刀刀伀刀ഀഀ
        IF @Error <> 0 SET @CurrentCommandOutput03 = @Error਍      䔀一䐀ഀഀ
਍      ⴀⴀ 䐀攀氀攀琀攀 漀氀搀 戀愀挀欀甀瀀 昀椀氀攀猀ഀഀ
      IF (@CurrentCommandOutput02 = 0 AND @Verify = 'N' AND @CurrentCleanupDate IS NOT NULL)਍      伀刀 ⠀䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀伀甀琀瀀甀琀　㈀ 㴀 　 䄀一䐀 䀀嘀攀爀椀昀礀 㴀 ✀夀✀ 䄀一䐀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀伀甀琀瀀甀琀　㌀ 㴀 　 䄀一䐀 䀀䌀甀爀爀攀渀琀䌀氀攀愀渀甀瀀䐀愀琀攀 䤀匀 一伀吀 一唀䰀䰀⤀ഀഀ
      BEGIN਍        䤀䘀 䀀䈀愀挀欀甀瀀匀漀昀琀眀愀爀攀 䤀匀 一唀䰀䰀ഀഀ
        BEGIN਍          匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㐀 㴀 ✀䐀䔀䌀䰀䄀刀䔀 䀀刀攀琀甀爀渀䌀漀搀攀 椀渀琀 䔀堀䔀䌀唀吀䔀 䀀刀攀琀甀爀渀䌀漀搀攀 㴀 洀愀猀琀攀爀⸀搀戀漀⸀砀瀀开搀攀氀攀琀攀开昀椀氀攀 　Ⰰ 一✀✀✀ ⬀ 刀䔀倀䰀䄀䌀䔀⠀䀀䌀甀爀爀攀渀琀䐀椀爀攀挀琀漀爀礀Ⰰ✀✀✀✀Ⰰ✀✀✀✀✀✀⤀ ⬀ ✀✀✀Ⰰ ✀✀✀ ⬀ 䀀䌀甀爀爀攀渀琀䘀椀氀攀䔀砀琀攀渀猀椀漀渀 ⬀ ✀✀✀Ⰰ ✀✀✀ ⬀ 䌀伀一嘀䔀刀吀⠀渀瘀愀爀挀栀愀爀⠀㄀㤀⤀Ⰰ䀀䌀甀爀爀攀渀琀䌀氀攀愀渀甀瀀䐀愀琀攀Ⰰ㄀㈀㘀⤀ ⬀ ✀✀✀ 䤀䘀 䀀刀攀琀甀爀渀䌀漀搀攀 㰀㸀 　 刀䄀䤀匀䔀刀刀伀刀⠀✀✀䔀爀爀漀爀 搀攀氀攀琀椀渀最 昀椀氀攀猀⸀✀✀Ⰰ ㄀㘀Ⰰ ㄀⤀✀ഀഀ
        END਍ഀഀ
        IF @BackupSoftware = 'LITESPEED'਍        䈀䔀䜀䤀一ഀഀ
          SET @CurrentCommand04 = 'DECLARE @ReturnCode int EXECUTE @ReturnCode = master.dbo.xp_slssqlmaint N''-MAINTDEL -DELFOLDER "' + REPLACE(@CurrentDirectory,'''','''''') + '" -DELEXTENSION "' + @CurrentFileExtension + '" -DELUNIT "' + CAST(DATEDIFF(mi,@CurrentCleanupDate,GETDATE()) + 1 AS nvarchar) + '" -DELUNITTYPE "minutes" -DELUSEAGE'' IF @ReturnCode <> 0 RAISERROR(''Error deleting LiteSpeed backup files.'', 16, 1)'਍        䔀一䐀ഀഀ
਍        䔀堀䔀䌀唀吀䔀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀伀甀琀瀀甀琀　㐀 㴀 嬀搀戀漀崀⸀嬀䌀漀洀洀愀渀搀䔀砀攀挀甀琀攀崀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㐀Ⰰ ✀✀Ⰰ ㄀Ⰰ 䀀䔀砀攀挀甀琀攀ഀഀ
        SET @Error = @@ERROR਍        䤀䘀 䀀䔀爀爀漀爀 㰀㸀 　 匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀伀甀琀瀀甀琀　㐀 㴀 䀀䔀爀爀漀爀ഀഀ
      END਍ഀഀ
    END਍ഀഀ
    -- Update that the database is completed਍    唀倀䐀䄀吀䔀 䀀琀洀瀀䐀愀琀愀戀愀猀攀猀ഀഀ
    SET Completed = 1਍    圀䠀䔀刀䔀 䤀䐀 㴀 䀀䌀甀爀爀攀渀琀䤀䐀ഀഀ
਍    ⴀⴀ 䌀氀攀愀爀 瘀愀爀椀愀戀氀攀猀ഀഀ
    SET @CurrentID = NULL਍    匀䔀吀 䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀 㴀 一唀䰀䰀ഀഀ
    SET @CurrentBackupType = NULL਍    匀䔀吀 䀀䌀甀爀爀攀渀琀䘀椀氀攀䔀砀琀攀渀猀椀漀渀 㴀 一唀䰀䰀ഀഀ
    SET @CurrentDifferentialLSN = NULL਍    匀䔀吀 䀀䌀甀爀爀攀渀琀䰀漀最䰀匀一 㴀 一唀䰀䰀ഀഀ
    SET @CurrentLatestBackup = NULL਍    匀䔀吀 䀀䌀甀爀爀攀渀琀䐀愀琀愀戀愀猀攀䘀匀 㴀 一唀䰀䰀ഀഀ
    SET @CurrentDirectory = NULL਍    匀䔀吀 䀀䌀甀爀爀攀渀琀䐀愀琀攀 㴀 一唀䰀䰀ഀഀ
    SET @CurrentFileName = NULL਍    匀䔀吀 䀀䌀甀爀爀攀渀琀䘀椀氀攀倀愀琀栀 㴀 一唀䰀䰀ഀഀ
    SET @CurrentCleanupDate = NULL਍    匀䔀吀 䀀䌀甀爀爀攀渀琀䤀猀䐀愀琀愀戀愀猀攀䄀挀挀攀猀猀椀戀氀攀 㴀 一唀䰀䰀ഀഀ
    SET @CurrentMirroringRole = NULL਍ഀഀ
    SET @CurrentCommand01 = NULL਍    匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㈀ 㴀 一唀䰀䰀ഀഀ
    SET @CurrentCommand03 = NULL਍    匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀　㐀 㴀 一唀䰀䰀ഀഀ
਍    匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀伀甀琀瀀甀琀　㄀ 㴀 一唀䰀䰀ഀഀ
    SET @CurrentCommandOutput02 = NULL਍    匀䔀吀 䀀䌀甀爀爀攀渀琀䌀漀洀洀愀渀搀伀甀琀瀀甀琀　㌀ 㴀 一唀䰀䰀ഀഀ
    SET @CurrentCommandOutput04 = NULL਍ഀഀ
  END਍ഀഀ
  ----------------------------------------------------------------------------------------------------਍  ⴀⴀ⼀⼀ 䰀漀最 挀漀洀瀀氀攀琀椀渀最 椀渀昀漀爀洀愀琀椀漀渀                                                                 ⼀⼀ⴀⴀഀഀ
  ----------------------------------------------------------------------------------------------------਍ഀഀ
  Logging:਍  匀䔀吀 䀀䔀渀搀䴀攀猀猀愀最攀 㴀 ✀䐀愀琀攀吀椀洀攀㨀 ✀ ⬀ 䌀伀一嘀䔀刀吀⠀渀瘀愀爀挀栀愀爀Ⰰ䜀䔀吀䐀䄀吀䔀⠀⤀Ⰰ㄀㈀　⤀ഀഀ
  SET @EndMessage = REPLACE(@EndMessage,'%','%%')਍  刀䄀䤀匀䔀刀刀伀刀⠀䀀䔀渀搀䴀攀猀猀愀最攀Ⰰ㄀　Ⰰ㄀⤀ 圀䤀吀䠀 一伀圀䄀䤀吀ഀഀ
਍  ⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀഀഀ
਍䔀一䐀ഀഀ
GO਍�