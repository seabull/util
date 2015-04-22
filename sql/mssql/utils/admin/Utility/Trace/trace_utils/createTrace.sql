IF EXISTS
(
	SELECT 1
	FROM INFORMATION_SCHEMA.ROUTINES
	WHERE ROUTINE_NAME = 'Util_CreateTrace'
	AND ROUTINE_SCHEMA = 'dbo'
	AND ROUTINE_TYPE = 'PROCEDURE'
)
BEGIN
	RAISERROR('Dropping and recreating procedure ''%s''', 0, 1, 'Util_CreateTrace')
	DROP PROC dbo.Util_CreateTrace
END
GO

/******************************************************************
        $Id: createTrace.sql,v 1.1 2011/10/12 15:49:35 a645276 Exp $
        $Author: a645276 $
        $Date: 2011/10/12 15:49:35 $

        @OutputFile - nvarchar(245)
        
        Specifies the trace file name and complete path. Do not provide a .trc extension to the file name, as SQL Trace automatically adds the .trc extension to the output file.
        
        @OverwriteFile - bit
        
        Specifies whether to overwrite the trace file, if it already exists. Default is 0, in which case if the file already exists, an error will be raised and trace will not be created. Specify 1 to overwrite an existing trace file.
        
        @MaxSize - bigint
        
        Specifies the maximum size in megabytes (MB) a trace file can grow upto. Default is 5 MB. This stored procedure code restricts the maximum trace file size to 512 MB (half Giga Byte (GB)) as a safety measure, but can be overridden by setting the variable @MaxAllowedSize to a bigger value. You will find @MaxAllowedSize in the body of the stored procedure.
        
        @Rollover - bit
        
        Specifies that when the trace file reaches the maximum specified size, a new trace file will be created. Default is 1, meaning new file will be created when the current trace file reaches the maximum size. If you specify 0, tracing will stop when the file reaches its size limit. The new file will get the same name, but will be postfixed with a number, to indicate the sequence. For example, when the file MyTrace.trc reaches its maximum size, MyTrace_1.trc will be created.
        
        @Shutdown - bit
        
        Defaults to 0. If you specify 1, SQL Server will shut down, if the trace cannot be written to the file for whatever reason. Use this option with caution, and only when absolutely needed.
        
        @Blackbox - bit
        
        Defaults to 0. If you specify 1, a blackbox trace will be created. A black box trace stores a record of the last 5 MB of trace information produced by the server. When 1 is specified, all other parameters will be ignored. To learn more about how black box trace works, consult SQL Server 2000 Books Online.
        
        @StopAt - datetime
        
        Defaults to NULL. When NULL, the trace will run until it is manually stopped or until the server shuts down. If you specify a valid date and time, the trace will stop automatically at that specified date and time.
        
        @OutputTraceID - int - OUTPUT parameter
        
        This is an OUTPUT parameter and returns the ID for the trace that is created. This ID is needed for adding events and filters to the trace, as well as for querying the trace definition.
        
        Return values: -1 indicates a failure and 0 indicates success
        
        Note: The ID of the created trace will also be returned as a resultset for convenience. 

*/

CREATE PROC dbo.Util_CreateTrace
(
	@OutputFile	nvarchar(245) = NULL,
	@OverwriteFile	bit = 0,
	@MaxSize	bigint = 5,
	@Rollover	bit = 1,
	@Shutdown	bit = 0,
	@Blackbox	bit = 0,
	@StopAt		datetime = NULL,
	@OutputTraceID	int = NULL OUT
)
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @ReturnValue int, @FileExists int, @MaxAllowedSize int, @Options int
	DECLARE @ProcedureName varchar(25), @TraceFileExt nchar(4), @OSCommand nvarchar(255)
	DECLARE @Error varchar(100)
	DECLARE @TraceErrors table (Error int, [Description] varchar(100))

	SET @ProcedureName = 'Util_CreateTrace'
	SET @TraceFileExt = '.trc'
	SET @MaxAllowedSize = 512

	IF COALESCE(@Blackbox, 0) = 0
	BEGIN
		IF (@MaxSize IS NULL) OR (@MaxSize <= 0) OR (@MaxSize > @MaxAllowedSize)
		BEGIN
			RAISERROR('Invalid trace file size. Valid values are between 1 and %d. You could change the maximum allowed size by editing the stored procedure and setting @MaxAllowedSize to a desired value. Source: %s', 16, 1, @MaxAllowedSize, @ProcedureName)
			RETURN -1
		END
	
		IF @StopAt < CURRENT_TIMESTAMP
		BEGIN
			RAISERROR('The trace stop time cannot be in the past. Source: %s', 16, 1, @ProcedureName)
			RETURN -1
		END
	
		SET @Options =	  CASE @Rollover WHEN 1 THEN 2 ELSE 0 END
				+ CASE @Shutdown WHEN 1 THEN 4 ELSE 0 END
	
		IF @Options < 2
		BEGIN
			RAISERROR('Please provide valid tracing options. If you don''t specify any, the trace will default to ''Rollover to new file'' when the specified max trace file size is reached', 16, 1, @ProcedureName)
			RETURN -1
		END
	
		IF (@OutputFile IS NOT NULL) AND (LTRIM(@OutputFile) <> '')
		BEGIN
			SET @OutputFile = RTRIM(@OutputFile) + @TraceFileExt
	
			EXEC @ReturnValue = master..xp_fileexist @OutputFile, @FileExists OUT
	
			IF @ReturnValue <> 0
			BEGIN
				RAISERROR('Error occured while checking for trace output file existence. Source: %s', 16, 1, @ProcedureName)
				RETURN -1
			END
			
			IF @OverwriteFile = 1
			BEGIN
				IF @FileExists = 1
				BEGIN
					SET @OSCommand = 'Del ' + @OutputFile
					EXEC @ReturnValue = master..xp_cmdshell @OSCommand, 'no_output'
	
					IF @ReturnValue <> 0
					BEGIN
						RAISERROR('Error occured while deleting the trace output file. Source: %s', 16, 1, @ProcedureName)
						RETURN -1
					END
				END
			END
			ELSE
			BEGIN
				IF @FileExists = 1
				BEGIN
					RAISERROR('Trace output file already exists. Either delete it or set @OverwriteFile to 1 and try again. Source: %s', 16, 1, @ProcedureName)
					RETURN -1
				END			
			END		
		END
		ELSE
		BEGIN
			RAISERROR('@OutputFile is a mandatory parameter and you must provide a valid value. Source: %s', 16, 1, @ProcedureName)
			RETURN -1
		END
	END
	ELSE
	BEGIN
		IF (@Rollover = 1) OR (@Shutdown = 1)
		BEGIN
			RAISERROR('Warning: When setting @Blackbox to 1, any other options you set will be ignored, as @Blackbox option is not compatible with other options. Source: %s', 0, 1, @ProcedureName)
			SET @Options = 8
		END
	END

	INSERT INTO @TraceErrors (Error, [Description]) VALUES (1, 'Unknown error')
	INSERT INTO @TraceErrors (Error, [Description]) VALUES (10, 'Invalid options')
	INSERT INTO @TraceErrors (Error, [Description]) VALUES (12, 'File not created')
	INSERT INTO @TraceErrors (Error, [Description]) VALUES (13, 'Out of memory')
	INSERT INTO @TraceErrors (Error, [Description]) VALUES (14, 'Invalid stop time')
	INSERT INTO @TraceErrors (Error, [Description]) VALUES (15, 'Invalid parameters')

	IF @Blackbox = 0
	BEGIN
		SET @OutputFile = LEFT(@OutputFile, LEN(@OutputFile) - LEN(@TraceFileExt))
		EXEC @ReturnValue = sp_trace_create	@traceid = @OutputTraceID OUT,
						    	@options = @Options,
							@tracefile = @OutputFile,
							@maxfilesize = @MaxSize,
							@stoptime = @StopAt
	END
	ELSE
	BEGIN
		EXEC @ReturnValue = sp_trace_create	@traceid = @OutputTraceID OUT,
						    	@options = @Options
	END
		
	IF @ReturnValue <> 0
	BEGIN
		SET @Error = (SELECT [Description] FROM @TraceErrors WHERE Error = @ReturnValue)
		SET @Error = COALESCE(@Error, 'Unknown error ' + CAST(@ReturnValue AS varchar(10)))
		RAISERROR('Failed to create trace. Error: %s. Source: %s', 16, 1, @Error, @ProcedureName)
		RETURN -1
	END
	ELSE
	BEGIN
		SELECT @OutputTraceID AS TraceID
		RETURN 0
	END
END
GO

IF @@ERROR = 0
BEGIN
	RAISERROR('Successfully created procedure ''%s''', 0, 1, 'Util_CreateTrace')
END
ELSE
BEGIN
	RAISERROR('Failed to create procedure ''%s''', 16, 1, 'Util_CreateTrace')
END



