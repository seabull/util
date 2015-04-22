@echo off
REM	Create T38DB001 database and schema.
REM
REM	$Author: A645276 $
REM	$Date: 2011/02/08 17:09:56 $
REM	$Revision: 1.1 $
REM	$Archive:   //uxpvcs2/pvcs/projects/Database/archives/DatabaseSolutions/MSSQL/EnvironmentMonitoring/T38DB001/Scripts/T38DB001.install.cvd  $

echo %CMDCMDLINE%
set SQLName=%computername%
if .%1. equ .. (echo "Have to provide server name" && goto exitpoint)
if .%1. neq .. set SQLName=%1

@echo on
sqlcmd -E -S %SQLName% -i T38DB001.crdb.sql -o T38DB001.crdb.log
sqlcmd -E -S %SQLName% -d T38DB001 -i T38DB001.tbl.sql -o T38DB001.tbl.log
sqlcmd -E -S %SQLName% -d T38DB001 -i T38DB001.proc.sql -o T38DB001.proc.log
sqlcmd -E -S %SQLName% -d T38DB001 -i T38DB001.load.sql -o T38DB001.load.log
sqlcmd -E -S %SQLName% -i t38mon-exec_query_stats.sqlagent.sql -o t38mon-exec_query_stats.sqlagent.log
sqlcmd -E -S %SQLName% -i t38mon-virtual_file_stats.sqlagent.sql -o t38mon-virtual_file_stats.sqlagent.log
sqlcmd -E -S %SQLName% -i t38mon_index_operational_stats.sqlagent.sql -o t38mon_index_operational_stats.sqlagent.log
sqlcmd -E -S %SQLName% -i t38mon_index_usage_stats.sqlagent.sql -o t38mon_index_usage_stats.sqlagent.log
sqlcmd -E -S %SQLName% -i t38mon_os_wait_stats.sqlagent.sql -o t38mon_os_wait_stats.sqlagent.log
sqlcmd -E -S %SQLName% -i t38mon_os_schedulers.sqlagent.sql -o t38mon_os_schedulers.sqlagent.log
sqlcmd -E -S %SQLName% -i t38mon_os_waiting_tasks.sqlagent.sql -o t38mon_os_waiting_tasks.sqlagent.log
sqlcmd -E -S %SQLName% -i Workfiles\T38DB001.tblsave.sql -o Workfiles\T38DB001.tblsave.log
sqlcmd -E -S %SQLName% -i Workfiles\PerfTestStart.sqlagent.sql -o Workfiles\PerfTestStart.sqlagent.log
sqlcmd -E -S %SQLName% -i Workfiles\PerfTestStartSched.sqlagent.sql -o Workfiles\PerfTestStartSched.sqlagent.log
sqlcmd -E -S %SQLName% -i Workfiles\PerfTestStop.sqlagent.sql -o Workfiles\PerfTestStop.sqlagent.log
sqlcmd -E -S %SQLName% -i Workfiles\PerfTestStopSched.sqlagent.sql -o Workfiles\PerfTestStopSched.sqlagent.log

:exitpoint
@echo off
echo Exit
