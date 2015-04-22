SET NOCOUNT ON

DECLARE @spd1 varchar(max)
SET @spd1 = 'spd1'

DECLARE @spd2 varchar(max)
SET @spd2 = 'spd2'

-- insert lines of spd #1 into temp table:

CREATE TABLE #spd1 (
CodeLineTxt varchar(max), 
CodeLineNum int not null identity(1,1)
)

INSERT INTO #spd1 (CodeLineTxt) 
EXEC sp_HelpText @spd1


-- insert lines of spd #2 into temp table:
CREATE TABLE #spd2 (
CodeLineTxt varchar(max), 
CodeLineNum int not null identity(1,1)
)

INSERT INTO #spd2 (CodeLineTxt) 
EXEC sp_HelpText @spd2


-- raw count of #lines in spd #1:
DECLARE @cnt1 int
SELECT @cnt1 = COUNT(*) FROM #spd1


-- count of #lines in spd #1 that match in spd #2:
DECLARE @cnt1a int
SELECT @cnt1a = COUNT(*) 
FROM #spd1 T1 
WHERE EXISTS (SELECT NULL FROM #spd2 T2 WHERE T2.CodeLineTxt = T1.CodeLineTxt)


-- raw count of #lines in spd #2:
DECLARE @cnt2 int
SELECT @cnt2 = COUNT(*) FROM #spd2

-- count of #lines in spd #2 that match in spd #1:
DECLARE @cnt2a int
SELECT @cnt2a = COUNT(*) 
FROM #spd2 T1 
WHERE EXISTS (SELECT NULL FROM #spd1 T2 WHERE T2.CodeLineTxt = T1.CodeLineTxt)


PRINT 'spd1: ' + @spd1
PRINT 'spd2: ' + @spd2
PRINT ''
PRINT 'Percentage match between the spds: '
+ LTRIM(STR(100.0 * (@cnt1a + @cnt2a) / (1.0 * @cnt1 + @cnt2), 10, 2)) + '%'
PRINT 'Percentage of spd1 found in spd2: '
+ LTRIM(STR(100.0 * @cnt1a / (1.0 * @cnt1), 10, 2)) + '%'
PRINT 'Percentage of spd2 found in spd1: '
+ LTRIM(STR(100.0 * @cnt2a / (1.0 * @cnt2), 10, 2)) + '%'
PRINT ''
PRINT ''

DROP TABLE #spd1
DROP TABLE #spd2

SET NOCOUNT OFF


