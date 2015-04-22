/*********************************************************************************/
/* CREATE USER DATABASES SCRIPT:                                                 */
/* BEST BUY CO, INC.                                                             */
/*-------------------------------------------------------------------------------*/

/* $Author: A645276 $
** $Archive:   //uxpvcs2/pvcs/projects/Database/archives/DatabaseSolutions/MSSQL/EnvironmentMonitoring/T38DB001/Scripts/T38DB001.crdb.svl  $
** $Date: 2011/02/08 17:09:55 $
** $Revision: 1.1 $
**/

use master
GO
print ''
print SUSER_SNAME() + ' is creating database for T38DB001 .  This will take awhile...'
GO

declare @db_name	char(8),
	@prefix		char(3),
	@seq		smallint

-- Get default mdf, ndf and ldf path from SQL Server registry.

declare @SmoDefaultFile nvarchar(512)
declare @SmoDefaultLog nvarchar(512)
declare @mdfpath varchar(256)
	, @ndfpath varchar(256)
	, @ldfpath varchar(256)

exec master.dbo.xp_instance_regread 
	N'HKEY_LOCAL_MACHINE', 
	N'Software\Microsoft\MSSQLServer\MSSQLServer', 
	N'DefaultData', @SmoDefaultFile OUTPUT

exec master.dbo.xp_instance_regread 
	N'HKEY_LOCAL_MACHINE', 
	N'Software\Microsoft\MSSQLServer\MSSQLServer', 
	N'DefaultLog', @SmoDefaultLog OUTPUT

set @mdfpath = substring(@SmoDefaultFile, 1, 1) + ':\DBMS\t38mdf\'
set @ndfpath = substring(@SmoDefaultFile, 1, 1) + ':\DBMS\t38ndf\'
set @ldfpath = substring(@SmoDefaultLog, 1, 1) + ':\DBMS\t38ldf\'

-- Get backup path from Share name.

declare 
	@t38bkpshare	nvarchar(256),
	@t38bkppath		nvarchar(256),
	@machinename	varchar(128)

set @t38bkpshare = N't38bkp'
select @machinename = cast (serverproperty('MachineName') as varchar(128))

if serverproperty('IsClustered')= 1
begin
	set @t38bkpshare = N't38bkp.' + @machinename
end

exec master.dbo.sp_T38share2phypath @sharename = @t38bkpshare, @phy_path = @t38bkppath output
if (right(@t38bkppath, 1) <> '\') set @t38bkppath = @t38bkppath + '\'

select 
	@mdfpath as 't38mdf'
	, @ndfpath as 't38ndf'
	, @ldfpath as 't38ldf'
	, @t38bkppath as 'T38bkp'

select 
	@db_name = 'T38DB001',
 
	@prefix = substring(@db_name, 1, 3), 
	@seq = convert(int, substring(@db_name, 6, 3))

	if @prefix <> 'T38' RAISERROR('Invalid database subject area', 10, 127)
	else if @seq <> '1' RAISERROR('Invalid database sequence number', 10, 127)
	else begin
		EXEC sp_T38CRDB
			@dbcid='T38',
			@dbid=1,
			@mdfpath=@mdfpath, -- 'F:\DBMS\t38mdf\',
			@ndfpath=@ndfpath, -- 'F:\DBMS\t38ndf\',
			@ldfpath=@ldfpath, -- 'L:\DBMS\t38ldf\',
			@szdb=2048,
			@szlog=512,
			@phydmp=@t38bkppath, -- 'H:\DBMS\t38bkp\',
			@ndffiles=4,
			@DBcreator='Mike Royzman',
			@DBapp='T38',
			@DBdesc='SQL DBA Monitoring Database',
		  @backupsets = 1

		print ''
		print 'Changing the logger options for T38DB001 databases.'
		EXEC sp_dboption T38DB001, 'trunc. log on chkpt.', true

		print 'Changing the bulkcopy options for T38DB001 databases.'
		EXEC sp_dboption T38DB001, 'select into/bulkcopy', true
	end
GO
USE T38DB001
GO
CHECKPOINT
GO

/*** End script ***/
PRINT ''
go
select '
End of script' = convert(varchar(8), getdate(), 1) + ' ' + convert(varchar(8), getdate(), 8) + ': $Workfile:   T38DB001.crdb.sql  $, $Revision: 1.1 $'
go

