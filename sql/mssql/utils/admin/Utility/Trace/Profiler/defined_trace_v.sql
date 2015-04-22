Select
    CAT.name as event_category,
    E.name as event_name,
    C.name as column_name,
    Case
        When FI.logical_operator = '0' Then 'AND'
        Else 'OR'
    End as logical_operator,
    Case   
        When FI.comparison_operator = 0 Then '='
        When FI.comparison_operator = 1 Then '<>'
        When FI.comparison_operator = 2 Then '>'
        When FI.comparison_operator = 3 Then '<'
        When FI.comparison_operator = 4 Then '>='
        When FI.comparison_operator = 5 Then '<='
        When FI.comparison_operator = 6 Then 'Like'
        When FI.comparison_operator = 7 Then 'Not Like'
    End as comparison_operator,
    FI.value as filter_value
From
    sys.traces T Cross Apply
    -- this function provides the details about the trace
    ::fn_trace_geteventinfo(T.id) EI Join
    sys.trace_events E On
        EI.eventid = E.trace_event_id Join
    sys.trace_columns C On
        EI.columnid = C.trace_column_id Join

    sys.trace_categories CAT On
        E.category_id = CAT.category_id Outer Apply
    --outer apply is like a left join as there may not be filters
    ::fn_trace_getfilterinfo(T.id) FI
--Optional
Where
    T.id = 1

