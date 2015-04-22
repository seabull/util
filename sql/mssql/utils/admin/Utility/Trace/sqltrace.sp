/*---------------------------------------------------------------------
  $Header: c:\\Repository/sql/mssql/utils/admin/Utility/Trace/sqltrace.sp,v 1.1 2011/03/10 17:06:05 a645276 Exp $

  sqltrace - Run an SQL batch and trace it. Written by Lee Tudor.

  $History: sqltrace.sp $
 * 
 * *****************  Version 3  *****************
 * User: Sommar       Date: 10-08-21   Time: 22:03
 * Updated in $/WWW/sqlutil
 * Behzad Sadeghi pointed out that plans were missing for dynamic SQL
 * invoked through sp_executesql, but not EXEC(). This was due to an
 * inconsistency in SQL Server, which I have reported on Connect.With help
 * Behzad I have implemented a workaround for the issue.
 *
 * *****************  Version 2  *****************
 * User: Sommar       Date: 08-11-29   Time: 23:29
 * Updated in $/WWW/sqlutil
 * First release on the web site.
---------------------------------------------------------------------*/
IF object_id('dbo.sqltrace') IS NULL
      EXEC ('CREATE PROCEDURE dbo.sqltrace AS RETURN')
GO
ALTER PROCEDURE [dbo].[sqltrace]
  @batch nvarchar(max),
    -- sql batch to analyse
  @minReads bigint = 1,
    -- min reads (logical)
  @minCPU int = 0,
    -- min cpu time (milliseconds)
  @minDuration bigint = 0,
    -- min duration (microseconds)
  @factor varchar(50) = 'Duration',
    -- % (Duration, Reads, Writes, CPU)
  @order varchar(50) = '',
    -- order (Duration, Reads, Writes, CPU)
  @plans varchar(50) = '',
    -- include query plans - intentive (Actual, Estimated)
  @rollback bit = 0,
    -- run in a transaction and rollback
  @timeout int = 300
    -- set a maximum trace duration (seconds)
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @id int, @spid int, @file nvarchar(256), @fsize bigint, @plan int, @on bit, @rc int,
    @stoptime datetime, @total int, @rcCPU int, @rcDuration int

  SELECT @spid = @@SPID, @on = 1, @fsize = 5,
    @plan = CASE lower(@plans) WHEN 'actual' THEN 146 WHEN 'estimated' THEN 122 END,
    @stoptime = dateadd(second, @timeout, getdate()),
    @file = N'c:\temp\'+Cast(newid() as char(36))

  EXEC sp_trace_create @id output, 2, @file, @fsize, @stoptime

  IF @plan IS NOT NULL BEGIN
    EXEC sp_trace_setevent @id, @plan, 1, @on   -- XML Plan
    EXEC sp_trace_setevent @id, @plan, 5, @on   -- XML Plan / Line
    EXEC sp_trace_setevent @id, @plan, 34, @on   -- XML Plan / ObjectName
    EXEC sp_trace_setevent @id, @plan, 51, @on   -- XML Plan / EventSequence
  END
  EXEC sp_trace_setevent @id, 45, 51, @on   -- SP:StmtCompleted / EventSeq
  EXEC sp_trace_setevent @id, 41, 51, @on   -- SQL:StmtCompleted / EventSeq
  EXEC sp_trace_setevent @id, 166, 51, @on   -- SQL:StmtRecompile / EventSeq
  EXEC sp_trace_setevent @id, 166, 21, @on   -- SQL:StmtRecompile / Subclass
  EXEC sp_trace_setevent @id, 45, 1, @on   -- SP:StmtCompleted / TextData
  EXEC sp_trace_setevent @id, 41, 1, @on   -- SQL:StmtCompleted / TextData
  EXEC sp_trace_setevent @id, 166, 1, @on   -- SQL:StmtRecompile / TextData
  EXEC sp_trace_setevent @id, 45, 13, @on   -- SP:StmtCompleted / Duration
  EXEC sp_trace_setevent @id, 41, 13, @on   -- SQL:StmtCompleted / Durantion
  EXEC sp_trace_setevent @id, 45, 16, @on   -- SP:StmtCompleted / Reads
  EXEC sp_trace_setevent @id, 41, 16, @on   -- SQL:StmtCompleted / Reads
  EXEC sp_trace_setevent @id, 45, 17, @on   -- SP:StmtCompleted / Writes
  EXEC sp_trace_setevent @id, 41, 17, @on   -- SQL:StmtCompleted / Writes
  EXEC sp_trace_setevent @id, 45, 18, @on   -- SP:StmtCompleted / CPU
  EXEC sp_trace_setevent @id, 41, 18, @on   -- SQL:StmtCompleted / CPU
  EXEC sp_trace_setevent @id, 45, 5, @on   -- SP:StmtCompleted / Line
  EXEC sp_trace_setevent @id, 41, 5, @on   -- SQL:StmtCompleted / Line
  EXEC sp_trace_setevent @id, 45, 34, @on   -- SP:StmtCompleted / ObjectName
  EXEC sp_trace_setevent @id, 45, 29, @on   -- SP:StmtCompleted / NestLevel

  EXEC sp_trace_setfilter @id, 12, 0, 0, @spid -- spid = @@spid
  EXEC sp_trace_setfilter @id, 13, 0, 4, @minDuration -- duration >= @min
  EXEC sp_trace_setfilter @id, 16, 0, 4, @minReads -- reads >= @minReads
  EXEC sp_trace_setfilter @id, 18, 0, 4, @minCPU -- cpu >= @minCPU

  IF @rollback=1
    BEGIN TRAN

  EXEC sp_trace_setstatus @id, 1
  EXEC (@batch)
  EXEC sp_trace_setstatus @id, 0

  IF @@TRANCOUNT>0
    ROLLBACK

  EXEC sp_trace_setstatus @id, 2

  DECLARE @Results TABLE (
    EventClass smallint,
    SubClass smallint,
    TextData nvarchar(max),
    ObjectName varchar(128),
    Nesting smallint,
    LineNumber smallint,
    Duration numeric(18,3),
    Reads int,
    CPU int,
    Writes int,
    Compile int,
    rcCPU int,
    rcDuration bigint,
    XPlan xml,
    ID bigint PRIMARY KEY
  )

-- load trace
  SET  @file = @file+'.trc'
  INSERT @Results
  SELECT EventClass, EventSubClass, TextData, ObjectName, NestLevel-2,
    LineNumber, Duration/1000.0, Reads, CPU, Writes, 0, null, null, '', EventSequence
  FROM fn_trace_gettable ( @file , default )
  WHERE EventSequence IS NOT NULL

-- sequence query plans
  IF @plan IS NOT NULL
    UPDATE M SET
      XPlan = S.TextData,
      ObjectName = CASE WHEN M.ObjectName IS NULL THEN S.ObjectName ELSE M.ObjectName END
    FROM @Results S
    CROSS APPLY(
      SELECT top 1 * FROM @Results R
      WHERE R.ID > S.ID AND R.LineNumber=S.LineNumber
                      AND ( coalesce(R.ObjectName, 'Dynamic SQL') = S.ObjectName )
     ORDER BY ID) M
    WHERE S.EventClass = @plan

-- sequence recompiles
  UPDATE M SET
    Compile = 1,
    SubClass = S.SubClass,
    rcCPU = M.XPlan.value('*[1]/*[1]/*[1]/*[1]/*[1]/*[1]/@CompileCPU','int'),
    rcDuration = M.XPlan.value('*[1]/*[1]/*[1]/*[1]/*[1]/*[1]/@CompileTime','int')
  FROM @Results S
  CROSS APPLY(
    SELECT top 1 * FROM @Results
    WHERE ID > S.ID AND TextData=S.TextData
    ORDER BY ID) M
  WHERE S.EventClass = 166

-- remove xplan variables
  UPDATE @Results
  SET XPlan.modify('delete *[1]/*[1]/*[1]/*[1]/*[1]/*[1]/@CompileTime')
  WHERE XPlan IS NOT NULL
  UPDATE @Results
  SET XPlan.modify('delete *[1]/*[1]/*[1]/*[1]/*[1]/*[1]/@CompileCPU')
  WHERE XPlan IS NOT NULL

-- total measure
  SELECT @total = NullIf(MAX(CASE lower(@factor) WHEN 'cpu' THEN CPU
    WHEN 'reads' THEN Reads
    WHEN 'writes' THEN Writes
    ELSE Duration END),0),
    @rcDuration = SUM(rcDuration),
    @rcCPU = SUM(rcCPU),
    @rc = SUM(CASE WHEN EventClass=166 THEN 1 ELSE 0 END)
  FROM @Results

  UPDATE @Results SET
    rcDuration = @rcDuration,
    rcCPU = @rcCPU,
    Compile = @rc
  WHERE ObjectName='sqltrace'

-- results
  SELECT CASE WHEN ObjectName='sqltrace' THEN '' ELSE
    isnull(cast(nullif(floor((@total/2+100*Sum(CASE lower(@factor) WHEN 'cpu' THEN CPU+IsNull(rcCPU,0)
      WHEN 'reads' THEN Reads
      WHEN 'writes' THEN Writes
      ELSE Duration+IsNull(rcDuration,0) END))/@total),0) as varchar)+'%','') END AS Factor,
    CASE WHEN TextData LIKE 'EXEC%' THEN '\---- '+TextData
      WHEN TextData LIKE '%StatMan%' THEN 'Statistics -- '+TextData
      ELSE TextData END AS Text,
    CASE WHEN ObjectName='sqltrace' OR COUNT(*)=1 THEN '' ELSE cast(COUNT(*) as varchar) END AS Calls,
    CASE WHEN ObjectName='sqltrace' THEN '' ELSE Cast(Nesting as varchar) END AS Nesting,
    CASE WHEN ObjectName='sqltrace' THEN '' ELSE ObjectName+' - '+cast(LineNumber as varchar) END [Object - Line],
    Sum(Duration) AS Duration,
    IsNull(Cast(NullIf(Sum(CPU),0) as varchar),'') AS CPU,
    IsNull(Cast(NullIf(Sum(Reads),0) as varchar),'') AS Reads,
    IsNull(Cast(NullIf(Sum(Writes),0) as varchar),'') AS Writes,
    IsNull(Cast(NullIf(Sum(Compile),0) as varchar),'') AS Compiles,
    CASE SubClass
      WHEN 1 THEN 'Local' WHEN 2 THEN 'Stats' WHEN 3 THEN 'DNR'
      WHEN 4 THEN 'SET' WHEN 5 THEN 'Temp' WHEN 6 THEN 'Remote'
      WHEN 7 THEN 'Browse' WHEN 8 THEN 'QN' WHEN 9 THEN 'MPI'
      WHEN 10 THEN 'Cursor' WHEN 11 THEN 'Manual' ELSE '' END Reason,
    CASE WHEN Sum(Compile)>0 THEN isnull(cast(Sum(rcDuration) as varchar),'?') ELSE '' END AS rcDuration,
    CASE WHEN Sum(Compile)>0 THEN isnull(cast(Sum(rcCPU) as varchar),'?') ELSE '' END AS rcCPU,
    Cast(Cast(XPlan as nvarchar(max)) as xml) XPlan
  FROM @Results
  WHERE EventClass IN (41,45)
  GROUP BY Nesting, ObjectName, LineNumber, TextData, EventClass, SubClass, Cast(XPlan as nvarchar(max))
  ORDER BY Min(CASE WHEN @order='' THEN ID END),
    Sum(CASE lower(@order) WHEN 'cpu' THEN CPU+IsNull(rcCPU,0)
       WHEN 'reads' THEN Reads
       WHEN 'writes' THEN Writes
       ELSE Duration+IsNull(rcDuration,0) END) DESC
END
