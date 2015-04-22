DECLARE @bigintfilter bigint ;
DECLARE @datetimefilter datetime ;
DECLARE @varbinaryfilter varbinary(256) ;
DECLARE @intfilter int ;
DECLARE @nvarcharfilter nvarchar(256) ;
DECLARE @varcharfilter varchar(256) ;
DECLARE @uniqueidentifierfilter uniqueidentifier ;
DECLARE @return_code int ;

SET @maxfilesize = <%maxfilesize%>
EXEC @return_code = sp_trace_create 
 @traceid OUTPUT 
 , @options = <%options%>
 , @tracefile = N''<%tracefile%>''
 , @maxfilesize = @maxfilesize
 , @stoptime = <%stoptime%>
 , @filecount = <%filecount%> ;
IF @return_code <> 0 GOTO finish ;'
 
SELECT @maxfilesize = max_size
 ,@tracefile = SUBSTRING(path, 1, LEN(path) - 4)
 ,@stoptime = stop_time
 ,@filecount = max_files
 ,@options = CASE is_rollover
 WHEN 1 THEN 2
 ELSE 0
 END + CASE is_shutdown
 WHEN 1 THEN 4
 ELSE 0
 END
FROM sys.traces
WHERE id = @current_trace_id ;

SET @sp_trace_create = REPLACE(@sp_trace_create, '<%tracefile%>',
 CONVERT(NVARCHAR(245), @tracefile)) ;
SET @sp_trace_create = REPLACE(@sp_trace_create, '<%options%>',
 CONVERT(CHAR(1), @options)) ;
SET @sp_trace_create = REPLACE(@sp_trace_create, '<%maxfilesize%>',
 CONVERT(VARCHAR(19), @maxfilesize)) ;
SET @sp_trace_create = REPLACE(@sp_trace_create, '<%stoptime%>',
 COALESCE(QUOTENAME(CONVERT(VARCHAR(23), 
 @stoptime, 121), ''''), 'NULL')) ;
SET @sp_trace_create = REPLACE(@sp_trace_create, '<%filecount%>',
 CONVERT(VARCHAR(10), @filecount)) ;

SELECT SqlStatement
FROM ( SELECT 1 AS Seq
 ,@sp_trace_create AS SqlStatement
 UNION ALL
 SELECT 2
 ,REPLACE(REPLACE('EXEC sp_trace_setevent
 @traceid = @TraceID
 , @eventid = <%EventID%>
 , @columnid = <%ColumnID%>
 , @on = 1 ;', '<%EventID%>', CAST(tevent.eventid AS VARCHAR(5))),
 '<%ColumnID%>',
 CAST(tevent.columnid AS VARCHAR(5))) AS 
 seteventcommand
 FROM sys.traces t
 CROSS APPLY fn_trace_geteventinfo(@current_trace_id) AS tevent
 WHERE t.id = 2
 UNION ALL
 SELECT 3
 ,CASE tcol.type_name
 WHEN 'bigint'
 THEN 'SET @bigintfilter = '
 + COALESCE(CONVERT(NVARCHAR(19), tf.value), 'NULL')
 + ' ;'
 WHEN 'datetime'
 THEN 'SET @datetimefilter = '
 + COALESCE(QUOTENAME(CONVERT(NVARCHAR(23), tf.value, 121),
 ''''), 'NULL') + ' ;'
 WHEN 'image'
 THEN 'SET @varbinaryfilter = '
 + COALESCE(CONVERT(NVARCHAR(1000), tf.value, 1),
 'NULL') + ' ;'
 WHEN 'int'
 THEN 'SET @intfilter = '
 + COALESCE(CONVERT(NVARCHAR(10), tf.value), 'NULL')
 + ' ;'
 WHEN 'nvarchar'
 THEN 'SET @nvarcharfilter = '
 + COALESCE(QUOTENAME(CONVERT(NVARCHAR(1000), tf.value),
 ''''), 'NULL') + ' ;'
 WHEN 'text'
 THEN 'SET @nvarcharfilter = '
 + COALESCE(QUOTENAME(CONVERT(NVARCHAR(1000), tf.value),
 ''''), 'NULL') + ' ;'
 WHEN 'uniqueidentifier'
 THEN 'SET @uniqueidentifierfilter = '
 + COALESCE(QUOTENAME(CONVERT(NVARCHAR(39), tf.value),
 ''''), 'NULL') + ' ;'
 ELSE 'SET @nvarcharfilter = NULL ;'
 END + CHAR(13) + CHAR(10) + 'EXEC sp_trace_setfilter'
 + CHAR(13) + CHAR(10) + CHAR(9) + '@traceid = @TraceID'
 + CHAR(13) + CHAR(10) + CHAR(9) + ', @columnid = '
 + CONVERT(VARCHAR(10), tf.columnid) + CHAR(13) 
 + CHAR(10) + CHAR(9) + ', @logical_operator = '
 + CONVERT(VARCHAR(10), tf.logical_operator) + CHAR(13)
 + CHAR(10) + CHAR(9) + ', @comparison_operator = '
 + CONVERT(VARCHAR(10), tf.comparison_operator) 
 + CHAR(13) + CHAR(10) + CHAR(9) + ', @value = '
 + CASE tcol.type_name
 WHEN 'bigint' THEN '@bigintfilter ;'
 WHEN 'datetime' THEN '@datetimefilter ;'
 WHEN 'image' THEN '@varbbinaryfilter ;'
 WHEN 'int' THEN '@intfilter ;'
 WHEN 'nvarchar' THEN '@nvarcharfilter ;'
 WHEN 'text' THEN '@nvarcharfilter = ;'
 WHEN 'uniqueidentifier'
 THEN '@uniqueidentifierfilter ;'
 ELSE '@nvarcharfilter ;'
 END
 FROM fn_trace_getfilterinfo(@current_trace_id) AS tf
 JOIN sys.trace_columns tcol ON tcol.trace_column_id = tf.columnid
 UNION ALL
 SELECT 4
 ,'EXEC sp_trace_setstatus @TraceID, 1 ;' + CHAR(13)
 + CHAR(10)
 + 'RAISERROR(''TraceID is %d'', 0, 1, @TraceID)' 
 + CHAR(13) + CHAR(10) + 'finish: ;'
 ) AS script
ORDER BY Seq ;

