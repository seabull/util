BEGIN TRAN

DBCC SQLPERF(logspace)

dbcc checktable("dbo.FORTVault")

DBCC OPENTRAN 

exec dbo.Util_BlockedProcesses

exec dbo.Util_LockInfo 0

--dbcc log(PRFDB001, 0)
--SELECT * FROM master.dbo.fn_dblog(null, null)
ROLLBACK