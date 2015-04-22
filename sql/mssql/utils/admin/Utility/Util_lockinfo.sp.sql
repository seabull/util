/*---------------------------------------------------------------------
  $Header: c:\\Repository/sql/mssql/utils/admin/Utility/Util_lockinfo.sp.sql,v 1.1 2010/10/20 16:10:27 a645276 Exp $

  This SP lists locking information for all active processes, that is
  processes that have a running request, is holding locks or have an
  open transaction. Information about all locked objects are included,
  as well the last command sent from the client and the currently
  running statement. The procedure also displays the blocking chain
  for blocked processes.

  Note that locks and processes are read independently from the DMVs, and
  may not be wholly in sync. Likewise, object names and DBCC INPUTBUFFER
  are run later.

  This version of the procedure is for SQL 2005 SP2 and later. For
  SQL 2005 SP1 and earlier versions, use aba_lockinfo instead.

  Parameters:
  @allprocesses - If 0, only include "interesting processes", i.e.
                  processes running something or holding locks. 1 - show
                  all processes.
  @textmode     - If 0, output is sent as-is, intended for grid mode.
                  If 1, output columns are trimmed the width derived from
                  data, and a blank line is inserted between spids.
  @procdata     - A - show process-common data on all rows. F - show
                  process-common data only on the first rows. Defaults
                  to A in text mode and F in grid mode.
  @debug        - If 1, prints progress messages with timings.

  $History: Util_LockInfo.sp $
 * 
 * *****************  Version 11  *****************
 * User: Sommar       Date: 09-01-31   Time: 20:01
 * Updated in $/WWW/sqlutil
 * 1) The procedure body now reads ALTER PROCEDURE, and the script creates
 * a dummy procedure if Util_LockInfo does not exist.
 * 2) Retrieving query texts separately, to handle the case that a process
 * creates a procedure within a transaction and then executes it without
 * committing the transaction. In this case Util_LockInfo gets blocked,
 * and we fall back to get texts spid by spid.
 *
 * *****************  Version 10  *****************
 * User: Sommar       Date: 09-01-10   Time: 22:18
 * Updated in $/WWW/sqlutil
 * Fixed bug that caused NULL violation when there was a lock on a dropped
 * allocatoin unit.
 *
 * *****************  Version 9  *****************
 * User: Sommar       Date: 08-11-04   Time: 21:51
 * Updated in $/WWW/sqlutil
 * Failed to consider that a lead blocker may be waiting too, if not for
 * another spid.
 *
 * *****************  Version 8  *****************
 * User: Sommar       Date: 08-11-03   Time: 23:30
 * Updated in $/WWW/sqlutil
 * 1) Incorrectly showed NULL in blkby when process was not blocked.
 * 2) When modifying the XML document for the plan, we need to consider
 * that our statement information may be NULL, or else .modify blows up.
 *
 * *****************  Version 7  *****************
 * User: Sommar       Date: 08-11-02   Time: 20:55
 * Updated in $/WWW/sqlutil
 * Reworked the block-chain handling,so that deadlocks are detected and
 * marked with DD in the block_chain column. We also find processes that
 * are blocked by the deadlocked processes. We now also mark processes
 * that waiting for a lock, but are not in the block_chain (because they
 * started waiting after we read dm_os_waiting_tasks.)
 *
 * *****************  Version 6  *****************
 * User: Sommar       Date: 08-11-01   Time: 22:13
 * Updated in $/WWW/sqlutil
 * 1) Work around bug in dm_exec_text_query_plan that causes bloat in the
 * return XML plan.
 * 2) Show database name for application locks.
 * 3) Show object_id directly when we cannot translate it.
 * 4) Return the statement text in full on the first row for a process
 * only.
 * 5) For some resource types, for instance METADATA there were two
 * identical lines displayed, because we incorrectly groupe on
 * rsc_description for other resource types than application locks.
 *
 * *****************  Version 5  *****************
 * User: Sommar       Date: 08-08-16   Time: 23:22
 * Updated in $/WWW/sqlutil
 * CRLF in text mode was replaced with the empty string, not spaces.
 *
 * *****************  Version 4  *****************
 * User: Sommar       Date: 08-08-16   Time: 23:13
 * Updated in $/WWW/sqlutil
 * 1) Run with a short lock-timeout when retrieving query plans. According
 * to SQL Server MVP Adam Machanic, this can occur. I'm therefore now
 * including the error message if the query plan cannot be retrieved.
 * 2) Error handling for DBCC INPUTBUFFER, as on SQL 2008 a missing spid
 * raises an error.
 *
 * *****************  Version 3  *****************
 * User: Sommar       Date: 07-12-09   Time: 23:15
 * Updated in $/WWW/sqlutil
 * 1] Implemented a workaround to avoid the problem with duplicates keys
 * that occur when the two tasks got the same execution context id.
 * 2) Also worked around a case where dm_os_waiting_tasks can include
 * duplicate rows.
 * 3) If a thread is only blocking other threads or requests in the same
 * thread, put the value in block_level in parentheses.
 * 4) Added an indicator in the blkby column on how many other tasks
 * that may be blocking.
 * 5) The spid string now uses slashes as delimiter. This is because that
 * use -1 indicate that a task was that was blocking had exited when
 * we merge the block chain with the processes.
 * 6) I'm now reading sys.dm_exec_sessions and related views more
 * directly after reading sys.dm_os_waiting_tasks to increase the odds
 * for a consistent view.
 *
 * *****************  Version 2  *****************
 * User: Sommar       Date: 07-11-18   Time: 20:49
 * Updated in $/WWW/sqlutil
 * 1) Adding error handling around INSERTs that are known to bomb on
 *    PK violation, and produce a debug output, so we can find out what is
 * going on.
 * 2) Added fallback for the possible case that the query plan is not
 *   convertible to XML. Kudos to SQL Server MVP Razvan Socol for
 *   giving me a test case.
 *
 * *****************  Version 1  *****************
 * User: Sommar       Date: 07-07-29   Time: 0:09
 * Created in $/WWW/sqlutil
  ---------------------------------------------------------------------*/
IF object_id('dbo.Util_LockInfo') IS NULL EXEC ('CREATE PROCEDURE dbo.Util_LockInfo AS PRINT 12')
go
ALTER PROCEDURE dbo.Util_LockInfo @allprocesses bit     = 0,
                              @textmode     bit     = 0,
                              @procdata     char(1) = NULL,
                              @debug        bit     = 0 AS

-- This table holds the information in sys.dm_tran_locks, aggregated
-- on a number of items. Note that we do not include subthreads or
-- requests in the aggregation.
DECLARE @locks TABLE (
   session_id      int  NOT NULL,
   req_mode        varchar(60)   COLLATE Latin1_General_BIN2 NOT NULL,
   rsc_type        varchar(60)   COLLATE Latin1_General_BIN2 NOT NULL,
   rsc_subtype     varchar(60)   COLLATE Latin1_General_BIN2 NOT NULL,
   req_status      varchar(60)   COLLATE Latin1_General_BIN2 NOT NULL,
   req_owner_type  varchar(60)   COLLATE Latin1_General_BIN2 NOT NULL,
   rsc_description nvarchar(256) COLLATE Latin1_General_BIN2 NULL,
   database_id     int      NOT NULL,
   entity_id       bigint   NULL,
   cnt             int      NOT NULL,
   activelock AS CASE WHEN rsc_type = 'DATABASE' AND
                           req_status = 'GRANT'
                      THEN convert(bit, 0)
                      ELSE convert(bit, 1)
                 END,
   ident          int IDENTITY PRIMARY KEY,
   rowno          int NULL     -- Set per session_id if @procdata is F.
)

-- This table holds the translation of entity_id in @locks. This is a
-- temp table since we access it from dynamic SQL. The type_desc is used
-- for allocation units.
CREATE TABLE #objects (
     idtype         char(4)       NOT NULL
                    CHECK (idtype IN ('OBJ', 'HOBT', 'AU', 'MISC')),
     database_id    int           NOT NULL,
     entity_id      bigint        NOT NULL,
     hobt_id        bigint        NULL,
     object_name    nvarchar(550) COLLATE Latin1_General_BIN2 NULL,
     type_desc      varchar(60)   COLLATE Latin1_General_BIN2 NULL,
     PRIMARY KEY CLUSTERED (database_id, idtype, entity_id),
     UNIQUE NONCLUSTERED (database_id, entity_id, idtype)
)

-- This table captures sys.dm_os_waiting_tasks and later augment it with
-- data about the block chain. A waiting task always has a always has a
-- task address, but the blocker may be idle and without a task.
-- All columns for the blocker are nullable, as we add extra rows for
-- non-waiting blockers.
DECLARE @dm_os_waiting_tasks TABLE
   (wait_session_id   smallint     NOT NULL,
    wait_task         varbinary(8) NOT NULL,
    block_session_id  smallint     NULL,
    block_task        varbinary(8) NULL,
    wait_type         varchar(60) COLLATE Latin1_General_BIN2  NULL,
    wait_duration_ms  bigint       NULL,
    -- The level in the chain. Level 0 is the lead blocker. NULL for
    -- tasks that are waiting, but not blocking.
    block_level       smallint     NULL,
    -- The lead blocker for this block chain.
    lead_blocker_spid smallint     NULL,
    -- Whether the block chain consists of the threads of the same spid only.
    blocksamespidonly bit         NOT NULL DEFAULT 0,
  UNIQUE CLUSTERED (wait_session_id, wait_task, block_session_id, block_task),
  UNIQUE (block_session_id, block_task, wait_session_id, wait_task)
)

-- This table holds information about all sessions and requests.
DECLARE @procs TABLE (
   session_id       smallint      NOT NULL,
   task_address     varbinary(8)  NOT NULL,
   exec_context_id  int           NOT NULL,
   request_id       int           NOT NULL,
   spidstr AS ltrim(str(session_id)) +
              CASE WHEN exec_context_id <> 0 OR request_id <> 0
                   THEN '/' + ltrim(str(exec_context_id)) +
                        '/' + ltrim(str(request_id))
                   ELSE ''
              END,
   is_user_process  bit           NOT NULL,
   orig_login       nvarchar(128) COLLATE Latin1_General_BIN2 NULL,
   current_login    nvarchar(128) COLLATE Latin1_General_BIN2 NULL,
   session_state    varchar(30)   COLLATE Latin1_General_BIN2 NOT NULL,
   task_state       varchar(60)   COLLATE Latin1_General_BIN2 NULL,
   proc_dbid        smallint      NULL,
   request_dbid     smallint      NULL,
   host_name        nvarchar(128) COLLATE Latin1_General_BIN2 NULL,
   host_process_id  int           NULL,
   endpoint_id      int           NOT NULL,
   program_name     nvarchar(128) COLLATE Latin1_General_BIN2 NULL,
   request_command  varchar(32)   COLLATE Latin1_General_BIN2 NULL,
   trancount        int           NOT NULL,
   session_cpu      int           NOT NULL,
   request_cpu      int           NULL,
   session_physio   bigint        NOT NULL,
   request_physio   bigint        NULL,
   session_logreads bigint        NOT NULL,
   request_logreads bigint        NULL,
   isclr            bit           NOT NULL DEFAULT 0,
   nest_level       int           NULL,
   now              datetime      NOT NULL,
   login_time       datetime      NOT NULL,
   last_batch       datetime      NOT NULL,
   last_since       decimal(10,3) NULL,
   curdbid          smallint      NULL,
   curobjid         int           NULL,
   current_stmt     nvarchar(MAX) COLLATE Latin1_General_BIN2 NULL,
   sql_handle       varbinary(64) NULL,
   plan_handle      varbinary(64) NULL,
   stmt_start       int           NULL,
   stmt_end         int           NULL,
   current_plan     xml           NULL,
   rowno            int           NOT NULL,
   block_level      tinyint       NULL,
   block_session_id smallint      NULL,
   block_exec_context_id int      NULL,
   block_request_id      int      NULL,
   blockercnt        int          NULL,
   block_spidstr AS ltrim(str(block_session_id)) +
               CASE WHEN block_exec_context_id <> 0 OR block_request_id <> 0
                    THEN '/' + ltrim(str(block_exec_context_id)) +
                         '/' + ltrim(str(block_request_id))
                    ELSE ''
               END +
               CASE WHEN blockercnt > 1
                    THEN ' (+' + ltrim(str(blockercnt - 1)) + ')'
                    ELSE ''
               END,
   blocksamespidonly bit          NOT NULL DEFAULT 0,
   waiter_no_blocker bit          NOT NULL DEFAULT 0,
   wait_type        varchar(60)   COLLATE Latin1_General_BIN2 NULL,
   wait_time        decimal(18,3) NULL,
   PRIMARY KEY (session_id, task_address))


-- Output from DBCC INPUTBUFFER. The IDENTITY column is there to make
-- it possible to add the spid later.
DECLARE @inputbuffer TABLE
       (eventtype    nvarchar(30)   NULL,
        params       int            NULL,
        inputbuffer  nvarchar(4000) NULL,
        ident        int            IDENTITY UNIQUE,
        spid         int            NOT NULL DEFAULT 0 PRIMARY KEY)

------------------------------------------------------------------------
-- Local variables.
------------------------------------------------------------------------
DECLARE @now             datetime,
        @ms              int,
        @spid            smallint,
        @rowc            int,
        @lvl             int,
        @dbname          sysname,
        @dbidstr         varchar(10),
        @stmt            nvarchar(MAX),
        @request_id      int,
        @handle          varbinary(64),
        @stmt_start      int,
        @stmt_end        int;

------------------------------------------------------------------------
-- Set up.
------------------------------------------------------------------------
-- All reads are dirty! The most important reason for this is tempdb.sys.objects.
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET NOCOUNT ON;

-- Processes below @minspid are system processes.
SELECT @now = getdate();

-- Validate the @procdata parameter, and set default.
IF @procdata IS NULL
   SELECT @procdata = CASE @textmode WHEN 1 THEN 'A' ELSE 'F' END
IF @procdata NOT IN ('A', 'F')
BEGIN
   RAISERROR('Invalid value for @procdata parameter. A and F are permitted', 16, 1)
   RETURN
END

-- If there is a request for textdata output, jump to the end where we call
-- ourselves non-texmode. (Ugly? Yes, having two procedures would be
-- prettier, but it's easier only have to distribute one.)
IF @textmode = 1 GOTO do_textmode

------------------------------------------------------------------------
-- First capture all locks. We aggregate by type, object etc to keep
-- down the volume.
------------------------------------------------------------------------
IF @debug = 1
BEGIN
   RAISERROR ('Compiling lock information, time 0 ms.', 0, 1) WITH NOWAIT
END;

-- We force binary collation, to make the GROUP BY operation faster.
WITH CTE AS (
   SELECT request_session_id,
          req_mode        = request_mode       COLLATE Latin1_General_BIN2,
          rsc_type        = resource_type      COLLATE Latin1_General_BIN2,
          rsc_subtype     = resource_subtype   COLLATE Latin1_General_BIN2,
          req_status      = request_status     COLLATE Latin1_General_BIN2,
          req_owner_type  = request_owner_type COLLATE Latin1_General_BIN2,
          rsc_description =
             CASE WHEN resource_type = 'APPLICATION'
                  THEN nullif(resource_description
                              COLLATE Latin1_General_BIN2, '')
             END,
          resource_database_id, resource_associated_entity_id
    FROM  sys.dm_tran_locks)
INSERT @locks (session_id, req_mode, rsc_type, rsc_subtype, req_status,
               req_owner_type, rsc_description,
               database_id, entity_id, cnt)
   SELECT request_session_id, req_mode, rsc_type, rsc_subtype, req_status,
          req_owner_type, rsc_description,
          resource_database_id, resource_associated_entity_id,
          COUNT(*)
   FROM   CTE
   GROUP  BY request_session_id, req_mode, rsc_type, rsc_subtype, req_status,
          req_owner_type, rsc_description,
          resource_database_id, resource_associated_entity_id

-----------------------------------------------------------------------
-- Get the blocking chain.
-----------------------------------------------------------------------
IF @debug = 1
BEGIN
   SELECT @ms = datediff(ms, @now, getdate())
   RAISERROR ('Determining blocking chain, time %d ms.', 0, 1, @ms) WITH NOWAIT
END

-- First capture sys.dm_os_waiting_tasks, skipping non-spid tasks. The
-- DISTINCT is needed, because there may be duplicates. (I've seen them.)
INSERT @dm_os_waiting_tasks (wait_session_id, wait_task, block_session_id,
                             block_task, wait_type, wait_duration_ms)
   SELECT DISTINCT
          owt.session_id, owt.waiting_task_address, owt.blocking_session_id,
          CASE WHEN owt.blocking_session_id IS NOT NULL
               THEN coalesce(owt.blocking_task_address, 0x)
          END, owt.wait_type, owt.wait_duration_ms
   FROM   sys.dm_os_waiting_tasks owt
   WHERE  owt.session_id IS NOT NULL;

------------------------------------------------------------------------
-- Then get the processes. We filter here for active processes once for all
------------------------------------------------------------------------
IF @debug = 1
BEGIN
   SELECT @ms = datediff(ms, @now, getdate())
   RAISERROR ('Collecting process information, time %d ms.', 0, 1, @ms) WITH NOWAIT
END

INSERT @procs(session_id, task_address,
              exec_context_id, request_id,
              is_user_process,
              current_login,
              orig_login,
              session_state, task_state, endpoint_id, proc_dbid, request_dbid,
              host_name, host_process_id, program_name, request_command,
              trancount,
              session_cpu, request_cpu,
              session_physio, request_physio,
              session_logreads, request_logreads,
              isclr, nest_level,
              now, login_time, last_batch,
              last_since,
              sql_handle, plan_handle,
              stmt_start, stmt_end,
              rowno)
   SELECT es.session_id, coalesce(ot.task_address, 0x),
          coalesce(ot.exec_context_id, 0), coalesce(er.request_id, 0),
          es.is_user_process,
          coalesce(nullif(es.login_name, ''), suser_sname(es.security_id)),
          coalesce(nullif(es.original_login_name, ''),
                   suser_sname(es.original_security_id)),
          es.status, ot.task_state, es.endpoint_id, sp.dbid, er.database_id,
          es.host_name, es.host_process_id, es.program_name, er.command,
          coalesce(er.open_transaction_count, sp.open_tran),
          es.cpu_time, er.cpu_time,
          es.reads + es.writes, er.reads + er.writes,
          es.logical_reads, er.logical_reads,
          coalesce(er.executing_managed_code, 0), er.nest_level,
          @now, es.login_time, es.last_request_start_time,
          CASE WHEN datediff(DAY, es.last_request_start_time, @now) > 20
               THEN NULL
               ELSE datediff(MS, es.last_request_start_time,  @now) / 1000.000
          END,
          er.sql_handle, er.plan_handle,
          er.statement_start_offset, er.statement_end_offset,
          rowno = row_number() OVER (PARTITION BY es.session_id
                                     ORDER BY ot.exec_context_id, er.request_id)
   FROM   sys.dm_exec_sessions es
   JOIN   (SELECT spid, dbid = MIN(dbid), open_tran = MIN(open_tran)
           FROM   sys.sysprocesses
           WHERE  ecid = 0
           GROUP  BY spid) AS sp ON sp.spid = es.session_id
   LEFT   JOIN sys.dm_os_tasks ot ON es.session_id = ot.session_id
   LEFT   JOIN sys.dm_exec_requests er ON ot.task_address = er.task_address
   WHERE  -- All processes requested
          @allprocesses > 0
          -- All user sessions with a running request save ourselevs.
      OR  ot.exec_context_id IS NOT NULL AND
          es.is_user_process = 1  AND
          es.session_id <> @@spid
          -- All sessions with an open transaction, even if they are idle.
     OR   sp.open_tran > 0 AND es.session_id <> @@spid
          -- All sessions that have an interesting lock, save ourselves.
     OR   EXISTS (SELECT *
                   FROM   @locks l
                   WHERE  l.session_id = es.session_id
                     AND  l.activelock = 1) AND es.session_id <> @@spid
          -- All sessions that is blocking someone.
     OR   EXISTS (SELECT *
                  FROM   @dm_os_waiting_tasks owt
                  WHERE  owt.block_session_id = es.session_id)

------------------------------------------------------------------------
-- Get input buffers. Note that we can only find one per session, even
-- a session has several requests.
-- We skip this part if @@nestlevel is > 1, as presumably we are calling
-- ourselves recursively from INSERT EXEC, and we may no not do another
-- level of INSERT-EXEC.
------------------------------------------------------------------------
IF @@nestlevel = 1
BEGIN
   IF @debug = 1
   BEGIN
      SELECT @ms = datediff(ms, @now, getdate())
      RAISERROR ('Getting input buffers, time %d ms.', 0, 1, @ms) WITH NOWAIT
   END

   DECLARE C1 CURSOR FAST_FORWARD LOCAL FOR
      SELECT DISTINCT session_id
      FROM   @procs
      WHERE  is_user_process = 1
   OPEN C1

   WHILE 1 = 1
   BEGIN
      FETCH C1 INTO @spid
      IF @@fetch_status <> 0
         BREAK

      BEGIN TRY
         INSERT @inputbuffer(eventtype, params, inputbuffer)
            EXEC sp_executesql N'DBCC INPUTBUFFER (@spid) WITH NO_INFOMSGS',
                               N'@spid int', @spid

         UPDATE @inputbuffer
         SET    spid = @spid
         WHERE  ident = scope_identity()
      END TRY
      BEGIN CATCH
         INSERT @inputbuffer(inputbuffer, spid)
            VALUES('Error getting inputbuffer: ' + error_message(), @spid)
      END CATCH
  END

   DEALLOCATE C1
END

-----------------------------------------------------------------------
-- Compute the blocking chain.
-----------------------------------------------------------------------
IF @debug = 1
BEGIN
   SELECT @ms = datediff(ms, @now, getdate())
   RAISERROR ('Computing blocking chain, time %d ms.', 0, 1, @ms) WITH NOWAIT
END

-- Mark blockers that are waiting, that is waiting for something else
-- than another spid.
UPDATE @dm_os_waiting_tasks
SET    block_level = 0,
       lead_blocker_spid = a.wait_session_id
FROM   @dm_os_waiting_tasks a
WHERE  a.block_session_id IS NULL
  AND  EXISTS (SELECT *
               FROM   @dm_os_waiting_tasks b
               WHERE  a.wait_session_id = b.block_session_id
                 AND  a.wait_task       = b.block_task)
SELECT @rowc = @@rowcount

-- Add an extra row for blockers that are not waiting at all.
INSERT @dm_os_waiting_tasks (wait_session_id, wait_task,
                             block_level, lead_blocker_spid)
   SELECT DISTINCT a.block_session_id, coalesce(a.block_task, 0x),
                   0, a.block_session_id
   FROM   @dm_os_waiting_tasks a
   WHERE  NOT EXISTS (SELECT *
                      FROM  @dm_os_waiting_tasks b
                      WHERE a.block_session_id = b.wait_session_id
                        AND a.block_task       = b.wait_task)
     AND  a.block_session_id IS NOT NULL;

SELECT @rowc = @rowc + @@rowcount, @lvl = 0

-- Then iterate as long as we find blocked processes. You may think
-- that a recursive CTE would be great here, but we want to exclude
-- rows that has already been marked. This is difficult to do with a CTE.
WHILE @rowc > 0
BEGIN
   UPDATE a
   SET    block_level = b.block_level + 1,
          lead_blocker_spid = b.lead_blocker_spid
   FROM   @dm_os_waiting_tasks a
   JOIN   @dm_os_waiting_tasks b ON a.block_session_id = b.wait_session_id
                                AND a.block_task       = b.wait_task
   WHERE  b.block_level = @lvl
     AND  a.block_level IS NULL

  SELECT @rowc = @@rowcount, @lvl = @lvl + 1
END

-- Next to find are processes that are blocked, but no one is waiting for.
-- They are directly or indirectly blocked by a deadlock. They get a
-- negative level initially. We clean this up later.
UPDATE @dm_os_waiting_tasks
SET    block_level = -1
FROM   @dm_os_waiting_tasks a
WHERE  a.block_level IS NULL
  AND  a.block_session_id IS NOT NULL
  AND  NOT EXISTS (SELECT *
                   FROM   @dm_os_waiting_tasks b
                   WHERE  b.block_session_id = a.wait_session_id
                     AND  b.block_task       = a.wait_task)

SELECT @rowc = @@rowcount, @lvl = -2

-- Then unwind these chains in the opposite direction to before.
WHILE @rowc > 0
BEGIN
   UPDATE @dm_os_waiting_tasks
   SET    block_level = @lvl
   FROM   @dm_os_waiting_tasks a
   WHERE  a.block_level IS NULL
     AND  a.block_session_id IS NOT NULL
     AND  NOT EXISTS (SELECT *
                      FROM   @dm_os_waiting_tasks b
                      WHERE  b.block_session_id = a.wait_session_id
                        AND  b.block_task       = a.wait_task
                        AND  b.block_level IS NULL)
   SELECT @rowc = @@rowcount, @lvl = @lvl - 1
END

-- Determine which blocking tasks that only block tasks within the same
-- spid.
UPDATE @dm_os_waiting_tasks
SET    blocksamespidonly = 1
FROM   @dm_os_waiting_tasks a
WHERE  a.block_level IS NOT NULL
  AND  a.wait_session_id = a.lead_blocker_spid
  AND  NOT EXISTS (SELECT *
                   FROM   @dm_os_waiting_tasks b
                   WHERE  a.wait_session_id = b.lead_blocker_spid
                     AND  a.wait_session_id <> b.wait_session_id)

-----------------------------------------------------------------------
-- Add block-chain and wait information to @procs. If a blockee has more
-- than one blocker, we pick one.
-----------------------------------------------------------------------
IF @debug = 1
BEGIN
   SELECT @ms = datediff(ms, @now, getdate())
   RAISERROR ('Adding blocking chain to @procs, time %d ms.', 0, 1, @ms) WITH NOWAIT
END

; WITH block_chain AS (
    SELECT wait_session_id, wait_task, block_session_id, block_task,
           block_level = CASE WHEN block_level >= 0 THEN block_level
                              ELSE block_level - @lvl - 1
                         END,
    wait_duration_ms, wait_type, blocksamespidonly,
    cnt   = COUNT(*) OVER (PARTITION BY wait_task),
    rowno = row_number() OVER (PARTITION BY wait_task
                               ORDER BY block_level, block_task)
    FROM @dm_os_waiting_tasks
)
UPDATE p
SET    block_level           = bc.block_level,
       block_session_id      = bc.block_session_id,
       block_exec_context_id = coalesce(p2.exec_context_id, -1),
       block_request_id      = coalesce(p2.request_id, -1),
       blockercnt            = bc.cnt,
       blocksamespidonly     = bc.blocksamespidonly,
       wait_time             = convert(decimal(18, 3), bc.wait_duration_ms) / 1000,
       wait_type             = bc.wait_type
FROM   @procs p
JOIN   block_chain bc ON p.session_id   = bc.wait_session_id
                     AND p.task_address = bc.wait_task
                     AND bc.rowno = 1
LEFT   JOIN @procs p2 ON bc.block_session_id = p2.session_id
                     AND bc.block_task       = p2.task_address

--------------------------------------------------------------------
-- Delete "uninteresting" locks from @locks for processes not in @procs.
--------------------------------------------------------------------
IF @allprocesses = 0
BEGIN
   IF @debug = 1
   BEGIN
      SELECT @ms = datediff(ms, @now, getdate())
      RAISERROR ('Deleting uninteresting locks, time %d ms.', 0, 1, @ms) WITH NOWAIT
   END

   DELETE @locks
   FROM   @locks l
   WHERE  (activelock = 0 OR session_id = @@spid)
     AND  NOT EXISTS (SELECT *
                      FROM   @procs p
                      WHERE  p.session_id = l.session_id)
END

-----------------------------------------------------------------------
-- Get object names from ids in @procs and @locks. You may think that
-- we could use object_name and its second database parameter, but
-- object_name takes out a Sch-S lock (even with READ UNCOMMITTED) and
-- gets blocked if a object (read temp table) has been created in a transaction.
-----------------------------------------------------------------------
IF @debug = 1
BEGIN
   SELECT @ms = datediff(ms, @now, getdate())
   RAISERROR ('Getting object names, time %d ms.', 0, 1, @ms) WITH NOWAIT
END

-- First get all entity ids into the temp table. We can translate
-- object ids now. And we save the database name as a fallback for
-- those where do not translate more. Yes, we save the entity id twice.
INSERT #objects (idtype, database_id, entity_id, hobt_id)
   SELECT DISTINCT
          CASE WHEN rsc_type = 'OBJECT' THEN 'OBJ'
               WHEN rsc_type IN ('PAGE', 'KEY', 'RID', 'HOBT') THEN 'HOBT'
               WHEN rsc_type = 'ALLOCATION_UNIT' THEN 'AU'
               ELSE 'MISC'
          END,
          database_id, entity_id, entity_id
   FROM   @locks
   WHERE  rsc_type IN ('PAGE', 'KEY', 'RID', 'HOBT', 'ALLOCATION_UNIT',
                       'OBJECT')
   UNION
   SELECT DISTINCT 'OBJ', curdbid, curobjid, curobjid
   FROM   @procs
   WHERE  curdbid IS NOT NULL
     AND  curobjid IS NOT NULL


DECLARE C2 CURSOR STATIC LOCAL FOR
   SELECT DISTINCT str(database_id),
                   quotename(db_name(database_id))
   FROM   #objects
   WHERE  idtype IN  ('OBJ', 'HOBT', 'AU')
   OPTION (KEEPFIXED PLAN)

OPEN C2

WHILE 1 = 1
BEGIN
   FETCH C2 INTO @dbidstr, @dbname
   IF @@fetch_status <> 0
      BREAK

   -- First handle allocation units. They bring us a hobt_id, or we go
   -- directly to the object when the container is a partition_id. We
   -- always get the type_desc. To make the dynamic SQL easier to read,
   -- we use some placeholders.
   SELECT @stmt = '
      UPDATE #objects
      SET    type_desc = au.type_desc,
             hobt_id   = CASE WHEN au.type IN (1, 3)
                              THEN au.container_id
                         END,
             idtype    = CASE WHEN au.type IN (1, 3)
                              THEN "HOBT"
                              ELSE "AU"
                         END,
             object_name = CASE WHEN au.type = 2 THEN
                              db_name(@dbidstr) + "." +
                              s.name + "." + o.name +
                              CASE WHEN p.index_id <= 1
                                   THEN ""
                                   ELSE "." + i.name
                              END +
                              CASE WHEN p.partition_number > 1
                                   THEN "(" +
                                         ltrim(str(p.partition_number)) +
                                        ")"
                                   ELSE ""
                              END
                              WHEN au.type = 0 THEN
                                 db_name(@dbidstr) + " (dropped table et al)"
                           END
      FROM   #objects ob
      JOIN   @dbname.sys.allocation_units au ON ob.entity_id = au.allocation_unit_id
      -- We should only go all the way from sys.partitions, for type = 3.
      LEFT   JOIN  (@dbname.sys.partitions p
                    JOIN    @dbname.sys.objects o ON p.object_id = o.object_id
                    JOIN    @dbname.sys.indexes i ON p.object_id = i.object_id
                                                 AND p.index_id  = i.index_id
                    JOIN    @dbname.sys.schemas s ON o.schema_id = s.schema_id)
         ON  au.container_id = p.partition_id
        AND  au.type = 2
      WHERE  ob.database_id = @dbidstr
        AND  ob.idtype = "AU"
      OPTION (KEEPFIXED PLAN);
   '

   -- Now we can translate all hobt_id, including those we got from the
   -- allocation units.
   SELECT @stmt = @stmt + '
      UPDATE #objects
      SET    object_name = db_name(@dbidstr) + "." + s.name + "." + o.name +
                           CASE WHEN p.index_id <= 1
                                THEN ""
                                ELSE "." + i.name
                           END +
                           CASE WHEN p.partition_number > 1
                                THEN "(" +
                                      ltrim(str(p.partition_number)) +
                                     ")"
                                ELSE ""
                           END + coalesce(" (" + ob.type_desc + ")", "")
      FROM   #objects ob
      JOIN   @dbname.sys.partitions p ON ob.hobt_id  = p.hobt_id
      JOIN   @dbname.sys.objects o    ON p.object_id = o.object_id
      JOIN   @dbname.sys.indexes i    ON p.object_id = i.object_id
                                     AND p.index_id  = i.index_id
      JOIN   @dbname.sys.schemas s    ON o.schema_id = s.schema_id
      WHERE  ob.database_id = @dbidstr
        AND  ob.idtype = "HOBT"
      OPTION (KEEPFIXED PLAN)
      '

   -- And now object ids, idtype = OBJ.
   SELECT @stmt = @stmt + '
      UPDATE #objects
      SET    object_name = db_name(@dbidstr) + "." +
                           coalesce(s.name + "." + o.name,
                                    "<" + ltrim(str(ob.entity_id)) + ">")
      FROM   #objects ob
      LEFT   JOIN   (@dbname.sys.objects o
                     JOIN @dbname.sys.schemas s ON o.schema_id = s.schema_id)
             ON convert(int, ob.entity_id) = o.object_id
      WHERE  ob.database_id = @dbidstr
        AND  ob.idtype = "OBJ"
      OPTION (KEEPFIXED PLAN)
   '

   -- Fix the placeholders.
   SELECT @stmt = replace(replace(replace(@stmt,
                         '"', ''''),
                         '@dbname', @dbname),
                         '@dbidstr', @dbidstr)

   --  And run the beast.
   --PRINT @stmt
   EXEC (@stmt)
END
DEALLOCATE C2

----------------------------------------------------------------------
-- Get the query text. This is not done in the main query, as we could
-- be blocked if someone is creating an SP and executes it in a
-- transaction.
----------------------------------------------------------------------
IF @@nestlevel = 1
BEGIN
   IF @debug = 1
   BEGIN
      SELECT @ms = datediff(ms, @now, getdate())
      RAISERROR ('Retrieving current statement, time %d ms.', 0, 1, @ms) WITH NOWAIT
   END

   -- Set lock timeout to avoid being blocked.
   SET LOCK_TIMEOUT 5

   -- First try to get all query plans in one go.
   BEGIN TRY
      UPDATE @procs
      SET    curdbid      = est.dbid,
             curobjid     = est.objectid,
             current_stmt =
             CASE WHEN est.encrypted = 1
                  THEN '-- ENCRYPTED, pos ' +
                       ltrim(str((p.stmt_start + 2)/2)) + ' - ' +
                       ltrim(str((p.stmt_end + 2)/2))
                  WHEN p.stmt_start >= 0
                  THEN substring(est.text, (p.stmt_start + 2)/2,
                                 CASE p.stmt_end
                                      WHEN -1 THEN datalength(est.text)
                                    ELSE (p.stmt_end - p.stmt_start + 2) / 2
                                 END)
             END
      FROM   @procs p
      CROSS  APPLY sys.dm_exec_sql_text(p.sql_handle) est
   END TRY
   BEGIN CATCH
      -- If this fails, try to get the texts one by one.
      DECLARE text_cur CURSOR STATIC LOCAL FOR
         SELECT DISTINCT session_id, request_id, sql_handle,
                         stmt_start, stmt_end
         FROM   @procs
         WHERE  sql_handle IS NOT NULL
      OPEN text_cur

      WHILE 1 = 1
      BEGIN
         FETCH text_cur INTO @spid, @request_id, @handle,
                             @stmt_start, @stmt_end
         IF @@fetch_status <> 0
            BREAK

         BEGIN TRY
            UPDATE @procs
            SET    curdbid      = est.dbid,
                   curobjid     = est.objectid,
                   current_stmt =
                   CASE WHEN est.encrypted = 1
                        THEN '-- ENCRYPTED, pos ' +
                             ltrim(str((p.stmt_start + 2)/2)) + ' - ' +
                             ltrim(str((p.stmt_end + 2)/2))
                        WHEN p.stmt_start >= 0
                        THEN substring(est.text, (p.stmt_start + 2)/2,
                                       CASE p.stmt_end
                                            WHEN -1 THEN datalength(est.text)
                                          ELSE (p.stmt_end - p.stmt_start + 2) / 2
                                       END)
                   END
            FROM   @procs p
            CROSS  APPLY sys.dm_exec_sql_text(p.sql_handle) est
            WHERE  p.session_id = @spid
              AND  p.request_id = @request_id
         END TRY
         BEGIN CATCH
             UPDATE @procs
             SET    current_stmt = 'ERROR: *** ' + error_message() + ' ***'
             WHERE  session_id = @spid
               AND  request_id = @request_id
         END CATCH
      END

      DEALLOCATE text_cur

      END CATCH

   SET LOCK_TIMEOUT 0
END


--------------------------------------------------------------------
-- Get query plans. The difficult part is that the convert to xml may
-- fail if the plan is too deep. Therefore we catch this error, and
-- resort to a cursor in this case. Since query plans are not included
-- in text mode, we skip if @nestlevel is > 1.
--------------------------------------------------------------------
IF @@nestlevel = 1
BEGIN
   IF @debug = 1
   BEGIN
      SELECT @ms = datediff(ms, @now, getdate())
      RAISERROR ('Retrieving query plans, time %d ms.', 0, 1, @ms) WITH NOWAIT
   END

   -- Adam says that getting the query plans can time out too...
   SET LOCK_TIMEOUT 5

   BEGIN TRY
      UPDATE @procs
      SET    current_plan = convert(xml, etqp.query_plan)
      FROM   @procs p
      OUTER  APPLY sys.dm_exec_text_query_plan(
                   p.plan_handle, p.stmt_start, p.stmt_end) etqp
      WHERE  p.plan_handle IS NOT NULL
   END TRY
   BEGIN CATCH
      DECLARE plan_cur CURSOR STATIC LOCAL FOR
         SELECT DISTINCT session_id, request_id, plan_handle,
                         stmt_start, stmt_end
         FROM   @procs
         WHERE  plan_handle IS NOT NULL
      OPEN plan_cur

      WHILE 1 = 1
      BEGIN
         FETCH plan_cur INTO @spid, @request_id, @handle,
                             @stmt_start, @stmt_end
         IF @@fetch_status <> 0
            BREAK

         BEGIN TRY
            UPDATE @procs
            SET    current_plan = (SELECT convert(xml, etqp.query_plan)
                                   FROM   sys.dm_exec_text_query_plan(
                                      @handle, @stmt_start, @stmt_end) etqp)
            FROM   @procs p
            WHERE  p.session_id = @spid
              AND  p.request_id = @request_id
         END TRY
         BEGIN CATCH
            UPDATE @procs
            SET    current_plan =
                     (SELECT 'Could not get query plan' AS [@alert],
                             error_number() AS [@errno],
                             error_severity() AS [@level],
                             error_message() AS [@errmsg]
                      FOR    XML PATH('ERROR'))
            WHERE  session_id = @spid
              AND  request_id = @request_id
         END CATCH
      END

      DEALLOCATE plan_cur
   END CATCH

   SET LOCK_TIMEOUT 0

   -- There is a bug in dm_exec_text_query_plan which causes the attribute
   -- StatementText to include the full text of the batch up to current
   -- statement. This causes bloat in SSMS. Whence we fix the attribute.
   ; WITH XMLNAMESPACES(
      'http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS SP)
   UPDATE @procs
   SET    current_plan.modify('
            replace value of (
                  /SP:ShowPlanXML/SP:BatchSequence/SP:Batch/
                   SP:Statements/SP:StmtSimple/@StatementText)[1]
            with
               substring((/SP:ShowPlanXML/SP:BatchSequence/SP:Batch/
                         SP:Statements/SP:StmtSimple/@StatementText)[1],
                        (sql:column("stmt_start") + 2) div 2)
          ')
   WHERE  current_plan IS NOT NULL
     AND  stmt_start IS NOT NULL
END

--------------------------------------------------------------------
-- If user has selected to see process data only on the first row,
-- we should number the rows in @locks.
--------------------------------------------------------------------
IF @procdata = 'F'
BEGIN
   IF @debug = 1
   BEGIN
      SELECT @ms = datediff(ms, @now, getdate())
      RAISERROR ('Determining first row, time %d ms.', 0, 1, @ms) WITH NOWAIT
   END

   UPDATE @locks
   SET    rowno = b.rowno
   FROM   @locks a
   JOIN   (SELECT l.ident,
                  rowno = row_number() OVER(PARTITION BY l.session_id
                    ORDER BY CASE l.req_status
                                  WHEN 'GRANT' THEN 'ZZZZ'
                                  ELSE l.req_status
                             END, o.object_name, l.rsc_type, l.rsc_description)
           FROM   @locks l
           LEFT   JOIN   #objects o ON l.database_id = o.database_id
                                   AND l.entity_id   = o.entity_id) AS b
          ON a.ident = b.ident
  OPTION (KEEPFIXED PLAN)
END

---------------------------------------------------------------------
-- Before we can join in the locks, we need to make sure that all
-- processes with a running request has a row with exec_context_id =
-- request_id = 0. (Those without already has such a row.)
---------------------------------------------------------------------
IF @debug = 1
BEGIN
   SELECT @ms = datediff(ms, @now, getdate())
   RAISERROR ('Supplementing @procs, time %d ms.', 0, 1, @ms) WITH NOWAIT
END

INSERT @procs(session_id, task_address, exec_context_id, request_id,
              is_user_process, orig_login, current_login,
              session_state, endpoint_id, trancount, proc_dbid,
              host_name, host_process_id, program_name,
              session_cpu, session_physio, session_logreads,
              now, login_time, last_batch, last_since, rowno)
   SELECT session_id, 0x, 0, 0,
          is_user_process, orig_login, current_login,
          session_state, endpoint_id, 0, proc_dbid,
          host_name, host_process_id, program_name,
          session_cpu, session_physio, session_logreads,
          now, login_time, last_batch, last_since, 0
    FROM  @procs a
    WHERE a.rowno = 1
      AND NOT EXISTS (SELECT *
                      FROM   @procs b
                      WHERE  b.session_id      = a.session_id
                        AND  b.exec_context_id = 0
                        AND  b.request_id      = 0)

-- A process may be waiting for a lock according sys.dm_os_tran_locks,
-- but it was not in sys.dm_os_waiting_tasks. Let's mark this up.
UPDATE @procs
SET    waiter_no_blocker = 1
FROM   @procs p
WHERE  EXISTS (SELECT *
               FROM   @locks l
               WHERE  l.req_status = 'WAIT'
                 AND  l.session_id = p.session_id
                 AND  NOT EXISTS (SELECT *
                                  FROM   @procs p2
                                  WHERE  p.session_id = l.session_id))

------------------------------------------------------------------------
-- For Plain results we are ready to return now.
------------------------------------------------------------------------
IF @debug = 1
BEGIN
   SELECT @ms = datediff(ms, @now, getdate())
   RAISERROR ('Returning result set, time %d ms.', 0, 1, @ms) WITH NOWAIT
END

IF @textmode = 0
BEGIN
   -- Note that the query is a full join, since @locks and @procs may not
   -- be in sync. Processes may gone away, or be active without any locks.
   SELECT spid        = coalesce(p.spidstr, ltrim(str(l.session_id))),
          command     = CASE WHEN coalesce(p.exec_context_id, 0) = 0 AND
                                  coalesce(l.rowno, 1) = 1
                             THEN p.request_command
                             ELSE ''
                        END,
          login       = CASE WHEN coalesce(p.exec_context_id, 0) = 0 AND
                                  coalesce(l.rowno, 1) = 1
                             THEN
                             CASE WHEN p.is_user_process = 0
                                  THEN 'SYSTEM PROCESS'
                                  ELSE p.orig_login +
                                     CASE WHEN p.current_login <> p.orig_login OR
                                               p.orig_login IS NULL
                                          THEN ' (' + p.current_login + ')'
                                          ELSE ''
                                     END
                            END
                            ELSE ''
                        END,
          host        = CASE WHEN coalesce(p.exec_context_id, 0)= 0 AND
                                  coalesce(l.rowno, 1) = 1
                             THEN p.host_name
                             ELSE ''
                        END,
          hostprc     = CASE WHEN coalesce(p.exec_context_id, 0) = 0 AND
                                  coalesce(l.rowno, 1) = 1
                             THEN ltrim(str(p.host_process_id))
                             ELSE ''
                        END,
          endpoint    = CASE WHEN coalesce(p.exec_context_id, 0) = 0 AND
                                  coalesce(l.rowno, 1) = 1
                             THEN e.name
                             ELSE ''
                        END,
          appl        = CASE WHEN coalesce(p.exec_context_id, 0) = 0 AND
                                  coalesce(l.rowno, 1) = 1
                             THEN p.program_name
                             ELSE ''
                        END,
          dbname      = CASE WHEN coalesce(l.rowno, 1) = 1 AND
                                  coalesce(p.exec_context_id, 0) = 0
                             THEN coalesce(db_name(p.request_dbid),
                                           db_name(p.proc_dbid))
                             ELSE ''
                        END,
          prcstatus   = CASE WHEN coalesce(l.rowno, 1) = 1
                             THEN coalesce(p.task_state, p.session_state)
                             ELSE ''
                        END,
          spid_       = p.spidstr,
          opntrn      = CASE WHEN p.exec_context_id = 0
                             THEN coalesce(ltrim(str(nullif(p.trancount, 0))), '')
                             ELSE ''
                        END,
          blklvl      = CASE WHEN p.block_level IS NOT NULL
                             THEN CASE p.blocksamespidonly
                                       WHEN 1 THEN '('
                                       ELSE ''
                                  END +
                                  CASE WHEN p.block_level = 0
                                       THEN '!!'
                                       ELSE ltrim(str(p.block_level))
                                  END +
                                  CASE p.blocksamespidonly
                                       WHEN 1 THEN ')'
                                       ELSE ''
                                  END
                             -- If the process is blocked, but we do not
                             -- have a block level, the process is in a
                             -- dead lock.
                             WHEN p.block_session_id IS NOT NULL
                             THEN 'DD'
                             WHEN p.waiter_no_blocker = 1
                             THEN '??'
                             ELSE ''
                        END,
          blkby       = coalesce(p.block_spidstr, ''),
          cnt         = CASE WHEN p.exec_context_id = 0 AND
                                  p.request_id = 0
                             THEN coalesce(ltrim(str(l.cnt)), '0')
                             ELSE ''
                        END,
          object      = CASE l.rsc_type
                           WHEN 'APPLICATION'
                           THEN coalesce(db_name(l.database_id) + '|', '') +
                                         l.rsc_description
                           ELSE coalesce(o2.object_name,
                                         db_name(l.database_id), '')
                        END,
          rsctype     = coalesce(l.rsc_type, ''),
          locktype    = coalesce(l.req_mode, ''),
          lstatus     = CASE l.req_status
                             WHEN 'GRANT' THEN lower(l.req_status)
                             ELSE coalesce(l.req_status, '')
                        END,
          ownertype   = CASE l.req_owner_type
                             WHEN 'SHARED_TRANSACTION_WORKSPACE' THEN 'STW'
                             ELSE coalesce(l.req_owner_type, '')
                        END,
          rscsubtype  = coalesce(l.rsc_subtype, ''),
          waittime    = CASE WHEN coalesce(l.rowno, 1) = 1
                             THEN coalesce(ltrim(str(p.wait_time, 18, 3)), '')
                             ELSE ''
                        END,
          waittype    = CASE WHEN coalesce(l.rowno, 1) = 1
                             THEN coalesce(p.wait_type, '')
                             ELSE ''
                        END,
          spid__      = p.spidstr,
          cpu         = CASE WHEN p.exec_context_id = 0 AND
                                  coalesce(l.rowno, 1) = 1
                             THEN coalesce(ltrim(str(p.session_cpu)), '') +
                             CASE WHEN p.request_cpu IS NOT NULL
                                  THEN ' (' + ltrim(str(p.request_cpu)) + ')'
                                  ELSE ''
                             END
                             ELSE ''
                        END,
          physio      = CASE WHEN p.exec_context_id = 0 AND
                                  coalesce(l.rowno, 1) = 1
                             THEN coalesce(ltrim(str(p.session_physio, 18)), '') +
                             CASE WHEN p.request_physio IS NOT NULL
                                  THEN ' (' + ltrim(str(p.request_physio)) + ')'
                                  ELSE ''
                             END
                             ELSE ''
                        END,
          logreads    = CASE WHEN p.exec_context_id = 0 AND
                                  coalesce(l.rowno, 1) = 1
                             THEN coalesce(ltrim(str(p.session_logreads, 18)), '')  +
                             CASE WHEN p.request_logreads IS NOT NULL
                                  THEN ' (' + ltrim(str(p.request_logreads)) + ')'
                                  ELSE ''
                             END
                             ELSE ''
                        END,
          now         = CASE WHEN p.exec_context_id = 0 AND
                                  coalesce(l.rowno, 1) = 1
                             THEN convert(char(12), p.now, 114)
                             ELSE ''
                        END,
          login_time  = CASE WHEN p.exec_context_id = 0 AND
                                  coalesce(l.rowno, 1) = 1
                             THEN
                             CASE datediff(DAY, p.login_time, @now)
                                  WHEN 0
                                  THEN convert(varchar(8), p.login_time, 8)
                                  ELSE convert(char(7), p.login_time, 12) +
                                       convert(varchar(8), p.login_time, 8)
                             END
                             ELSE ''
                        END,
          last_batch  = CASE WHEN p.exec_context_id = 0 AND
                                  coalesce(l.rowno, 1) = 1
                             THEN
                             CASE datediff(DAY, p.last_batch, @now)
                                  WHEN 0
                                  THEN convert(varchar(8),
                                               p.last_batch, 8)
                                  ELSE convert(char(7), p.last_batch, 12) +
                                       convert(varchar(8), p.last_batch, 8)
                             END
                             ELSE ''
                        END,
          last_since  = CASE WHEN p.exec_context_id = 0 AND
                                  coalesce(l.rowno, 1) = 1
                             THEN str(p.last_since, 11, 3)
                             ELSE ''
                        END,
          clr         = CASE WHEN p.exec_context_id = 0 AND p.isclr = 1
                             THEN 'CLR'
                             ELSE ''
                        END,
          nstlvl      = CASE WHEN p.exec_context_id = 0 AND
                                  coalesce(l.rowno, 1) = 1
                             THEN coalesce(ltrim(str(p.nest_level)), '')
                             ELSE ''
                        END,
          inputbuffer = CASE WHEN p.exec_context_id = 0 AND
                                  coalesce(l.rowno, 1) = 1
                             THEN coalesce(i.inputbuffer, '')
                             ELSE ''
                        END,
          current_sp  = coalesce(o1.object_name, ''),
          curstmt     = CASE WHEN coalesce(l.rowno, 1) = 1
                             THEN coalesce(p.current_stmt, '')
                             ELSE coalesce(substring(
                                        p.current_stmt, 1, 50), '')
                        END,
          current_plan = CASE WHEN p.exec_context_id = 0 AND
                                   coalesce(l.rowno, 1) = 1
                              THEN p.current_plan
                         END
   FROM   @procs p
   LEFT   JOIN #objects o1 ON p.curdbid  = o1.database_id
                          AND p.curobjid = o1.entity_id
   LEFT   JOIN @inputbuffer i ON p.session_id = i.spid
                             AND p.exec_context_id = 0
   LEFT   JOIN sys.endpoints e ON p.endpoint_id = e.endpoint_id
   FULL   JOIN (@locks l
               LEFT JOIN #objects o2 ON l.database_id = o2.database_id
                                    AND l.entity_id   = o2.entity_id)
     ON    p.session_id      = l.session_id
    AND    p.exec_context_id = 0
    AND    p.request_id      = 0
   ORDER BY coalesce(p.session_id, l.session_id),
            p.exec_context_id, coalesce(nullif(p.request_id, 0), 99999999),
            l.rowno, lstatus,
            coalesce(o2.object_name, db_name(l.database_id)),
            l.rsc_type, l.rsc_description
   OPTION (KEEPFIXED PLAN)
END
ELSE
BEGIN
do_textmode:
   ------------------------------------------------------------------------
   -- For textmode result, we run ourselves in gridmode, receiving the
   -- result into a temp table.
   ------------------------------------------------------------------------

   CREATE TABLE #textmode(
          ident       int            IDENTITY,
          spid        varchar(30)    COLLATE Latin1_General_BIN2 NOT NULL,
          command     varchar(32)    COLLATE Latin1_General_BIN2 NULL,
          login       sysname        COLLATE Latin1_General_BIN2 NULL,
          host        nvarchar(128)  COLLATE Latin1_General_BIN2 NULL,
          hostprc     varchar(10)    COLLATE Latin1_General_BIN2 NULL,
          endpoint    sysname        COLLATE Latin1_General_BIN2 NULL,
          appl        nvarchar(128)  COLLATE Latin1_General_BIN2 NULL,
          dbname      sysname        COLLATE Latin1_General_BIN2 NULL,
          prcstatus   varchar(60)    COLLATE Latin1_General_BIN2 NULL,
          spid_       varchar(30)    COLLATE Latin1_General_BIN2 NULL,
          opntrn      varchar(10)    COLLATE Latin1_General_BIN2 NULL,
          blklvl      char(3)        COLLATE Latin1_General_BIN2 NULL,
          blkby       varchar(30)    COLLATE Latin1_General_BIN2 NULL,
          cnt         varchar(10)    COLLATE Latin1_General_BIN2 NULL,
          object      nvarchar(520)  COLLATE Latin1_General_BIN2 NULL,
          rsctype     varchar(60)   COLLATE Latin1_General_BIN2 NULL,
          locktype    varchar(60)   COLLATE Latin1_General_BIN2 NULL,
          lstatus     varchar(60)   COLLATE Latin1_General_BIN2 NULL,
          ownertype   varchar(60)   COLLATE Latin1_General_BIN2 NULL,
          rscsubtype  varchar(60)   COLLATE Latin1_General_BIN2 NULL,
          waittime    varchar(16)    COLLATE Latin1_General_BIN2 NULL,
          waittype    varchar(60)    COLLATE Latin1_General_BIN2 NULL,
          spid__      varchar(30)    COLLATE Latin1_General_BIN2 NULL,
          cpu         varchar(30)    COLLATE Latin1_General_BIN2 NULL,
          physio      varchar(50)    COLLATE Latin1_General_BIN2 NULL,
          logreads    varchar(50)    COLLATE Latin1_General_BIN2 NULL,
          now         char(12)       COLLATE Latin1_General_BIN2 NULL,
          login_time  varchar(16)    COLLATE Latin1_General_BIN2 NULL,
          last_batch  varchar(16)    COLLATE Latin1_General_BIN2 NULL,
          last_since  varchar(11)    COLLATE Latin1_General_BIN2 NULL,
          clr         char(3)        COLLATE Latin1_General_BIN2 NULL,
          nstlvl      char(3)        COLLATE Latin1_General_BIN2 NULL,
          inputbuffer nvarchar(4000) COLLATE Latin1_General_BIN2 NULL,
          current_sp  nvarchar(400)  COLLATE Latin1_General_BIN2 NULL,
          curstmt     nvarchar(MAX)  COLLATE Latin1_General_BIN2 NULL,
          queryplan   xml            NULL,
          last        bit            NOT NULL DEFAULT 0)

   -- Do the recursive call.
   INSERT #textmode (spid, command, login, host, hostprc, endpoint, appl,
                     dbname, prcstatus, spid_, opntrn, blklvl, blkby, cnt,
                     object, rsctype, locktype, lstatus, ownertype,
                     rscsubtype, waittime, waittype, spid__, cpu, physio,
                     logreads, now, login_time, last_batch, last_since, clr,
                     nstlvl, inputbuffer, current_sp, curstmt, queryplan)
      EXEC dbo.Util_LockInfo @allprocesses = @allprocesses, @textmode = 0,
                         @procdata = @procdata, @debug = @debug

   -- inputbuffer is always NULL, as the recursive call skips that part.
   -- We need to do that now.
   IF @debug = 1
   BEGIN
      SELECT @ms = datediff(ms, @now, getdate())
      RAISERROR ('Getting input buffers, time %d ms.', 0, 1, @ms) WITH NOWAIT
   END

   DECLARE C3 CURSOR FAST_FORWARD LOCAL FOR
      SELECT DISTINCT spid
      FROM   #textmode
      WHERE  login <> 'SYSTEM PROCESS'
        AND  spid NOT LIKE '%-%'
   OPEN C3

   WHILE 1 = 1
   BEGIN
      FETCH C3 INTO @spid
      IF @@fetch_status <> 0
         BREAK

      BEGIN TRY
         INSERT @inputbuffer(eventtype, params, inputbuffer)
            EXEC sp_executesql N'DBCC INPUTBUFFER (@spid) WITH NO_INFOMSGS',
                               N'@spid int', @spid

         UPDATE @inputbuffer
         SET    spid = @spid
         WHERE  ident = scope_identity()
      END TRY
      BEGIN CATCH
         INSERT @inputbuffer(inputbuffer, spid)
            VALUES('Error getting inputbuffer: ' + error_message(), @spid)
      END CATCH
   END

   DEALLOCATE C3

   -- Copy to the temp table and remove line breaks while we're at it.
   UPDATE #textmode
   SET    inputbuffer = replace(replace(i.inputbuffer,
                                char(10), ' '), char(13), ' ')
   FROM   #textmode t
   JOIN   @inputbuffer i ON CASE WHEN t.spid NOT LIKE '%-%'
                                 THEN convert(int, t.spid)
                            END = i.spid
   OPTION (KEEPFIXED PLAN)

   IF @debug = 1
   BEGIN
      SELECT @ms = datediff(ms, @now, getdate())
      RAISERROR ('Adjusting result set for text mode, time %d ms.', 0, 1, @ms) WITH NOWAIT
   END

   -- Mark last row.
   UPDATE #textmode
   SET    last = 1
   FROM   #textmode f1
   JOIN   (SELECT spid, ident = MAX(ident)
           FROM   (SELECT ident,
                          spid = substring(spid, 1,
                                 coalesce(nullif(
                                            charindex('-', spid, 2) - 1,
                                           -1), len(spid)))
                   FROM   #textmode) AS x
           GROUP  BY spid) AS f2 ON f2.ident = f1.ident
   OPTION (KEEPFIXED PLAN)

   -- Local varibles for the max lengths of all columns.
   DECLARE @spidlen        varchar(5),
           @commandlen     varchar(5),
           @loginlen       varchar(5),
           @hostlen        varchar(5),
           @hostprclen     varchar(5),
           @endpointlen    varchar(5),
           @appllen        varchar(5),
           @dbnamelen      varchar(5),
           @prcstatuslen   varchar(5),
           @opntrnlen      varchar(5),
           @blkbylen       varchar(5),
           @cntlen         varchar(5),
           @objectlen      varchar(5),
           @rsctypelen     varchar(5),
           @locktypelen    varchar(5),
           @lstatuslen     varchar(5),
           @ownertypelen   varchar(5),
           @rscsubtypelen  varchar(5),
           @waittimelen    varchar(5),
           @waittypelen    varchar(5),
           @cpulen         varchar(5),
           @physiolen      varchar(5),
           @logreadslen    varchar(5),
           @login_timelen  varchar(5),
           @last_batchlen  varchar(5),
           @last_sincelen  varchar(5),
           @inputbufferlen varchar(5),
           @current_splen  varchar(5)

   -- Get all maxlengths
   SELECT @spidlen        = convert(varchar(5), coalesce(nullif(max(len(spid)), 0), 1)),
          @commandlen     = convert(varchar(5), coalesce(nullif(max(len(command)), 0), 1)),
          @loginlen       = convert(varchar(5), coalesce(nullif(max(len(login)), 0), 1)),
          @hostlen        = convert(varchar(5), coalesce(nullif(max(len(host)), 0), 1)),
          @hostprclen     = convert(varchar(5), coalesce(nullif(max(len(hostprc)), 0), 1)),
          @endpointlen    = convert(varchar(5), coalesce(nullif(max(len(endpoint)), 0), 1)),
          @appllen        = convert(varchar(5), coalesce(nullif(max(len(appl)), 0), 1)),
          @dbnamelen      = convert(varchar(5), coalesce(nullif(max(len(dbname)), 0), 1)),
          @prcstatuslen   = convert(varchar(5), coalesce(nullif(max(len(prcstatus)), 0), 1)),
          @opntrnlen      = convert(varchar(5), coalesce(nullif(max(len(opntrn)), 0), 1)),
          @blkbylen       = convert(varchar(5), coalesce(nullif(max(len(blkby)), 0), 1)),
          @cntlen         = convert(varchar(5), coalesce(nullif(max(len(cnt)), 0), 1)),
          @objectlen      = convert(varchar(5), coalesce(nullif(max(len(object)), 0), 1)),
          @rsctypelen     = convert(varchar(5), coalesce(nullif(max(len(rsctype)), 0), 1)),
          @locktypelen    = convert(varchar(5), coalesce(nullif(max(len(locktype)), 0), 1)),
          @lstatuslen     = convert(varchar(5), coalesce(nullif(max(len(lstatus)), 0), 1)),
          @ownertypelen   = convert(varchar(5), coalesce(nullif(max(len(ownertype)), 0), 1)),
          @rscsubtypelen  = convert(varchar(5), coalesce(nullif(max(len(rscsubtype)), 0), 1)),
          @waittimelen    = convert(varchar(5), coalesce(nullif(max(len(waittime)), 0), 1)),
          @waittypelen    = convert(varchar(5), coalesce(nullif(max(len(waittype)), 0), 1)),
          @cpulen         = convert(varchar(5), coalesce(nullif(max(len(cpu)), 0), 1)),
          @physiolen      = convert(varchar(5), coalesce(nullif(max(len(physio)), 0), 1)),
          @logreadslen    = convert(varchar(5), coalesce(nullif(max(len(logreads)), 0), 1)),
          @login_timelen  = convert(varchar(5), coalesce(nullif(max(len(login_time)), 0), 1)),
          @last_batchlen  = convert(varchar(5), coalesce(nullif(max(len(last_batch)), 0), 1)),
          @last_sincelen  = convert(varchar(5), coalesce(nullif(max(len(last_since)), 0), 1)),
          @inputbufferlen = convert(varchar(5), coalesce(nullif(max(len(inputbuffer)), 0), 1)),
          @current_splen  = convert(varchar(5), coalesce(nullif(max(len(current_sp)), 0), 1))
   FROM   #textmode
   OPTION (KEEPFIXED PLAN)

   -- Remove line breaks in current statement
   UPDATE #textmode
   SET    curstmt = replace(replace(curstmt, char(10), ''), char(13), '')
   WHERE  len(curstmt) > 0
   OPTION (KEEPFIXED PLAN)

   -- Return the #textdata table with dynamic lengths.
   IF @debug = 1
   BEGIN
      SELECT @ms = datediff(ms, @now, getdate())
      RAISERROR ('Returning result set, time %d ms.', 0, 1, @ms) WITH NOWAIT
   END

   EXEC ('SELECT spid        = convert(varchar( ' + @spidlen + '), spid),
                 command     = convert(varchar( ' + @commandlen + '), command),
                 login       = convert(nvarchar( ' + @loginlen + '), login),
                 host        = convert(nvarchar( ' + @hostlen + '), host),
                 hostprc     = convert(varchar( ' + @hostprclen + '), hostprc),
                 endpoint    = convert(varchar( ' + @endpointlen + '), endpoint),
                 appl        = convert(nvarchar( ' + @appllen + '), appl),
                 dbname      = convert(nvarchar( ' + @dbnamelen + '), dbname),
                 prcstatus   = convert(varchar( ' + @prcstatuslen + '), prcstatus),
                 spid_       = convert(varchar( ' + @spidlen + '), spid),
                 opntrn      = convert(varchar( ' + @opntrnlen + '), opntrn),
                 blklvl,
                 blkby       = convert(varchar( ' + @blkbylen + '), blkby),
                 cnt         = convert(varchar( ' + @cntlen + '), cnt),
                 object      = convert(nvarchar( ' + @objectlen + '), object),
                 rsctype     = convert(varchar( ' + @rsctypelen + '), rsctype),
                 locktype    = convert(varchar( ' + @locktypelen + '), locktype),
                 lstatus     = convert(varchar( ' + @lstatuslen + '), lstatus),
                 ownertype   = convert(varchar( ' + @ownertypelen + '), ownertype),
                 rscsubtype  = convert(varchar( ' + @rscsubtypelen + '), rscsubtype),
                 waittime    = convert(varchar( ' + @waittimelen + '), waittime),
                 waittype    = convert(varchar( ' + @waittypelen + '), waittype),
                 spid__      = convert(varchar( ' + @spidlen + '), spid),
                 cpu         = convert(varchar( ' + @cpulen + '), cpu),
                 physio      = convert(varchar( ' + @physiolen + '), physio),
                 logreads    = convert(varchar( ' + @logreadslen + '), logreads),
                 now,
                 login_time  = convert(varchar( ' + @login_timelen + '), login_time),
                 last_batch  = convert(varchar( ' + @last_batchlen + '), last_batch),
                 last_since  = convert(varchar( ' + @last_sincelen + '), last_since),
                 clr,
                 nstlvl,
                 inputbuffer = convert(nvarchar( ' + @inputbufferlen + '), inputbuffer),
                 current_sp  = convert(nvarchar( ' + @current_splen + '), current_sp),
                 curstmt,
                 CASE last WHEN 1 THEN char(10) ELSE '' '' END
          FROM   #textmode
          ORDER  BY ident
          OPTION (KEEPFIXED PLAN)')
END

IF @debug = 1 AND @@nestlevel = 1
BEGIN
   SELECT @ms = datediff(ms, @now, getdate())
   RAISERROR ('Completed, time %d ms.', 0, 1, @ms) WITH NOWAIT
END
