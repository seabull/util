-- server side
SELECT t.id
 ,CASE t.status
 WHEN 0 THEN 'Stopped'
 ELSE 'Running'
 END AS status
 ,t.path
 ,t.max_size
 ,t.stop_time
 ,t.max_files
 ,t.is_rollover
 ,t.is_shutdown
 ,t.is_default
 ,t.file_position
 ,t.start_time
 ,t.last_event_time
 ,t.event_count
FROM sys.traces AS t
WHERE t.is_rowset = 0 ;

-- client side
SELECT t.id
 ,CASE t.status
 WHEN 0 THEN 'Paused'
 ELSE 'Running'
 END AS status
 ,t.reader_spid
 ,t.start_time
 ,s.HOST_NAME
 ,s.program_name
 ,s.login_name
FROM sys.traces AS t
 LEFT JOIN sys.dm_exec_sessions AS s ON s.session_id = reader_spid
WHERE t.is_rowset = 1 ;

