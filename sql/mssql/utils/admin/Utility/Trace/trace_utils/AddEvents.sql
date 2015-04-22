IF EXISTS
(
	SELECT 1
	FROM INFORMATION_SCHEMA.ROUTINES
	WHERE ROUTINE_NAME = 'Util_AddEvent'
	AND ROUTINE_SCHEMA = 'dbo'
	AND ROUTINE_TYPE = 'PROCEDURE'
)
BEGIN
	RAISERROR('Dropping and recreating procedure ''%s''', 0, 1, 'Util_AddEvent')
	DROP PROC dbo.Util_AddEvent
END
GO

/**************************************************
        @TraceID - int
        
        The ID of the trace, created by CreateTrace, and is used to identify the trace to which to add the events and columns.
        
        @EventList - varchar(1000)
        
        Used to specify a comma separated list of events to capture. You can see a list of all valid events in the SQL Server Books Online page titled "sp_trace_setevent". Alternatively, you will find a list of all the events and their descriptions, in this script.
        
        @ColumnList - varchar(1000)
        
        Used to specify a comma separated list of data columns to capture. You can see a list of all valid column names in the SQL Server Books Online page titled "sp_trace_setevent". Alternatively, you will find a list of all the data columns and their descriptions, in this script.
        
        Return values: -1 indicates a failure and 0 indicates success
        
**************************************************/

CREATE PROC dbo.Util_AddEvent
(
	@TraceID	int,
	@EventList	varchar(1000),
	@ColumnList	varchar(1000) = NULL
)
AS
BEGIN
	CREATE TABLE #EventList
	(
		EventID		smallint NULL,
		EventName	varchar(50) COLLATE database_default NOT NULL 
	)

	CREATE TABLE #ColumnList
	(
		ColumnID		smallint NULL,
		ColumnName		varchar(50) COLLATE database_default NOT NULL 
	)

	CREATE TABLE #DistinctEvents
	(
		EventID smallint PRIMARY KEY
	)

	CREATE TABLE #DistinctColumns
	(
		ColumnID smallint PRIMARY KEY
	)

	SET NOCOUNT ON

	DECLARE @ProcedureName varchar(25), @EventName varchar(50), @ColumnName varchar(50), @Error varchar(100)
	DECLARE @Pos int, @ReturnValue int
	DECLARE @EventID int, @ColumnID int
	DECLARE @On bit
	DECLARE @TraceErrors table (Error int, [Description] varchar(100))

	SET @ProcedureName = 'Util_AddEvent'
	SET @On = 1

	IF NOT EXISTS
	(
		SELECT 1 
		FROM ::fn_trace_getinfo(@TraceID)
	)
	BEGIN
		RAISERROR('Cannot find trace with ID %d. Source: %s', 16, 1, @TraceID, @ProcedureName)
		RETURN -1
	END

	IF LTRIM(@EventList) = ''
	BEGIN
		RAISERROR('Provide a valid list of Events. @EventList cannot be left blank. Source: %s', 16, 1, @TraceID, @ProcedureName)
		RETURN -1		
	END

	SET @EventList = LTRIM(RTRIM(@EventList))+ ','
	SET @Pos = CHARINDEX(',', @EventList, 1)

	IF REPLACE(@EventList, ',', '') <> ''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @EventName = LTRIM(RTRIM(LEFT(@EventList, @Pos - 1)))

			IF @EventName <> ''
			BEGIN
				INSERT INTO #EventList (EventName) VALUES (@EventName)
			END

			SET @EventList = RIGHT(@EventList, LEN(@EventList) - @Pos)
			SET @Pos = CHARINDEX(',', @EventList, 1)

		END
	END	
	
	UPDATE #EventList
	SET EventID = E.EventClass
	FROM #EventList AS EL 
	JOIN dbo.Events AS E
	ON E.EventName = EL.EventName

	DELETE #EventList WHERE EventID IS NULL

	IF @@ROWCOUNT > 0
	BEGIN
		RAISERROR('Warning: some (or all) of the specified events are not recognized. Please double check the spelling and make sure all the events exists in the Events table. Source: %s', 0, 1, @ProcedureName)
	END

	IF LTRIM(@ColumnList) = ''
	BEGIN
		RAISERROR('Provide a valid list of Columns. @ColumnList cannot be left blank. Source: %s', 16, 1, @TraceID, @ProcedureName)
		RETURN -1		
	END

	SET @ColumnList = LTRIM(RTRIM(@ColumnList))+ ','
	SET @Pos = CHARINDEX(',', @ColumnList, 1)

	IF REPLACE(@ColumnList, ',', '') <> ''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @ColumnName = LTRIM(RTRIM(LEFT(@ColumnList, @Pos - 1)))

			IF @ColumnName <> ''
			BEGIN
				INSERT INTO #ColumnList (ColumnName) VALUES (@ColumnName)
			END

			SET @ColumnList = RIGHT(@ColumnList, LEN(@ColumnList) - @Pos)
			SET @Pos = CHARINDEX(',', @ColumnList, 1)

		END
	END	
	
	UPDATE #ColumnList
	SET ColumnID = C.ColumnID
	FROM #ColumnList AS CL 
	JOIN dbo.ColumnList AS C
	ON C.ColumnName = CL.ColumnName

	DELETE #ColumnList WHERE ColumnID IS NULL

	IF @@ROWCOUNT > 0
	BEGIN
		RAISERROR('Warning: some (or all) of the specified columns are not recognized. Please double check the spelling and make sure all the columns exists in the Columns table. Source: %s', 0, 1, @ProcedureName)
	END

	INSERT INTO #DistinctEvents (EventID)
	SELECT DISTINCT EventID FROM #EventList
	
	INSERT INTO #DistinctColumns (ColumnID)
	SELECT DISTINCT ColumnID FROM #ColumnList

	INSERT INTO @TraceErrors (Error, Description) VALUES (1, 'Unknown error')
	INSERT INTO @TraceErrors (Error, Description) VALUES (2, 'The trace is currently running')
	INSERT INTO @TraceErrors (Error, Description) VALUES (3, 'The specified Event is not valid')
	INSERT INTO @TraceErrors (Error, Description) VALUES (4, 'The specified Column is not valid')
	INSERT INTO @TraceErrors (Error, Description) VALUES (9, 'The specified Trace Handle is not valid')
	INSERT INTO @TraceErrors (Error, Description) VALUES (11, 'The specified Column is used internally and cannot be removed')
	INSERT INTO @TraceErrors (Error, Description) VALUES (13, 'Out of memory')
	INSERT INTO @TraceErrors (Error, Description) VALUES (16, 'The function is not valid for this trace')

	SET @EventID = (SELECT MIN(EventID) FROM #DistinctEvents)
	WHILE @EventID IS NOT NULL
	BEGIN
		SET @ColumnID = (SELECT MIN(ColumnID) FROM #DistinctColumns)
		WHILE @ColumnID IS NOT NULL
		BEGIN
			EXEC @ReturnValue = sp_trace_setevent
								@traceid = @TraceID,
								@eventid = @EventID,
								@columnid = @ColumnID,
								@on = @On

			IF @ReturnValue <> 0
			BEGIN
				SET @Error = (SELECT [Description] FROM @TraceErrors WHERE Error = @ReturnValue)
				SET @Error = COALESCE(@Error, 'Unknown error ' + CAST(@ReturnValue AS varchar(10)))
				RAISERROR('Failed to add Event %d with Column %d. Error: %s. Source: %s', 16, 1, @EventID, @ColumnID, @Error, @ProcedureName)
				RETURN -1
			END

			SET @ColumnID = (SELECT MIN(ColumnID) FROM #DistinctColumns WHERE ColumnID > @ColumnID)			
		END
		SET @EventID = (SELECT MIN(EventID) FROM #DistinctEvents WHERE EventID > @EventID)
	END




END
GO

IF @@ERROR = 0
BEGIN
	RAISERROR('Successfully created procedure ''%s''', 0, 1, 'Util_AddEvent')
END
ELSE
BEGIN
	RAISERROR('Failed to create procedure ''%s''', 16, 1, 'Util_AddEvent')
END

