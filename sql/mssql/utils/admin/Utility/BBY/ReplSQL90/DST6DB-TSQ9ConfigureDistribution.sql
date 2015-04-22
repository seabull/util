/****** Scripting replication configuration for server DST6DB\TSQ9. Script Date: 3/24/2006 9:15:38 AM ******/
/****** Please Note: For security reasons, all password parameters were scripted with either NULL or an empty string. ******/

/****** Installing the server DST6DB\TSQ9 as a Distributor. Script Date: 3/24/2006 9:15:38 AM ******/
--use master
--exec sp_adddistributor @distributor = N'DST6DB\TSQ9', @password = N''
--GO
--exec sp_adddistributiondb @database = N'DISDB001', @data_folder = N'F:\DBMS\t38mdf\TSQ9', @data_file_size = 4, --@log_folder = N'L:\DBMS\t38ldf\TSQ9', @log_file_size = 2, @min_distretention = 0, @max_distretention = 72, --@history_retention = 48, @security_mode = 1
--GO

use [DISDB001] 
if (not exists (select * from sysobjects where name = 'UIProperties' and type = 'U ')) 
	create table UIProperties(id int) 
if (exists (select * from ::fn_listextendedproperty('SnapshotFolder', 'user', 'dbo', 'table', 'UIProperties', null, null))) 
	EXEC sp_updateextendedproperty N'SnapshotFolder', N'\\dst6db\h$\dbms\t38rpl\tsq9', 'user', dbo, 'table', 'UIProperties' 
else 
	EXEC sp_addextendedproperty N'SnapshotFolder', '\\dst6db\h$\dbms\t38rpl\tsq9', 'user', dbo, 'table', 'UIProperties'
GO

exec sp_adddistpublisher @publisher = N'dsd4dbai\df01', @distribution_db = N'DISDB001', @security_mode = 1, @working_directory = N'\\dst6db\h$\dbms\t38rpl\tsq9', @trusted = N'false', @thirdparty_flag = 0, @publisher_type = N'MSSQLSERVER'
GO
