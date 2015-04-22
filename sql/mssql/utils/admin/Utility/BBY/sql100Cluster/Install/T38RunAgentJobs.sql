/******************************************************************************/
/* Server Installation Registration System Database                           */
/* BEST BUY CO, INC.                                                          */
/*----------------------------------------------------------------------------*/
/* Created September 28, 2000 by Michael Royzman                              */
/******************************************************************************/ 

/* $Author: A645276 $
** $Archive:   //cs01pvcs/pvcs/cm/Database/archives/Applications/DBINST/SQL80/InstallWithModule/Install/T38RunAgentJobs.svl  $
** $Date: 2011/02/08 15:37:18 $
** $Revision: 1.1 $
**/

PRINT ''
go
select '
Start of script' = convert(varchar(8), getdate(), 1) + ' ' + convert(varchar(8), getdate(), 8) + ': $Workfile:   T38RunAgentJobs.sql  $, $Revision: 1.1 $'
go

/*** Start script ***/

PRINT ''
PRINT ''

-- =============================================
-- Declare and using a READ_ONLY cursor
-- =============================================
DECLARE T38jobs CURSOR
READ_ONLY
FOR SELECT name FROM msdb.dbo.sysjobs where lower(name) like "t38n%"

DECLARE @name varchar(40)
OPEN T38jobs

FETCH NEXT FROM T38jobs INTO @name
WHILE (@@fetch_status <> -1)
BEGIN
	IF (@@fetch_status <> -2)
	BEGIN
		PRINT 'Run Job name @name'
		EXEC msdb.dbo.sp_start_job @name
		WAITFOR DELAY '00:00:20'

--		DECLARE @message varchar(100)
--		SELECT @message = 'my name is: ' + @name
--		PRINT @message
		
	END
	FETCH NEXT FROM T38jobs INTO @name
END

CLOSE T38jobs
DEALLOCATE T38jobs
go

/*** End script ***/

PRINT ''
go
select '
End of script' = convert(varchar(8), getdate(), 1) + ' ' + convert(varchar(8), getdate(), 8) + ': $Workfile:   T38RunAgentJobs.sql  $, $Revision: 1.1 $'
go

