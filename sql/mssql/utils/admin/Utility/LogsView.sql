/******************************************************************
*
* 		SQL Server Disk Space Check
* 
* This script displays the entries from a given SQL Server log.
* The data displayed will be the same as what can be seen under
* the "SQL Server logs" section in Enterpise Manager.
*
* In the current configuration the log displayed is the currently 
* active log; to display an archived log, change the last parameter 
* on the "Get event log" line.
* requires sysadmin fixed role.
******************************************************************/

BEGIN

	-- Variable declarations
	DECLARE @oServer INT, @oQuery INT, @ret INT
	DECLARE @maxrow INT, @row INT, @maxcol INT, @col INT
	DECLARE @colname VARCHAR(255), @logentry VARCHAR(256), @cont INT
	DECLARE @entrytime DATETIME, @logtext VARCHAR(256), @source VARCHAR(20)

	CREATE TABLE #logdata (EntryTime DATETIME, Source VARCHAR(20), LogEntry VARCHAR(2000), Continued INT)

	-- Connect to server
	EXEC @ret = master.dbo.sp_OACreate 'SQLDMO.SQLServer', @oServer OUT
	EXEC @ret = master.dbo.sp_OASetProperty @oServer, 'LoginSecure', -1
	EXEC @ret = master.dbo.sp_OAMethod @oServer, 'Connect', NULL, @@SERVERNAME

	-- Get event log
	EXEC @ret = master.dbo.sp_OAMethod @oServer, 'ReadErrorLog', @oQuery OUTPUT, 0

	-- Read log
	EXEC @ret = master.dbo.sp_OAGetProperty @oQuery, 'Rows', @maxrow OUTPUT
	EXEC @ret = master.dbo.sp_OAGetProperty @oQuery, 'Columns', @maxcol OUTPUT
	SET @row = 0
	WHILE @row < @maxrow
	BEGIN
		SET @row = @row + 1
		EXEC @ret = master.dbo.sp_OAGetProperty @oQuery, 'GetColumnString', @logentry OUTPUT, @row, 1
		EXEC @ret = master.dbo.sp_OAGetProperty @oQuery, 'GetColumnDouble', @cont OUTPUT, @row, 2
		IF (ISDATE(LEFT(@logentry,22)) = 1) OR (@cont <> 0)
		BEGIN
			IF (@cont = 0)
			BEGIN
				SET @entrytime = CONVERT(datetime,LEFT(@logentry,22),121)
				SET @source = SUBSTRING(@logentry,24,9)
				SET @logtext = RIGHT(@logentry,LEN(@logentry)-32)
				INSERT INTO #logdata (EntryTime, Source, LogEntry, Continued)
				VALUES (@entrytime, @source, @logtext, @cont)
			END
			ELSE
			BEGIN
				SET @logtext = @logentry
				UPDATE #logdata SET LogEntry = LogEntry + @logtext
				WHERE Entrytime = @entrytime AND Source = @source AND Continued = 0
			END
		END
	END

	-- Display log entries
	SELECT EntryTime, Source, LogEntry FROM #logdata ORDER BY EntryTime

	-- Cleanup
	EXEC master.dbo.sp_OADestroy @oServer
	EXEC master.dbo.sp_OADestroy @oQuery
	DROP TABLE #logdata

END