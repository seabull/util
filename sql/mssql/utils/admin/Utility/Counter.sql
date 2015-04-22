SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET NUMERIC_ROUNDABORT OFF
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
GO

--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

/*
Counter Table (table of numbers) Setter-Upper for SQL Server 2005

CounterSmall - completely fills a single data page (two logical reads per seek or scan). 622 Numbers.
Counter - completely fills a two-level clustered index (two logical reads per seek). 386,884 Numbers.
CounterBig - completely fills a three-level clustered index (three logical reads per seek). 240,641,848 Numbers.

CounterSmall and Counter populate in 2-4 seconds, including statistics and index rebuilds.
CounterBig is commented as it usually isn't needed.  It takes a bit to populate this and pigs a lot of space. Un-comment it only if you need it.

*/

--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
--DDL
--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

SET NOCOUNT ON

--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

IF EXISTS (SELECT * FROM sys.tables WHERE name='CounterSmall' AND schema_id=1) DROP TABLE dbo.CounterSmall
IF EXISTS (SELECT * FROM sys.tables WHERE name='Counter' AND schema_id=1) DROP TABLE dbo.Counter
--IF EXISTS (SELECT * FROM sys.tables WHERE name='CounterBig' AND schema_id=1) DROP TABLE dbo.CounterBig
GO

--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

CREATE TABLE dbo.CounterSmall
(
	PK_CountID int NOT NULL,
	CONSTRAINT PK_C_IX__CounterSmall__CountID PRIMARY KEY CLUSTERED (PK_CountID) WITH FILLFACTOR=100
)

CREATE TABLE dbo.Counter
(
	PK_CountID int NOT NULL,
	CONSTRAINT PK_C_IX__Counter__CountID PRIMARY KEY CLUSTERED (PK_CountID) WITH FILLFACTOR=100
)

/*
CREATE TABLE dbo.CounterBig
(
	PK_CountID int NOT NULL,
	CONSTRAINT PK_C_IX__CounterBig__CountID PRIMARY KEY CLUSTERED (PK_CountID) WITH FILLFACTOR=100
)
*/
GO

--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
--Counter SQL 2005
--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

DECLARE @Power int
DECLARE @HeapRowsPerPage int
DECLARE @ClusteredRowsPerPage int
DECLARE @MaxRows int
DECLARE @MaxPositive int
DECLARE @MaxNegative int
DECLARE @OldMaxNegative int

SET @ClusteredRowsPerPage=622
SET @HeapRowsPerPage=299
SET @MaxPositive=621

--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

SET @MaxRows=@ClusteredRowsPerPage
SET @MaxPositive=@MaxPositive-1
SET @OldMaxNegative=0
SET @MaxNegative=@MaxRows-@MaxPositive-@OldMaxNegative
SET @Power=1

PRINT 'CounterSmall: ' + CONVERT(VarChar(10), @MaxNegative*-1+1) + ' to ' + CONVERT(VarChar(10), @MaxPositive) + ' - ' + CONVERT(VarChar(10), @MaxRows) + ' Rows - 1-Level Clustered Index'

--SELECT @MaxNegative AS MaxNegative, @MaxPositive AS MaxPositive, @OldMaxNegative AS OldMaxNegative, @Power AS Power, @MaxRows AS MaxRows

TRUNCATE TABLE CounterSmall

BEGIN TRANSACTION

/*
INSERT INTO CounterSmall WITH (TABLOCKX) (PK_CountID)
SELECT PK_CountID-@MaxNegative
FROM dbo.fn_Numbers(@MaxRows)
*/

INSERT INTO CounterSmall WITH (TABLOCKX) (PK_CountID) VALUES (1-@MaxNegative)

WHILE @Power<=@MaxRows
BEGIN
	INSERT INTO CounterSmall WITH (TABLOCKX) (PK_CountID)
	SELECT @Power+PK_CountID FROM CounterSmall
	WHERE @Power+PK_CountID<=@MaxPositive

	SET @Power=@Power*2
END

COMMIT

ALTER INDEX ALL ON CounterSmall REBUILD WITH (FillFactor=100)
UPDATE STATISTICS CounterSmall WITH FULLSCAN
--SELECT * FROM CounterSmall

--*=*=*=*=*=*=*=*=*=*=

SET @Power=@ClusteredRowsPerPage
SET @MaxRows=@Power*@ClusteredRowsPerPage
SET @OldMaxNegative=@MaxNegative+@OldMaxNegative
SET @MaxPositive=(@MaxPositive+1)*@ClusteredRowsPerPage
SET @MaxNegative=@MaxRows-@MaxPositive-@OldMaxNegative

PRINT 'Counter: ' + CONVERT(VarChar(10), @MaxNegative*-1-@OldMaxNegative+1) + ' to ' + CONVERT(VarChar(10), @MaxPositive) + ' - ' + CONVERT(VarChar(10), @MaxRows) + ' Rows - 2-Level Clustered Index'

--SELECT @MaxNegative AS MaxNegative, @MaxPositive AS MaxPositive, @OldMaxNegative AS OldMaxNegative, @Power AS Power, @MaxRows AS MaxRows

TRUNCATE TABLE Counter

BEGIN TRANSACTION

INSERT INTO Counter WITH (TABLOCKX) (PK_CountID)
SELECT PK_CountID-@MaxNegative FROM CounterSmall

WHILE @Power<=@MaxRows
BEGIN
	INSERT INTO Counter WITH (TABLOCKX) (PK_CountID)
	SELECT @Power+PK_CountID FROM Counter
	WHERE @Power+PK_CountID<=@MaxPositive

	SET @Power=@Power*2
END
COMMIT

ALTER INDEX ALL ON Counter REBUILD WITH (FillFactor=100)
UPDATE STATISTICS Counter WITH FULLSCAN
--SELECT * FROM Counter ORDER BY PK_CountID

--*=*=*=*=*=*=*=*=*=*=
/*
SET @Power=@ClusteredRowsPerPage*@ClusteredRowsPerPage
SET @MaxRows=@Power*(@ClusteredRowsPerPage-2)
SET @OldMaxNegative=@MaxNegative+@OldMaxNegative
SET @MaxPositive=(@MaxPositive+1)*@ClusteredRowsPerPage
SET @MaxNegative=@MaxRows-@MaxPositive-@OldMaxNegative

PRINT 'CounterBig: ' + CONVERT(VarChar(10), @MaxNegative*-1-@OldMaxNegative+1) + ' to ' + CONVERT(VarChar(10), @MaxPositive) + ' - ' + CONVERT(VarChar(10), @MaxRows) + ' Rows - 3-Level Clustered Index'

--SELECT @MaxNegative AS MaxNegative, @MaxPositive AS MaxPositive, @OldMaxNegative AS OldMaxNegative, @Power AS Power, @MaxRows AS MaxRows

TRUNCATE TABLE CounterBig
UPDATE STATISTICS CounterBig WITH FULLSCAN, NORECOMPUTE

BEGIN TRANSACTION

INSERT INTO CounterBig WITH (TABLOCKX) (PK_CountID)
SELECT PK_CountID-@MaxNegative FROM Counter

WHILE @Power<=@MaxRows
BEGIN
	INSERT INTO CounterBig WITH (TABLOCKX) (PK_CountID)
	SELECT @Power+PK_CountID FROM CounterBig
	WHERE @Power+PK_CountID<=@MaxPositive

	SET @Power=@Power*2
END
COMMIT

ALTER INDEX ALL ON CounterBig REBUILD WITH (FillFactor=100)
UPDATE STATISTICS CounterBig WITH FULLSCAN
--SELECT * FROM CounterBig ORDER BY PK_CountID
*/

--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

/*
SELECT * FROM sys.dm_db_index_physical_stats (DB_ID(), OBJECT_ID('CounterSmall'), NULL, NULL, 'DETAILED')
SELECT * FROM sys.dm_db_index_physical_stats (DB_ID(), OBJECT_ID('Counter'), NULL, NULL, 'DETAILED')
--SELECT * FROM sys.dm_db_index_physical_stats (DB_ID(), OBJECT_ID('CounterBig'), NULL, NULL, 'DETAILED')
*/

--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
GO


