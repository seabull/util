--list all possible trace events and columns
 SELECT  tcat.name AS EventCategoryName ,
        tevent.name AS EventClassName ,
        tcolumn.name AS EventColumn ,
        tevent.trace_event_id AS EventID ,
        tbinding.trace_column_id AS ColumnID ,
        tcolumn.type_name AS DataType
 FROM   sys.trace_categories AS tcat
        JOIN sys.trace_events AS tevent
            ON tevent.category_id = tcat.category_id
        JOIN sys.trace_event_bindings AS tbinding
            ON tbinding.trace_event_id = tevent.trace_event_id
        JOIN sys.trace_columns AS tcolumn
            ON tcolumn.trace_column_id = tbinding.trace_column_id
 ORDER BY tcat.name ,
        EventClassName ,
        EventColumn ;

