--list current file path, events and columns of the default trace
 SELECT  t.id AS TraceId ,
        path AS TraceFilePath ,
        tcat.name AS EventCategory ,
        tevent.name AS EventClassName ,
        tcolumn.name AS ColumnName
 FROM   sys.traces AS t
        CROSS APPLY FN_TRACE_GETEVENTINFO(t.id) AS tdef
        JOIN sys.trace_events AS tevent ON tdef.eventid = tevent.trace_event_id
        JOIN sys.trace_categories AS tcat ON tcat.category_id = tevent.category_id
        JOIN sys.trace_columns AS tcolumn ON tcolumn.trace_column_id = tdef.columnid
 WHERE   --t.is_default = 1 --default trace
        --AND 
        t.status= 1 --running
 ORDER BY TraceFilePath ,
        EventCategory ,
        EventClassName ,
        ColumnName
        
SELECT *
 FROM fn_trace_gettable(N'F:\DBMS\t38sys\MSSQL.1\MSSQL\LOG\log_652.trc', DEFAULT)
where LoginName = 'FortVaultUser';