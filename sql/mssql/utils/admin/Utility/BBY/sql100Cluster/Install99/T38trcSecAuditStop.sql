/******************************************************************************/਍⼀⨀ 䰀椀猀琀 愀氀氀 琀爀愀挀攀 焀甀攀甀攀猀 爀甀渀渀椀渀最 漀渀 匀儀䰀 㤀 猀攀爀瘀攀爀                              ⨀⼀ഀഀ
/* BEST BUY CO, INC.           */਍⼀⨀ 䌀爀攀愀琀攀✀猀 吀㌀㠀琀爀挀匀攀挀䄀甀搀椀琀匀琀漀瀀 䨀漀戀 椀渀 匀儀䰀 匀攀爀瘀攀爀 ㈀　　㔀 匀琀漀爀攀 匀攀爀瘀攀爀猀⸀ 圀漀爀欀✀猀 ⨀⼀ഀഀ
/*   with T38trace.pl Ver:1.9 and above only and CFG T38trcSecAudit.cfg ver:Revision: 1.2*/਍⼀⨀ⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀ⨀⼀ഀഀ
/* Created September 10, 2007 by CHANDRA CHATURVEDI (A819143)                              */਍⼀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⼀ ഀഀ
਍⼀⨀ ␀䄀甀琀栀漀爀㨀     ␀ഀഀ
** $Archive:   $਍⨀⨀ ␀䐀愀琀攀㨀 ␀ഀഀ
** $Revision:   $਍⨀⨀⼀ഀഀ
਍唀匀䔀 嬀洀猀搀戀崀ഀഀ
GO਍ഀഀ
/****** Object:  Job T38trcSecAuditStop    Script Date: 09/16/2007 20:31:24 ******/਍䤀䘀  䔀堀䤀匀吀匀 ⠀匀䔀䰀䔀䌀吀 樀漀戀开椀搀 䘀刀伀䴀 洀猀搀戀⸀搀戀漀⸀猀礀猀樀漀戀猀开瘀椀攀眀 圀䠀䔀刀䔀 渀愀洀攀 㴀 一✀吀㌀㠀琀爀挀匀攀挀䄀甀搀椀琀匀琀漀瀀✀⤀ഀഀ
EXEC msdb.dbo.sp_delete_job @job_name=N'T38trcSecAuditStop', @delete_unused_schedule=1਍ഀഀ
/****** Object:  Job T38trcSecAuditStop    Script Date: 09/16/2007 20:31:32 ******/਍䈀䔀䜀䤀一 吀刀䄀一匀䄀䌀吀䤀伀一ഀഀ
਍搀攀挀氀愀爀攀 䀀䄀瀀瀀䐀椀爀攀挀琀漀爀礀 瘀愀爀挀栀愀爀⠀㄀㈀㠀⤀ഀഀ
declare @InstanceName varchar(128)਍搀攀挀氀愀爀攀 䀀匀琀漀瀀䌀漀洀洀愀渀搀 瘀愀爀挀栀愀爀⠀㄀　㈀㐀⤀ഀഀ
set @InstanceName = cast(serverproperty('InstanceName') as varchar(128))਍ഀഀ
-- determine the directory name਍椀昀 猀攀爀瘀攀爀瀀爀漀瀀攀爀琀礀⠀✀䤀猀䌀氀甀猀琀攀爀攀搀✀⤀㴀 ㄀ഀഀ
	begin਍ऀऀ瀀爀椀渀琀 ✀挀氀甀猀琀攀爀攀搀✀ഀഀ
		set @AppDirectory = ਍ऀऀऀ✀尀尀✀ഀഀ
			+ cast (serverproperty('MachineName') as varchar(128))਍ऀऀऀ⬀ ✀尀琀㌀㠀愀瀀瀀㠀　⸀✀ ഀഀ
			+ cast (serverproperty('MachineName') as varchar(128))਍ऀऀऀ⬀ ✀尀✀ഀഀ
 			+ @InstanceName਍ऀ攀渀搀ഀഀ
else if (select serverproperty('InstanceName')) is not NULL ਍ऀ戀攀最椀渀ഀഀ
		print 'instance'਍ऀऀ猀攀琀 䀀䄀瀀瀀䐀椀爀攀挀琀漀爀礀 㴀 ഀഀ
			'\\'਍ऀऀऀ⬀ 挀愀猀琀 ⠀猀攀爀瘀攀爀瀀爀漀瀀攀爀琀礀⠀✀䴀愀挀栀椀渀攀一愀洀攀✀⤀ 愀猀 瘀愀爀挀栀愀爀⠀㄀㈀㠀⤀⤀ഀഀ
			+ '\t38app80\' ਍ ऀऀऀ⬀ 挀愀猀琀 ⠀猀攀爀瘀攀爀瀀爀漀瀀攀爀琀礀⠀✀䤀渀猀琀愀渀挀攀一愀洀攀✀⤀ 愀猀 瘀愀爀挀栀愀爀⠀㄀㈀㠀⤀⤀ഀഀ
	end਍攀氀猀攀 ഀഀ
	begin਍ऀऀ瀀爀椀渀琀 ✀渀漀爀洀愀氀✀ഀഀ
		set @AppDirectory = ਍ऀऀऀ✀尀尀✀ഀഀ
			+ cast (serverproperty('MachineName') as varchar(128))਍ऀऀऀ⬀ ✀尀琀㌀㠀愀瀀瀀㠀　✀ ഀഀ
	end਍ഀഀ
-- set trace config file based on the version of SQL Server਍搀攀挀氀愀爀攀 䀀䌀漀渀昀椀最䘀椀氀攀 瘀愀爀挀栀愀爀⠀㘀㐀⤀ഀഀ
if (select left(cast(serverproperty('productversion') as varchar),4)) = '8.00'਍ऀ戀攀最椀渀ഀഀ
		set @ConfigFile = 't38trcSecAudit2000'਍ऀ攀渀搀ഀഀ
else਍ऀ戀攀最椀渀ഀഀ
		set @ConfigFile = 't38trcSecAudit'਍ऀ攀渀搀ഀഀ
਍椀昀 䀀䤀渀猀琀愀渀挀攀一愀洀攀 椀猀 渀甀氀氀ഀഀ
begin਍ऀ猀攀琀 䀀匀琀漀瀀䌀漀洀洀愀渀搀 㴀 ✀挀洀搀 ⼀䌀 瀀攀爀氀 ✀ ⬀ 䀀䄀瀀瀀䐀椀爀攀挀琀漀爀礀 ⬀ ✀尀琀㌀㠀琀爀愀挀攀⸀瀀氀 ⴀ砀 砀 ⴀ匀 ⸀ ⴀ搀 挀漀氀氀攀挀琀漀爀 ✀ ⬀ 䀀䄀瀀瀀䐀椀爀攀挀琀漀爀礀 ⬀ ✀尀✀ ⬀ 䀀䌀漀渀昀椀最䘀椀氀攀 ⬀ ✀⸀挀昀最✀ഀഀ
end਍攀氀猀攀ഀഀ
begin਍ऀ猀攀琀 䀀匀琀漀瀀䌀漀洀洀愀渀搀 㴀 ✀挀洀搀 ⼀䌀 瀀攀爀氀 ✀ ⬀ 䀀䄀瀀瀀䐀椀爀攀挀琀漀爀礀 ⬀ ✀尀琀㌀㠀琀爀愀挀攀⸀瀀氀 ⴀ砀 砀 ⴀ匀 ⸀尀✀ ⬀ 䀀䤀渀猀琀愀渀挀攀一愀洀攀 ⬀ ✀ ⴀ搀 挀漀氀氀攀挀琀漀爀 ✀ ⬀ 䀀䄀瀀瀀䐀椀爀攀挀琀漀爀礀 ⬀ ✀尀✀ ⬀ 䀀䌀漀渀昀椀最䘀椀氀攀 ⬀ ✀⸀挀昀最✀ഀഀ
end਍ഀഀ
DECLARE @ReturnCode INT਍匀䔀䰀䔀䌀吀 䀀刀攀琀甀爀渀䌀漀搀攀 㴀 　ഀഀ
/****** Object:  JobCategory [Database Maintenance]    Script Date: 09/16/2007 20:31:32 ******/਍䤀䘀 一伀吀 䔀堀䤀匀吀匀 ⠀匀䔀䰀䔀䌀吀 渀愀洀攀 䘀刀伀䴀 洀猀搀戀⸀搀戀漀⸀猀礀猀挀愀琀攀最漀爀椀攀猀 圀䠀䔀刀䔀 渀愀洀攀㴀一✀䐀愀琀愀戀愀猀攀 䴀愀椀渀琀攀渀愀渀挀攀✀ 䄀一䐀 挀愀琀攀最漀爀礀开挀氀愀猀猀㴀㄀⤀ഀഀ
BEGIN਍䔀堀䔀䌀 䀀刀攀琀甀爀渀䌀漀搀攀 㴀 洀猀搀戀⸀搀戀漀⸀猀瀀开愀搀搀开挀愀琀攀最漀爀礀 䀀挀氀愀猀猀㴀一✀䨀伀䈀✀Ⰰ 䀀琀礀瀀攀㴀一✀䰀伀䌀䄀䰀✀Ⰰ 䀀渀愀洀攀㴀一✀䐀愀琀愀戀愀猀攀 䴀愀椀渀琀攀渀愀渀挀攀✀ഀഀ
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback਍ഀഀ
END਍ഀഀ
DECLARE @jobId BINARY(16)਍䔀堀䔀䌀 䀀刀攀琀甀爀渀䌀漀搀攀 㴀  洀猀搀戀⸀搀戀漀⸀猀瀀开愀搀搀开樀漀戀 䀀樀漀戀开渀愀洀攀㴀一✀吀㌀㠀琀爀挀匀攀挀䄀甀搀椀琀匀琀漀瀀✀Ⰰ ഀഀ
		@enabled=1, ਍ऀऀ䀀渀漀琀椀昀礀开氀攀瘀攀氀开攀瘀攀渀琀氀漀最㴀㈀Ⰰ ഀഀ
		@notify_level_email=0, ਍ऀऀ䀀渀漀琀椀昀礀开氀攀瘀攀氀开渀攀琀猀攀渀搀㴀　Ⰰ ഀഀ
		@notify_level_page=0, ਍ऀऀ䀀搀攀氀攀琀攀开氀攀瘀攀氀㴀　Ⰰ ഀഀ
		@description=N'Start detailed SQL 8 trace. -d option(review version) $Revision:   1.8  $, $Workfile:   T38trcSecAuditStop.sql  $This stop script is for STORE SQL Server 2005 Servers only.', ਍ऀऀ䀀挀愀琀攀最漀爀礀开渀愀洀攀㴀一✀䐀愀琀愀戀愀猀攀 䴀愀椀渀琀攀渀愀渀挀攀✀Ⰰ ഀഀ
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT਍䤀䘀 ⠀䀀䀀䔀刀刀伀刀 㰀㸀 　 伀刀 䀀刀攀琀甀爀渀䌀漀搀攀 㰀㸀 　⤀ 䜀伀吀伀 儀甀椀琀圀椀琀栀刀漀氀氀戀愀挀欀ഀഀ
/****** Object:  Step [T38trcSecAuditStop]    Script Date: 09/16/2007 20:31:32 ******/਍䔀堀䔀䌀 䀀刀攀琀甀爀渀䌀漀搀攀 㴀 洀猀搀戀⸀搀戀漀⸀猀瀀开愀搀搀开樀漀戀猀琀攀瀀 䀀樀漀戀开椀搀㴀䀀樀漀戀䤀搀Ⰰ 䀀猀琀攀瀀开渀愀洀攀㴀一✀吀㌀㠀琀爀挀匀攀挀䄀甀搀椀琀匀琀漀瀀✀Ⰰ ഀഀ
		@step_id=1, ਍ऀऀ䀀挀洀搀攀砀攀挀开猀甀挀挀攀猀猀开挀漀搀攀㴀　Ⰰ ഀഀ
		@on_success_action=1, ਍ऀऀ䀀漀渀开猀甀挀挀攀猀猀开猀琀攀瀀开椀搀㴀　Ⰰ ഀഀ
		@on_fail_action=2, ਍ऀऀ䀀漀渀开昀愀椀氀开猀琀攀瀀开椀搀㴀　Ⰰ ഀഀ
		@retry_attempts=0, ਍ऀऀ䀀爀攀琀爀礀开椀渀琀攀爀瘀愀氀㴀㄀Ⰰ ഀഀ
		@os_run_priority=0, @subsystem=N'CmdExec', ਍ऀऀ䀀挀漀洀洀愀渀搀㴀䀀匀琀漀瀀䌀漀洀洀愀渀搀Ⰰ ഀഀ
		@flags=0਍ഀഀ
print 'command ' + @StopCommand਍ഀഀ
Print 'Job ''T38trcSecAuditStop'' Created successfully'਍ഀഀ
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback਍䔀堀䔀䌀 䀀刀攀琀甀爀渀䌀漀搀攀 㴀 洀猀搀戀⸀搀戀漀⸀猀瀀开甀瀀搀愀琀攀开樀漀戀 䀀樀漀戀开椀搀 㴀 䀀樀漀戀䤀搀Ⰰ 䀀猀琀愀爀琀开猀琀攀瀀开椀搀 㴀 ㄀ഀഀ
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback਍䔀堀䔀䌀 䀀刀攀琀甀爀渀䌀漀搀攀 㴀 洀猀搀戀⸀搀戀漀⸀猀瀀开愀搀搀开樀漀戀猀攀爀瘀攀爀 䀀樀漀戀开椀搀 㴀 䀀樀漀戀䤀搀Ⰰ 䀀猀攀爀瘀攀爀开渀愀洀攀 㴀 一✀⠀氀漀挀愀氀⤀✀ഀഀ
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback਍䌀伀䴀䴀䤀吀 吀刀䄀一匀䄀䌀吀䤀伀一ഀഀ
GOTO EndSave਍儀甀椀琀圀椀琀栀刀漀氀氀戀愀挀欀㨀ഀഀ
	IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION਍䔀渀搀匀愀瘀攀㨀ഀഀ
਍�