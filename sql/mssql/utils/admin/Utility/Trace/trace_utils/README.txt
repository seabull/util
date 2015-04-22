Scenario 1: Identifying long running stored procedures

In this scenario, we will trace for all stored procedures, that took more than 15 Seconds to complete. The output trace file 'LongRunningProcs.trc' will be saved to 'C:\My SQL Traces\' (Note that this is the location on the SQL Server machine, not the client machine).


DECLARE @TraceID int

EXEC CreateTrace
	'C:\My SQL Traces\LongRunningProcs', 
	@OutputTraceID = @TraceID OUT

EXEC AddEvent 
	@TraceID, 
	'SP:Completed', 
	'TextData, Duration'

EXEC AddFilter
	@TraceID,
	'Duration',
	15000,
	'>='
 
EXEC StartTrace @TraceID
GO

Once you are done, you could stop the trace by calling the following stored procedures. Important Note: You can only view the trace file, after successfully stopping the trace and clearing it from memory: (Lets assume that the ID of the trace created above was 1)


EXEC StopTrace 1
EXEC ClearTrace 1

Scenario 2: Get a list of all the stored procedures called within a specific database:

In this scenario, I will show you, how to get a list of all the stored procedures called, from within a specific database. In this example, we will look for all stored procedure calls from msdb database. We will also capture the start time, end time, application name, client host name, NT user name and the domain name.


DECLARE @TraceID int, @DB_ID int

EXEC CreateTrace
	'C:\My SQL Traces\ProceduresCalledInMSDB', 
	@OutputTraceID = @TraceID OUT

EXEC AddEvent 
	@TraceID, 
	'SP:Completed', 
	'TextData, StartTime, EndTime, ApplicationName, ClientHostName, NTUserName, NTDomainName, DatabaseID'

SET @DB_ID = DB_ID('msdb')

EXEC AddFilter
	@TraceID,
	'DatabaseID',
	@DB_ID
 
EXEC StartTrace @TraceID
GO

Scenario 3: Tracing for specific errors:

Let us imagine a scenario, where you deployed a brand new application and database. Now the old database is not needed anymore. So, you took the old database offline, but you want to make sure no user or application is trying to access the old database. As you probably know, when somebody or some application tries to open an offline database, you get the following error: 942: Database 'OldDatabase' cannot be opened because it is offline. In the following example, we will setup a trace that looks for error 942 and captures the time of the request, application name, NT user name and the client machine name from which the request originated. We will also specify that if the trace file already exists, it'll be overwritten.


DECLARE @TraceID int

EXEC CreateTrace 
	'C:\Trapping942s', 
	@OverwriteFile = 1,
	@OutputTraceID = @TraceID OUTPUT

EXEC AddEvent 
	@TraceID, 
	'Exception', 
	'Error, StartTime, ApplicationName, NTUserName, ClientHostName'

EXEC AddFilter
	@TraceID,
	'Error',
	942

EXEC StartTrace @TraceID

Scenario 4: Troubleshooting deadlocks:

In this scenario, I will show you how to setup a trace to identify the connections (SPIDs) involved in a deadlock, using the Deadlock and Deadlock Chain events.


DECLARE @TraceID int

EXEC dbo.CreateTrace 
	'C:\My SQL Traces\Dead Locks', 
	@OutputTraceID = @TraceID OUT

EXEC dbo.AddEvent 
	@TraceID, 
	'Lock:Deadlock, Lock:Deadlock Chain, RPC:Starting, SQL:BatchStarting', 
	'TextData'

EXEC dbo.StartTrace 
	@TraceID

Scenario 5: Identifying stored procedure recompilations:

Stored procedure recompiles have a potential to hinder the performance of your application. So it is important to identify those procedures that are recompiling repeatedly, and fix them, if the recompilation is not beneficial. The following template creates a trace that logs the stored procedures that are recompiling along with the database ID in which they are running. It also captures EventSubClass. From SQL Server 2000 SP3 and above, EventSubClass tells you the exact reason for the stored procedure recompilation. For more information search Microsoft Knowledge Base (KB) for article 308737.


DECLARE @TraceID int

EXEC dbo.CreateTrace 
	'C:\My SQL Traces\Recompilations', 
	@OutputTraceID = @TraceID OUT

EXEC dbo.AddEvent 
	@TraceID, 
	'SP:Recompile', 
	'ObjectID, ObjectName, EventSubClass, DatabaseID'

EXEC dbo.StartTrace 
	@TraceID

Scenario 6: Starting a Blackbox trace:

A black box trace stores a record of the last 5 MB of trace information produced by the server. This is very useful for troubleshooting nasty problems, bugs and access violation errors, that cause the SQL Server to shutdown. Consult SQL Server 2000 Books Online and Microsoft Knowledge Base for more information on Blackbox traces.


DECLARE @TraceID int

EXEC CreateTrace 
	@Blackbox = 1, 
	@OutputTraceID = @TraceID OUT

EXEC StartTrace 
	@TraceID

Conclusion:

The above scenarios, will just get you started, but you can really use these stored procedures to setup complicated traces with various columns, events and different types of filters. I hope you find my work useful. For the sake of completeness, I'll mention the fact that, you could even schedule the above stored procedures, as SQL Agent jobs, in order to start the traces at a desired date and time.

In the process of learning the SQL Trace system stored procedures, I did stumble upon few bugs. For example, when you set a filter on ObjectID, and then query the trace definition using fn_trace_getfilterinfo function, the ObjectID reported will be incorrect when the ObjectID is greater than 255 (SELECT value FROM ::fn_trace_getfilterinfo(@TraceID)).

One thing I observed with Profiler is that, though the trace system stored procedures support the comparison operators > and <, Profiler only shows >= and <=.

Before we end, here are the links to some of the best SQL Server performance tuning related books. I personally, read some of these books and found them extremely useful and enlightening. Hope you find them useful too:

