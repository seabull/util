/*********************************************************************************/
/* CREATE USER DATABASES SCRIPT:                                                 */
/* BEST BUY CO, INC.                                                             */
/*-------------------------------------------------------------------------------*/

/* $Author: A645276 $
** $Archive:   //uxpvcs2/pvcs/projects/Database/archives/DatabaseSolutions/MSSQL/EnvironmentMonitoring/T38DB001/T38DB001.install.svl  $
** $Date: 2011/02/08 16:59:19 $
** $Revision: 1.1 $
**/

use master
GO
print ''
print SUSER_SNAME() + ' is creating database for  T38DB001 .  This will take awhile...'
GO

:r .\T38DB001\scripts\T38DB001.crdb.sql
go
use T38DB001
go

:r .\T38DB001\scripts\T38DB001.tbl.sql
go
:r .\T38DB001\scripts\T38DB001.proc.sql
go
:r .\T38DB001\scripts\T38DB001.load.sql
go
:r .\T38DB001\scripts\t38mon-exec_query_stats.sqlagent.sql
go
:r .\T38DB001\scripts\t38mon-virtual_file_stats.sqlagent.sql
go
:r .\T38DB001\scripts\t38mon_index_operational_stats.sqlagent.sql
go
:r .\T38DB001\scripts\t38mon_index_usage_stats.sqlagent.sql
go
:r .\T38DB001\scripts\t38mon_os_wait_stats.sqlagent.sql
go
:r .\T38DB001\scripts\t38mon_os_schedulers.sqlagent.sql
go
:r .\T38DB001\scripts\t38mon_os_waiting_tasks.sqlagent.sql
go
:r .\T38DB001\scripts\Workfiles\T38DB001.tblsave.sql
go
:r .\T38DB001\scripts\Workfiles\PerfTestStart.sqlagent.sql
go
:r .\T38DB001\scripts\Workfiles\PerfTestStartSched.sqlagent.sql
go
:r .\T38DB001\scripts\Workfiles\PerfTestStop.sqlagent.sql
go
:r .\T38DB001\scripts\Workfiles\PerfTestStopSched.sqlagent.sql
go
/*** End script ***/
PRINT ''
go
select '
End of script' = convert(varchar(8), getdate(), 1) + ' ' + convert(varchar(8), getdate(), 8) + ': $Workfile:   T38DB001.install.sql  $, $Revision: 1.1 $'
go
