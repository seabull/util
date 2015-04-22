IF EXISTS
(
	SELECT 1
	FROM INFORMATION_SCHEMA.ROUTINES
	WHERE ROUTINE_NAME = 'Util_AddFilter'
	AND ROUTINE_SCHEMA = 'dbo'
	AND ROUTINE_TYPE = 'PROCEDURE'
)
BEGIN
	RAISERROR('Dropping and recreating procedure ''%s''', 0, 1, 'Util_AddFilter')
	DROP PROC dbo.Util_AddFilter
END
GO

/******************************************************************
        $Id: addFilter.sql,v 1.1 2011/10/12 15:49:34 a645276 Exp $
        $Author: a645276 $
        $Date: 2011/10/12 15:49:34 $

        @TraceID - int
        
        The ID of the trace, created by CreateTrace, and is used to identify the trace to which to add the filter.
        
        @ColumnName - varchar(50)
        
        Name of the column on which to apply the filter. You can only filter on a column, after adding that column to the trace definition, using AddEvent
        
        @Value - sql_variant
        
        Specifies the value on which to filter.
        
        @ComparisonOperator - varchar(8)
        
        Specifies the type of comparison to be made. Defaults to '=', meaning 'Equals' comparison. Other valid comparison operators are: '<>' (Not Equal) , '>' (Greater Than) , '<' (Less Than) , '>=' (Greater Than Or Equal), '<=' (Less Than Or Equal), 'LIKE' and 'NOT LIKE'.
        
        @LogicalOperator - varchar(3)
        
        Defaults to 'OR'. You could also specify 'AND'. Useful for filtering a column for multiple values.
        
        Return values: -1 indicates a failure and 0 indicates success
        
        Note: Call this procedure once for each filter. If you want to filter a column for a range of values (similar to BETWEEN operator), call this procedure once with '>=' comparison operator and again with '<=' comparison operator. 

*/

CREATE PROC dbo.Util_AddFilter
(
	@TraceID		int,
	@ColumnName		varchar(50),
	@Value			sql_variant,
	@ComparisonOperator	varchar(8) = '=',
	@LogicalOperator	varchar(3) = 'OR'
)
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @ProcedureName varchar(25), @Error varchar(100), @DataType varchar(20)
	DECLARE @ReturnValue int, @CompOp int, @LogOp int, @ColumnID int
	DECLARE @TraceErrors table (Error int, [Description] varchar(100))
	DECLARE @ComparisonOperators table (OperatorID int, Operator varchar(8))
	DECLARE @bigint bigint, @datetime datetime, @int int, @nvarchar nvarchar(128), @varbinary varbinary


	SET @ProcedureName = 'Util_AddFilter'

	IF NOT EXISTS
	(
		SELECT 1 
		FROM ::fn_trace_getinfo(@TraceID)
	)
	BEGIN
		RAISERROR('Cannot find trace with ID %d. Source: %s', 16, 1, @TraceID, @ProcedureName)
		RETURN -1
	END
	
	IF (LTRIM(@ColumnName) = '') OR (@ColumnName IS NULL)
	BEGIN
		RAISERROR('Provide a valid value for @ColumnName parameter. Source: %s', 16, 1, @ProcedureName)
		RETURN -1		
	END

	IF (LTRIM(CAST(@Value AS varchar)) = '') OR (@Value IS NULL)
	BEGIN
		RAISERROR('Provide a valid value for @Value parameter. NULLs and empty values are not allowed. Source: %s', 16, 1, @ProcedureName)
		RETURN -1		
	END

	IF UPPER(@LogicalOperator) NOT IN ('AND', 'OR')
	BEGIN
		RAISERROR('Provide a valid value for @LogicalOperator parameter. Only ''AND'' and ''OR'' are allowed. Source: %s', 16, 1, @ProcedureName)
		RETURN -1		
	END

	INSERT @ComparisonOperators (OperatorID, Operator) VALUES (0, '=')
	INSERT @ComparisonOperators (OperatorID, Operator) VALUES (1, '<>')
	INSERT @ComparisonOperators (OperatorID, Operator) VALUES (2, '>')
	INSERT @ComparisonOperators (OperatorID, Operator) VALUES (3, '<')
	INSERT @ComparisonOperators (OperatorID, Operator) VALUES (4, '>=')
	INSERT @ComparisonOperators (OperatorID, Operator) VALUES (5, '<=')
	INSERT @ComparisonOperators (OperatorID, Operator) VALUES (6, 'LIKE')
	INSERT @ComparisonOperators (OperatorID, Operator) VALUES (7, 'NOT LIKE')
	
	SET @CompOp = (SELECT OperatorID FROM @ComparisonOperators WHERE LOWER(Operator) = LOWER(@ComparisonOperator))
	
	IF @CompOp IS NULL
	BEGIN
		RAISERROR('Provide a valid comparison operator. Source: %s', 16, 1, @ProcedureName)
		RETURN -1
	END

	SET @LogOp = CASE UPPER(@LogicalOperator) WHEN 'AND' THEN 0 WHEN 'OR' THEN 1 END

	IF @LogOp IS NULL
	BEGIN
		RAISERROR('Provide a valid logical operator. Source: %s', 16, 1, @ProcedureName)
		RETURN -1
	END

	SELECT @ColumnID = ColumnID, @DataType = DataType FROM dbo.ColumnList WHERE ColumnName = @ColumnName

	IF (@ColumnID IS NULL) OR (@DataType IS NULL)
	BEGIN
		RAISERROR('Provide a valid column name. Source: %s', 16, 1, @ProcedureName)
		RETURN -1
	END

	IF NOT EXISTS
	(
		SELECT 1
		FROM ::fn_trace_geteventinfo(@TraceID)
		WHERE ColumnID = @ColumnID
	)
	BEGIN
		RAISERROR('The data column you are trying to filter on, is not currently added to the trace definition. Add the column and retry setting the filter. Source: %s', 16, 1, @ProcedureName)
		RETURN -1		
	END

	INSERT INTO @TraceErrors (Error, Description) VALUES (1, 'Unknown error')
	INSERT INTO @TraceErrors (Error, Description) VALUES (2, 'The trace is currently running')
	INSERT INTO @TraceErrors (Error, Description) VALUES (4, 'The specified Column is not valid')
	INSERT INTO @TraceErrors (Error, Description) VALUES (5, 'The specified Column is not allowed for filtering')
	INSERT INTO @TraceErrors (Error, Description) VALUES (6, 'The specified Comparison Operator is not valid')
	INSERT INTO @TraceErrors (Error, Description) VALUES (7, 'The specified Logical Operator is not valid')
	INSERT INTO @TraceErrors (Error, Description) VALUES (9, 'The specified Trace Handle is not valid')
	INSERT INTO @TraceErrors (Error, Description) VALUES (13, 'Out of memory')
	INSERT INTO @TraceErrors (Error, Description) VALUES (16, 'The function is not valid for this trace')

	IF @DataType = 'bigint'
	BEGIN
		SET @bigint = CAST(@Value AS bigint)
		EXEC @ReturnValue = sp_trace_setfilter 
							@traceid = @TraceID, 
							@columnid = @ColumnID,
							@logical_operator = @LogOp,
							@comparison_operator = @CompOp,
							@value = @bigint
	END
	ELSE IF @DataType = 'datetime'
	BEGIN
		SET @datetime = CAST(@Value AS datetime)
		EXEC @ReturnValue = sp_trace_setfilter 
							@traceid = @TraceID, 
							@columnid = @ColumnID,
							@logical_operator = @LogOp,
							@comparison_operator = @CompOp,
							@value = @datetime	
	END
	ELSE IF @DataType = 'int'
	BEGIN
		SET @int = CAST(@Value AS int)
		EXEC @ReturnValue = sp_trace_setfilter 
							@traceid = @TraceID, 
							@columnid = @ColumnID,
							@logical_operator = @LogOp,
							@comparison_operator = @CompOp,
							@value = @int	
	END
	ELSE IF @DataType = 'nvarchar(128)'
	BEGIN
		SET @nvarchar = CAST(@Value AS nvarchar(128))
		EXEC @ReturnValue = sp_trace_setfilter 
							@traceid = @TraceID, 
							@columnid = @ColumnID,
							@logical_operator = @LogOp,
							@comparison_operator = @CompOp,
							@value = @nvarchar	
	END
	ELSE IF @DataType = 'varbinary'
	BEGIN
		SET @varbinary = CAST(@Value AS varbinary)
		EXEC @ReturnValue = sp_trace_setfilter 
							@traceid = @TraceID, 
							@columnid = @ColumnID,
							@logical_operator = @LogOp,
							@comparison_operator = @CompOp,
							@value = @varbinary			
	END
	ELSE
	BEGIN
		RAISERROR('Unrecognized datatype for the filter column. Source: %s', 16, 1, @ProcedureName)
		RETURN -1
	END

	IF @ReturnValue <> 0
	BEGIN
		SET @Error = (SELECT [Description] FROM @TraceErrors WHERE Error = @ReturnValue)
		SET @Error = COALESCE(@Error, 'Unknown error ' + CAST(@ReturnValue AS varchar(10)))
		RAISERROR('Failed to add Filter. Error: %s. Source: %s', 16, 1, @Error, @ProcedureName)
		RETURN -1
	END

	RETURN 0
END
GO

IF @@ERROR = 0
BEGIN
	RAISERROR('Successfully created procedure ''%s''', 0, 1, 'Util_AddFilter')
END
ELSE
BEGIN
	RAISERROR('Failed to create procedure ''%s''', 16, 1, 'Util_AddFilter')
END

