਍⼀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⼀ഀഀ
/* List all trace queues running on SQL Server														*/਍⼀⨀ 䈀䔀匀吀 䈀唀夀 䌀伀Ⰰ 䤀一䌀⸀ऀऀऀऀऀऀऀऀऀऀऀऀऀऀऀऀऀऀऀऀ⨀⼀ഀഀ
/* Create's T38trcSecAuditStart Job in SQL Server 2000 & 2005 Store and Corporate Servers. Work's 	*/਍⼀⨀   眀椀琀栀 吀㌀㠀琀爀愀挀攀⸀瀀氀 嘀攀爀㨀㄀⸀㤀 愀渀搀 愀戀漀瘀攀 漀渀氀礀 愀渀搀 䌀䘀䜀 吀㌀㠀琀爀挀匀攀挀䄀甀搀椀琀⸀挀昀最 瘀攀爀㨀刀攀瘀椀猀椀漀渀㨀 ㄀⸀㈀ऀऀऀ⨀⼀ഀഀ
/*----------------------------------------------------------------------------						*/਍⼀⨀ 䌀爀攀愀琀攀搀 匀攀瀀琀攀洀戀攀爀 ㄀　Ⰰ ㈀　　㜀 戀礀 䌀䠀䄀一䐀刀䄀 䌀䠀䄀吀唀刀嘀䔀䐀䤀 ⠀䄀㠀㄀㤀㄀㐀㌀⤀                 ऀऀऀऀऀऀ⨀⼀ഀഀ
/* Updated June 5, 2008 by David Duffy (A710446)                              						*/਍⼀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⼀ ഀഀ
਍⼀⨀ ␀䄀甀琀栀漀爀㨀     ␀ഀഀ
** $Archive:   $਍⨀⨀ ␀䐀愀琀攀㨀 ␀ഀഀ
** $Revision:   $਍⨀⨀⼀ഀഀ
਍ഀഀ
USE [msdb]਍䜀伀ഀഀ
਍⼀⨀⨀⨀⨀⨀⨀ 伀戀樀攀挀琀㨀  䨀漀戀 嬀吀㌀㠀琀爀挀匀攀挀䄀甀搀椀琀匀琀愀爀琀崀    匀挀爀椀瀀琀 䐀愀琀攀㨀 　㘀⼀　㔀⼀㈀　　㠀 　㤀㨀㌀㌀㨀　㌀ ⨀⨀⨀⨀⨀⨀⼀ഀഀ
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'T38trcSecAuditPIIPCIStart')਍䔀堀䔀䌀 洀猀搀戀⸀搀戀漀⸀猀瀀开搀攀氀攀琀攀开樀漀戀 䀀樀漀戀开渀愀洀攀㴀一✀吀㌀㠀琀爀挀匀攀挀䄀甀搀椀琀倀䤀䤀倀䌀䤀匀琀愀爀琀✀ഀഀ
਍⼀⨀ഀഀ
The PCI/PII and sysadmin trace results need to be saved to ਍愀 昀漀氀搀攀爀 渀愀洀攀搀 ∀挀漀氀氀攀挀琀漀爀㈀∀⸀ഀഀ
਍吀栀椀猀 猀攀挀琀椀漀渀 眀椀氀氀 挀爀攀愀琀攀 琀栀攀 昀漀氀搀攀爀 椀昀 椀琀 搀漀攀猀 渀漀琀 攀砀椀猀琀 愀氀爀攀愀搀礀⸀ഀഀ
*/਍ഀഀ
declare @DirCommand varchar(128)਍搀攀挀氀愀爀攀 䀀䌀漀氀氀攀挀琀漀爀䐀椀爀攀挀琀漀爀礀 瘀愀爀挀栀愀爀⠀㄀㈀㠀⤀ഀഀ
declare @MkdirCommand varchar(128)਍ഀഀ
create table #tmp (directory_name varchar(255))਍ഀഀ
-- determine the directory name਍椀昀 猀攀爀瘀攀爀瀀爀漀瀀攀爀琀礀⠀✀䤀猀䌀氀甀猀琀攀爀攀搀✀⤀㴀 ㄀ഀഀ
	begin਍ऀऀ瀀爀椀渀琀 ✀挀氀甀猀琀攀爀攀搀✀ഀഀ
		set @CollectorDirectory = ਍ऀऀऀ✀尀尀✀ഀഀ
			+ cast (serverproperty('MachineName') as varchar(128))਍ऀऀऀ⬀ ✀尀琀㌀㠀琀爀挀⸀✀ ഀഀ
			+ cast (serverproperty('MachineName') as varchar(128))਍ऀ攀渀搀ഀഀ
else if (select serverproperty('InstanceName')) is not NULL ਍ऀ戀攀最椀渀ഀഀ
		print 'instance'਍ऀऀ猀攀琀 䀀䌀漀氀氀攀挀琀漀爀䐀椀爀攀挀琀漀爀礀 㴀 ഀഀ
			'\\'਍ऀऀऀ⬀ 挀愀猀琀 ⠀猀攀爀瘀攀爀瀀爀漀瀀攀爀琀礀⠀✀䴀愀挀栀椀渀攀一愀洀攀✀⤀ 愀猀 瘀愀爀挀栀愀爀⠀㄀㈀㠀⤀⤀ഀഀ
			+ '\t38trc' ਍ऀ攀渀搀ഀഀ
else ਍ऀ戀攀最椀渀ഀഀ
		print 'normal'਍ऀऀ猀攀琀 䀀䌀漀氀氀攀挀琀漀爀䐀椀爀攀挀琀漀爀礀 㴀 ഀഀ
			'\\'਍ऀऀऀ⬀ 挀愀猀琀 ⠀猀攀爀瘀攀爀瀀爀漀瀀攀爀琀礀⠀✀䴀愀挀栀椀渀攀一愀洀攀✀⤀ 愀猀 瘀愀爀挀栀愀爀⠀㄀㈀㠀⤀⤀ഀഀ
			+ '\t38trc' ਍ऀ攀渀搀ഀഀ
਍猀攀琀 䀀䐀椀爀䌀漀洀洀愀渀搀 㴀 ✀搀椀爀 ✀ ⬀ 䀀䌀漀氀氀攀挀琀漀爀䐀椀爀攀挀琀漀爀礀 ⬀ ✀尀 ⼀䈀 ⼀䄀㨀䐀 ⼀匀✀ഀഀ
set @MkdirCommand = 'mkdir ' + @CollectorDirectory + '\collector2'਍ഀഀ
-- get a listing of the existing directories਍ⴀⴀ 猀攀攀 椀昀 琀栀攀 挀漀氀氀攀挀琀漀爀㈀ 搀椀爀攀挀琀漀爀礀 攀砀椀猀琀猀ഀഀ
-- create it if it is not there਍椀渀猀攀爀琀 椀渀琀漀 ⌀琀洀瀀ഀഀ
exec master.dbo.xp_cmdshell @DirCommand਍椀昀 渀漀琀 攀砀椀猀琀猀 ⠀ഀഀ
	select	਍ऀऀ搀椀爀攀挀琀漀爀礀开渀愀洀攀ഀഀ
	from਍ऀऀ⌀琀洀瀀ഀഀ
	where਍ऀऀ搀椀爀攀挀琀漀爀礀开渀愀洀攀 㴀 䀀䌀漀氀氀攀挀琀漀爀䐀椀爀攀挀琀漀爀礀 ⬀ ✀尀挀漀氀氀攀挀琀漀爀㈀✀⤀ഀഀ
	begin਍ऀऀ攀砀攀挀 洀愀猀琀攀爀⸀搀戀漀⸀砀瀀开挀洀搀猀栀攀氀氀 䀀䴀欀搀椀爀䌀漀洀洀愀渀搀ഀഀ
		print 'Created missing collector2 directory.'਍ऀ攀渀搀ഀഀ
else਍ऀ瀀爀椀渀琀 ✀䌀漀氀氀攀挀琀漀爀㈀ 搀椀爀攀挀琀漀爀礀 愀氀爀攀愀搀礀 攀砀椀猀琀猀⸀✀ഀഀ
਍ⴀⴀ猀攀氀攀挀琀 ⨀ 昀爀漀洀 ⌀琀洀瀀ഀഀ
਍ⴀⴀ 挀氀攀愀渀 甀瀀 ഀഀ
drop table #tmp਍ⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀⴀഀഀ
਍⼀⨀ 䌀栀攀挀欀 昀漀爀 挀漀爀爀攀挀琀 瘀攀爀猀椀漀渀 漀昀 琀栀攀 匀儀䰀 匀攀爀瘀攀爀 ⨀⼀ഀഀ
if (select @@version) like '%SQL Server for Windows NT 4%'਍ऀ戀攀最椀渀ഀഀ
		RAISERROR('This script is not for SQL Server 4.xx', 10, 127)਍ऀ攀渀搀ഀഀ
਍最漀ഀഀ
PRINT ''਍最漀ഀഀ
਍猀攀氀攀挀琀 ✀匀琀愀爀琀 漀昀 猀挀爀椀瀀琀✀ 㴀 挀漀渀瘀攀爀琀⠀瘀愀爀挀栀愀爀⠀㠀⤀Ⰰ 最攀琀搀愀琀攀⠀⤀Ⰰ ㄀⤀ ⬀ ✀ ✀ ⬀ 挀漀渀瘀攀爀琀⠀瘀愀爀挀栀愀爀⠀㠀⤀Ⰰ 最攀琀搀愀琀攀⠀⤀Ⰰ 㠀⤀ ⬀ ✀㨀 ␀圀漀爀欀昀椀氀攀㨀   吀㌀㠀琀爀挀匀攀挀䄀甀搀椀琀倀䤀䤀倀䌀䤀匀琀愀爀琀⸀猀焀氀  ␀Ⰰ ␀刀攀瘀椀猀椀漀渀㨀   ㄀⸀㄀  ␀✀ഀഀ
go਍ഀഀ
਍倀刀䤀一吀 ✀✀ഀഀ
PRINT ''਍倀刀䤀一吀 ✀㰀㰀㰀㰀 洀愀猀琀攀爀 㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀㸀✀ഀഀ
PRINT ''਍唀匀䔀 洀愀猀琀攀爀ഀഀ
GO਍ഀഀ
if @@ERROR <> 0 RAISERROR('Problems in sql script', 10, 127)਍最漀ഀഀ
਍ഀഀ
/*** Start script ***/਍ഀഀ
BEGIN TRANSACTION਍ऀⴀⴀ 猀攀琀 琀爀愀挀攀 挀漀渀昀椀最 昀椀氀攀 戀愀猀攀搀 漀渀 琀栀攀 瘀攀爀猀椀漀渀 漀昀 匀儀䰀 匀攀爀瘀攀爀ഀഀ
	declare @ConfigFile varchar(64)਍ऀ椀昀 ⠀猀攀氀攀挀琀 氀攀昀琀⠀挀愀猀琀⠀猀攀爀瘀攀爀瀀爀漀瀀攀爀琀礀⠀✀瀀爀漀搀甀挀琀瘀攀爀猀椀漀渀✀⤀ 愀猀 瘀愀爀挀栀愀爀⤀Ⰰ㐀⤀⤀ 㴀 ✀㠀⸀　　✀ഀഀ
		begin਍ऀऀऀ猀攀琀 䀀䌀漀渀昀椀最䘀椀氀攀 㴀 ✀琀㌀㠀琀爀挀匀攀挀䄀甀搀椀琀倀䤀䤀倀䌀䤀㈀　　　✀ഀഀ
		end਍ऀ攀氀猀攀ഀഀ
		begin਍ऀऀऀ猀攀琀 䀀䌀漀渀昀椀最䘀椀氀攀 㴀 ✀琀㌀㠀琀爀挀匀攀挀䄀甀搀椀琀倀䤀䤀倀䌀䤀✀ഀഀ
		end਍ഀഀ
਍ऀ䐀䔀䌀䰀䄀刀䔀 䀀䨀漀戀䤀䐀 䈀䤀一䄀刀夀⠀㄀㘀⤀  ഀഀ
	DECLARE @ReturnCode INT    ਍ऀ匀䔀䰀䔀䌀吀 䀀刀攀琀甀爀渀䌀漀搀攀 㴀 　     ഀഀ
਍ऀ䤀䘀 ⠀匀䔀䰀䔀䌀吀 䌀伀唀一吀⠀⨀⤀ 䘀刀伀䴀 洀猀搀戀⸀搀戀漀⸀猀礀猀挀愀琀攀最漀爀椀攀猀 圀䠀䔀刀䔀 渀愀洀攀 㴀 一✀䐀愀琀愀戀愀猀攀 䴀愀椀渀琀攀渀愀渀挀攀✀⤀ 㰀 ㄀ ഀഀ
		EXECUTE msdb.dbo.sp_add_category @name = N'Database Maintenance'਍ഀഀ
	-- Delete the job with the same name (if it exists)਍ऀ匀䔀䰀䔀䌀吀 䀀䨀漀戀䤀䐀 㴀 樀漀戀开椀搀     ഀഀ
	FROM   msdb.dbo.sysjobs    ਍ऀ圀䠀䔀刀䔀 ⠀渀愀洀攀 㴀 一✀吀㌀㠀琀爀挀匀攀挀䄀甀搀椀琀倀䤀䤀倀䌀䤀匀琀愀爀琀✀⤀       ഀഀ
਍ऀ䤀䘀 ⠀䀀䨀漀戀䤀䐀 䤀匀 一伀吀 一唀䰀䰀⤀    ഀഀ
		BEGIN  ਍ऀऀऀⴀⴀ 䌀栀攀挀欀 椀昀 琀栀攀 樀漀戀 椀猀 愀 洀甀氀琀椀ⴀ猀攀爀瘀攀爀 樀漀戀  ഀഀ
			IF (EXISTS (SELECT  * ਍ऀऀऀऀऀ䘀刀伀䴀    洀猀搀戀⸀搀戀漀⸀猀礀猀樀漀戀猀攀爀瘀攀爀猀 ഀഀ
					WHERE   (job_id = @JobID) AND (server_id <> 0))) ਍ऀऀऀऀ䈀䔀䜀䤀一 ഀഀ
					-- There is, so abort the script ਍ऀऀऀऀऀ刀䄀䤀匀䔀刀刀伀刀 ⠀一✀唀渀愀戀氀攀 琀漀 椀洀瀀漀爀琀 樀漀戀 ✀✀吀㌀㠀琀爀挀匀攀挀䄀甀搀椀琀倀䤀䤀倀䌀䤀匀琀愀爀琀✀✀ 猀椀渀挀攀 琀栀攀爀攀 椀猀 愀氀爀攀愀搀礀 愀 洀甀氀琀椀ⴀ猀攀爀瘀攀爀 樀漀戀 眀椀琀栀 琀栀椀猀 渀愀洀攀⸀✀Ⰰ ㄀㘀Ⰰ ㄀⤀ ഀഀ
					GOTO QuitWithRollback  ਍ऀऀऀऀ䔀一䐀 ഀഀ
			ELSE ਍ऀऀऀⴀⴀ 䐀攀氀攀琀攀 琀栀攀 嬀氀漀挀愀氀崀 樀漀戀 ഀഀ
			EXECUTE msdb.dbo.sp_delete_job @job_name = N'T38trcSecAuditPIIPCIStart' ਍ऀऀऀ匀䔀䰀䔀䌀吀 䀀䨀漀戀䤀䐀 㴀 一唀䰀䰀ഀഀ
		END ਍ഀഀ
	BEGIN ਍ऀऀⴀⴀ 䄀搀搀 琀栀攀 樀漀戀ഀഀ
		EXECUTE @ReturnCode = msdb.dbo.sp_add_job @job_id = @JobID OUTPUT਍ऀऀऀⰀ 䀀攀渀愀戀氀攀搀㴀㄀ഀഀ
			, @job_name = N'T38trcSecAuditPIIPCIStart'਍ऀऀऀⰀ 䀀漀眀渀攀爀开氀漀最椀渀开渀愀洀攀 㴀 一✀猀愀✀ഀഀ
			, @description = N'Start Standard SQL trace with custom filter. Stop it with T38trcSecAuditPIIPCIStop job. $Revision:   1.1  $, $Workfile:   T38trcSecAuditPIIPCIStart.sql  $ '਍ऀऀऀⰀ 䀀挀愀琀攀最漀爀礀开渀愀洀攀 㴀 一✀䐀愀琀愀戀愀猀攀 䴀愀椀渀琀攀渀愀渀挀攀✀ഀഀ
			, @notify_level_email = 0਍ऀऀऀⰀ 䀀渀漀琀椀昀礀开氀攀瘀攀氀开瀀愀最攀 㴀 　ഀഀ
			, @notify_level_netsend = 0਍ऀऀऀⰀ 䀀渀漀琀椀昀礀开氀攀瘀攀氀开攀瘀攀渀琀氀漀最 㴀 ㈀ഀഀ
			, @delete_level= 0਍ऀऀ䤀䘀 ⠀䀀䀀䔀刀刀伀刀 㰀㸀 　 伀刀 䀀刀攀琀甀爀渀䌀漀搀攀 㰀㸀 　⤀ 䜀伀吀伀 儀甀椀琀圀椀琀栀刀漀氀氀戀愀挀欀 ഀഀ
਍ऀऀⴀⴀ 䄀搀搀 琀栀攀 樀漀戀 猀琀攀瀀猀ഀഀ
		declare @runcmd	varchar(256), ਍ऀऀऀ䀀猀挀爀椀瀀琀䐀椀爀ऀ瘀愀爀挀栀愀爀⠀㈀㔀㘀⤀Ⰰഀഀ
			@serverOpt	varchar(256),਍ऀऀऀ䀀洀愀挀栀椀渀攀渀愀洀攀ऀ瘀愀爀挀栀愀爀⠀㄀㈀㠀⤀Ⰰഀഀ
			@instsrvname	varchar(128)਍ഀഀ
		if serverproperty('IsClustered')= 1਍ऀऀऀ戀攀最椀渀ഀഀ
				select @machinename = cast (serverproperty('MachineName') as varchar(128))਍ऀऀऀऀ猀攀氀攀挀琀 䀀椀渀猀琀猀爀瘀渀愀洀攀 㴀 挀愀猀琀 ⠀猀攀爀瘀攀爀瀀爀漀瀀攀爀琀礀⠀✀匀攀爀瘀攀爀渀愀洀攀✀⤀愀猀 瘀愀爀挀栀愀爀⠀㄀㈀㠀⤀⤀ഀഀ
				select @scriptDir = '\\' + @machinename + '\t38app80.' + @instsrvname਍ऀऀऀऀ猀攀氀攀挀琀 䀀猀攀爀瘀攀爀伀瀀琀 㴀 ✀ ⴀ匀 ✀ ⬀ 䀀椀渀猀琀猀爀瘀渀愀洀攀 ⬀ ✀ ✀ ⬀ 䀀猀挀爀椀瀀琀䐀椀爀 ⬀ ✀尀✀ ⬀ 䀀䌀漀渀昀椀最䘀椀氀攀 ⬀ ✀⸀挀昀最✀ഀഀ
			end਍ऀऀ攀氀猀攀 椀昀 ⠀猀攀氀攀挀琀 猀攀爀瘀攀爀瀀爀漀瀀攀爀琀礀⠀✀䤀渀猀琀愀渀挀攀一愀洀攀✀⤀⤀ 椀猀 渀漀琀 一唀䰀䰀 ഀഀ
			begin਍ऀऀऀऀ猀攀氀攀挀琀 䀀猀挀爀椀瀀琀䐀椀爀 㴀 ✀尀尀─挀漀洀瀀甀琀攀爀渀愀洀攀─尀琀㌀㠀愀瀀瀀㠀　尀✀ ⬀ 挀愀猀琀 ⠀猀攀爀瘀攀爀瀀爀漀瀀攀爀琀礀⠀✀䤀渀猀琀愀渀挀攀一愀洀攀✀⤀ 愀猀 瘀愀爀挀栀愀爀⠀㄀㈀㠀⤀⤀ഀഀ
				select @serverOpt = ' -S .\' + cast (serverproperty('InstanceName') as varchar(128)) + ' ' + @scriptDir + '\' + @ConfigFile + '.cfg'਍ऀऀऀ攀渀搀ഀഀ
		else ਍ऀऀऀ戀攀最椀渀ഀഀ
				select @scriptDir = '\\%computername%\t38app80'਍ऀऀऀऀ猀攀氀攀挀琀 䀀猀攀爀瘀攀爀伀瀀琀 㴀 ✀ ✀ ⬀ 䀀猀挀爀椀瀀琀䐀椀爀 ⬀ ✀尀✀ ⬀ 䀀䌀漀渀昀椀最䘀椀氀攀 ⬀ ✀⸀挀昀最✀ഀഀ
			end਍ऀऀ猀攀氀攀挀琀 䀀爀甀渀挀洀搀 㴀 ✀挀洀搀 ⼀䌀 瀀攀爀氀 ✀ ⬀ 䀀猀挀爀椀瀀琀䐀椀爀 ⬀ ✀尀琀㌀㠀琀爀愀挀攀⸀瀀氀 ⴀ氀 ✀ ⬀ 䀀䌀漀渀昀椀最䘀椀氀攀 ⬀ ✀ ⴀ搀 挀漀氀氀攀挀琀漀爀㈀ ✀ ⬀ 䀀猀攀爀瘀攀爀伀瀀琀ഀഀ
਍ऀऀ䔀堀䔀䌀唀吀䔀 䀀刀攀琀甀爀渀䌀漀搀攀 㴀 洀猀搀戀⸀搀戀漀⸀猀瀀开愀搀搀开樀漀戀猀琀攀瀀 䀀樀漀戀开椀搀 㴀 䀀䨀漀戀䤀䐀ഀഀ
			, @step_id = 1਍ऀऀऀⰀ 䀀猀琀攀瀀开渀愀洀攀 㴀 一✀吀㌀㠀琀爀挀匀攀挀䄀甀搀椀琀倀䤀䤀倀䌀䤀匀琀愀爀琀✀ഀഀ
			, @command = @runcmd਍ऀऀऀⰀ 䀀搀愀琀愀戀愀猀攀开渀愀洀攀 㴀 一✀✀ഀഀ
			, @server = N''਍ऀऀऀⰀ 䀀搀愀琀愀戀愀猀攀开甀猀攀爀开渀愀洀攀 㴀 一✀✀ഀഀ
			, @subsystem = N'CmdExec'਍ऀऀऀⰀ 䀀挀洀搀攀砀攀挀开猀甀挀挀攀猀猀开挀漀搀攀 㴀 　ഀഀ
			, @flags = 0਍ऀऀऀⰀ 䀀爀攀琀爀礀开愀琀琀攀洀瀀琀猀 㴀 　ഀഀ
			, @retry_interval = 1਍ऀऀऀⰀ 䀀漀甀琀瀀甀琀开昀椀氀攀开渀愀洀攀 㴀 一✀✀ഀഀ
			, @on_success_step_id = 0਍ऀऀऀⰀ 䀀漀渀开猀甀挀挀攀猀猀开愀挀琀椀漀渀 㴀 ㄀ഀഀ
			, @on_fail_step_id = 0਍ऀऀऀⰀ 䀀漀渀开昀愀椀氀开愀挀琀椀漀渀 㴀 ㈀ഀഀ
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback ਍ऀऀ䔀堀䔀䌀唀吀䔀 䀀刀攀琀甀爀渀䌀漀搀攀 㴀 洀猀搀戀⸀搀戀漀⸀猀瀀开甀瀀搀愀琀攀开樀漀戀 䀀樀漀戀开椀搀 㴀 䀀䨀漀戀䤀䐀Ⰰ 䀀猀琀愀爀琀开猀琀攀瀀开椀搀 㴀 ㄀ ഀഀ
਍ऀऀ䤀䘀 ⠀䀀䀀䔀刀刀伀刀 㰀㸀 　 伀刀 䀀刀攀琀甀爀渀䌀漀搀攀 㰀㸀 　⤀ 䜀伀吀伀 儀甀椀琀圀椀琀栀刀漀氀氀戀愀挀欀 ഀഀ
਍ऀऀⴀⴀ 䄀搀搀 琀栀攀 樀漀戀 猀挀栀攀搀甀氀攀猀ഀഀ
		EXECUTE @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id = @JobID਍ऀऀऀⰀ 䀀渀愀洀攀 㴀 一✀吀㌀㠀琀爀挀匀攀挀䄀甀搀椀琀倀䤀䤀倀䌀䤀匀琀愀爀琀✀ഀഀ
			, @enabled = 1਍ऀऀऀⰀ 䀀昀爀攀焀开琀礀瀀攀 㴀 㐀ഀഀ
			, @active_start_date = 20001017਍ऀऀऀⰀ 䀀愀挀琀椀瘀攀开猀琀愀爀琀开琀椀洀攀 㴀 　　㄀㔀　　ഀഀ
			, @freq_interval = 1਍ऀऀऀⰀ 䀀昀爀攀焀开猀甀戀搀愀礀开琀礀瀀攀 㴀 㠀ഀഀ
			, @freq_subday_interval = 1਍ऀऀऀⰀ 䀀昀爀攀焀开爀攀氀愀琀椀瘀攀开椀渀琀攀爀瘀愀氀 㴀 　ഀഀ
			, @freq_recurrence_factor = 0਍ऀऀऀⰀ 䀀愀挀琀椀瘀攀开攀渀搀开搀愀琀攀 㴀 㤀㤀㤀㤀㄀㈀㌀㄀ഀഀ
			, @active_end_time = 235959਍ऀऀ䤀䘀 ⠀䀀䀀䔀刀刀伀刀 㰀㸀 　 伀刀 䀀刀攀琀甀爀渀䌀漀搀攀 㰀㸀 　⤀ 䜀伀吀伀 儀甀椀琀圀椀琀栀刀漀氀氀戀愀挀欀 ഀഀ
਍ऀऀⴀⴀ 䄀搀搀 琀栀攀 吀愀爀最攀琀 匀攀爀瘀攀爀猀ഀഀ
		EXECUTE @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @JobID, @server_name = N'(local)' ਍ऀऀ䤀䘀 ⠀䀀䀀䔀刀刀伀刀 㰀㸀 　 伀刀 䀀刀攀琀甀爀渀䌀漀搀攀 㰀㸀 　⤀ 䜀伀吀伀 儀甀椀琀圀椀琀栀刀漀氀氀戀愀挀欀 ഀഀ
਍ऀ䔀一䐀ഀഀ
COMMIT TRANSACTION          ਍䜀伀吀伀   䔀渀搀匀愀瘀攀              ഀഀ
QuitWithRollback:਍䤀䘀 ⠀䀀䀀吀刀䄀一䌀伀唀一吀 㸀 　⤀ 刀伀䰀䰀䈀䄀䌀䬀 吀刀䄀一匀䄀䌀吀䤀伀一 ഀഀ
EndSave: ਍ഀഀ
਍⼀⨀⨀⨀ 䔀渀搀 猀挀爀椀瀀琀 ⨀⨀⨀⼀ഀഀ
਍倀刀䤀一吀 ✀✀ഀഀ
go਍ഀഀ
select 'End of script' = convert(varchar(8), getdate(), 1) + ' ' + convert(varchar(8), getdate(), 8) + ': $Workfile:   T38trcSecAuditPIIPCIStart.sql  $, $Revision:   1.1  $'਍最漀ഀഀ
਍ഀഀ
