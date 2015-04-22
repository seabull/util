
--
-- to check the default trace to see if it is enabled
-- SELECT * FROM sys.configurations WHERE configuration_id = 1568
-- 
-- To enable default trace
-- sp_configure 'show advanced options', 1;
-- GO
-- RECONFIGURE;
-- GO
-- sp_configure 'default trace enabled', 1;
-- GO
-- RECONFIGURE;
-- GO

-- get the current trace rollover file
-- SELECT * FROM ::fn_trace_getinfo(0)
-- 

--list of events 
-- SELECT *FROM sys.trace_events

--list of categories 
-- SELECT *FROM sys.trace_categories

-- --list of subclass values
-- SELECT * FROM sys.trace_subclass_values

--Get trace Event Columns
-- SELECT      t.EventID
--    ,     t.ColumnID
--    ,     e.name AS Event_Descr
--    ,     c.name AS Column_Descr
--  FROM ::fn_trace_geteventinfo(1) t
--     INNER JOIN sys.trace_events e
--           ON t.eventID = e.trace_event_id
--     INNER JOIN sys.trace_columns c
--           ON t.columnid = c.trace_column_id


-- Open trace file content
-- change the file PATH below
SELECT
    loginname
    , loginsid
    , spid
    , hostname
    , applicationname
    , servername
    ,     databasename
    ,     objectName
    ,     e.category_id
    ,     cat.name as [CategoryName]
    ,     textdata
    ,     starttime
    ,     eventclass
    ,     eventsubclass --0=begin,1=commit
    ,     e.name as EventName
  FROM ::fn_trace_gettable('G:\DBMS\t38sys\MSSQL.2\MSSQL\LOG\log_58.trc',0)
     INNER JOIN sys.trace_events e
          ON eventclass = trace_event_id
     INNER JOIN sys.trace_categories AS cat
          ON e.category_id = cat.category_id
 WHERE databasename = 'PRFDB001'
 AND      objectname IS NULL
 --filter by objectname
 AND e.category_id = 5
 --category 5 is objects
 AND e.trace_event_id = 46
       --trace_event_id: 46=Create Obj,47=Drop Obj,164=Alter Obj

WHERE databasename = 'TraceDB' AND
      objectname = 'MyTable' AND --filter by objectname
      e.category_id = 5 AND --category 5 is objects
      e.trace_event_id = 46      --trace_event_id: 46=Create Obj,47=Drop Obj,164=Alter Obj



