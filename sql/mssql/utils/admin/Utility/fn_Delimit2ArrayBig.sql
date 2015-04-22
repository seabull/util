SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO


/*
    --*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
    Delimited String Parsing Functions - Big Set
    
    Feed it large strings of delimited horizontal data and it returns it back as a vertical table.
    The Big function set supports more than 8000 character delimited strings, but the individual elements 
        must be 8000 characters or less.
    If you like performance you don't need to process delimited strings over 8000 characters, then use 
        the basic delimiter function set instead of the Big delimiter function set.
    Requires a table of numbers.  These functions expect it to be called 'Counter' in the same database 
        that you save these functions to.
    
    Variants:
    	Array		Has array position index and value data is not casted.
    	Table		No array position index and value data is not casted.
    	IntArray	Has array position index and value data is casted to int.
    	IntTable	No array position index and value data is casted to int.
    In the Big2D delimiter function set, the table variants have some performance gain over the array variants, but are not very useful except in joins.
    
    Usage:
    	SELECT * FROM dbo.fn_Delimit2ArrayBig ('red,green,yellow,blue,orange,purple',',') AS Delimit
    	SELECT * FROM dbo.fn_Delimit2IntArrayBig('1111,22,333,444,5555,66',',') AS Delimit
    	SELECT * FROM dbo.fn_Delimit2IntTableBig ('1111,22,333,444,5555,66',',') AS Delimit
    	SELECT * FROM dbo.fn_Delimit2TableBig ('red,green,yellow,blue,orange,purple',',') AS Delimit
    
    --*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
*/


IF OBJECT_ID('dbo.fn_Delimit2ArrayBig') IS NOT NULL DROP FUNCTION dbo.fn_Delimit2ArrayBig
GO

CREATE FUNCTION dbo.fn_Delimit2ArrayBig
	(
		@String text,
		@Delimiter VarChar(1)
	)
RETURNS @T TABLE
	(
		Pos int NOT NULL,
		Value VarChar(8000) NOT NULL
	)
AS

BEGIN

    DECLARE @Slices Table
    (
    	Slice VarChar(8000) NOT NULL,
    	CumulativeElementCount int NOT NULL
    )
    
    DECLARE @Slice VarChar(8000)
    DECLARE @TextPos int
    DECLARE @MaxLength int
    DECLARE @StopPos int
    DECLARE @StringLength int
    DECLARE @CumulativeElementCount int
    SELECT @TextPos = 1, @MaxLength = 8000 - 2, @CumulativeElementCount=0
    SELECT @StringLength=ISNULL(DATALENGTH(@String),0)-@MaxLength
    
    WHILE @TextPos < @StringLength
    BEGIN
    	SELECT @Slice = SUBSTRING(@String, @TextPos, @MaxLength)
    	SELECT @StopPos = @MaxLength - CHARINDEX(@Delimiter, REVERSE(@Slice))
    
    	INSERT INTO @Slices (Slice, CumulativeElementCount) VALUES (@Delimiter + LEFT(@Slice, @StopPos) + @Delimiter, @CumulativeElementCount)
    
    	SELECT @CumulativeElementCount=@CumulativeElementCount+LEN(@Slice)-LEN(REPLACE(@Slice, @Delimiter, ''))
    	SELECT @TextPos = @TextPos + @StopPos + 1
    END
    IF @StringLength>0-@MaxLength INSERT INTO @Slices (Slice, CumulativeElementCount) VALUES (@Delimiter + SUBSTRING(@String, @TextPos, @MaxLength) + @Delimiter, @CumulativeElementCount);
    
    INSERT INTO @T (Pos, Value)
    SELECT Pos, Value
    FROM
    	(
    		SELECT
    			PK_CountID - LEN(REPLACE(LEFT(Slices.Slice, PK_CountID-1), @Delimiter, '')) + Slices.CumulativeElementCount AS Pos,
    			SUBSTRING(Slices.Slice, Counter.PK_CountID + 1, CHARINDEX(@Delimiter, Slices.Slice, Counter.PK_CountID + 1) - Counter.PK_CountID - 1) AS Value
    		FROM
    			dbo.Counter WITH (NOLOCK)
    			JOIN @Slices AS Slices ON
    				Counter.PK_CountID>0 AND Counter.PK_CountID <= LEN(Slices.Slice) - 1 AND
    				SUBSTRING(Slices.Slice, Counter.PK_CountID, 1) = @Delimiter
    	) AS StringGet
    RETURN
END
GO

--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

IF OBJECT_ID('dbo.fn_Delimit2IntArrayBig') IS NOT NULL DROP FUNCTION dbo.fn_Delimit2IntArrayBig
GO

CREATE FUNCTION dbo.fn_Delimit2IntArrayBig
	(
		@String text,
		@Delimiter VarChar(1)
	)
RETURNS @T TABLE
	(
		Pos int NOT NULL,
		PK_IntID int NOT NULL
	)
AS

BEGIN

	DECLARE @Slices Table
	(
		Slice VarChar(8000) NOT NULL,
		CumulativeElementCount int NOT NULL
	)

	DECLARE @Slice VarChar(8000)
	DECLARE @TextPos int
	DECLARE @MaxLength int
	DECLARE @StopPos int
	DECLARE @StringLength int
	DECLARE @CumulativeElementCount int
	SELECT @TextPos = 1, @MaxLength = 8000 - 2, @CumulativeElementCount=0
	SELECT @StringLength=ISNULL(DATALENGTH(@String),0)-@MaxLength

	WHILE @TextPos < @StringLength
	BEGIN
		SELECT @Slice = SUBSTRING(@String, @TextPos, @MaxLength)
		SELECT @StopPos = @MaxLength - CHARINDEX(@Delimiter, REVERSE(@Slice))

		INSERT INTO @Slices (Slice, CumulativeElementCount) VALUES (@Delimiter + LEFT(@Slice, @StopPos) + @Delimiter, @CumulativeElementCount)

		SELECT @CumulativeElementCount=@CumulativeElementCount+LEN(@Slice)-LEN(REPLACE(@Slice, @Delimiter, ''))
		SELECT @TextPos = @TextPos + @StopPos + 1
	END
	IF @StringLength>0-@MaxLength INSERT INTO @Slices (Slice, CumulativeElementCount) VALUES (@Delimiter + SUBSTRING(@String, @TextPos, @MaxLength) + @Delimiter, @CumulativeElementCount);

	INSERT INTO @T (Pos, PK_IntID)
	SELECT Pos, PK_IntID
	FROM
		(
			SELECT
				PK_CountID - LEN(REPLACE(LEFT(Slices.Slice, PK_CountID-1), @Delimiter, '')) + Slices.CumulativeElementCount AS Pos,
				CONVERT(int, SUBSTRING(Slices.Slice, Counter.PK_CountID + 1, CHARINDEX(@Delimiter, Slices.Slice, Counter.PK_CountID + 1) - Counter.PK_CountID - 1)) AS PK_IntID
			FROM
				dbo.Counter WITH (NOLOCK)
				JOIN @Slices AS Slices ON
					Counter.PK_CountID>0 AND Counter.PK_CountID <= LEN(Slices.Slice) - 1 AND
					SUBSTRING(Slices.Slice, Counter.PK_CountID, 1) = @Delimiter
		) AS StringGet
	RETURN
END
GO

--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

IF OBJECT_ID('dbo.fn_Delimit2IntTableBig') IS NOT NULL DROP FUNCTION dbo.fn_Delimit2IntTableBig
GO

CREATE FUNCTION dbo.fn_Delimit2IntTableBig
	(
		@String text,
		@Delimiter VarChar(1)
	)
RETURNS @T TABLE
	(
		PK_IntID int NOT NULL
	)
AS

BEGIN

	DECLARE @Slices Table
	(
		Slice VarChar(8000) NOT NULL
	)

	DECLARE @Slice VarChar(8000)
	DECLARE @TextPos int
	DECLARE @MaxLength int
	DECLARE @StopPos int
	DECLARE @StringLength int
	SELECT @TextPos = 1, @MaxLength = 8000 - 2
	SELECT @StringLength=ISNULL(DATALENGTH(@String),0)-@MaxLength

	WHILE @TextPos < @StringLength
	BEGIN
		SELECT @Slice = SUBSTRING(@String, @TextPos, @MaxLength)
		SELECT @StopPos = @MaxLength - CHARINDEX(@Delimiter, REVERSE(@Slice))

		INSERT INTO @Slices (Slice) VALUES (@Delimiter + LEFT(@Slice, @StopPos) + @Delimiter)

		SELECT @TextPos = @TextPos + @StopPos + 1
	END
	IF @StringLength>0-@MaxLength INSERT INTO @Slices (slice) VALUES (@Delimiter + SUBSTRING(@String, @TextPos, @MaxLength) + @Delimiter);

	INSERT INTO @T (PK_IntID)
	SELECT PK_IntID
	FROM
		(
			SELECT
				CONVERT(int, SUBSTRING(Slices.Slice, Counter.PK_CountID + 1, CHARINDEX(@Delimiter, Slices.Slice, Counter.PK_CountID + 1) - Counter.PK_CountID - 1)) AS PK_IntID
			FROM
				dbo.Counter WITH (NOLOCK)
				JOIN @Slices AS Slices ON
					Counter.PK_CountID>0 AND Counter.PK_CountID <= LEN(Slices.Slice) - 1 AND
					SUBSTRING(Slices.Slice, Counter.PK_CountID, 1) = @Delimiter
		) AS StringGet
	RETURN
END
GO

--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

IF OBJECT_ID('dbo.fn_Delimit2TableBig') IS NOT NULL DROP FUNCTION dbo.fn_Delimit2TableBig
GO

CREATE FUNCTION dbo.fn_Delimit2TableBig
	(
		@String text,
		@Delimiter VarChar(1)
	)
RETURNS @T TABLE
	(
		Value VarChar(8000) NOT NULL
	)
AS

BEGIN

	DECLARE @Slices Table
	(
		Slice VarChar(8000) NOT NULL
	)

	DECLARE @Slice VarChar(8000)
	DECLARE @TextPos int
	DECLARE @MaxLength int
	DECLARE @StopPos int
	DECLARE @StringLength int
	SELECT @TextPos = 1, @MaxLength = 8000 - 2
	SELECT @StringLength=ISNULL(DATALENGTH(@String),0)-@MaxLength

	WHILE @TextPos < @StringLength
	BEGIN
		SELECT @Slice = SUBSTRING(@String, @TextPos, @MaxLength)
		SELECT @StopPos = @MaxLength - CHARINDEX(@Delimiter, REVERSE(@Slice))

		INSERT INTO @Slices (Slice) VALUES (@Delimiter + LEFT(@Slice, @StopPos) + @Delimiter)

		SELECT @TextPos = @TextPos + @StopPos + 1
	END
	IF @StringLength>0-@MaxLength INSERT INTO @Slices (slice) VALUES (@Delimiter + SUBSTRING(@String, @TextPos, @MaxLength) + @Delimiter);

	INSERT INTO @T (Value)
	SELECT Value
	FROM
		(
			SELECT
				SUBSTRING(Slices.Slice, Counter.PK_CountID + 1, CHARINDEX(@Delimiter, Slices.Slice, Counter.PK_CountID + 1) - Counter.PK_CountID - 1) AS Value
			FROM
				dbo.Counter WITH (NOLOCK)
				JOIN @Slices AS Slices ON
					Counter.PK_CountID>0 AND Counter.PK_CountID <= LEN(Slices.Slice) - 1 AND
					SUBSTRING(Slices.Slice, Counter.PK_CountID, 1) = @Delimiter
		) AS StringGet
	RETURN
END
GO

--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

