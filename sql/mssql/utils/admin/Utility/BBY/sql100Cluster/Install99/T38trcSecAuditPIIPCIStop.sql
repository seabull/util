/******************************************************************************/਍⼀⨀ 䰀椀猀琀 愀氀氀 琀爀愀挀攀 焀甀攀甀攀猀 爀甀渀渀椀渀最 漀渀 匀儀䰀 㤀 猀攀爀瘀攀爀                              ⨀⼀ഀഀ
/* BEST BUY CO, INC.           */਍⼀⨀ 䌀爀攀愀琀攀✀猀 吀㌀㠀琀爀挀匀攀挀䄀甀搀椀琀匀琀漀瀀 䨀漀戀 椀渀 匀儀䰀 匀攀爀瘀攀爀 ㈀　　㔀 匀琀漀爀攀 匀攀爀瘀攀爀猀⸀ 圀漀爀欀✀猀 ⨀⼀ഀഀ
/*   with T38trace.pl Ver:1.9 and above only and CFG T38trcSecAudit.cfg ver:Revision: 1.2*/਍⼀⨀ⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀ⨀⼀ഀഀ
/* Created September 10, 2007 by CHANDRA CHATURVEDI (A819143)                              */਍⼀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⼀ ഀഀ
਍⼀⨀ ␀䄀甀琀栀漀爀㨀     ␀ഀഀ
** $Archive:   $਍⨀⨀ ␀䐀愀琀攀㨀 ␀ഀഀ
** $Revision:   $਍⨀⨀⼀ഀഀ
਍唀匀䔀 嬀洀猀搀戀崀ഀഀ
GO਍ഀഀ
/****** Object:  Job T38trcSecAuditPIIPCIStop    Script Date: 09/16/2007 20:31:24 ******/਍䤀䘀  䔀堀䤀匀吀匀 ⠀匀䔀䰀䔀䌀吀 樀漀戀开椀搀 䘀刀伀䴀 洀猀搀戀⸀搀戀漀⸀猀礀猀樀漀戀猀开瘀椀攀眀 圀䠀䔀刀䔀 渀愀洀攀 㴀 一✀吀㌀㠀琀爀挀匀攀挀䄀甀搀椀琀倀䤀䤀倀䌀䤀匀琀漀瀀✀⤀ഀഀ
EXEC msdb.dbo.sp_delete_job @job_name=N'T38trcSecAuditPIIPCIStop', @delete_unused_schedule=1਍ഀഀ
/****** Object:  Job T38trcSecAuditPIIPCIStop    Script Date: 09/16/2007 20:31:32 ******/਍䈀䔀䜀䤀一 吀刀䄀一匀䄀䌀吀䤀伀一ഀഀ
਍搀攀挀氀愀爀攀 䀀䄀瀀瀀䐀椀爀攀挀琀漀爀礀 瘀愀爀挀栀愀爀⠀㄀㈀㠀⤀ഀഀ
declare @InstanceName varchar(128)਍搀攀挀氀愀爀攀 䀀匀琀漀瀀䌀漀洀洀愀渀搀 瘀愀爀挀栀愀爀⠀㄀　㈀㐀⤀ഀഀ
set @InstanceName = cast(serverproperty('InstanceName') as varchar(128))਍ഀഀ
਍ⴀⴀ 搀攀琀攀爀洀椀渀攀 琀栀攀 搀椀爀攀挀琀漀爀礀 渀愀洀攀ഀഀ
if serverproperty('IsClustered')= 1਍ऀ戀攀最椀渀ഀഀ
		print 'clustered'਍ऀऀ猀攀琀 䀀䄀瀀瀀䐀椀爀攀挀琀漀爀礀 㴀 ഀഀ
			'\\'਍ऀऀऀ⬀ 挀愀猀琀 ⠀猀攀爀瘀攀爀瀀爀漀瀀攀爀琀礀⠀✀䴀愀挀栀椀渀攀一愀洀攀✀⤀ 愀猀 瘀愀爀挀栀愀爀⠀㄀㈀㠀⤀⤀ഀഀ
			+ '\t38app80.' ਍ऀऀऀ⬀ 挀愀猀琀 ⠀猀攀爀瘀攀爀瀀爀漀瀀攀爀琀礀⠀✀䴀愀挀栀椀渀攀一愀洀攀✀⤀ 愀猀 瘀愀爀挀栀愀爀⠀㄀㈀㠀⤀⤀ഀഀ
			+ '\'਍ ऀऀऀ⬀ 䀀䤀渀猀琀愀渀挀攀一愀洀攀ഀഀ
	end਍攀氀猀攀 椀昀 ⠀猀攀氀攀挀琀 猀攀爀瘀攀爀瀀爀漀瀀攀爀琀礀⠀✀䤀渀猀琀愀渀挀攀一愀洀攀✀⤀⤀ 椀猀 渀漀琀 一唀䰀䰀 ഀഀ
	begin਍ऀऀ瀀爀椀渀琀 ✀椀渀猀琀愀渀挀攀✀ഀഀ
		set @AppDirectory = ਍ऀऀऀ✀尀尀✀ഀഀ
			+ cast (serverproperty('MachineName') as varchar(128))਍ऀऀऀ⬀ ✀尀琀㌀㠀愀瀀瀀㠀　尀✀ ഀഀ
 			+ cast (serverproperty('InstanceName') as varchar(128))਍ऀ攀渀搀ഀഀ
else ਍ऀ戀攀最椀渀ഀഀ
		print 'normal'਍ऀऀ猀攀琀 䀀䄀瀀瀀䐀椀爀攀挀琀漀爀礀 㴀 ഀഀ
			'\\'਍ऀऀऀ⬀ 挀愀猀琀 ⠀猀攀爀瘀攀爀瀀爀漀瀀攀爀琀礀⠀✀䴀愀挀栀椀渀攀一愀洀攀✀⤀ 愀猀 瘀愀爀挀栀愀爀⠀㄀㈀㠀⤀⤀ഀഀ
			+ '\t38app80' ਍ऀ攀渀搀ഀഀ
਍ⴀⴀ 猀攀琀 琀爀愀挀攀 挀漀渀昀椀最 昀椀氀攀 戀愀猀攀搀 漀渀 琀栀攀 瘀攀爀猀椀漀渀 漀昀 匀儀䰀 匀攀爀瘀攀爀ഀഀ
declare @ConfigFile varchar(64)਍椀昀 ⠀猀攀氀攀挀琀 氀攀昀琀⠀挀愀猀琀⠀猀攀爀瘀攀爀瀀爀漀瀀攀爀琀礀⠀✀瀀爀漀搀甀挀琀瘀攀爀猀椀漀渀✀⤀ 愀猀 瘀愀爀挀栀愀爀⤀Ⰰ㐀⤀⤀ 㴀 ✀㠀⸀　　✀ഀഀ
	begin਍ऀऀ猀攀琀 䀀䌀漀渀昀椀最䘀椀氀攀 㴀 ✀琀㌀㠀琀爀挀匀攀挀䄀甀搀椀琀倀䤀䤀倀䌀䤀㈀　　　✀ഀഀ
	end਍攀氀猀攀ഀഀ
	begin਍ऀऀ猀攀琀 䀀䌀漀渀昀椀最䘀椀氀攀 㴀 ✀琀㌀㠀琀爀挀匀攀挀䄀甀搀椀琀倀䤀䤀倀䌀䤀✀ഀഀ
	end਍ഀഀ
if @InstanceName is null਍戀攀最椀渀ഀഀ
	set @StopCommand = 'cmd /C perl ' + isnull(@AppDirectory,'') + '\t38trace.pl -x x -S . -d collector2 ' + isnull(@AppDirectory,'') + '\' + isnull(@ConfigFile,'') + '.cfg'਍攀渀搀ഀഀ
else਍戀攀最椀渀ഀഀ
	set @StopCommand = 'cmd /C perl ' + isnull(@AppDirectory,'') + '\t38trace.pl -x x -S .\' + isnull(@InstanceName,'') + ' -d collector2 ' + isnull(@AppDirectory,'') + '\' + isnull(@ConfigFile, '') + '.cfg'਍攀渀搀ഀഀ
਍瀀爀椀渀琀 䀀匀琀漀瀀䌀漀洀洀愀渀搀ഀഀ
਍䐀䔀䌀䰀䄀刀䔀 䀀刀攀琀甀爀渀䌀漀搀攀 䤀一吀ഀഀ
SELECT @ReturnCode = 0਍⼀⨀⨀⨀⨀⨀⨀ 伀戀樀攀挀琀㨀  䨀漀戀䌀愀琀攀最漀爀礀 嬀䐀愀琀愀戀愀猀攀 䴀愀椀渀琀攀渀愀渀挀攀崀    匀挀爀椀瀀琀 䐀愀琀攀㨀 　㤀⼀㄀㘀⼀㈀　　㜀 ㈀　㨀㌀㄀㨀㌀㈀ ⨀⨀⨀⨀⨀⨀⼀ഀഀ
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)਍䈀䔀䜀䤀一ഀഀ
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'਍䤀䘀 ⠀䀀䀀䔀刀刀伀刀 㰀㸀 　 伀刀 䀀刀攀琀甀爀渀䌀漀搀攀 㰀㸀 　⤀ 䜀伀吀伀 儀甀椀琀圀椀琀栀刀漀氀氀戀愀挀欀ഀഀ
਍䔀一䐀ഀഀ
਍䐀䔀䌀䰀䄀刀䔀 䀀樀漀戀䤀搀 䈀䤀一䄀刀夀⠀㄀㘀⤀ഀഀ
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'T38trcSecAuditPIIPCIStop', ਍ऀऀ䀀攀渀愀戀氀攀搀㴀㄀Ⰰ ഀഀ
		@notify_level_eventlog=2, ਍ऀऀ䀀渀漀琀椀昀礀开氀攀瘀攀氀开攀洀愀椀氀㴀　Ⰰ ഀഀ
		@notify_level_netsend=0, ਍ऀऀ䀀渀漀琀椀昀礀开氀攀瘀攀氀开瀀愀最攀㴀　Ⰰ ഀഀ
		@delete_level=0, ਍ऀऀ䀀搀攀猀挀爀椀瀀琀椀漀渀㴀一✀匀琀愀爀琀 搀攀琀愀椀氀攀搀 匀儀䰀 㠀 琀爀愀挀攀⸀ ⴀ搀 漀瀀琀椀漀渀⠀爀攀瘀椀攀眀 瘀攀爀猀椀漀渀⤀ ␀刀攀瘀椀猀椀漀渀㨀   ㄀⸀㠀  ␀Ⰰ ␀圀漀爀欀昀椀氀攀㨀   吀㌀㠀琀爀挀匀攀挀䄀甀搀椀琀倀䤀䤀倀䌀䤀匀琀漀瀀⸀猀焀氀  ␀吀栀椀猀 猀琀漀瀀 猀挀爀椀瀀琀 椀猀 昀漀爀 匀吀伀刀䔀 匀儀䰀 匀攀爀瘀攀爀 ㈀　　㔀 匀攀爀瘀攀爀猀 漀渀氀礀⸀✀Ⰰ ഀഀ
		@category_name=N'Database Maintenance', ਍ऀऀ䀀漀眀渀攀爀开氀漀最椀渀开渀愀洀攀㴀一✀猀愀✀Ⰰ 䀀樀漀戀开椀搀 㴀 䀀樀漀戀䤀搀 伀唀吀倀唀吀ഀഀ
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback਍⼀⨀⨀⨀⨀⨀⨀ 伀戀樀攀挀琀㨀  匀琀攀瀀 嬀吀㌀㠀琀爀挀匀攀挀䄀甀搀椀琀匀琀漀瀀崀    匀挀爀椀瀀琀 䐀愀琀攀㨀 　㤀⼀㄀㘀⼀㈀　　㜀 ㈀　㨀㌀㄀㨀㌀㈀ ⨀⨀⨀⨀⨀⨀⼀ഀഀ
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'T38trcSecAuditPIIPCIStop', ਍ऀऀ䀀猀琀攀瀀开椀搀㴀㄀Ⰰ ഀഀ
		@cmdexec_success_code=0, ਍ऀऀ䀀漀渀开猀甀挀挀攀猀猀开愀挀琀椀漀渀㴀㄀Ⰰ ഀഀ
		@on_success_step_id=0, ਍ऀऀ䀀漀渀开昀愀椀氀开愀挀琀椀漀渀㴀㈀Ⰰ ഀഀ
		@on_fail_step_id=0, ਍ऀऀ䀀爀攀琀爀礀开愀琀琀攀洀瀀琀猀㴀　Ⰰ ഀഀ
		@retry_interval=1, ਍ऀऀ䀀漀猀开爀甀渀开瀀爀椀漀爀椀琀礀㴀　Ⰰ 䀀猀甀戀猀礀猀琀攀洀㴀一✀䌀洀搀䔀砀攀挀✀Ⰰ ഀഀ
		@command=@StopCommand, ਍ऀऀ䀀昀氀愀最猀㴀　ഀഀ
Print 'Job ''T38trcSecAuditPIIPCIStop'' Created successfully'਍ഀഀ
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback਍䔀堀䔀䌀 䀀刀攀琀甀爀渀䌀漀搀攀 㴀 洀猀搀戀⸀搀戀漀⸀猀瀀开甀瀀搀愀琀攀开樀漀戀 䀀樀漀戀开椀搀 㴀 䀀樀漀戀䤀搀Ⰰ 䀀猀琀愀爀琀开猀琀攀瀀开椀搀 㴀 ㄀ഀഀ
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback਍䔀堀䔀䌀 䀀刀攀琀甀爀渀䌀漀搀攀 㴀 洀猀搀戀⸀搀戀漀⸀猀瀀开愀搀搀开樀漀戀猀攀爀瘀攀爀 䀀樀漀戀开椀搀 㴀 䀀樀漀戀䤀搀Ⰰ 䀀猀攀爀瘀攀爀开渀愀洀攀 㴀 一✀⠀氀漀挀愀氀⤀✀ഀഀ
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback਍䌀伀䴀䴀䤀吀 吀刀䄀一匀䄀䌀吀䤀伀一ഀഀ
GOTO EndSave਍儀甀椀琀圀椀琀栀刀漀氀氀戀愀挀欀㨀ഀഀ
	IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION਍䔀渀搀匀愀瘀攀㨀ഀഀ
਍�