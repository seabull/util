SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET ANSI_PADDING ON
GO

/****
    * Util_RunningRequests
    * 
    * Reports all running requests along with the request's identifying information (SPID, login etc),
    *   current resource consumption, query batch text, statement text, and XML query plan.
    *
    * Requires VIEW_SERVER_STATE permission to work.  DB-owner does not have this permission.
    *   Sysadmin does have this permission. VIEW_SERVER_STATE can be granted as a separate permission to some or all dbo users.
    * 
    * Usage:
    *  	EXECUTE dbo.Util_RunningRequests
    * 
*****/

CREATE PROCEDURE dbo.Util_RunningRequests AS
--
SELECT
    Sessions.session_id AS SessionID
    , Sessions.login_name AS LoginName
    , Sessions.host_name AS HostName
    , Sessions.program_name AS ProgramName
    , Sessions.client_interface_name AS ClientInterfaceName
    , Requests.wait_time AS WaitTime
    , Requests.cpu_time AS CPUTime
    , Requests.total_elapsed_time AS ElapsedTime
    , Requests.reads AS Reads
    , Requests.writes AS Writes
    , Requests.logical_reads AS LogicalReads
    , Requests.row_count AS [RowCount]
    , Requests.granted_query_memory*8 AS GrantedQueryMemoryKB
    , (Requests.cpu_time+1)*(Requests.reads+Requests.writes+1) AS Score
    , Statements.text AS BatchText
    , LEN(Statements.text) AS BatchTextLength
    , Requests.statement_start_offset/2 AS StartPos
    , Requests.statement_end_offset/2 AS EndPos
    , CASE WHEN Requests.sql_handle IS NULL THEN ' '
        ELSE
            SubString(
                Statements.text,
                (Requests.statement_start_offset+2)/2,
                (CASE WHEN Requests.statement_end_offset = -1 
                    THEN LEN(CONVERT(nvarchar(MAX),Statements.text))*2
                    ELSE Requests.statement_end_offset
                END - Requests.statement_start_offset)/2
            )
    END AS StatementText
    , QueryPlans.query_plan AS QueryPlan
FROM
    sys.dm_exec_sessions AS Sessions
JOIN sys.dm_exec_requests AS Requests 
    ON Sessions.session_id=Requests.session_id
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS Statements
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS QueryPlans
ORDER BY score DESC
GO
