DECLARE @YourDatabaseName varchar(125)
SET @YourDatabaseName='PRFDX001'

exec('USE ' + @YourDatabaseName)
SELECT 
 DB_NAME(ius.database_id) AS DBName,
 OBJECT_NAME(ius.object_id) AS TableName,
 SUM(ius.user_seeks + ius.user_scans + ius.user_lookups) AS TimesAccessed 
FROM sys.indexes i
INNER JOIN sys.dm_db_index_usage_stats ius
 ON ius.object_id = i.object_id
 AND ius.index_id = i.index_id
WHERE
 ius.database_id = DB_ID()
 AND DB_NAME(ius.database_id)=@YourDatabaseName
GROUP BY 
 DB_NAME(ius.database_id),
 OBJECT_NAME(ius.object_id)
ORDER BY SUM(ius.user_seeks + ius.user_scans + ius.user_lookups) DESC

--------------------------------------------

DECLARE @TableName varchar(125)
DECLARE @NumberOfTimesAccessed int
DECLARE @YourDatabaseName varchar(125)
DECLARE @ThreshholdNumberOfTimesAccessed int
DECLARE @UpdateQueryText varchar(255)
DECLARE @TargetedColumnName varchar(255)

/*
 *
 * Use this variable to prevent locking on
 * a table if it hasn't been accessed enough
 * In this example, locking will not be
 * simulated if the table has not been
 * accessed at least 5 times
 * This is a good candidate variable for parameterization,
 * If you choose to make this script into a stored procedure
 *
 */
SET @ThreshholdNumberOfTimesAccessed=5

SET @YourDatabaseName='ADT'
exec('USE ' + @YourDatabaseName)
BEGIN TRANSACTION
DECLARE MostUsedTables_cur CURSOR
FOR 
 /*
 * This query gets the most recently used tables in the database.
 * As time goes on, this script becomes more targeted, as the
 * most frequently used tables in the database get used more and more
 */
 SELECT
 OBJECT_NAME(ius.object_id) AS TableName,
 SUM(ius.user_seeks + ius.user_scans + ius.user_lookups) AS TimesAccessed 
 FROM sys.indexes i
 INNER JOIN sys.dm_db_index_usage_stats ius
 ON ius.object_id = i.object_id
 AND ius.index_id = i.index_id
 WHERE
 ius.database_id = DB_ID()
 AND DB_NAME(ius.database_id)=@YourDatabaseName
 GROUP BY 
 DB_NAME(ius.database_id),
 OBJECT_NAME(ius.object_id)
 ORDER BY SUM(ius.user_seeks + ius.user_scans + ius.user_lookups) DESC


Open MostUsedTables_cur
Fetch NEXT FROM MostUsedTables_cur INTO @TableName, @NumberOfTimesAccessed
While (@@FETCH_STATUS = 0)
 BEGIN
 IF @NumberOfTimesAccessed >= @ThreshholdNumberOfTimesAccessed
 BEGIN 
 /*
 * The below query grabs an arbitrary, non-primary key column
 * in the current table, and assembles an update statement
 * to set the column value equal to itself, so this behavior
 * should be relatively low-risk
 */
 SET @TargetedColumnName = ( select top 1 co.[name] as ColumnName
 FROM sys.indexes i 
 JOIN sys.objects o on i.object_id = o.object_id
 JOIN sys.index_columns ic on ic.object_id = i.object_id 
 AND ic.index_id = i.index_id
 JOIN sys.columns co on co.object_id = i.object_id 
 AND co.column_id = ic.column_id
 WHERE i.is_primary_key = 0
 AND o.[type] = 'U'
 AND o.name = @TableName )
 SET @UpdateQueryText = 'UPDATE ' + @TableName + ' SET ' + @TargetedColumnName + ' = ' + @TargetedColumnName

 /*
  * Commenting the below Print line out, but if you wish to debug 
  * this script, simply Uncomment the Print line, and 
  *comment the exec() line
  */
 -- PRINT @UpdateQueryText


 exec(@UpdateQueryText)

 /*
 * The below command waits 5 seconds. You can parameterize this to
 * make it more configurable on-the-fly
 * The effect is that the transaction stays open for
 * a long time
 */
 WAITFOR DELAY '00:00:05'
 END
 Fetch NEXT FROM MostUsedTables_cur INTO @TableName, @NumberOfTimesAccessed
 END

CLOSE MostUsedTables_cur
DEALLOCATE MostUsedTables_cur
--Commit the transaction here, thus ending the long-held open transaction
COMMIT

--The above script, when run as a job, and possibly parameterized into a stored procedure, can really wreak havoc on a database, particularly if your database is large. The considerations to keep in mind will revolve around the following:
--1. Setting the @ThreshholdNumberOfTimesAccessed value correctly. If your database is highly used, the value of this variable should be high
--2. Setting the WAITFOR DELAY value appropriately. Setting it too long will create a very long script, and if this script is being run in the context of a SQL Agent job, the script may not be done running before the next iteration begins
--3. Frequency of running the script. If running as a SQL Agent job, make sure to couple the frequency of the job with how the system is being tested.
--
--If used correctly, the above script can become another tool for appropriately testing your system, and could perhaps be a shell of your stress test methodology. Obviously, this script is not the be-all-end-all for all testing, but I believe that it is a high value tool that can definitely add value in diagnosing how well your application can recover from a bad database environment.
--
--Takeaways
--
--There are a number of database-side and application-side solutions one can implement to reduce contention and increase the gracefulness of dealing with deadlocks and timeouts. From the database side, one could use some combination of isolation levels, query hints, small transaction lengths, and temporary tables (and other buffer-based paradigms). From the application side, I've found that one of the best ways to reduce contention is to reduce the application's "chatiness" with the database; in other words, implement strategies in my business logic to do the following:
--
--   1. Load static data 1 time (and avoid requerying for it)
--   2. Be less granular in how I grab data, so if I know the end user will probably need historical data later, then grab that data all at once
--   3. Avoid database updates if data hasn't changed (a no-brainer, but it's easy to forget to check)
--
--As for gracefulness of dealing with database contention and slowness, there are lots of strategies, as well. One of the things I do is to take my data-access related portions of my code off the user-interface thread, to avoid the dreaded "Application Not Responding" issue. I also will retry queries if my data access layer gets thrown an exception because of a deadlock or timeout. But I think that regardless of the solutions one uses to reduce contention and add gracefulness, the application and the database need to be partners in these efforts.
----
