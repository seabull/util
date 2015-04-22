-- This script returns login information from the default trace created in SQL Server 2005. 
-- When the sys.server_principals data is null that would mean the login is allowed via a Windows Group.
-- 
-- sys.traces provides the information for the default trace such as the file path and the max files.
-- 
-- fn_trace_gettable returns the data from trace file(s) in table format.
-- 
-- sys.server_principals is the way you should access server logins in SQL Server 2005, replacing syslogins.
--
-- An important thing to note is that the default trace will create up to 100MB (5 20MB files) 
-- of event data and then begin wrapping. Also it creates a new file when ever the SQL Server is 
-- restarted so you may not have the full 100MB of data if you reboot or restart SQL Server often.
--

create view dbo.Util_LoginTraceInfo
as
SELECT 
   I.NTUserName,
   I.loginname,
   I.SessionLoginName,
   I.databasename,
   Min(I.StartTime) as first_used,
   Max(I.StartTime) as last_used,
   S.principal_id,
   S.sid,
   S.type_desc,
   S.name
  FROM sys.traces T
CROSS Apply ::fn_trace_gettable(CASE WHEN CHARINDEX( '_',T.[path]) <> 0 THEN 
                               SUBSTRING(T.PATH, 1, CHARINDEX( '_',T.[path])-1) + '.trc' 
                          ELSE T.[path] 
                       End, T.max_files) I
LEFT JOIN sys.server_principals S
    ON CONVERT(VARBINARY(MAX), I.loginsid) = S.sid  
 WHERE T.id = 1
  And I.LoginSid is not null
Group By
   I.NTUserName,
   I.loginname,
   I.SessionLoginName,
   I.databasename,
   S.principal_id,
   S.sid,
   S.type_desc,
   S.name

--- Who did what
create view dbo.Util_SessionInfo
as
select 
    sys.dm_exec_sessions.session_id
    ,sys.dm_exec_sessions.host_name
    ,sys.dm_exec_sessions.program_name
    ,sys.dm_exec_sessions.client_interface_name
    ,sys.dm_exec_sessions.login_name
    ,sys.dm_exec_sessions.nt_domain
    ,sys.dm_exec_sessions.nt_user_name
    ,sys.dm_exec_connections.client_net_address
    ,sys.dm_exec_connections.local_net_address
    ,sys.dm_exec_connections.connection_id
    ,sys.dm_exec_connections.parent_connection_id
    ,sys.dm_exec_connections.most_recent_sql_handle
    ,(select text from master.sys.dm_exec_sql_text(sys.dm_exec_connections.most_recent_sql_handle )) as sqlscript
    ,(select db_name(dbid) from master.sys.dm_exec_sql_text(sys.dm_exec_connections.most_recent_sql_handle )) as databasename
    ,(select object_id(objectid) from master.sys.dm_exec_sql_text(sys.dm_exec_connections.most_recent_sql_handle )) as objectname
 from sys.dm_exec_sessions 
inner join sys.dm_exec_connections
    on sys.dm_exec_connections.session_id=sys.dm_exec_sessions.session_id


