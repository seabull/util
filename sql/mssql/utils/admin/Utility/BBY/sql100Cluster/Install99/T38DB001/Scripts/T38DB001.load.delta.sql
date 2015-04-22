/******************************************************************************/
/* Server SQL DBA System Support Database                                     */
/* SQL Server 'T38DB001' DATABASE                                             */
/*----------------------------------------------------------------------------*/
/* Created July 24, 2008 by Michael Royzman                                   */
/******************************************************************************/ 

/* $Author: A645276 $
** $Archive:   //uxpvcs2/pvcs/projects/Database/archives/DatabaseSolutions/MSSQL/EnvironmentMonitoring/T38DB001/Scripts/T38DB001.load.delta.svl  $
** $Date: 2011/02/08 17:09:56 $
** $Revision: 1.1 $
**/

PRINT ''
go
select '
Start of script' = convert(varchar(8), getdate(), 1) + ' ' + convert(varchar(8), getdate(), 8) + ': $Workfile:   T38DB001.load.delta.sql  $, $Revision: 1.1 $'
go

/*** Start script ***/

PRINT ''
PRINT ''
PRINT '<<<< T38DB001 >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
PRINT ''
USE T38DB001
GO

PRINT 'Load T38CONFIGPARAMETERS table'
insert into T38CONFIGPARAMETERS(PARAMETER_NM, PARAMETER_VAL, PARAMETER_DESC) values (
	'MAXHOURS2KEEP:T38_os_waiting_tasks', 6, 'Data older than specified numbers of hours to be deleted'
)

insert into T38CONFIGPARAMETERS(PARAMETER_NM, PARAMETER_VAL, PARAMETER_DESC) values (
	'MAXHOURS2KEEP:T38_os_schedulers', 6, 'Data older than specified numbers of hours to be deleted'
)

select PARAMETER_ID, PARAMETER_NM, PARAMETER_VAL, SQL_VARIANT_PROPERTY(PARAMETER_VAL, 'BASETYPE') from T38CONFIGPARAMETERS

if @@ERROR <> 0 RAISERROR('Problems in sql script', 21, 127)
go

/*** End script ***/
PRINT ''
go
select '
End of script' = convert(varchar(8), getdate(), 1) + ' ' + convert(varchar(8), getdate(), 8) + ': $Workfile:   T38DB001.load.delta.sql  $, $Revision: 1.1 $'
go
