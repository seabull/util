/****************************************************/਍⼀⨀ 䌀爀攀愀琀攀搀 戀礀㨀 匀儀䰀 匀攀爀瘀攀爀 ㈀　　㠀 倀爀漀昀椀氀攀爀             ⨀⼀ഀഀ
/* Date: 04/22/2011  11:58:31 AM         */਍⼀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⨀⼀ഀഀ
਍ഀഀ
-- Create a Queue਍搀攀挀氀愀爀攀 䀀爀挀 椀渀琀ഀഀ
declare @TraceID int਍搀攀挀氀愀爀攀 䀀洀愀砀昀椀氀攀猀椀稀攀 戀椀最椀渀琀ഀഀ
set @maxfilesize = 5 ਍ഀഀ
-- Please replace the text InsertFileNameHere, with an appropriate਍ⴀⴀ 昀椀氀攀渀愀洀攀 瀀爀攀昀椀砀攀搀 戀礀 愀 瀀愀琀栀Ⰰ 攀⸀最⸀Ⰰ 挀㨀尀䴀礀䘀漀氀搀攀爀尀䴀礀吀爀愀挀攀⸀ 吀栀攀 ⸀琀爀挀 攀砀琀攀渀猀椀漀渀ഀഀ
-- will be appended to the filename automatically. If you are writing from਍ⴀⴀ 爀攀洀漀琀攀 猀攀爀瘀攀爀 琀漀 氀漀挀愀氀 搀爀椀瘀攀Ⰰ 瀀氀攀愀猀攀 甀猀攀 唀一䌀 瀀愀琀栀 愀渀搀 洀愀欀攀 猀甀爀攀 猀攀爀瘀攀爀 栀愀猀ഀഀ
-- write access to your network share਍ⴀⴀ 吀漀 挀栀攀挀欀 琀爀愀挀攀 搀愀琀愀ഀഀ
--SELECT *਍ⴀⴀ 䘀刀伀䴀 昀渀开琀爀愀挀攀开最攀琀琀愀戀氀攀⠀一✀䌀㨀尀吀爀愀挀攀䘀椀氀攀猀尀䄀琀琀攀渀琀椀漀渀䔀瘀攀渀琀猀⸀琀爀挀✀Ⰰ 䐀䔀䘀䄀唀䰀吀⤀㬀ഀഀ
--਍ⴀⴀ 吀漀 猀琀漀瀀 愀渀搀 搀攀氀攀琀攀 琀栀攀 猀攀爀瘀攀爀 猀椀搀攀 琀爀愀挀攀ഀഀ
--਍ⴀⴀ 䐀䔀䌀䰀䄀刀䔀 䀀吀爀愀挀攀䤀䐀 椀渀琀 㬀ഀഀ
-- SET @TraceID = 3 ; -- specify value from sp_trace_create਍ⴀⴀ 䔀堀䔀䌀 猀瀀开琀爀愀挀攀开猀攀琀猀琀愀琀甀猀ഀഀ
--    @traceid = @TraceID਍ⴀⴀ    Ⰰ䀀猀琀愀琀甀猀 㴀 　 㬀ⴀⴀ 猀琀漀瀀 琀爀愀挀攀ഀഀ
-- EXEC sp_trace_setstatus਍ⴀⴀ    䀀琀爀愀挀攀椀搀 㴀 䀀吀爀愀挀攀䤀䐀ഀഀ
--  ,@status = 2 ;-- delete trace਍ഀഀ
਍ഀഀ
--exec @rc = sp_trace_create @TraceID output, 0, N'InsertFileNameHere', @maxfilesize, NULL ਍攀砀攀挀 䀀爀挀 㴀 猀瀀开琀爀愀挀攀开挀爀攀愀琀攀 䀀吀爀愀挀攀䤀䐀 漀甀琀瀀甀琀Ⰰ ㈀Ⰰ 一✀䌀㨀尀吀爀愀挀攀䘀椀氀攀猀尀䄀琀琀攀渀琀椀漀渀䔀瘀攀渀琀猀✀Ⰰ 䀀洀愀砀昀椀氀攀猀椀稀攀Ⰰ一唀䰀䰀Ⰰ ㌀ഀഀ
਍椀昀 ⠀䀀爀挀 ℀㴀 　⤀ 最漀琀漀 攀爀爀漀爀ഀഀ
਍ⴀⴀ 䌀氀椀攀渀琀 猀椀搀攀 䘀椀氀攀 愀渀搀 吀愀戀氀攀 挀愀渀渀漀琀 戀攀 猀挀爀椀瀀琀攀搀ഀഀ
਍ⴀⴀ 匀攀琀 琀栀攀 攀瘀攀渀琀猀ഀഀ
declare @on bit਍猀攀琀 䀀漀渀 㴀 ㄀ഀഀ
exec sp_trace_setevent @TraceID, 16, 7, @on਍攀砀攀挀 猀瀀开琀爀愀挀攀开猀攀琀攀瘀攀渀琀 䀀吀爀愀挀攀䤀䐀Ⰰ ㄀㘀Ⰰ ㄀㔀Ⰰ 䀀漀渀ഀഀ
exec sp_trace_setevent @TraceID, 16, 4, @on਍攀砀攀挀 猀瀀开琀爀愀挀攀开猀攀琀攀瘀攀渀琀 䀀吀爀愀挀攀䤀䐀Ⰰ ㄀㘀Ⰰ 㠀Ⰰ 䀀漀渀ഀഀ
exec sp_trace_setevent @TraceID, 16, 12, @on਍攀砀攀挀 猀瀀开琀爀愀挀攀开猀攀琀攀瘀攀渀琀 䀀吀爀愀挀攀䤀䐀Ⰰ ㄀㘀Ⰰ 㘀　Ⰰ 䀀漀渀ഀഀ
exec sp_trace_setevent @TraceID, 16, 64, @on਍攀砀攀挀 猀瀀开琀爀愀挀攀开猀攀琀攀瘀攀渀琀 䀀吀爀愀挀攀䤀䐀Ⰰ ㄀㘀Ⰰ 㤀Ⰰ 䀀漀渀ഀഀ
exec sp_trace_setevent @TraceID, 16, 13, @on਍攀砀攀挀 猀瀀开琀爀愀挀攀开猀攀琀攀瘀攀渀琀 䀀吀爀愀挀攀䤀䐀Ⰰ ㄀㘀Ⰰ 㐀㄀Ⰰ 䀀漀渀ഀഀ
exec sp_trace_setevent @TraceID, 16, 49, @on਍攀砀攀挀 猀瀀开琀爀愀挀攀开猀攀琀攀瘀攀渀琀 䀀吀爀愀挀攀䤀䐀Ⰰ ㄀㘀Ⰰ 㘀Ⰰ 䀀漀渀ഀഀ
exec sp_trace_setevent @TraceID, 16, 10, @on਍攀砀攀挀 猀瀀开琀爀愀挀攀开猀攀琀攀瘀攀渀琀 䀀吀爀愀挀攀䤀䐀Ⰰ ㄀㘀Ⰰ ㄀㐀Ⰰ 䀀漀渀ഀഀ
exec sp_trace_setevent @TraceID, 16, 26, @on਍攀砀攀挀 猀瀀开琀爀愀挀攀开猀攀琀攀瘀攀渀琀 䀀吀爀愀挀攀䤀䐀Ⰰ ㄀㘀Ⰰ ㌀Ⰰ 䀀漀渀ഀഀ
exec sp_trace_setevent @TraceID, 16, 11, @on਍攀砀攀挀 猀瀀开琀爀愀挀攀开猀攀琀攀瘀攀渀琀 䀀吀爀愀挀攀䤀䐀Ⰰ ㄀㘀Ⰰ ㌀㔀Ⰰ 䀀漀渀ഀഀ
exec sp_trace_setevent @TraceID, 16, 51, @on਍ഀഀ
਍ⴀⴀ 匀攀琀 琀栀攀 䘀椀氀琀攀爀猀ഀഀ
declare @intfilter int਍搀攀挀氀愀爀攀 䀀戀椀最椀渀琀昀椀氀琀攀爀 戀椀最椀渀琀ഀഀ
਍ⴀⴀ 匀攀琀 琀栀攀 琀爀愀挀攀 猀琀愀琀甀猀 琀漀 猀琀愀爀琀ഀഀ
exec sp_trace_setstatus @TraceID, 1਍ഀഀ
-- display trace id for future references਍猀攀氀攀挀琀 吀爀愀挀攀䤀䐀㴀䀀吀爀愀挀攀䤀䐀ഀഀ
goto finish਍ഀഀ
error: ਍猀攀氀攀挀琀 䔀爀爀漀爀䌀漀搀攀㴀䀀爀挀ഀഀ
਍昀椀渀椀猀栀㨀 ഀഀ
go਍�