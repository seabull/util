IF EXISTS
(
	SELECT 1
	FROM INFORMATION_SCHEMA.ROUTINES
	WHERE ROUTINE_NAME = 'Util_StartTrace'
	AND ROUTINE_SCHEMA = 'dbo'
	AND ROUTINE_TYPE = 'PROCEDURE'
)
BEGIN
	RAISERROR('Dropping and recreating procedure ''%s''', 0, 1, 'Util_StartTrace')
	DROP PROC dbo.Util_StartTrace
END
GO

/******************************************************************
        $Id: startTrace.sql,v 1.1 2011/10/12 15:49:35 a645276 Exp $
        $Author: a645276 $
        $Date: 2011/10/12 15:49:35 $

        @TraceID - int
        
        The ID of the trace (created by CreateTrace), to be started.
        
        Return values: -1 indicates a failure and 0 indicates success

*/

CREATE PROC dbo.Util_StartTrace
(
	@TraceID int
)
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @ReturnValue int, @Start int
	DECLARE @ProcedureName varchar(25), @Error varchar(100)
	DECLARE @TraceErrors table (Error int, [Description] varchar(100))

	SET @ProcedureName = 'Util_StartTrace'
	SET @Start = 1

	IF NOT EXISTS
	(
		SELECT 1 
		FROM ::fn_trace_getinfo(@TraceID)
	)
	BEGIN
		RAISERROR('Cannot find trace with ID %d. Source: %s', 16, 1, @TraceID, @ProcedureName)
		RETURN -1
	END

	INSERT INTO @TraceErrors (Error, [Description]) VALUES (1, 'Unknown error')
	INSERT INTO @TraceErrors (Error, [Description]) VALUES (8, 'The specified Status is not valid')
	INSERT INTO @TraceErrors (Error, [Description]) VALUES (9, 'The specified Trace Handle is not valid')
	INSERT INTO @TraceErrors (Error, [Description]) VALUES (13, 'Out of memory')
		
	EXEC @ReturnValue = sp_trace_setstatus @traceid = @TraceID, @status = @Start

	IF @ReturnValue <> 0
	BEGIN
		SET @Error = (SELECT [Description] FROM @TraceErrors WHERE Error = @ReturnValue)
		SET @Error = COALESCE(@Error, 'Unknown error ' + CAST(@ReturnValue AS varchar(10)))
		RAISERROR('Failed to start trace. Error: %s. Source: %s', 16, 1, @Error, @ProcedureName)
		RETURN -1
	END

	RETURN 0

END
GO

IF @@ERROR = 0
BEGIN
	RAISERROR('Successfully created procedure ''%s''', 0, 1, 'Util_StartTrace')
END
ELSE
BEGIN
	RAISERROR('Failed to create procedure ''%s''', 16, 1, 'Util_StartTrace')
END



