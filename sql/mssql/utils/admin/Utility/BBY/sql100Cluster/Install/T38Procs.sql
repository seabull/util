/******************************************************************************/
/* Create DBA support stored procedures for MS SQL 2005                       */
/* SQL Server master DATABASE                                                 */
/* BEST BUY CO, INC.                                                          */
/*----------------------------------------------------------------------------*/
/* Created December 31, 2005 by Michael Royzman                               */
/******************************************************************************/

/* $Author: A645276 $
** $Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/DBINST/SQL90/SourceCode/T38Procs.svl  $
** $Date: 2011/02/08 15:37:18 $
** $Revision: 1.1 $
**/

set QUOTED_IDENTIFIER off
go

/* Check for correct version of the SQL Server */
if ((select @@version) not like '%Microsoft SQL Server 2005%') 
	and ((select @@version) not like '%Microsoft SQL Server % - 10.0.%')
begin
	RAISERROR('This script is for Microsoft SQL Server 2005 and above', 10, 127) with log
end
GO


PRINT ''
go

select '
Start of script' = convert(varchar(8), getdate(), 1) + ' ' + convert(varchar(8), getdate(), 8) + ': $Workfile:   T38Procs.sql  $, $Revision: 1.1 $'
go


PRINT ''
PRINT ''
PRINT '<<<< master >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
PRINT ''
USE master
GO

if @@ERROR <> 0 RAISERROR('Problems in sql script', 21, 127)
go


/*** Start script ***/

/* BBY functions */

print 'Creating function: dbo.fn_T38CHKDBWRITABLE'
go

if not exists (select * from sysobjects where id = object_id('dbo.fn_T38CHKDBWRITABLE') and type = 'FN')
begin
	exec ('create function dbo.fn_T38CHKDBWRITABLE () returns int as begin return(1) end')
end
go
alter function dbo.fn_T38CHKDBWRITABLE (
	@dbname		sysname
)
returns sysname
as
/**	fn_T38CHKDBWRITABLE -- check database is writable.
 **
 **	Parameters:
 **	Input:
 **		@dbname		Name of the database to check.
 **	Output:
 **		@dbprop		Database property, values are:
 **				T38Writable		-- database is writable
 **				T38MissingDBName 	-- missing database name
 **				Any other value is result of databasepropertyex
 **	Example:
 **
 **	select @dbprop = master.dbo.fp_T38CHKDBWRITABLE('ADMDB001')
 **	if (@dbprop <> 'T38Writable')
 **	begin
 **		Print 'Database is not writable'
 **	end
 **/
begin
	declare @dbprop	sysname

	if (db_id(@dbname) is NULL)
	begin
		RETURN('T38MissingDBName')
	end

	select @dbprop = convert(sysname, databasepropertyex(@dbname, 'Status'))
	if @dbprop <> 'ONLINE'
	begin
		RETURN(@dbprop)
	end
	
	select @dbprop = convert(sysname, databasepropertyex(@dbname, 'Updateability'))
	if @dbprop  <> 'READ_WRITE'
	begin
		RETURN(@dbprop)
	end

	return('T38Writable')
end	-- fn_T38CHKDBWRITABLE
GO



/* BBY System stored procedures */


-- start of sp_T38CRBKP

print 'creating new version of sp_T38CRBKP'
go

if not exists (select * from sysobjects where id = object_id('dbo.sp_T38CRBKP') and sysstat & 0xf = 4)
begin
	exec ('create procedure dbo.sp_T38CRBKP as select 1')
end
go

alter procedure sp_T38CRBKP

/*
** sp_T38CRBKP(T-SQL) -- creates databases and transaction log backup devices
**
** PVCS information
**
** $Author: A645276 $
** $Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/DBINST/SQL90/SourceCode/T38Procs.svl  $
** $Date: 2011/02/08 15:37:18 $
** $Revision: 1.1 $	
** 
*/
@dbname  sysname = NULL,  -- database name in which to create the device for
@bkptype sysname = NULL,  -- type of backup device [db||diff|log] to create
@phypath sysname = NULL,  -- specified physical path
@nBkpDev sysname = 1 	  -- number of backup sets per database 

as
set nocount on

declare @Ldevname	sysname 	-- logical name of new device
declare @Pdevname	sysname		-- physical name of new device
declare @strsize	smallint	-- holds the number of characters in the backup path
declare @strpath	sysname 	-- holds the character string for the backup path
declare @msg		varchar(1024)	-- holds messages

-- validate input variables

if (@dbname is Null) 
begin
  print 'Procedure ''sp_T38CRBKP'' expects parameter ''@dbname'', which was not supplied.'
end

if (@bkptype is Null) 
begin
  print 'Procedure ''sp_T38CRBKP'' expects parameter ''@bkptype'', which was not supplied.'
end

if (@bkptype not in ('db', 'log', 'diff')) --Hemanth: add differential backup as a valid backup type.
begin
  print 'Procedure ''sp_T38CRBKP'' expects parameter ''@bkptype'', to be either ''log'' or ''db'' or ''diff''.' 
  print ''''+@bkptype +''' is an invalid parameter for ''@bkptype''.'
end

if (@nBkpDev not in ('1','2','3','4','5','6','7','8','9'))
begin
  print 'Procedure ''sp_T38CRBKP'' expects parameter ''@nBkpDev'', to be an integer from ''1'' to ''9''.'
  print ''''+@nBkpDev+''' is an invalid paramater for ''@nBkpDev''.'
end

if ((@dbname is Null) or (@bkptype is Null) 
    or (@bkptype not in ('db', 'log', 'diff')) 
    or @nBkpDev not in ('1','2','3','4','5','6','7','8','9'))
begin
  print ''
  print '----------------------------------------------------------------------------'
  print 'sp_T38CRBKP(T-SQL)'
  print ''
  print 'Creates database and transaction log backup devices.'
  print ''
  print 'Syntax:'
  print ''
  print 'sp_T38CRBKP {  @dbname  = '+"'"+'database_name'+"'}"
  print '             ,{@bkptype = '+"'"+'db'+"'"+'|'+"'"+'log'+"'"+'|'+"'"+'diff'+"'}"  --Hemanth--
  print '	     ,[@phypath = physical path][, @nBkpDev]'
  print '' 
  print 'Arguments:'
  print ''
  print ' {@dbname  = '+"'"+'database_name'+"'}"
  print ''
  print '	Is the name of the database that you want to create the backup device for.'
  print ''
  print ' {@bkptype = '+"'"+'db'+"'"+'|'+"'"+'log'+"'"+'|'+"'"+'diff'+"'}"	 --Hemanth--
  print ''
  print '	Is the type of backup device to create, either database, database differential or transaction log.'
  print ''
  print ' [@phypath = physical path]'
  print ''
  print '	If you want to use a physical path other than the standard t38bkp directory.'
  print '	Default is NULL.'
  print ''
  print ' [@nBkpDev]'
  print ''
  print '	Is the number of backup sets to create.  For example, if you create 2, then'
  print '	the database backups will alternate backup files.  Default is 1.'
  print ''
  print '----------------------------------------------------------------------------'
  print 'Example:'
  print ''
  print '  	EXEC sp_T38CRBKP @dbname  = ADMDB001, @bkptype = db'
  print ''         
  print ' -- This will create a backup file, ADMDB001_db.bkp, for database ADMDB001.'
  print ''	   
  print '----------------------------------------------------------------------------'
  print 'Best Buy''s naming standards for SQL Server 7.0 backup devices:'
  print ' '
  print 'Database      Logical 	            Physical 		   Description'
  print '  Name      Backup Name		Backup File Name'
  print ' '
  print 'xxxDByyy  xxxDByyy_db_bkp	xxxDByyy_db.bkp	    Database Backup'
  print 'xxxDByyy  xxxDByyy_log_bkp	xxxDByyy_log.bkp    Database Log Backup'
  print ' '
  print 'xxxDByyy  xxxDByyy_db_Z_bkp	xxxDByyy_db_Z.bkp   Database Backup w/ seq no.'
  print 'xxxDByyy  xxxDByyy_log_Z_bkp	xxxDByyy_log_Z.bkp  Database Log Backup w/ seq'
  print ' '
  print '----------------------------------------------------------------------------'
  return(1)
end -- input validation

-- build device name from input variables

if @nBkpDev = '1' 
begin
  select @Ldevname = @dbname+'_'+@bkptype+'_bkp'
  select @Pdevname = @dbname+'_'+@bkptype+'.bkp'
end

else	-- more that one backup device

begin
  select @Ldevname = @dbname+'_'+@bkptype+'_'+@nBkpDev+'_bkp'
  select @Pdevname = @dbname+'_'+@bkptype+'_'+@nBkpDev+'.bkp'
end

-- test if device already exists

if exists (select 1 from master..sysdevices where phyname like '%' + @Pdevname)
begin 
  print 'backup device '''+@Ldevname+''' already exists.'
  return (1)	
end

-- create device

if not exists (select 1 from sysdevices where phyname like '%master_db.bkp')
  begin  
    print 'sp_T38CRDBKP -> I cannot find the ''master_db_bkp'' backup device.'
    print 'so I will not be able to create the backup devices.'
    return (1)
  end

else
begin -- master backup device exists so create new device
  if @phypath is NULL
  begin
    select @strsize = PATINDEX('%master_db%', phyname) from sysdevices where phyname like '%master_db%'
    select @strpath = LEFT(phyname, (@strsize - 1 )) from sysdevices where phyname like '%master_db%'
    select @msg = 'sp_addumpdevice ''disk'', ''' + @Ldevname + ''', ''' + @strpath + @Pdevname+ ''', 2'
	-- print @msg
    exec (@msg)
  end
  else -- physical path is given

  begin -- append a \ on the end of the path if non exists (to separate the device from the path)
    if RIGHT(@phypath,1) != '\'
    begin
      select @phypath = @phypath + '\'
    end
    if (select convert(varchar(10), SERVERPROPERTY('InstanceName'))) is not null
    begin
	if (select charindex(reverse(convert(varchar(10), SERVERPROPERTY('InstanceName')) + '\'),reverse(@phypath))) <> 1
		select @phypath = @phypath + convert(varchar(10), SERVERPROPERTY('InstanceName')) + '\'
    end

    select @msg = 'sp_addumpdevice ''disk'', ''' + @Ldevname + ''', ''' + @phypath + @Pdevname+''', 2'
    exec (@msg)
  end

  if @@error > 0
  begin
      print @@error
      print ' '
      print 'The backup device ''' + @Ldevname + ''' was not created'
      return(1)
  end
  else 
    begin -- backup device was successfully created
      if exists (select 1 from master..sysdevices where phyname like '%' + @Pdevname)
      begin
        print 'The ''' + @Ldevname  + ''' backup device added successfully.'
        return(0)
      end
  end -- backup device was successfully created
     	
end -- building new backup device

-- end of sp_T38CRBKP

GO


print 'Creating stored procedure: dbo.sp_T38ALTERDB'
go

if not exists (select * from sysobjects where id = object_id('dbo.sp_T38ALTERDB') and sysstat & 0xf = 4)
begin
	exec ("create procedure dbo.sp_T38ALTERDB as select 1")
end
go
alter procedure dbo.sp_T38ALTERDB
	@filename	sysname	= NULL,
	@filesize	int	= NULL,
	@filetype	char(1)	= NULL
as
/**	sp_T38ALTERDB -- Alter file for active database.
 **
 **	This stored procedure alters file @filename for current database to 
 **	@filesize. If file is bigger larger or equal to @filesize, no action
 **	is taken.
 **
 **	Parameters:
 **		@filename	File Name to alter.
 **		@filesize	New File size for @filename in megabytes.
 **		@filetype	File type: D = data, L = log.
 **
 **	Example:
 **
 **	Execute sp_T38ALTERDB @filename = 'templog', @filesize = 30, @filetype = 'L'
 **/

	-- raiserror('sp_T38ALTERDB has to be re-tested without sp_MS_marksysobject',11,1)
	-- return(1)

	declare	@dbName		sysname
	declare @dbOldSz	int
	declare	@dbAltr		int
	declare	@msg		varchar(1024)

	select @dbName = db_name()

	if (@filename is null)
	begin
		select @msg = 'Cannot alter database ' + @dbName + '. Missing @filename.'
		RAISERROR(@msg, 11, 1)
		select @msg = 'SYNTAX: exec sp_T38ALTERDB @filename, @filesize (MB), @filetype = ''L''|''D'''
		print @msg
		RETURN(1)
	end

	if (@filesize is null)
	begin
		select @msg = 'Cannot alter database ' + @dbName + '. Missing @filesize.'
		RAISERROR(@msg, 11, 1)
		select @msg = 'SYNTAX: exec sp_T38ALTERDB @filename, @filesize (MB), @filetype = ''L''|''D'''
		print @msg
		RETURN(1)
	end

	if (@filetype is NULL or (@filetype not in ('D', 'L')))
	begin
		select @msg = 'Cannot alter database ' + @dbName + '. File type is invalid.'
		RAISERROR(@msg, 11, 1)
		select @msg = 'SYNTAX: exec sp_T38ALTERDB @filename, @filesize (MB), @filetype = ''L''|''D'''
		print @msg
		RETURN(1)
	end

	if (@filetype = 'D')
	begin
		select @dbOldSz = (sum(size)*8/1024)
		from sysfiles
		where	status & 0x40 = 0
	end else
	begin
		select @dbOldSz = (sum(size)*8/1024)
		from sysfiles
		where	status & 0x40 = 0x40
	end

	select @dbAltr = @filesize - @dbOldSz

	IF (@dbAltr > 0)
	BEGIN
		SELECT @msg = 'SA is expanding the ' + @dbName + ' database by ' + convert(varchar(11), @dbAltr) + ' Megabytes.'
		PRINT ''
		PRINT @msg

		SELECT @msg = 'ALTER DATABASE ' +@dbName+' MODIFY FILE (NAME = ' + @filename + ', SIZE = ' + convert(varchar(11),@filesize) + ' )'
		SELECT @msg
		EXEC (@msg)
	END
GO

sp_MS_marksystemobject sp_T38ALTERDB
go

use master
go
print 'creating new version of sp_T38CalculateCipherLen'
go

if not exists (select * from sysobjects where id = object_id('dbo.sp_T38CalculateCipherLen') and sysstat & 0xf = 4)
begin
	exec ('create procedure dbo.sp_T38CalculateCipherLen as select 1')
end
go

/* From 
Protect Sensitive Data Using Encryption in SQL Server 2005
by Don Kiely

http://download.microsoft.com/download/4/7/a/47a548b9-249e-484c-abd7-29f31282b04d/SQLEncryption.doc

*/

/* MXR Notes:

Converted documented function to stored procedure. There is no documented or 
known to general public process to setup UDF, which is calleble from user db 
acting on user db objects. It will be working on objects in master db. There 
is undocumented process of setting up stored procedure for this implemented 
in this script.
*/

/*  This user defined function (udf) can be used to calculate the expected output 
*   length for encrypted data (using EncryptByKey) based on the key, plaintext 
*   length and if a hashed data/column is being used (optional parameter). 
*   If you are using the results of the formula/udf to calculate the size of the
*   column for a table, I strongly suggest adding 1 or 2 blocks (i.e. 16 bytes)
*   to the expected size to account for possible future changes to algorithms
*   of choice or the stored format.
*
*     (c) 2005 Microsoft Corporation. All rights reserved. 
*
*************************************************************************/

-- @KeyName		:= name of the symmetric key.
-- @PTLen		:= length in bytes of the plain text
-- @UsesHash	:= if the optional MAC option of EncryptByKey is being using this value must be 1, 0 otherwise
--   returns the expected length in bytes of the ciphertext returned by EncryptByKey using @KeyName symnmetric key
-- and a plaintext of @PTLen bytes in length, either using the optional @MAC parameter or not.
ALTER PROCEDURE dbo.sp_T38CalculateCipherLen
/*
** sp_T38CRBKP(T-SQL) -- creates databases and transaction log backup devices
**
** PVCS information
**
** $Author: A645276 $
** $Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/DBINST/SQL90/SourceCode/T38Procs.svl  $
** $Date: 2011/02/08 15:37:18 $
** $Revision: 1.1 $	
** 
*/

( @KeyName sysname, @PTLen int, @UsesHash	int = 0 )
as
BEGIN
	declare @KeyType	nvarchar(2)
	declare @RetVal		int
	declare @BLOCK		int
	declare @IS_BLOCK	int
	declare @HASHLEN	int
	
	-- Hash length that
	SET @HASHLEN	= 20
	SET @RetVal	= NULL
	
	-- Look for the symmetric key in the catalog 
	SELECT @KeyType	= key_algorithm FROM sys.symmetric_keys WHERE name = @KeyName
	
	-- If parameters are valid
	if( @KeyType is not null AND @PTLen > 0)
	BEGIN
		-- If hash is being used. NOTE: as we use this value to calculate the length, we only use 0 or 1
		if( @UsesHash <> 0 )
			SET @UsesHash = 1
	
		-- 64 bit block ciphers
		if( @KeyType = N'R2' OR @KeyType = N'D' OR @KeyType = N'D3' OR @KeyType = N'DX' )
		BEGIN
			SET @BLOCK = 8
			SET @IS_BLOCK = 1
		END
		-- 128 bit block ciphers
		else if( @KeyType = N'A1' OR @KeyType = N'A2' OR @KeyType = N'A3' )
		BEGIN
			SET @BLOCK = 16
			SET @IS_BLOCK = 1
		END
		-- Stream ciphers, today only RC4 is supported as a stream cipher
		else
		BEGIN
			SET @IS_BLOCK = 0
		END
	
		-- Calclulate the expected length. Notice that the formula is different for block ciphres & stream ciphers
		if( @IS_BLOCK = 1 )
		BEGIN
			SET @RetVal = ( FLOOR( (8 + @PTLen + (@UsesHash * @HASHLEN) )/@BLOCK)+1 ) * @BLOCK + 16 + @BLOCK + 4
		END
		else
		BEGIN
			SET @RetVal = @PTLen + (@UsesHash * @HASHLEN) + 36 + 4
		END
	
	END

	select EstimatedLenght = @RetVal
	return @RetVal
END
go

exec sp_MS_marksystemobject sp_T38CalculateCipherLen
go

print 'creating new version of sp_T38CHKUSERKEYS'
go

if not exists (select * from sysobjects where id = object_id('dbo.sp_T38CHKUSERKEYS') and sysstat & 0xf = 4)
begin
	exec ('create procedure dbo.sp_T38CHKUSERKEYS as select 1')
end
go

alter procedure sp_T38CHKUSERKEYS

/*
** sp_T38CHKUSERKEYS(T-SQL) -- Check Symmetric and Asymmetric keys.
**
** PVCS information
**
** $Author: A645276 $
** $Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/DBINST/SQL90/SourceCode/T38Procs.svl  $
** $Date: 2011/02/08 15:37:18 $
** $Revision: 1.1 $	
** 
*/

as begin
declare @procname	sysname;	set @procname = 'sp_T38CHKUSERKEYS';
declare @dbname		sysname;	set @dbname = db_name();
declare @ssne		varbinary(100);	-- encrypted string
declare @ssn		varchar(40);		-- decrypted string
declare @tmpstr		varchar(max);

set @tmpstr = 'Starting, current database is ' + @dbname;
exec sp_T38LOGERROR 3, @procname, @tmpstr;

/* Debug code
select * from sys.symmetric_keys;
select * from sys.asymmetric_keys;
exec ('select * from ' + @dbname + '.sys.symmetric_keys');
*/

DECLARE encrkeys_cur CURSOR
READ_ONLY
FOR 
	select sk.name SymmetricKey, ak.name as EncryptedByAsymKey
	from 
	sys.symmetric_keys sk 
	join sys.key_encryptions encby on sk.symmetric_key_id = encby.key_id
	join sys.asymmetric_keys ak on ak.thumbprint = encby.thumbprint
	where encby.crypt_type = 'EPUA'
	order by 1

DECLARE @symkey		sysname;
DECLARE @asymkey	sysname;

BEGIN TRY
OPEN encrkeys_cur

FETCH NEXT FROM encrkeys_cur INTO @symkey, @asymkey
WHILE (@@fetch_status <> -1)
BEGIN
	IF (@@fetch_status <> -2)
	BEGIN
		SELECT 'symkey' = @symkey, 'asymkey' = @asymkey
		set @ssn = convert(varchar(40), newid());
		set @tmpstr = 'OPEN SYMMETRIC KEY ' + @symkey +
			' DECRYPTION BY ASYMMETRIC KEY ' + @asymkey
		print @tmpstr
		exec (@tmpstr)

		select @ssne = EncryptByKey(Key_GUID(@symkey), @ssn)
		set @tmpstr = 'CLOSE SYMMETRIC KEY ' + @symkey
		print @tmpstr
		exec (@tmpstr)

		-- select * from sys.openkeys

		-- Verify we can decrypt @ssne.

		if (SELECT 
			CONVERT(varchar(40), 
				DecryptByKeyAutoAsymKey ( AsymKey_ID(@asymkey) , 
				NULL , @ssne)) ) <> @ssn
		begin
			raiserror ('We have problem with a sym. key %s, asym. key %s', 10 /* Severity */, 1 /* state */, @symkey, @asymkey)
		end
		else
		begin
			exec sp_T38LOGERROR 3, @procname, 'we can decrypt';
			SELECT input = @ssn, output = CONVERT(varchar(40), 
				DecryptByKeyAutoAsymKey ( AsymKey_ID(@asymkey) , 
				NULL , @ssne)) 

		end
	END
	FETCH NEXT FROM encrkeys_cur INTO @symkey, @asymkey
END
END TRY
BEGIN CATCH
	SELECT
			ERROR_NUMBER() AS ErrorNumber,
			ERROR_SEVERITY() AS ErrorSeverity,
			ERROR_STATE() AS ErrorState,
			ERROR_PROCEDURE() AS ErrorProcedure,
			ERROR_LINE() AS ErrorLine,
			ERROR_MESSAGE() AS ErrorMessage;
	set @tmpstr = ERROR_MESSAGE();
	exec sp_T38LOGERROR 1, @procname, @tmpstr;
END CATCH

CLOSE encrkeys_cur
DEALLOCATE encrkeys_cur
end
GO
exec sp_MS_marksystemobject sp_T38CHKUSERKEYS
go

print 'Creating stored procedure: dbo.sp_T38CRDB'
go

if not exists (select * from sysobjects where id = object_id('dbo.sp_T38CRDB') and sysstat & 0xf = 4)
begin
	exec ("create procedure dbo.sp_T38CRDB as select 1")
end
go
ALTER  procedure dbo.sp_T38CRDB

/*
** sp_T38CRDB(T-SQL) -- creates user databases
**
** PVCS information
**
** $Author: A645276 $
** $Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/DBINST/SQL90/SourceCode/T38Procs.svl  $
** $Date: 2011/02/08 15:37:18 $
** $Revision: 1.1 $	
** 
*/

@dbcid		char (3)    = NULL,		-- 3 character identifier for database name
@dbid		tinyint     = NULL,		-- 1 integer sequence number
@mdfpath	varchar(255) = NULL,	-- file path for holding system data for user db
@ndfpath	varchar(255) = NULL,	-- file path for holding user data for user db
@ldfpath	varchar(255) = NULL,	-- file path for db transaction log
@szdb		int = NULL,				-- database size
@szlog		int = NULL,				-- database log size
@phydmp		varchar (30) = NULL,	-- path for backup files
@collate	sysname = NULL,			-- optional collation name
@backupsets	int = 1,				-- number of backup files for db and log
@ndffiles	int = NULL, 			-- number of ndf files for db
@typedb		char (1) = NULL,			-- Type of database (B=basic db, R=reporting db, X=dev sandbox)
@brand		char (3) = NULL,			-- BBY brand that the database is used by (FSP=Future Shop, BUS=BBY US, BCA=Canada, SHR=Shared between brands) 
@DBcreator	varchar (30) = NULL,		-- The name of the DBA that originally created the database
@DBcreatedate datetime = NULL,	-- The date the database was orginally created
@DBapp		varchar (30) = NULL,		-- The name of the application that uses the database
@DBdesc		varchar (255) = NULL	-- A description of what the database is

as

-- validate input variables

if (@dbcid is Null) 
begin
  print 'Procedure ''sp_T38CRDB'' expects parameter ''@dbcid'', which was not supplied.'
end

if (@dbid is Null) 
begin
  print 'Procedure ''sp_T38CRDB'' expects parameter ''@dbid'', which was not supplied.'
end

if (@mdfpath is Null) 
begin
  print 'Procedure ''sp_T38CRDB'' expects parameter ''@mdfpath'', which was not supplied.'
end

if (@ndfpath is Null) 
begin
  print 'Procedure ''sp_T38CRDB'' expects parameter ''@ndfpath'', which was not supplied.'
end

if (@ldfpath is Null) 
begin
  print 'Procedure ''sp_T38CRDB'' expects parameter ''@ldfpath'', which was not supplied.'
end

if (@szdb is Null) 
begin
  print 'Procedure ''sp_T38CRDB'' expects parameter ''@szdb'', which was not supplied.'
end

if (@szlog is Null) 
begin
  print 'Procedure ''sp_T38CRDB'' expects parameter ''@szlog'', which was not supplied.'
end

if (@ndffiles is Null) 
begin
  print 'Procedure ''sp_T38CRDB'' expects parameter ''@ndffiles'', which was not supplied.'
  print '@ndffiles is the number of ndf files for database, should be number of CPUs devided by 2'
  
	create table #info  (
	[Index]	smallint,  
	[Name]	varchar(128),  
	Internal_Value	int null,
	Character_Value varchar(128)
	)

	insert #info exec master..xp_msver 'ProcessorCount'
    select 'Procedure ''sp_T38CRDB'' expects parameter ''@ndffiles'', which was not supplied.'
    select '@ndffiles is the number of ndf files for database, should be number of CPUs devided by 2'
    select  'Number of CPUs: ', Internal_Value from #info where Name = 'ProcessorCount'
	print 'To find number of CPUs: execute xp_msver '+"'"+'ProcessorCount'+"'"
end

if (@typedb is Null) 
begin
  set @typedb = 'B'
end

if (@typedb not in ('B','R','X')) 
begin
  print 'Invalid database type.  Database type must be ''B'' for basic database, ''R'' for reporting database, or ''X'' for dev sand box database'
end

if (@DBcreator is Null) 
begin
  print 'Procedure ''sp_T38CRDB'' expects parameter ''@DBcreator'', which was not supplied.'
end

if (@DBapp is Null) 
begin
  print 'Procedure ''sp_T38CRDB'' expects parameter ''@DBapp'', which was not supplied.'
end

if (@DBdesc is Null) 
begin
  print 'Procedure ''sp_T38CRDB'' expects parameter ''@DBdesc'', which was not supplied.'
end

if (@brand is not null and @brand not in ('FSP','BUS','BCA','SHR')) 
begin
  print 'Invalid brand.  Brand must be ''FSP'' for Future Shop, ''BUS'' for Best Buy USA, ''BCA'' for Best Buy Canada, ''SHR'' for Shared, or NULL'
end

if (	   (@dbcid is Null) 
	or (@dbid is Null) 
    or (@mdfpath is Null)
	or (@ndfpath is Null)
	or (@ldfpath is Null)
	or (@szdb is Null)
	or (@szlog is Null)
	or (@ndffiles is null)
	or (@typedb not in ('B','R','X'))
	or (@DBcreator is Null) 
	or (@DBapp is Null) 
	or (@DBdesc is Null)
	or (@brand not in ('FSP','BUS','BCA','SHR') and @brand is not NULL))
begin
  print ''
  print '----------------------------------------------------------------------------'
  print 'sp_T38CRDB(T-SQL)'
  print ''
  print 'Creates user databases.'
  print ''
  print 'Syntax:'
  print ''
  print 'sp_T38CRDB	 @dbcid		= '+"'"+'database_name_prefix'+"'"
  print '			,@dbid		= '+"'"+'database_iteration'+"'"
  print '			,@mdfpath	= '+"'"+'primary_file_path'+"'"
  print '			,@ndfpath	= '+"'"+'secondary_file_path'+"'"
  print '			,@ldfpath	= '+"'"+'log_file_path'+"'"
  print '			,@szdb		= '+"'"+'database_size'+"'"
  print '			,@szlog		= '+"'"+'database_log'+"'"
  print '			,@phydmp	= physical_backup_path,'
  print '			,@nBkpDev	= number_backup_devices'
  print '			,@ndffiles	= number of ndf files,'
  print '			,@typedb	= type of database,'
  print '			,[@collate	= '+"'"+'collation_name'+"']"
  print '			,@brand		= name of the Best Buy brand (if applicable),'
  print '			,@DBcreator	= name of the person creating the database,'
  print '			,@DBapp		= name of the application that uses the database,'
  print '			,@DBdesc	= a short description of the database'
  print '' 
  print 'Arguments:'
  print ''
  print ' {@dbcid  =  '+"'"+'database_name_prefix'+"'}"
  print ''
  print '	Is the three character database id (i.e. ADM for Admin)'
  print ''
  print ' {@dbid =    '+"'"+'database_iteration'+"'}"
  print ' 	Is the verision iterator for the db (i.e. ADM 1, 2, 3)'
  print ''
  print ' {@mdfpath = '+"'"+'primary_file_path'+"'}"
  print ''
  print '	Is the path to create the system tables db file  (i.e. ...\t38mdf\)'
  print ''
  print ' {@ndfpath = '+"'"+'secondary_file_path'+"'}"
  print ''
  print '	Is the path to create the user table db file  (i.e. ...\t38ndf\)'
  print ''
  print ' {@ldfpath = '+"'"+'log_file_path'+"'}"
  print ''
  print ' 	Is the path to create the db transaction log file (i.e. ...\t38ldf\)'
  print ''
  print ' {@szdb =    '+"'"+'database_size'+"'}"
  print ''
  print '	Is the size of the database contain to be create in MB.'
  print ''
  print ' {@szlog =   '+"'"+'database_log'+"'}"
  print ''
  print ' 	Is the size of the database log to be create in MB.'
  print ''
  print ' [@phydmp =   physical_backup_path],'
  print ''
  print '	Is the path to create the db and log backup files (i.e. ...\t38bkp\)'
  print ''
  print ' [@nBkpDev =  number_backup_devices]'
  print ''
  print '	Is the number of backup devices to sequence through.  Default is 1.'
  print ''
  print ' @ndffiles =  number of ndf files'
  print ''
  print '	Is the number of ndf files for database, should be number of CPUs devided by 2'
  print '	To find number of CPUs: execute xp_msver '+"'"+'ProcessorCount'+"'"
  print ''
  print ' @typedb =  Type of database'
  print ''
  print '	Is the type of database:  B=basic database, R=Reporting Database, X=Dev sand box database'
  print ''  
  print ' [@collate =   '+"'"+'collation_name'+"']"
  print ''
  print ' 	Is collation name, returned by SELECT * FROM ::fn_helpcollations().'
  print ''
  print ' @brand = name of the Best Buy brand (if applicable),'
  print ''
  print ' 	Is the Best Buy brand that will use the database.  Valid values are:'
  print ' 	FSP=Future Shop, BUS=Best Buy USA, BCA=Best Buy Canada, SHR=Shared between brands, or NULL'
  print ''
  print ' @DBcreator = name of the person creating the database,'
  print ''
  print ' 	Is the full name of the DBA who is initially creating the database (you)'
  print ''
  print ' @DBapp = name of the application that uses the database,'
  print ''
  print ' 	The name of the application that will be using the database.'
  print ''
  print ' @DBdesc = a short description of the database'
  print ''
  print ' 	A short description of the database and how it is used.'
  print ''
  print '----------------------------------------------------------------------------'
  print ''
  print 'Example:'
  print ''
  print '	EXEC sp_T38CRDB'
  print '		@dbcid	    = '+"'"+'SRC'+"', "
  print '		@dbid	    = 2,'
  print '		@mdfpath    = '+"'"+'F:\dbms\t38mdf\'+"',"
  print '		@ndfpath    = '+"'"+'F:\dbms\t38ndf\'+"',"   
  print '		@ldfpath    = '+"'"+'L:\dbms\t38ldf\'+"',"
  print '		@szdb	    = 100,'
  print '		@szlog	    = 25,'
  print '		@phydmp	    = '+"'"+'H:\dbms\t38bkp\'+"',"
  print '		@backupsets = 1,'
  print '		@ndffiles   = 2,'
  print '		@typedb     = '+"'"+'B'+"',"
  print '		@brand     = '+"'"+'SHR'+"',"
  print '		@dbcreator = '+"'"+'Scott Franz'+"',"
  print '		@DBapp     = '+"'"+'Star Repair/Phoenix'+"',"
  print '		@DBdesc    = '+"'"+'Holds check in and check out information'+"'"
  print ''
  print '----------------------------------------------------------------------------'
  print ''
  return(1)
end -- input validation


/***** First Declare local variables needed by procedure *******/
declare	@sql			varchar(8000)   /*	help hold a sql ddl statement to execute
                                       			*/
declare	@msg			varchar(255)	-- another variable to hold sql or error msg text
declare	@systemsize		char(2)		-- hold the default size of the Primary File Group
declare	@dbname			varchar(11)		-- hold derived database name according to BBY standards
declare	@mdfpathfile	varchar(255)	-- holds the path and file name of the mdf file
declare	@ndfpathfile	varchar(255)	-- holds the path and file name of the ndf file
declare	@ldfpathfile	varchar(255)	-- holds the path and file name of the ldf file
declare	@NL				char(3)		-- holds new line sequence = ' '+char(13)+char(10)
declare @collateArg		varchar(255)	-- holds collate argument
declare	@errmsg			varchar(255)	-- holds custom messages to print
declare @i			integer		-- loop counter
declare @ndfsz			integer		-- size of one ndf file
declare @ndfcnt			integer		-- used to figure out suffix in ndf file name
declare @ndfcntchar		char(2)		-- ndf suffix in the file name	
declare @chardate		char(20)	-- used to convert current date to character format	

/***** Ensure all path names are ended with '\' *****/

select @mdfpath = ltrim(rtrim(@mdfpath))
if (right(@mdfpath, 1) <> ':' and right(@mdfpath, 1) <> '\') select @mdfpath = @mdfpath + '\'

select @ndfpath = ltrim(rtrim(@ndfpath))
if (right(@ndfpath, 1) <> ':' and right(@ndfpath, 1) <> '\') select @ndfpath = @ndfpath + '\'

select @ldfpath = ltrim(rtrim(@ldfpath))
if (right(@ldfpath, 1) <> ':' and right(@ldfpath, 1) <> '\') select @ldfpath = @ldfpath + '\'

if (select convert(varchar(10), SERVERPROPERTY('InstanceName'))) is not null
begin
	if (select charindex(reverse(convert(varchar(10), SERVERPROPERTY('InstanceName')) + '\'),reverse(@mdfpath))) <> 1
		select @mdfpath = @mdfpath + convert(varchar(10), SERVERPROPERTY('InstanceName')) + '\'
	if (select charindex(reverse(convert(varchar(10), SERVERPROPERTY('InstanceName')) + '\'),reverse(@ndfpath))) <> 1
		select @ndfpath = @ndfpath + convert(varchar(10), SERVERPROPERTY('InstanceName')) + '\'
	if (select charindex(reverse(convert(varchar(10), SERVERPROPERTY('InstanceName')) + '\'),reverse(@ldfpath))) <> 1
		select @ldfpath = @ldfpath + convert(varchar(10), SERVERPROPERTY('InstanceName')) + '\'
end
select @phydmp = ltrim(rtrim(@phydmp))
if (right(@phydmp, 1) <> ':' and right(@phydmp, 1) <> '\') select @phydmp = @phydmp + '\'

/***** Next initialize local variables and derive names from parameters *****/
select @systemsize = '10'
if (@brand is not null)
	begin
		select @dbname = upper(@dbcid) + "D" + upper(@typedb) + RIGHT('000'+CONVERT(varchar(3),@dbid),3) + upper(@brand)
	end
else 
	begin
		select @dbname = upper(@dbcid) + "D" + upper(@typedb) + RIGHT('000'+CONVERT(varchar(3),@dbid),3)
		select @dbname = rtrim(@dbname)
	end

select @mdfpathfile = @mdfpath + @dbname + '.mdf'
--select @ndfpathfile = @ndfpath + @dbname + '.ndf'
select @ldfpathfile = @ldfpath + @dbname + '.ldf'
select @NL = ' '+char(13)+char(10)
select @collateArg = ''
--select @ndfcnt = 1
select @ndfcntchar = ''


if (@collate is not null)
begin
	select @collateArg = @NL + 'collate ' + @collate
end

if not exists ( select name 
             from master..sysdatabases
              where	name = @dbname)
	begin
		/***** Next Create the database *****/
		/* 	Setting System file to 10 MB and autogrow by 10MB
		   	Making a seperate Data Parttion
			Turning log autogrow off
		*/

		select @ndfsz = ceiling(convert (decimal, @szdb)/@ndffiles)
		set @ndfcnt = 1

		select @sql = 	'CREATE DATABASE ' + @dbname + @NL +
			      	'ON PRIMARY ' + @NL +
			      	'( NAME = ' + @dbname + '_mdf' + ',' + @NL +
			      	'FILENAME = ' + '"' + @mdfpathfile + '"' + ',' + @NL + 
			      	'SIZE = ' + @systemsize + ',' + @NL +
			      	'FILEGROWTH = 10 ),' + @NL +
			      	'FILEGROUP Group00' + @NL 

		if @ndffiles > 1
		  begin
			while @ndfcnt < @ndffiles 
				begin
				select @ndfcntchar = RIGHT('00'+CONVERT(varchar(2),@ndfcnt),2)
				select @ndfpathfile = @ndfpath + @dbname + '_00_' + @ndfcntchar + '.ndf'
				set @sql = @sql + 
					'( NAME = ' + @dbname + '_00_' + @ndfcntchar + '_ndf' + ','  + @NL +
				      	'FILENAME = ' + '"' + @ndfpathfile  +  '"' + ',' + @NL + 
				      	'SIZE = ' + convert(varchar(7), (@ndfsz)) + 'MB ' + ',' + 'FILEGROWTH = 0 )' + ',' + @NL

				select @ndfcnt = @ndfcnt + 1				
				end
		  end

		select @ndfcntchar = RIGHT('00'+CONVERT(varchar(2),@ndfcnt),2)
		select @ndfpathfile = @ndfpath + @dbname + '_00_' + @ndfcntchar + '.ndf'
		   		set @sql = @sql + 
				'( NAME = ' + @dbname + '_00_' + @ndfcntchar + '_ndf' + ','  + @NL +
			      	'FILENAME = ' + '"' + @ndfpathfile +  '"' + ',' + @NL + 
			      	'SIZE = ' + convert(varchar(7), (@ndfsz)) + 'MB ' + ',' + @NL +      
			      	'FILEGROWTH = 0 )' + @NL +
			      	'LOG ON' + @NL +
			      	'( NAME = ' + @dbname + '_ldf' + ','  + @NL +
			      	'FILENAME = ' + '"' + @ldfpathfile + '"' + ',' + @NL + 
			      	'SIZE = ' + convert(varchar(7), (@szlog)) + 'MB ' + ',' + @NL +        
			      	'FILEGROWTH = 0 )' +
				@collateArg

		exec(@sql)
		if @@error <> 0 
			begin
				select @errmsg = 'failure creating database'
				print @errmsg
				RETURN(1)
			end 
		
		/***** Next make Group00 the default Group so all data is added to this Group *****/
		
		select @sql = 'ALTER DATABASE ' + @dbname + ' MODIFY FILEGROUP Group00 DEFAULT'
		exec(@sql)
		if @@error <> 0 
			begin
				select @errmsg = 'failure setting filegroup default'
				print @errmsg
				RETURN(1)
	   end
	   
	end /** database did not exist **/
		


/** Next create backup devices
   
We will only create the backups devices if the @phydmp is Not Null.
    
**/


if(@phydmp is not null)
begin
  if @backupsets = 1  -- create just one backup set for db and log
  begin	
    select @msg = "sp_T38CRBKP @dbname = "+@dbname+", @bkptype = 'db', @phypath = '"+@phydmp+"'"  
    exec(@msg)
  
    select @msg = "sp_T38CRBKP @dbname = "+@dbname+", @bkptype = 'log', @phypath = '"+@phydmp+"'"
    exec(@msg)
  end

  if @backupsets > 1  -- create more than one backup set for db and log
  begin
    select @i = 2
    While (@i <= @backupsets)
    begin
      if not exists (select * from sysdevices 
      where name = @dbname + '_' + convert(char(1),@i) + '_db_bkp')
      begin
	select @msg = "sp_T38CRBKP @dbname = "+@dbname+", @bkptype = 'db', @phypath = '" + @phydmp +"', @nBkpDev ="+convert(char(1),@i)
 	exec(@msg)
      end
      if not exists (select * from sysdevices 
      where name = @dbname + '_' + convert(char(1),@i) + '_log_bkp')
      begin
	select @msg = "sp_T38CRBKP @dbname = "+@dbname+", @bkptype = 'log', @phypath = '" + @phydmp +"', @nBkpDev ="+convert(char(1),@i)
	exec(@msg)
      end
      
      select @i = @i + 1
    end   -- while loop
  end	-- create more than one backup set for db and log				 
end -- create backup sets

select @msg = 'sp_dboption '+@dbname+','+'autoshrink,'+'FALSE'
exec(@msg)
print 'Turning off the autoshrink option for database:  '+@dbname+'.'

select @msg = 'sp_dboption '+@dbname+','+'"auto update statistics",'+'"ON"'
exec(@msg)

select @msg = 'alter database '+@dbname+' set AUTO_UPDATE_STATISTICS_ASYNC ON'
exec(@msg)

/*  Add extended properties to the database   */

select @sql = 'EXEC [' + @dbname + '].sys.sp_addextendedproperty @name=N''T38Creator'', @value=''' + @DBcreator + ''''
exec(@sql)
if @@error <> 0 
	begin
		select @errmsg = 'failure adding T38Creator extended property'
		print @errmsg
		RETURN(1)
	end

set @chardate = cast(getdate() as char(20))
select @sql = 'EXEC [' + @dbname + '].sys.sp_addextendedproperty @name=N''T38CreateDate'', @value=''' + @chardate + ''''
exec(@sql)
if @@error <> 0 
	begin
		select @errmsg = 'failure adding T38CreateDate extended property'
		print @errmsg
		RETURN(1)
	end

select @sql = 'EXEC [' + @dbname + '].sys.sp_addextendedproperty @name=N''T38App'', @value=''' + @DBapp + ''''
exec(@sql)
if @@error <> 0 
	begin
		select @errmsg = 'failure adding T38App extended property'
		print @errmsg
		RETURN(1)
	end

select @sql = 'EXEC [' + @dbname + '].sys.sp_addextendedproperty @name=N''T38Desc'', @value=''' + @DBdesc + ''''
exec(@sql)
if @@error <> 0 
	begin
		select @errmsg = 'failure adding T38Desc extended property'
		print @errmsg
		RETURN(1)
	end

GO

-- end of sp_T38CRDB

if exists (select 1 from master.sys.objects where name = 'sp_T38CRDBSNAPSHOT')
begin
	print 'Dropping old version of sp_T38CRDBSNAPSHOT'
	drop procedure dbo.sp_T38CRDBSNAPSHOT
end
go

print 'Creating stored procedure: sp_T38CRDBSNAPSHOT'
go

/*
** sp_T38CRDBSNAPSHOT -- create snapshot of the database
**
** PVCS information
**
** $Author: A645276 $
** $Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/DBINST/SQL90/SourceCode/T38Procs.svl  $
** $Date: 2011/02/08 15:37:18 $
** $Revision: 1.1 $	
** 
*/

 

create PROCEDURE dbo.sp_T38CRDBSNAPSHOT
	@dbname sysname,
	@snapshotdb sysname
/*

exec sp_T38CRDBSNAPSHOT N'MXRDB001', N'MXRDR001'


*/

as
SET nocount on
SET xact_abort on

-- This procedure creates a snapshot database from the base database.
-- The names of the base database and snapshot database are passed as arguments.
-- Old snapshot database is dropped and new one is created.
-- NOTE: Since we cannot issue ALTER Database command to rename snapshot database,
-- old snapshot has to be dropped first to create new one with same name.

-- Declare variables used by script.

DECLARE
	@sql nvarchar(max)

DECLARE @file_name sysname,
	@physical_name sysname,
	@physical_name_new sysname,
	@timestamp sysname,
	@snapshotext sysname,
	@tmpstr nvarchar(max)		-- string for temp sql to be executed

-- Validate input

if (@dbname is null)
begin
	set @tmpstr = 'Missing source database name.'
	exec sp_T38LOGERROR 2, 'CREATESNAPSHOT', @tmpstr
	goto ExitThisCode
end

if (@snapshotdb is null)
begin
	set @tmpstr = 'Missing snapshot database name.'
	exec sp_T38LOGERROR 2, 'CREATESNAPSHOT', @tmpstr
	goto ExitThisCode
end

if (@dbname = @snapshotdb)
begin
	set @tmpstr = 'Snapshot database name ' + @snapshotdb + ' cannot be same as source database name.'
	exec sp_T38LOGERROR 2, 'CREATESNAPSHOT', @tmpstr
	goto ExitThisCode
end

if not exists (SELECT 1 FROM sys.master_files 
where db_name(database_id) = @dbname and type <> 1)
begin
	set @tmpstr = 'Source database ' + @dbname + ' has no files. Cannot create snapshot.'
	exec sp_T38LOGERROR 2, 'CREATESNAPSHOT', @tmpstr
	goto ExitThisCode
end

-- Initialize variables

set @snapshotext = 'ssh'
set @timestamp =  -- timestamp: yymmddhhmissmmm
	convert(varchar(6), getdate(), 12) + 
	replace(convert(varchar(12), getdate(), 14), ':', '')

-- Initialize output sql statement

SET @sql = 'CREATE DATABASE ' + @snapshotdb + ' ON
'

-- Get file group information

DECLARE dbfiles_cur CURSOR
READ_ONLY
FOR SELECT name, physical_name FROM sys.master_files 
where db_name(database_id) = @dbname and type <> 1
order by file_id

OPEN dbfiles_cur

FETCH NEXT FROM dbfiles_cur INTO @file_name, @physical_name

WHILE (@@fetch_status <> -1)
BEGIN
	IF (@@fetch_status <> -2)
	BEGIN
		SET @physical_name_new = @physical_name + '.' + @timestamp + '.' + @snapshotext
		SET @sql = @sql + ' ( NAME = N''' + @file_name + ''', FILENAME = N''' + @physical_name_new + ''' ),
'
	END
	FETCH NEXT FROM dbfiles_cur INTO @file_name, @physical_name
END

CLOSE dbfiles_cur
DEALLOCATE dbfiles_cur

-- remove last comma (,<CR><LF>)

SET @sql = Left(@sql, Len(@sql) -3)

SET @sql = @sql + '
AS SNAPSHOT OF ' + @dbname

-- Drop old snapshot

if (select count(*) from sys.databases where name = @snapshotdb) > 0
begin
	if (select source_database_id from sys.databases where name = @snapshotdb) is null
	begin
		-- We have problem. What we think is snapshot is not a snapshot but a regular database.
		-- Issue warning and exit.
		set @tmpstr = 'Database ' + @snapshotdb + ' is not a snapshot database.'
		exec sp_T38LOGERROR 2, 'CREATESNAPSHOT', @tmpstr
		set @tmpstr = 'Check input parameters: Source database name is ' + @dbname + '. Snapshot database name is ' + @snapshotdb + '.'
		exec sp_T38LOGERROR 3, 'CREATESNAPSHOT', @tmpstr
		goto ExitThisCode
	end
	-- Everything checked out. Drop old snapshot.
	set @tmpstr = 'drop database ' + @snapshotdb
	select @tmpstr
	EXEC sp_executesql @tmpstr
end
if @@error <> 0
begin
	set @tmpstr = 'Previous error prevents from setting snapshot datbase name ' + @snapshotdb
	exec sp_T38LOGERROR 2, 'CREATESNAPSHOT', @tmpstr
	goto ExitThisCode
end

-- Create snapshot.

select @sql
EXEC sp_executesql @sql
if @@error <> 0
begin
	set @tmpstr = 'Cannot create snapshot database ' + @snapshotdb
	exec sp_T38LOGERROR 2, 'CREATESNAPSHOT', @tmpstr
	goto ExitThisCode
end

ExitThisCode:

return

GO

-- end of sp_T38CRDBSNAPSHOT


PRINT " "
go


set nocount on
select "	using "+db_name()+" database"
go

set QUOTED_IDENTIFIER off
set ANSI_DEFAULTS off
go

/************  master stored procedures *********************/

/* First create stored procedures used by other procedures in this script */

/****** Object:  Stored Procedure dbo.sp_T38NETSEND    ******/
if exists (select * from sysobjects where id = object_id('dbo.sp_T38NETSEND') and sysstat & 0xf = 4)
begin
	print 'Dropping old version of dbo.sp_T38NETSEND'
	drop procedure dbo.sp_T38NETSEND
end
go

print 'Creating stored procedure: dbo.sp_T38NETSEND'
go

create procedure dbo.sp_T38NETSEND 
	@msg		varchar(200)	= NULL
as

/**	sp_T38NETSEND -- uses net send command to send a message 
 **	to predefined operators.
 **
 **	Parameters:
 **	@msg		= text of the message to send.
 **/

       	declare @cmd		varchar(255),
		@user		varchar(50)

	set nocount on

	declare operatorCursor cursor for select name from msdb..sysoperators
	where upper(name) <> 'T38ALERT' and enabled = 1

	open operatorCursor
	fetch next from operatorCursor into @user

	while (@@fetch_status = 0)
	begin
		select @cmd = 'net send ' + @user + ' ' + @msg
		exec master..xp_cmdshell @cmd
		fetch next from operatorCursor into @user
	end
	deallocate operatorCursor

GO

GRANT  EXECUTE  ON dbo.sp_T38NETSEND  TO public
GO

-- sp_T38LOGERROR

use master
go

if exists (select 1 from master..sysobjects where name = 'sp_T38LOGERROR')
begin
	print 'Dropping old version of dbo.sp_T38LOGERROR'
	drop procedure sp_T38LOGERROR
end
go

print 'Creating stored procedure: sp_T38LOGERROR'
go

CREATE procedure [dbo].[sp_T38LOGERROR] 

/*
** sp_T38LOGERROR -- logs errors to SQL Server Errorlog, NT Event Log and ITO messaging
**
** PVCS information
**
** $Author: A645276 $
** $Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/DBINST/SQL90/SourceCode/T38Procs.svl  $
** $Date: 2011/02/08 15:37:18 $
** $Revision: 1.1 $	
** 
*/

@error_level	smallint	= 2,	-- level of severity (see below)
@application	varchar(20)	= NULL,	-- application name
@msg		varchar(150)	= NULL  -- text of message 
as

if (@application is Null or @msg is Null)
begin
  print ''
  print '----------------------------------------------------------------------------'
  print 'sp_T38LOGERROR(T-SQL)'
  print ''
  print 'Sends a text message to the SQL Server Errorlog, NT Eventlog and ITO messaging.'
  print ''
  print 'Syntax:'
  print ''
  print 'sp_T38LOGERROR	 [@error_level = ] {0|1|2|3},'
  print '           	 [@application = ] [''application''],'
  print '           	 [@msg = ] {''msg''} ]'                                              
  print '' 
  print 'Arguments:'
  print ''
  print ' [@error_level =] {0 | 1 | 2 or 3}'                                                                                                                                                                                                       
  print ''
  print	'	Is the serverity level of the message.  It can be one of the following:'
  print '	0 - Critical error, which aborts the script, and creates a "Fatal" error in the '
  print '		NT Event log, SQL Server errorlog, and a "Critical" message to ITO.'
  print '	1 - Error - which creates an "Error" in the NT Event log, SQL Server errorlog,'
  print '		and sends a "Major" message to ITO.'
  print ' 	2 - Warning - which creates a "Warning" in the NT Event log, SQL Server errorlog,'
  print '		and sends a "Minor" message to ITO.'
  print '	3 - Note - an informative message is returned to the client with no error levels.'
  print ''
  print '	** Note: 2 is the default'
  print ''
  print ' [@application =  ] {''application''},'
  print ''
  print '	Is the name of the application sends the message. Default is APP_NAME()'
  print ''
  print ' [@msg = ] {''msg''} ]'                                        
  print ''
  print '	Is the text message to send when reporting the error'
  print ''
  print '----------------------------------------------------------------------------'
  print ''
  print 'Example:'                        
  print ''
  print '	EXEC sp_T38LOGERROR @error_level = 0, @application =''SQLXFER'', @msg = ''Unable to read log'''
  print ''
  print '----------------------------------------------------------------------------'
  print ''
  return(1)
end -- input validation


declare	@severity	smallint
declare	@level		smallint
declare @errmsg		varchar(512)
declare	@errtype	varchar(8)
declare @cmd		varchar(255)
declare @itoseverity	varchar(8)
declare @MachineName varchar(64)
declare @InstName    varchar(32)
declare @tmp		 varchar(520)
declare @IsClustered int;

	
if (@application is null) select @application = APP_NAME()

-- Note: SQL Server 7.0 versus 6.5 change
--
-- Caution Severity levels 20 through 25 are considered fatal. If a fatal severity level 
-- is encountered, the client connection is terminated after receiving the message, 
-- and the error is logged in the error log and the application log

if (@error_level > 3 or @error_level < 0) select @error_level = 2
select	@severity = 
	case @error_level
		when 0	then 22	-- send an snmp trap to 7 x 24 paging (aborts script)
		when 1	then 19 -- send an snmp trap to 7 x 24 paging (logs error but continues)
		when 2	then 11	-- send an snmp trap to e-mail (writes warning to standard out)
		when 3	then 0	-- send nothing 
	end

select	@level = 
	case @error_level
		when 0	then 127
		when 1	then 1
		when 2	then 1
		when 3	then 1
	end

select	@errtype = 
	case @error_level
		when 0	then "T38abort"
		when 1	then "T38error"
		when 2	then "T38warn"
		when 3	then "T38note"
	end

select	@itoseverity = 
	case @error_level
		when 0	then "critical"
		when 1	then "major"
		when 2	then "minor"
		when 3	then "note"
	end

select @errmsg =
	convert(varchar(8), getdate(), 1) + " " +
	convert(varchar(8), getdate(), 8) + ":" +
	@errtype + " (" +
	@application + ") " +
	@msg
		

if (@error_level <= 2) -- write error message to SQL Server log and  NT Event Viewer 
begin
--select @cmd = "echo DUMMY new_t38logerror_opcmsg program stub to be used en replacing HPOV with SCOM"

	-- Get the Machine Name 
	select @MachineName = convert (varchar(64), serverproperty('MachineName'))

	-- Get the Instance Name
	select @InstName = convert (varchar(64), serverproperty('InstanceName'))

	-- Is this a cluster
	select @IsClustered = convert (int, serverproperty('IsClustered'))

	IF (@IsClustered <> 0)
	BEGIN
		if (@InstName is not null)
		BEGIN
			select @tmp = '"'+@itoseverity+'__'+@errmsg+'"'
			select @cmd = 'perl \\'+@MachineName+'\t38app80.'+@MachineName+'\'+@InstName+'\T38logerror.pl -C'+@tmp
		END
		else
		BEGIN
			select @tmp = '"'+@itoseverity+'__'+@errmsg+'"'
			select @cmd = 'perl \\'+@MachineName+'\t38app80.'+@MachineName+'\T38logerror.pl -C'+@tmp
		END
	END
	else
	BEGIN
		if (@InstName is not NULL) 
		BEGIN
			select @tmp = '"'+@itoseverity+'__'+@errmsg+'"'
			select @cmd = 'perl \\'+@MachineName+'\t38app80\'+@InstName+'\T38logerror.pl -C'+@tmp
		END
		else
		BEGIN
			select @tmp = '"'+@itoseverity+'__'+@errmsg+'"'
			select @cmd = 'perl \\'+@MachineName+'\t38app80\T38logerror.pl -C'+@tmp
		END
	END
  print @cmd
  exec master..xp_cmdshell @cmd
  raiserror(@errmsg, @severity, @level) with log
end
else
begin
  raiserror(@errmsg, @severity, @level) -- log all @error_level 3 errors
end
GO

GRANT  EXECUTE  ON sp_T38LOGERROR TO public
GO

-- sp_T38OPCMSGCRITICAL

if exists (select 1 from master.sys.objects where name = 'sp_T38OPCMSGCRITICAL')
begin
	print 'Dropping old version of sp_T38OPCMSGCRITICAL'
	drop procedure sp_T38OPCMSGCRITICAL
end
go

print 'Creating stored procedure: sp_T38OPCMSGCRITICAL'
go

create procedure [dbo].[sp_T38OPCMSGCRITICAL] 

/*
** sp_T38OPCMSGCRITICAL -- logs errors to SQL Server Errorlog, NT Event Log and ITO messaging
**
** PVCS information
**
** $Author: A645276 $
** $Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/DBINST/SQL90/SourceCode/T38Procs.svl  $
** $Date: 2011/02/08 15:37:18 $
** $Revision: 1.1 $	
** 18-Nov-09    Modified to include t38error for SCOm Alerting 
*/

@application	nvarchar(20)	= NULL,	-- application name
@msg			nvarchar(256)	= NULL  -- text of message 
as

if (@application is Null or @msg is Null)
begin
  print ''
  print '----------------------------------------------------------------------------'
  print 'sp_T38OPCMSGCRITICAL(T-SQL)'
  print ''
  print 'Sends critical message to the SQL Server Errorlog, NT Eventlog and ITO messaging.'
  print ''
  print 'Syntax:'
  print ''
  print 'sp_T38OPCMSGCRITICAL	 '
  print '           	 [@application = ] [''application''],'
  print '           	 [@msg = ] {''msg''} ]'                                              
  print '' 
  print 'Arguments:'
  print ''
  print ' [@application =  ] {''application''},'
  print ''
  print '	Is the name of the application sends the message. Default is APP_NAME()'
  print ''
  print ' [@msg = ] {''msg''} ]'                                        
  print ''
  print '	Is the text message to send when reporting the error'
  print ''
  print '----------------------------------------------------------------------------'
  print ''
  print 'Example:'                        
  print ''
  print '	EXEC sp_T38OPCMSGCRITICAL @application =''SQLXFER'', @msg = ''Unable to read log'''
  print ''
  print '----------------------------------------------------------------------------'
  print ''
  return(1)
end -- input validation


declare	@severity	smallint
declare	@level		smallint
declare @errmsg		nvarchar(512)
declare	@errtype	varchar(10)
declare @cmd		nvarchar(1024)
declare @itoseverity	varchar(8)

	
if (@application is null) select @application = APP_NAME()

-- Try to prevent SQL Injection.
set @application = replace (@application, nchar(10), '?')
set @application = replace (@application, nchar(13), '?')
set @application = replace (@application, '"', '?')
set @application = replace (@application, '''', '?')

set @msg = replace (@msg, nchar(10), '?')
set @msg = replace (@msg, nchar(13), '?')
set @msg = replace (@msg, '"', '?')
set @msg = replace (@msg, '''', '?')

-- Initialize error level.
select	@severity = 1
select	@level = 1
select	@errtype = 't38error'
select	@itoseverity = 'major'

-- Set error message.
select @errmsg =
	convert(varchar(8), getdate(), 1) + ' ' +
	convert(varchar(8), getdate(), 8) + ':' +
	@errtype + ' (' +
	@application + ') ' +
	@msg
		

select @cmd = 'opcmsg application=T38ALERT msg_grp=BBY_T38 object=T38LOGERROR severity="'
	+@itoseverity+'" msg_text="'+@errmsg+'"'
print @cmd
exec master..xp_cmdshell @cmd
raiserror(@errmsg, @severity, @level) with log
GO

 
/****** Object:  Stored Procedure dbo.sp_T38DBCURSOR    ******/
if exists (select * from sysobjects where id = object_id('dbo.sp_T38DBCURSOR') and sysstat & 0xf = 4)
begin
	print 'Dropping old version of dbo.sp_T38DBCURSOR'
	drop procedure dbo.sp_T38DBCURSOR
end
GO

print 'Creating stored procedure: dbo.sp_T38DBCURSOR'
go

create procedure [dbo].[sp_T38DBCURSOR]
	@cmd		varchar(8000),
	@dbin		varchar(8000)	= NULL,
	@dbnotin	varchar(8000)	= NULL,
	@EXCLUDE_SNAPSHOTS char(1) = 'N',
	@EXCLUDE_READONLY  char(1) = 'N',
	@EXCLUDE_SYSTEMDB  char(1) = 'N'
as

/**	sp_T38DBCURSOR -- executes command in requested database.
 **
 **	This stored procedure scrolls through specified databases and
 **	executes provided command in each of them.
 **
 **	Parameters:
 **	@cmd		Command string to execute in each database.
 **	@dbin		List of databases to include.
 **	@dbnotin	If @dbin is null, list of databases to exclude.
 **
 **	Example:
 **
 **	Switch to PSIDB001 and ISPDB001 and print switched database name.
 **	exec sp_T38DBCURSOR @cmd = "select @db_name()", @dbin = "'PSIDB001', 'ISPDB001'"
 **
 **	Switch to all databases, excluding master, model, msdb, pubs and tempdb
 **	and print switched database name.
 **	exec sp_T38DBCURSOR @cmd = "select @db_name()",  @dbnotin = "'master', 'model', 'msdb', 'tempdb', 'pubs'"
 ** 	3-Feb-2010 	@EXCLUDE_SNAPSHOTS,@EXCLUDE_READONLY, @EXCLUDE_SYSTEMDB included 
 **/

	declare	@dbname		sysname
	declare @cCond	as varchar(100)
	--state = 0 and source_database_id is Null and
	if (@cmd is null)
	begin
		exec sp_T38LOGERROR 2, "ForEachDB", "Empty command string."
		return
	end
	Set @cCond=''
	If @EXCLUDE_SNAPSHOTS ='Y' Set @cCond = @cCond + ' and source_database_id is Null '
	If @EXCLUDE_READONLY = 'Y' Set @cCond = @cCond + ' and is_read_only = 0 '
	If @EXCLUDE_SYSTEMDB = 'Y' Set @cCond = @cCond + ' and database_id > 4 '
	
	if (@dbin is not null)
	begin
		exec ("declare dbnames_cursor cursor for " + 
			"select name from sys.databases " +
			"where state=0 and name in (" + @dbin + ") " +
			@cCond +  "order by name")
	end
	else if (@dbnotin is not null)
	begin
		exec ("declare dbnames_cursor cursor for " + 
			"select name from sys.databases " +
			"where state=0 and name not in (" + @dbnotin + ") " +
			@cCond +  " order by name")
	end
	else
	begin
		exec ("declare dbnames_cursor cursor for " + 
			"select name from sys.databases " +
			" where state = 0" +@cCond +" order by name")
	end
	
	open dbnames_cursor
	fetch next from dbnames_cursor into @dbname
	while @@fetch_status = 0
	begin
		EXEC ("use [" + @dbname + "] " + @cmd)
		fetch next from dbnames_cursor into @dbname
	end
	deallocate dbnames_cursor

GO


GRANT  EXECUTE  ON dbo.sp_T38DBCURSOR  TO public
GO


/****** Object:  Stored Procedure dbo.sp_T38DBFILESIZE ******/

if exists (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_T38DBFILESIZE]') AND type in (N'P', N'PC'))
begin
	print 'Dropping old version of dbo.sp_T38DBFILESIZE'
	drop procedure [dbo].[sp_T38DBFILESIZE]
end
go

print 'Creating stored procedure: dbo.sp_T38DBFILESIZE'
go

create procedure dbo.sp_T38DBFILESIZE
as
/**	sp_T38DBFILESIZE -- calculate database sizes
 **
 **	Date:	February 23, 2006
 **	Author:	TSMMXR
 **
 **	This stored procedure reports file allocated size and space used.
 **	It calculates these parameters in current database. 
 **
 **/
	declare @dbname 	sysname
	declare	@sqlstr		varchar(1024)

	set nocount on

select @dbname = db_name();
set @sqlstr = 'Select ''' + @dbname + ''' as ''Database Name'', name as ''File Name'',
	FILEPROPERTY (name, ''islogfile'') as ''IsLogFile'', 
	round(cast(size as float)*8/1024, 0) as ''Size (MB)'',
	round(cast(FILEPROPERTY (name, ''spaceused'') as float)*8/1024, 0) as ''Used (MB)''
	from [' + @dbname + '].dbo.sysfiles'
-- print @sqlstr
execute (@sqlstr)

GO
GRANT EXECUTE ON dbo.sp_T38DBFILESIZE to public
GO


/****** Object:  Stored Procedure dbo.sp_T38DBSIZE ******/

if exists (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_T38DBSIZE]') AND type in (N'P', N'PC'))
begin
	print 'Dropping old version of dbo.sp_T38DBSIZE'
	drop procedure dbo.sp_T38DBSIZE
end
go

CREATE Procedure [dbo].[sp_T38DBSIZE]
as
/**	sp_T38DBSIZE -- calculate database sizes
 **
 **	Date:	March 23, 2000
 **	Author:	TSMMXR
 **     Version 1.2	
 **	Modified for Microsoft SQL Server 2005. 
 **	Same code should work with SQL 7 and 2000.
 **
 **	This stored procedure reports database allocated size and space used.
 **	It calculates these parameters in current database. Also sp_T38DBSIZE
 **	produce notifications, in case used space is approaching critical
 **	limits.
 **
 ** 	13-Oct-2009 Modified to remove alerting when database size exceeds thresholds
 **/
 	declare	@pages		int			-- Working variable for size calc.
	declare @dbname 	sysname
	declare @dbsize 	decimal(15,2)
	declare	@dbused 	decimal(15,2)
	declare @filename	varchar(48)
	declare	@filesize	decimal(15,2)
	declare	@fileused	decimal(15,2)
	declare	@rate		decimal(5,2)
	declare	@msg		varchar(max)
	declare	@sqlstr		nvarchar(max)

	declare @tblfilesz table (
		FileName	sysname,
		IsLogFile	bit,
		Size		int,
		Used		int
	)
	set nocount on

	select @dbname = db_name();


	set @sqlstr = N'Select name as ''FileName'',
		FILEPROPERTY (name, ''IsLogFile'') as ''IsLogFile'', 
		size as ''Size'',
		FILEPROPERTY (name, ''spaceused'') as ''Used''
		from [' + @dbname + '].dbo.sysfiles'
	--print @sqlstr

	insert into @tblfilesz execute sp_executesql @sqlstr;


	select @dbsize = cast(sum(Size) as decimal(15,2))*8/1024 from @tblfilesz where IsLogFile = 0
	select @dbused = cast(sum(Used) as decimal(15,2))*8/1024 from @tblfilesz where IsLogFile = 0

	/* Print final summary */
	select
		convert(char(10),getdate(),111) + ' ' + convert(char(8),getdate(),8) as 'Date',
		convert (char(25), @@servername) as 'Server',
		convert(varchar(30), @dbname) as 'DB Name',
		@dbsize as 'DB Size (MB)',
		@dbused as 'Used (MB)',
		convert(decimal(5,2), (@dbused/@dbsize)*100) as  '% Full'
	set nocount off
GO
GRANT EXECUTE ON dbo.sp_T38DBSIZE to public
GO


/* Create stored procedures */

/****** Object:  Stored Procedure dbo.sp_T38CHECKCATALOG    ******/
if exists (select * from sysobjects where id = object_id('dbo.sp_T38CHECKCATALOG') and sysstat & 0xf = 4)
begin
	print 'Dropping old version of dbo.sp_T38CHECKCATALOG'
	drop procedure dbo.sp_T38CHECKCATALOG
end
go

print 'Creating stored procedure: dbo.sp_T38CHECKCATALOG'
go
CREATE PROCEDURE dbo.sp_T38CHECKCATALOG
AS
	DECLARE @databasename varchar(128)
	SELECT @databasename = db_name()
	EXEC ("sp_T38LOGERROR 3, 'DB_CHKS', 'Checking catalog CHECKDB for database " + @databasename + "'")
	EXEC ("DBCC CHECKCATALOG WITH NO_INFOMSGS")
	if @@ERROR <> 0
	begin
		EXEC ("sp_T38LOGERROR 3, 'DB_CHKS', 'CHECKCATALOG Errors for  " + @databasename + " database'")
	end

GO

/*
GRANT  EXECUTE  ON dbo.sp_T38CHECKCATALOG  TO prod
--go
*/

/****** Object:  Stored Procedure dbo.sp_T38CHECKDB    ******/
if exists (select * from sysobjects where id = object_id('dbo.sp_T38CHECKDB') and sysstat & 0xf = 4)
begin
	print 'Dropping old version of dbo.sp_T38CHECKDB'
	drop procedure dbo.sp_T38CHECKDB
end
go

print 'Creating stored procedure: dbo.sp_T38CHECKDB'
go
CREATE PROCEDURE dbo.sp_T38CHECKDB
AS
	DECLARE @databasename varchar(128)
	SELECT @databasename = db_name()
	EXEC ("sp_T38LOGERROR 3, 'DB_CHKS', 'Running CHECKDB for database " + @databasename + "'")
	EXEC ("DBCC CHECKDB WITH NO_INFOMSGS")
	if @@ERROR <> 0
	begin
		EXEC ("sp_T38LOGERROR 3, 'DB_CHKS', 'CHECKDB Errors for  " + @databasename + " database'")
	end

GO

/*
GRANT  EXECUTE  ON dbo.sp_T38CHECKDB  TO prod
--go
*/



GO
print 'Creating sp_T38hexadecimal'
GO

IF OBJECT_ID ('dbo.sp_T38hexadecimal') IS NULL
begin
	exec ('create procedure dbo.sp_T38hexadecimal as select 1')
end
go

alter procedure sp_T38hexadecimal
    @binvalue varbinary(256),
    @hexvalue varchar (514) OUTPUT
/*
** sp_T38hexadecimal -- convert binary value to hexadecimal character string
**
** This stored procedure is based on Microsoft KB Article Q918992
** http://support.microsoft.com/kb/918992/
**
** PVCS information
**
** $Author: A645276 $
** $Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/DBINST/SQL90/SourceCode/T38Procs.svl  $
** $Date: 2011/02/08 15:37:18 $
** $Revision: 1.1 $	
** 
*/

AS
DECLARE @charvalue varchar (514)
DECLARE @i int
DECLARE @length int
DECLARE @hexstring char(16)
SELECT @charvalue = '0x'
SELECT @i = 1
SELECT @length = DATALENGTH (@binvalue)
SELECT @hexstring = '0123456789ABCDEF'
WHILE (@i <= @length)
BEGIN
  DECLARE @tempint int
  DECLARE @firstint int
  DECLARE @secondint int
  SELECT @tempint = CONVERT(int, SUBSTRING(@binvalue,@i,1))
  SELECT @firstint = FLOOR(@tempint/16)
  SELECT @secondint = @tempint - (@firstint*16)
  SELECT @charvalue = @charvalue +
    SUBSTRING(@hexstring, @firstint+1, 1) +
    SUBSTRING(@hexstring, @secondint+1, 1)
  SELECT @i = @i + 1
END

SELECT @hexvalue = @charvalue
GO
 
-- End of sp_T38hexadecimal

print 'Creating sp_T38help_revlogin'
go

IF OBJECT_ID ('sp_T38help_revlogin') IS NULL
begin
	exec ('create procedure dbo.sp_T38help_revlogin as select 1')
end
go

alter PROCEDURE sp_T38help_revlogin 
	@action char(3) = 'sql',
	@login_name sysname = NULL

/*
** sp_T38help_revlogin -- script logins
**
** This stored procedure is based on Microsoft KB Article Q918992
** http://support.microsoft.com/kb/918992/
**
** PVCS information
**
** $Author: A645276 $
** $Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/DBINST/SQL90/SourceCode/T38Procs.svl  $
** $Date: 2011/02/08 15:37:18 $
** $Revision: 1.1 $	
** 
** Parameters:
**	@login_name	create script for one login name
**	@action		controls which group of logins to script. Values are:
**			all	All accounts, except sa 
**			sql	All SQL Server standard login accounts, except sa (default)
**			nt	All trusted NT login accounts.
**
** !!!!!! WARNING!!!!!
** When scripting all accounts or NT accounts, carefully review all
** NT Accounts.
** Example:
**
**	print '----------------------------------------------------------------------'
**	print '--------------------------- SQL Accounts -----------------------------'
**	print '----------------------------------------------------------------------'
**	exec sp_T38help_revlogin @action = 'sql'
**	print '----------------------------------------------------------------------'
**	print '--------------------------- NT Accounts ------------------------------'
**	print '----------------------------------------------------------------------'
**	exec sp_T38help_revlogin @action = 'nt'
**	print '----------------------------------------------------------------------'
**	print '--------------------------- All Accounts -----------------------------'
**	print '----------------------------------------------------------------------'
**	exec sp_T38help_revlogin @action = 'all'
**	print '----------------------------------------------------------------------'
**	print '--------------------------- One Account -----------------------------'
**	print '----------------------------------------------------------------------'
**	exec sp_T38help_revlogin @login_name = 'batch'
*/

AS
set nocount on

DECLARE @name sysname
DECLARE @type varchar (1)
DECLARE @hasaccess int
DECLARE @denylogin int
DECLARE @is_disabled int
DECLARE @PWD_varbinary  varbinary (256)
DECLARE @PWD_string  varchar (514)
DECLARE @SID_varbinary varbinary (85)
DECLARE @SID_string varchar (514)
DECLARE @tmpstr  varchar (1024)
DECLARE @is_policy_checked varchar (3)
DECLARE @is_expiration_checked varchar (3)

DECLARE @defaultdb sysname
 

IF (@login_name IS NOT NULL)
  DECLARE login_curs CURSOR FOR

      SELECT p.sid, p.name, p.type, p.is_disabled, p.default_database_name, l.hasaccess, l.denylogin FROM 
      sys.server_principals p LEFT JOIN sys.syslogins l
      ON ( l.name = p.name ) WHERE p.type IN ( 'S', 'G', 'U' ) AND p.name = @login_name

ELSE if (@action is NOT NULL and lower(@action) = 'sql')
  DECLARE login_curs CURSOR FOR 
      SELECT p.sid, p.name, p.type, p.is_disabled, p.default_database_name, l.hasaccess, l.denylogin FROM 
      sys.server_principals p LEFT JOIN sys.syslogins l
      ON ( l.name = p.name ) WHERE p.type = 'S' AND p.name <> 'sa'

ELSE if (@action is NOT NULL and lower(@action) = 'nt')
  DECLARE login_curs CURSOR FOR 
      SELECT p.sid, p.name, p.type, p.is_disabled, p.default_database_name, l.hasaccess, l.denylogin FROM 
      sys.server_principals p LEFT JOIN sys.syslogins l
      ON ( l.name = p.name ) WHERE p.type IN ( 'G', 'U' ) AND p.name <> 'sa'

ELSE 
  DECLARE login_curs CURSOR FOR 

      SELECT p.sid, p.name, p.type, p.is_disabled, p.default_database_name, l.hasaccess, l.denylogin FROM 
      sys.server_principals p LEFT JOIN sys.syslogins l
      ON ( l.name = p.name ) WHERE p.type IN ( 'S', 'G', 'U' ) AND p.name <> 'sa'


OPEN login_curs

FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin
IF (@@fetch_status = -1)
BEGIN
  PRINT 'No login(s) found.'
  CLOSE login_curs
  DEALLOCATE login_curs
  RETURN -1
END
SET @tmpstr = '/* sp_T38help_revlogin script '
PRINT @tmpstr
SET @tmpstr = '** Generated ' + CONVERT (varchar, GETDATE()) + ' on ' + @@SERVERNAME + ' */'
PRINT @tmpstr
PRINT ''

set @tmpstr = '
select @@SERVERNAME'+char(13)+char(10)+ 'go
select getdate()'+char(13)+char(10)+'go
'
print @tmpstr
PRINT ''

WHILE (@@fetch_status <> -1)
BEGIN
  IF (@@fetch_status <> -2)
  BEGIN
    PRINT ''
    SET @tmpstr = '-- Login: ' + @name
    PRINT @tmpstr
    PRINT 'DECLARE @pwd 		sysname,'
    PRINT '	@procname	sysname'
    PRINT 'set @procname = ''sp_T38help_revlogin'''
    PRINT ''
    IF (@type IN ( 'G', 'U'))
    BEGIN -- NT authenticated account/group
      SET @tmpstr = 'IF EXISTS (select 1 from sys.server_principals where name = '''
          + @name + ''')
      exec sp_T38LOGERROR 3, @procname, ''Nothing to do, login ' + @name + ' already created!'''
      PRINT @tmpstr
      PRINT 'else begin'
      SET @tmpstr = '      CREATE LOGIN ' + QUOTENAME( @name ) + ' FROM WINDOWS WITH DEFAULT_DATABASE = [' + @defaultdb + ']'
    END
    ELSE BEGIN -- SQL Server authentication
        -- obtain password and sid
            SET @PWD_varbinary = CAST( LOGINPROPERTY( @name, 'PasswordHash' ) AS varbinary (256) )
        EXEC sp_T38hexadecimal @PWD_varbinary, @PWD_string OUT
        EXEC sp_T38hexadecimal @SID_varbinary,@SID_string OUT
 
        -- obtain password policy state
        SELECT @is_policy_checked = CASE is_policy_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END FROM sys.sql_logins WHERE name = @name
        SELECT @is_expiration_checked = CASE is_expiration_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END FROM sys.sql_logins WHERE name = @name
 
         SET @tmpstr = 'IF EXISTS (select 1 from sys.sql_logins where name = '''
          + @name + ''' and sid = 
          ' + @SID_string + '
           and password_hash = 
           ' + @PWD_string + 
          '
          ) exec sp_T38LOGERROR 3, @procname, ''Nothing to do, login ' + @name + ' already created!'''
        PRINT @tmpstr
	PRINT 'else'
	SET @tmpstr = 'IF EXISTS (select 1 from sys.sql_logins where name = '''
          + @name + ''') exec sp_T38LOGERROR 1, @procname, ''The ' + @name + ' account exists with old password or sid. Detach all databases, drop this account and re-run the script!'''
        PRINT @tmpstr
        SET @tmpstr = 'else begin'
        PRINT @tmpstr
        
                   SET @tmpstr = 'CREATE LOGIN ' + QUOTENAME( @name ) + ' WITH PASSWORD = ' + @PWD_string + ' HASHED, SID = ' + @SID_string + ', DEFAULT_DATABASE = [' + @defaultdb + ']'

        IF ( @is_policy_checked IS NOT NULL )
        BEGIN
          SET @tmpstr = @tmpstr + ', CHECK_POLICY = ' + @is_policy_checked
        END
        IF ( @is_expiration_checked IS NOT NULL )
        BEGIN
          SET @tmpstr = @tmpstr + ', CHECK_EXPIRATION = ' + @is_expiration_checked
        END
    END
    IF (@denylogin = 1)
    BEGIN -- login is denied access
      SET @tmpstr = @tmpstr + '; DENY CONNECT SQL TO ' + QUOTENAME( @name )
    END
    ELSE IF (@hasaccess = 0)
    BEGIN -- login exists but does not have access
      SET @tmpstr = @tmpstr + '; REVOKE CONNECT SQL TO ' + QUOTENAME( @name )
    END
    IF (@is_disabled = 1)
    BEGIN -- login is disabled
      SET @tmpstr = @tmpstr + '; ALTER LOGIN ' + QUOTENAME( @name ) + ' DISABLE'
    END
    PRINT @tmpstr
    SET @tmpstr = 'end' + char(13)+char(10) + 'GO'
    PRINT @tmpstr
  END

  FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin
   END
CLOSE login_curs
DEALLOCATE login_curs
RETURN 0
GO

-- End of sp_T38help_revlogin

/****** Object:  Stored Procedure dbo.sp_T38SCANDB ******/

if exists (select * from sysobjects where name = 'sp_T38SCANDB')
begin
	print 'Dropping old version of dbo.sp_T38SCANDB'
	drop procedure dbo.sp_T38SCANDB
end
go

print 'Creating stored procedure: dbo.sp_T38SCANDB'
go

create procedure dbo.sp_T38SCANDB
as

declare @dbname		varchar(128)
set nocount on

Declare cur cursor for select name from master..sysdatabases where name not in 
	('model', 'pubs', 'Northwind', 'AdventureWorks', 'AdventureWorksDW')
order by dbid

open cur

fetch next from cur into @dbname
while (@@fetch_status <> -1)
begin
	if (@@fetch_status <> -2 ) 
	begin
		exec ('use ' + @dbname + '; exec sp_T38DBSIZE')
	end
	fetch next from cur into @dbname
end
DEALLOCATE cur

set nocount off
go

GRANT EXECUTE ON sp_T38SCANDB to public
GO


/****** Object:  Stored Procedure dbo.sp_T38VCSVER_PROCS    ******/
if exists (select * from sysobjects where id = object_id('dbo.sp_T38VCSVER_PROCS') and sysstat & 0xf = 4)
begin
	print 'Dropping old version of dbo.sp_T38VCSVER_PROCS'
	drop procedure dbo.sp_T38VCSVER_PROCS
end
go

print 'Creating stored procedure: dbo.sp_T38VCSVER_PROCS'
go

create procedure dbo.sp_T38VCSVER_PROCS 
	@vcsver		varchar(1024)	= NULL OUTPUT
as

/**	sp_T38VCSVER_PROCS -- return version information for procs.sql.
 **
 **	Parameters:
 **	@msg		= text with version information.
 **/

	select @vcsver = "$Author: A645276 $
$Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/DBINST/SQL90/SourceCode/T38Procs.svl  $
$Date: 2011/02/08 15:37:18 $
$Revision: 1.1 $"

	select @vcsver
GO

GRANT  EXECUTE  ON dbo.sp_T38VCSVER_PROCS  TO public
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_T38share2phypath]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print 'Dropping old version of dbo.sp_T38share2phypath'
	drop procedure [dbo].[sp_T38share2phypath]
end
GO



print 'Creating stored procedure: dbo.sp_T38share2phypath'
go

CREATE PROCEDURE dbo.sp_T38share2phypath (
	@sharename		sysname = NULL,
	@phy_path		sysname = NULL output
)
as

/**	sp_T38share2phypath  -convert share name to physical path.
 **
 **	Parameters:
 **	Input:
 **		@sharename		Name of the share.
 **	Output:
 **		@phy_path		physical path
 **	Example:
 **
 ** declare @mypath sysname; exec master.dbo.sp_T38share2phypath @sharename = 't38app80.DVD08DB01', @phy_path = @mypath output; select @mypath as 'mypath'
 **/
begin
	

DECLARE @phy_path_tbl table(
    [Value] varchar(256) NULL,
    [Data] varchar(256) NULL);

insert into @phy_path_tbl
exec xp_regread 
	N'HKEY_LOCAL_MACHINE'
	, N'SYSTEM\CurrentControlSet\Services\lanmanserver\Shares'
	, @sharename
	-- , @param = @phy_path output  
	, @no_output = 'no_output'

	select @phy_path = substring(Data, 6, 256) From @phy_path_tbl where Data like 'path=%' collate SQL_Latin1_General_CP1_CI_AS
	-- select @phy_path as phy_path
end	-- sp_T38share2phypath



GO

/** Create main DBCC SHOWCONTIG procedure **/


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_T38SHOWCONTIG]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print 'Dropping old version of dbo.sp_T38SHOWCONTIG'
	drop procedure [dbo].[sp_T38SHOWCONTIG]
end
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO


print 'Creating stored procedure: dbo.sp_T38SHOWCONTIG'
go


CREATE  procedure sp_T38SHOWCONTIG


/*
** sp_T38SHOWCONTIG(T-SQL) -- Runs the DBCC showcontig on all user database, it uses sp_T38DBCURSOR
**
** PVCS information
**
** $Author: A645276 $
** $Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/DBINST/SQL90/SourceCode/T38Procs.svl  $
** $Date: 2011/02/08 15:37:18 $
** $Revision: 1.1 $	
** 
*/

AS

DECLARE	@id int,
	@indid smallint,
	@stmnt1 varchar(232),
	@stmnt varchar(232),
	@dbname sysname,
	@idxname sysname,
	@rows int,
	@sqlstr nvarchar(max)


declare @myind table (
	object_id	int,
	index_id	int,
	indname		sysname,
	rows		bigint
)

set @dbname = db_name();
set @sqlstr = N'
		select i.object_id, i.index_id, i.name, sum(p.rows) as rows
		from ' + @dbname + '.sys.indexes i join ' + @dbname + '.sys.partitions p on i.object_id = p.object_id and i.index_id = p.index_id
		where
			i.type_desc not in (''HEAP'', ''XML'')
			and i.object_id > 100
			and i.is_disabled = 0
			and i.is_hypothetical = 0
			and p.rows > 0
AND i.object_id NOT IN (SELECT object_id FROM sys.objects WHERE type = ''IT'')
		group by i.object_id, i.index_id, i.name
	'

insert into @myind exec sp_executesql @sqlstr

-- New cursor select statement, previous on was not selecting
-- some indexes
        
    DECLARE inner_cursor CURSOR FOR
		select object_id, index_id, indname, rows from @myind

    OPEN inner_cursor
    FETCH NEXT FROM inner_cursor INTO @id, @indid, @idxname, @rows

    WHILE @@FETCH_STATUS = 0
    BEGIN
	
	select @stmnt = 'DBCC FOR DB: ' + '''' + db_name() + '''' + '  IDX NAME: ' + '''' +
               @idxname + '''' + '  Row Counts: ' + '''' + CONVERT(varchar(20), @rows)+ '''' +
               '  Srvr Name: ' + '''' + @@servername + ''''
        print '  '
	print @stmnt
	PRINT '----------------------'
               
	SELECT @stmnt = 'DBCC SHOWCONTIG('
	SELECT @stmnt = @stmnt + CONVERT(varchar(20), @id) + ',' + CONVERT(varchar(20), @indid) + ')'

	-- print @stmnt
	EXEC (@stmnt)

	IF @@ERROR <> 0 
  	BEGIN
	EXEC ('sp_T38LOGERROR 2, ''sp_T38SHOWCONTIG'', ''Errors detecting in try to dbcc showcontig on  ' + @idxname + '''')
  	END

    FETCH NEXT FROM inner_cursor INTO @id, @indid, @idxname, @rows
    END
    CLOSE inner_cursor
    DEALLOCATE inner_cursor



GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

GRANT  EXECUTE  ON dbo.sp_T38SHOWCONTIG  TO public
GO

/** End Create of DBCC SHOWCONTIG procedure **/


/*****************************************************************************/
/****  Create stored procedure to manage SQL Logins for SCOF             *****/
/*****************************************************************************/

/****** Object:  Stored Procedure dbo.sp_T38addlogin    Script Date: 10/5/2005 9:11:19 AM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_T38addlogin]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print 'Dropping old version of dbo.sp_T38addlogin'
	drop procedure [dbo].[sp_T38addlogin]
end
GO

exec sp_configure 'allow updates',1
reconfigure with override
go

print 'Creating stored procedure: dbo.sp_T38addlogin'
go

create procedure sp_T38addlogin
    @loginame		sysname
   ,@passwd         sysname = Null
   ,@defdb          sysname = 'master'      -- UNDONE: DEFAULT CONFIGURABLE???
   ,@deflanguage    sysname = Null
   ,@sid			varbinary(16) = Null
   ,@encryptopt		varchar(20) = Null
AS
    -- SETUP RUNTIME OPTIONS / DECLARE VARIABLES --
	set nocount on
	Declare @ret    int    -- return value of sp call

	exec sp_T38LOGERROR 1, 'T38addlogin', 'sp_T38addlogin is not converted to SQL 2005'

	return  (1)	-- sp_T38addlogin

GO

exec sp_configure 'allow updates',0
reconfigure with override
go

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_T38password]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print 'Dropping old version of dbo.sp_T38password'
	drop procedure [dbo].[sp_T38password]
end
GO

print 'Creating stored procedure: dbo.sp_T38password'
go

create procedure sp_T38password
   @oldpwd		sysname = Null
   ,@newpwd		sysname = Null
AS
	Declare @ret    int    -- return value of sp call
	-- This stored procedure would have to be executed by SCOF standard login instead of
	-- the generic SCOF account, that created the login.

	execute @ret = sp_password @old = @oldpwd, @new = @newpwd
	return(@ret)
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

if not exists (select * from dbo.sysusers where name =  N'DWSCOFMngLogins_role' and issqlrole = 1)
begin
	print 'Create role DWSCOFMngLogins_role'
	execute sp_addrole [DWSCOFMngLogins_role]
end
go

GRANT  EXECUTE  ON [dbo].[sp_T38addlogin]  TO [DWSCOFMngLogins_role]
GRANT  EXECUTE  ON [dbo].[sp_T38password]  TO [public]
GO

/*****************************************************************************/
/****  End of Create stored procedure to manage SQL Logins for SCOF      *****/
/*****************************************************************************/

PRINT ' '
go

select '
End of script' = convert(varchar(8), getdate(), 1) + ' ' + convert(varchar(8), getdate(), 8) + ': $Workfile:   T38Procs.sql  $, $Revision: 1.1 $'
go

/*** End script ***/

/*
** sp_T38CRDBNC(T-SQL) -- creates user databases with non-compliant names
**
*/

/****** Object:  StoredProcedure [dbo].[sp_T38CRDBNC]    Script Date: 04/21/2009 12:18:45 ******/

print 'Creating stored procedure: dbo.sp_T38CRDBNC'
go

if not exists (select * from sysobjects where id = object_id('dbo.sp_T38CRDBNC') and sysstat & 0xf = 4)
begin
	exec ('create procedure dbo.sp_T38CRDBNC as select 1')
end
go
ALTER  procedure dbo.sp_T38CRDBNC

@dbname		varchar (50) = NULL,	-- database name
@mdfpath	varchar(255) = NULL,	-- file path for holding system data for user db
@ndfpath	varchar(255) = NULL,	-- file path for holding user data for user db
@ldfpath	varchar(255) = NULL,	-- file path for db transaction log
@szdb		int = NULL,				-- database size
@szlog		int = NULL,				-- database log size
@phydmp		varchar (30) = NULL,	-- path for backup files
@collate	sysname = NULL,			-- optional collation name
@backupsets	int = 1,				-- number of backup files for db and log
@ndffiles	int = NULL, 			-- number of ndf files for db
@DBcreator	varchar (30) = NULL,		-- The name of the DBA that originally created the database
@DBcreatedate datetime = NULL,	-- The date the database was orginally created
@DBapp		varchar (30) = NULL,		-- The name of the application that uses the database
@DBdesc		varchar (255) = NULL	-- A description of what the database is

as

-- validate input variables

if (@dbname is Null) 
begin
  print 'Procedure ''sp_T38CRDBNC'' expects parameter ''@dbname'', which was not supplied.'
end

if (@mdfpath is Null) 
begin
  print 'Procedure ''sp_T38CRDBNC'' expects parameter ''@mdfpath'', which was not supplied.'
end

if (@ndfpath is Null) 
begin
  print 'Procedure ''sp_T38CRDBNC'' expects parameter ''@ndfpath'', which was not supplied.'
end

if (@ldfpath is Null) 
begin
  print 'Procedure ''sp_T38CRDBNC'' expects parameter ''@ldfpath'', which was not supplied.'
end

if (@szdb is Null) 
begin
  print 'Procedure ''sp_T38CRDBNC'' expects parameter ''@szdb'', which was not supplied.'
end

if (@szlog is Null) 
begin
  print 'Procedure ''sp_T38CRDBNC'' expects parameter ''@szlog'', which was not supplied.'
end

if (@ndffiles is Null) 
begin
  print 'Procedure ''sp_T38CRDBNC'' expects parameter ''@ndffiles'', which was not supplied.'
  print '@ndffiles is the number of ndf files for database, should be number of CPUs devided by 2'
  
	create table #info  (
	[Index]	smallint,  
	[Name]	varchar(128),  
	Internal_Value	int null,
	Character_Value varchar(128)
	)

	insert #info exec master..xp_msver 'ProcessorCount'
    select 'Procedure ''sp_T38CRDBNC'' expects parameter ''@ndffiles'', which was not supplied.'
    select '@ndffiles is the number of ndf files for database, should be number of CPUs devided by 2'
    select  'Number of CPUs: ', Internal_Value from #info where Name = 'ProcessorCount'
	print 'To find number of CPUs: execute xp_msver '+"'"+'ProcessorCount'+"'"
end

if (@DBcreator is Null) 
begin
  print 'Procedure ''sp_T38CRDBNC'' expects parameter ''@DBcreator'', which was not supplied.'
end

if (@DBapp is Null) 
begin
  print 'Procedure ''sp_T38CRDBNC'' expects parameter ''@DBapp'', which was not supplied.'
end

if (@DBdesc is Null) 
begin
  print 'Procedure ''sp_T38CRDBNC'' expects parameter ''@DBdesc'', which was not supplied.'
end

if (	   (@dbname is Null) 
    or (@mdfpath is Null)
	or (@ndfpath is Null)
	or (@ldfpath is Null)
	or (@szdb is Null)
	or (@szlog is Null)
	or (@ndffiles is null)
	or (@DBcreator is Null) 
	or (@DBapp is Null) 
	or (@DBdesc is Null)
   )
begin
  print ''
  print '----------------------------------------------------------------------------'
  print 'sp_T38CRDBNC(T-SQL)'
  print ''
  print 'Creates user databases.'
  print ''
  print 'Syntax:'
  print ''
  print 'sp_T38CRDBNC	 @dbname	= '+"'"+'database_name'+"'"
  print '			,@mdfpath	= '+"'"+'primary_file_path'+"'"
  print '			,@ndfpath	= '+"'"+'secondary_file_path'+"'"
  print '			,@ldfpath	= '+"'"+'log_file_path'+"'"
  print '			,@szdb		= '+"'"+'database_size'+"'"
  print '			,@szlog		= '+"'"+'database_log'+"'"
  print '			,@phydmp	= physical_backup_path,'
  print '			,@nBkpDev	= number_backup_devices'
  print '			,@ndffiles	= number of ndf files,'
  print '			,[@collate	= '+"'"+'collation_name'+"']"
  print '			,@DBcreator	= name of the person creating the database,'
  print '			,@DBapp		= name of the application that uses the database,'
  print '			,@DBdesc	= a short description of the database'
  print '' 
  print 'Arguments:'
  print ''
  print ' {@dbname  =  '+"'"+'database_name'+"'}"
  print ''
  print '	Is the non-compliant database name (i.e. eXpress381)'
  print ''
  print ' {@mdfpath = '+"'"+'primary_file_path'+"'}"
  print ''
  print '	Is the path to create the system tables db file  (i.e. ...\t38mdf\)'
  print ''
  print ' {@ndfpath = '+"'"+'secondary_file_path'+"'}"
  print ''
  print '	Is the path to create the user table db file  (i.e. ...\t38ndf\)'
  print ''
  print ' {@ldfpath = '+"'"+'log_file_path'+"'}"
  print ''
  print ' 	Is the path to create the db transaction log file (i.e. ...\t38ldf\)'
  print ''
  print ' {@szdb =    '+"'"+'database_size'+"'}"
  print ''
  print '	Is the size of the database contain to be create in MB.'
  print ''
  print ' {@szlog =   '+"'"+'database_log'+"'}"
  print ''
  print ' 	Is the size of the database log to be create in MB.'
  print ''
  print ' [@phydmp =   physical_backup_path],'
  print ''
  print '	Is the path to create the db and log backup files (i.e. ...\t38bkp\)'
  print ''
  print ' [@nBkpDev =  number_backup_devices]'
  print ''
  print '	Is the number of backup devices to sequence through.  Default is 1.'
  print ''
  print ' @ndffiles =  number of ndf files'
  print ''
  print '	Is the number of ndf files for database, should be number of CPUs devided by 2'
  print '	To find number of CPUs: execute xp_msver '+"'"+'ProcessorCount'+"'"
  print ''
  print ' [@collate =   '+"'"+'collation_name'+"']"
  print ''
  print ' 	Is collation name, returned by SELECT * FROM ::fn_helpcollations().'
  print ''
  print ' @DBcreator = name of the person creating the database,'
  print ''
  print ' 	Is the full name of the DBA who is initially creating the database (you)'
  print ''
  print ' @DBapp = name of the application that uses the database,'
  print ''
  print ' 	The name of the application that will be using the database.'
  print ''
  print ' @DBdesc = a short description of the database'
  print ''
  print ' 	A short description of the database and how it is used.'
  print ''
  print '----------------------------------------------------------------------------'
  print ''
  print 'Example:'
  print ''
  print '	EXEC sp_T38CRDBNC'
  print '		@dbname	    = '+"'"+'eXpress381'+"', "
  print '		@mdfpath    = '+"'"+'F:\dbms\t38mdf\'+"',"
  print '		@ndfpath    = '+"'"+'F:\dbms\t38ndf\'+"',"   
  print '		@ldfpath    = '+"'"+'L:\dbms\t38ldf\'+"',"
  print '		@szdb	    = 100,'
  print '		@szlog	    = 25,'
  print '		@phydmp	    = '+"'"+'H:\dbms\t38bkp\'+"',"
  print '		@backupsets = 1,'
  print '		@ndffiles   = 2,'
  print '		@dbcreator = '+"'"+'Scott Franz'+"',"
  print '		@DBapp     = '+"'"+'eXpress'+"',"
  print '		@DBdesc    = '+"'"+'eXpress DB for Wintel RDP installs'+"'"
  print ''
  print '----------------------------------------------------------------------------'
  print ''
  return(1)
end -- input validation


/***** First Declare local variables needed by procedure *******/
declare	@sql			varchar(8000)   /*	help hold a sql ddl statement to execute
                                       			*/
declare	@msg			varchar(255)	-- another variable to hold sql or error msg text
declare	@systemsize		char(2)		-- hold the default size of the Primary File Group
--declare	@dbname			varchar(11)		-- hold derived database name according to BBY standards
declare	@mdfpathfile	varchar(255)	-- holds the path and file name of the mdf file
declare	@ndfpathfile	varchar(255)	-- holds the path and file name of the ndf file
declare	@ldfpathfile	varchar(255)	-- holds the path and file name of the ldf file
declare	@NL				char(3)		-- holds new line sequence = ' '+char(13)+char(10)
declare @collateArg		varchar(255)	-- holds collate argument
declare	@errmsg			varchar(255)	-- holds custom messages to print
declare @i			integer		-- loop counter
declare @ndfsz			integer		-- size of one ndf file
declare @ndfcnt			integer		-- used to figure out suffix in ndf file name
declare @ndfcntchar		char(2)		-- ndf suffix in the file name	
declare @chardate		char(20)	-- used to convert current date to character format	

/***** Ensure all path names are ended with '\' *****/

select @mdfpath = ltrim(rtrim(@mdfpath))
if (right(@mdfpath, 1) <> ':' and right(@mdfpath, 1) <> '\') select @mdfpath = @mdfpath + '\'

select @ndfpath = ltrim(rtrim(@ndfpath))
if (right(@ndfpath, 1) <> ':' and right(@ndfpath, 1) <> '\') select @ndfpath = @ndfpath + '\'

select @ldfpath = ltrim(rtrim(@ldfpath))
if (right(@ldfpath, 1) <> ':' and right(@ldfpath, 1) <> '\') select @ldfpath = @ldfpath + '\'

if (select convert(varchar(10), SERVERPROPERTY('InstanceName'))) is not null
begin
	if (select charindex(reverse(convert(varchar(10), SERVERPROPERTY('InstanceName')) + '\'),reverse(@mdfpath))) <> 1
		select @mdfpath = @mdfpath + convert(varchar(10), SERVERPROPERTY('InstanceName')) + '\'
	if (select charindex(reverse(convert(varchar(10), SERVERPROPERTY('InstanceName')) + '\'),reverse(@ndfpath))) <> 1
		select @ndfpath = @ndfpath + convert(varchar(10), SERVERPROPERTY('InstanceName')) + '\'
	if (select charindex(reverse(convert(varchar(10), SERVERPROPERTY('InstanceName')) + '\'),reverse(@ldfpath))) <> 1
		select @ldfpath = @ldfpath + convert(varchar(10), SERVERPROPERTY('InstanceName')) + '\'
end
select @phydmp = ltrim(rtrim(@phydmp))
if (right(@phydmp, 1) <> ':' and right(@phydmp, 1) <> '\') select @phydmp = @phydmp + '\'

/***** Next initialize local variables and derive names from parameters *****/
select @systemsize = '10'

/*
if (@brand is not null)
	begin
		select @dbname = upper(@dbcid) + "D" + upper(@typedb) + RIGHT('000'+CONVERT(varchar(3),@dbid),3) + upper(@brand)
	end
else 
	begin
		select @dbname = upper(@dbcid) + "D" + upper(@typedb) + RIGHT('000'+CONVERT(varchar(3),@dbid),3)
		select @dbname = rtrim(@dbname)
	end
*/

select @mdfpathfile = @mdfpath + @dbname + '.mdf'
--select @ndfpathfile = @ndfpath + @dbname + '.ndf'
select @ldfpathfile = @ldfpath + @dbname + '.ldf'
select @NL = ' '+char(13)+char(10)
select @collateArg = ''
--select @ndfcnt = 1
select @ndfcntchar = ''


if (@collate is not null)
begin
	select @collateArg = @NL + 'collate ' + @collate
end

if not exists ( select name 
             from master..sysdatabases
              where	name = @dbname)
	begin
		/***** Next Create the database *****/
		/* 	Setting System file to 10 MB and autogrow by 10MB
		   	Making a seperate Data Parttion
			Turning log autogrow off
		*/

		select @ndfsz = ceiling(convert (decimal, @szdb)/@ndffiles)
		set @ndfcnt = 1

		select @sql = 	'CREATE DATABASE ' + @dbname + @NL +
			      	'ON PRIMARY ' + @NL +
			      	'( NAME = ' + @dbname + '_mdf' + ',' + @NL +
			      	'FILENAME = ' + '"' + @mdfpathfile + '"' + ',' + @NL + 
			      	'SIZE = ' + @systemsize + ',' + @NL +
			      	'FILEGROWTH = 10 ),' + @NL +
			      	'FILEGROUP Group00' + @NL 

		if @ndffiles > 1
		  begin
			while @ndfcnt < @ndffiles 
				begin
				select @ndfcntchar = RIGHT('00'+CONVERT(varchar(2),@ndfcnt),2)
				select @ndfpathfile = @ndfpath + @dbname + '_00_' + @ndfcntchar + '.ndf'
				set @sql = @sql + 
					'( NAME = ' + @dbname + '_00_' + @ndfcntchar + '_ndf' + ','  + @NL +
				      	'FILENAME = ' + '"' + @ndfpathfile  +  '"' + ',' + @NL + 
				      	'SIZE = ' + convert(varchar(7), (@ndfsz)) + 'MB ' + ',' + 'FILEGROWTH = 0 )' + ',' + @NL

				select @ndfcnt = @ndfcnt + 1				
				end
		  end

		select @ndfcntchar = RIGHT('00'+CONVERT(varchar(2),@ndfcnt),2)
		select @ndfpathfile = @ndfpath + @dbname + '_00_' + @ndfcntchar + '.ndf'
		   		set @sql = @sql + 
				'( NAME = ' + @dbname + '_00_' + @ndfcntchar + '_ndf' + ','  + @NL +
			      	'FILENAME = ' + '"' + @ndfpathfile +  '"' + ',' + @NL + 
			      	'SIZE = ' + convert(varchar(7), (@ndfsz)) + 'MB ' + ',' + @NL +      
			      	'FILEGROWTH = 0 )' + @NL +
			      	'LOG ON' + @NL +
			      	'( NAME = ' + @dbname + '_ldf' + ','  + @NL +
			      	'FILENAME = ' + '"' + @ldfpathfile + '"' + ',' + @NL + 
			      	'SIZE = ' + convert(varchar(7), (@szlog)) + 'MB ' + ',' + @NL +        
			      	'FILEGROWTH = 0 )' +
				@collateArg

		exec(@sql)
		if @@error <> 0 
			begin
				select @errmsg = 'failure creating database'
				print @errmsg
				RETURN(1)
			end 
		
		/***** Next make Group00 the default Group so all data is added to this Group *****/
		
		select @sql = 'ALTER DATABASE ' + @dbname + ' MODIFY FILEGROUP Group00 DEFAULT'
		exec(@sql)
		if @@error <> 0 
			begin
				select @errmsg = 'failure setting filegroup default'
				print @errmsg
				RETURN(1)
	   end
	   
	end /** database did not exist **/
		


/** Next create backup devices
   
We will only create the backups devices if the @phydmp is Not Null.
    
**/


if(@phydmp is not null)
begin
  if @backupsets = 1  -- create just one backup set for db and log
  begin	
    select @msg = "sp_T38CRBKP @dbname = "+@dbname+", @bkptype = 'db', @phypath = '"+@phydmp+"'"  
    exec(@msg)
  
    select @msg = "sp_T38CRBKP @dbname = "+@dbname+", @bkptype = 'log', @phypath = '"+@phydmp+"'"
    exec(@msg)
  end

  if @backupsets > 1  -- create more than one backup set for db and log
  begin
    select @i = 2
    While (@i <= @backupsets)
    begin
      if not exists (select * from sysdevices 
      where name = @dbname + '_' + convert(char(1),@i) + '_db_bkp')
      begin
	select @msg = "sp_T38CRBKP @dbname = "+@dbname+", @bkptype = 'db', @phypath = '" + @phydmp +"', @nBkpDev ="+convert(char(1),@i)
 	exec(@msg)
      end
      if not exists (select * from sysdevices 
      where name = @dbname + '_' + convert(char(1),@i) + '_log_bkp')
      begin
	select @msg = "sp_T38CRBKP @dbname = "+@dbname+", @bkptype = 'log', @phypath = '" + @phydmp +"', @nBkpDev ="+convert(char(1),@i)
	exec(@msg)
      end
      
      select @i = @i + 1
    end   -- while loop
  end	-- create more than one backup set for db and log				 
end -- create backup sets

select @msg = 'sp_dboption '+@dbname+','+'autoshrink,'+'FALSE'
exec(@msg)
print 'Turning off the autoshrink option for database:  '+@dbname+'.'

select @msg = 'sp_dboption '+@dbname+','+'"auto update statistics",'+'"ON"'
exec(@msg)

select @msg = 'alter database '+@dbname+' set AUTO_UPDATE_STATISTICS_ASYNC ON'
exec(@msg)

/*  Add extended properties to the database   */

select @sql = 'EXEC [' + @dbname + '].sys.sp_addextendedproperty @name=N''T38Creator'', @value=''' + @DBcreator + ''''
exec(@sql)
if @@error <> 0 
	begin
		select @errmsg = 'failure adding T38Creator extended property'
		print @errmsg
		RETURN(1)
	end

set @chardate = cast(getdate() as char(20))
select @sql = 'EXEC [' + @dbname + '].sys.sp_addextendedproperty @name=N''T38CreateDate'', @value=''' + @chardate + ''''
exec(@sql)
if @@error <> 0 
	begin
		select @errmsg = 'failure adding T38CreateDate extended property'
		print @errmsg
		RETURN(1)
	end

select @sql = 'EXEC [' + @dbname + '].sys.sp_addextendedproperty @name=N''T38App'', @value=''' + @DBapp + ''''
exec(@sql)
if @@error <> 0 
	begin
		select @errmsg = 'failure adding T38App extended property'
		print @errmsg
		RETURN(1)
	end

select @sql = 'EXEC [' + @dbname + '].sys.sp_addextendedproperty @name=N''T38Desc'', @value=''' + @DBdesc + ''''
exec(@sql)
if @@error <> 0 
	begin
		select @errmsg = 'failure adding T38Desc extended property'
		print @errmsg
		RETURN(1)
	end

GO

/*************************************************************************************************/
/****  End of Create stored procedure to create user databases with non-compliant names      *****/
/*************************************************************************************************/

/*
** sp_T38INDEX_FRAG_INFO(T-SQL) -- runs sys.dm_db_index_physical_stats on databasee
**
*/

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_T38INDEX_FRAG_INFO]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print 'Dropping old version of dbo.sp_T38INDEX_FRAG_INFO'
	drop procedure [dbo].[sp_T38INDEX_FRAG_INFO]
end
GO

/****** Object:  StoredProcedure [dbo].[sp_T38INDEX_FRAG_INFO]    Script Date: 10/21/2010 05:11:09 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
print 'Creating stored procedure: dbo.sp_T38INDEX_FRAG_INFO'
GO
CREATE PROCEDURE [dbo].[sp_T38INDEX_FRAG_INFO] @scanmode varchar(10)='LIMITED',
@printonly char(1)='Y', @cRepoDBTable varchar(50)='', @showCntgLmtCount bigint=1
/*
** sp_T38INDEX_FRAG_INFO -- runs sys.dm_db_index_physical_stats on databasee
**
** PVCS information
**
** $Author: A645276 $
** $Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/DBINST/SQL90/SourceCode/T38Procs.svl  $
** $Date: 2011/02/08 15:37:18 $
** $Revision: 1.1 $	
*/

AS

/***************************************************************************************
This procedure will return fragmentation details of all the tables in the given datbase.
Changed the procedure to exclude indexes for which page locks are disallowed.
DMF sys.dm_db_index_physical_stats
The output is returned as table
Input Parameter : 
		@scanmode		: Level of scanning used by DMF
		@printonly		: When "Y"..it shows fragmentation information as Query output
						  When "N".. generates output as INSERT statements.
		@cRepoDBTable	: Repository table name in following DBNAME.Tablename				  
****************************************************************************************/
SET NOCOUNT ON
DECLARE	 @schemaname sysname,
	@dbName		sysname,
	@tablename sysname,
	@tableid sysname ,
	@indexname sysname ,
	@disallow_page_locks bit,
	@indID	INT,
	@sqlcmd	NVARCHAR (3072),
	@ignoreListCmd NVARCHAR(3072),
	@cTemp	char(10),
	@errDetail		varchar(200),
	@errNo		int,
	@errMsg		varchar(150),
	@errcount   smallint,
	@rowcnt bigint
	
Declare @cSQLName varchar(15),@cInstanceName varchar(15)

select @cSQLName=cast(serverproperty('MachineName') as varchar(15)),@cInstanceName=isnull(cast(serverproperty('InstanceName') as varchar(15)),'MSSQLServer')

DECLARE	@index_list	TABLE	(dbid int, tableid int , SchemaID int, tablename sysname,indexname sysname, indexid int,schemaname sysname, allow_page_locks bit)
DECLARE @index_ignore_list TABLE (dbid int, tablename sysname, indexname sysname)

SET @dbName = DB_NAME()
Print '--Processing DB : ' + DB_NAME()
SET @errDetail = ''

if @printonly <>'Y' and isnull(@cRepoDBTable,'') = '' 
	Begin
		exec sp_T38LOGERROR 1,'sp_T38Index_frag_info','Parameter 3 Repository databasename..tablename not provided'
		return -1
	End

IF (OBJECT_ID ('tempdb..#dba_showcontig')) IS NOT NULL
	TRUNCATE TABLE #dba_showcontig
Else

-- Build list of user tables and indexes in current database
IF (OBJECT_ID ('tempdb..#dba_showcontig')) IS NOT NULL
	DROP TABLE #dba_showcontig

CREATE TABLE #dba_showcontig (
			LOC_SRVR_NM varchar(15) ,LOC_SRVR_DBINST_NM varchar(15), DB_TABL_CNTIG_TS smalldatetime ,LOC_SRVR_DBINST_DB_NM varchar(50) ,SCHEMA_NM varchar(50) ,
			LOC_SRVR_DB_INST_DB_ID smallint ,DB_TABL_NM varchar(100),DB_TBL_ID int ,DB_TBL_INDX_ID int ,DB_TABL_INDX_NM varchar(100) ,
			DB_TBL_INDX_DESC varchar(100) ,PARTITION_NUM int ,INDX_SMP_TYP_VAL nvarchar(60) ,ALLOC_UNIT_TYP_DESC nvarchar(60) ,
			INDEX_DEPTH int ,INDEX_LEVEL int ,AVG_FRAG_PCT float ,FRAG_CNT bigint ,
			AVG_FRAG_SIZE_PG_CNT float ,PG_CNT bigint ,AVG_PG_SPACE_USE_PCT float ,REC_CNT bigint ,
			GHOST_REC_CNT bigint ,VER_GHOST_REC_CNT bigint ,MIN_REC_SIZE_BYTE_CNT int ,MAX_REC_SIZE_BYTE_CNT int ,
			AVG_REC_SIZE_BYTE_CNT float ,FWD_REC_CNT bigint, INDX_DISALLOW_PAGE_LOCKS bit
			)

-- ****************************************************************************************
-- ***						SECTION:	BUILD INDEX LIST 								***
-- ****************************************************************************************
-- when IsPageLockDisallowed = 0 means we can process this index for defragging as it allows page locks.
-- is not a statistics group (these don't return SHOWCONTIG results)
SET @sqlcmd = '
	SELECT db_id(),o.object_id as [tableid],o.schema_id,o.[name] as [tablename], i.[name] as [indexname], i.indid,s.name as [schemaname],ISNULL (INDEXPROPERTY (o.[object_id], i.[name], ''IsPageLockDisallowed''),0) as [allow_page_locks]
	FROM ['+@dbName+ '].sys.objects o JOIN ['+ @dbName+ '].dbo.sysindexes i ON o.[object_id] = i.[id]
		Join ['+@dbName+ '].sys.schemas s on o.schema_id = s.schema_id
	WHERE o.type IN (''U'', ''V'')
	    AND o.[name] <> ''dtproperties''
		AND ISNULL (INDEXPROPERTY (o.[object_id], i.[name], ''IsStatistics''), 0) = 0 ' + 	
		' and indid >0
	ORDER BY s.name,o.name,i.indid'

SET @ignoreListCmd = '
	SELECT db_id(), OBJECT_NAME(o.object_id) as [tablename], i.name as [indexname]
	FROM [' + @dbName + '].sys.objects o JOIN [' + @dbName + '].dbo.sysindexes i ON o.[object_id] = i.[id]
	WHERE o.type IN (''U'', ''V'')
		AND o.[name] <> ''dtproperties''
		AND ISNULL (INDEXPROPERTY (o.[object_id], i.[name], ''IsPageLockDisallowed''),0) = 1 ' +
	   'AND indid > 0
	ORDER BY o.name'
	
--Print '-- Generating Index list using statement :'+ @sqlcmd
Begin try
INSERT INTO @index_list exec sp_executesql @sqlcmd
INSERT INTO @index_ignore_list EXEC sp_executesql @ignoreListCmd

print '/*'
WHILE EXISTS( SELECT * FROM @index_ignore_list)
BEGIN
	DECLARE @excl_dbid int,
			@excl_tblName sysname,
			@excl_indxName sysname,
			@excl_msg VARCHAR(512)
		
	SELECT TOP 1 @excl_dbid=dbid, @excl_tblName = tablename, @excl_indxName = indexname FROM @index_ignore_list
	SELECT @excl_msg = 'Index:' + @excl_indxName + ' has Page Locks disallowed. Found on Table:' + @excl_tblName + '' 
	EXEC sp_T38LOGERROR 3,'sp_T38Index_frag_info', @excl_msg
	DELETE FROM @index_ignore_list WHERE [dbid] = @excl_dbid AND [tablename] = @excl_tblName AND [indexname] = @excl_indxName
END
print '*/'

select @cTemp=str(isnull(count(*),0)) from @index_list
End try
BEGIN CATCH
    SELECT @errNo= ERROR_NUMBER() ,@errMsg = error_message() ,
					@errDetail = 'Procedure:[sp_get_index_fragmentation_info]' + ' at line No:'+ cast(isnull(ERROR_LINE(),'') as char(4))
    Print '--**Error while generating Index list for database '+db_name() +'. Error No: '+ rtrim(cast(@errNo as char(10)))+ 
						' Message: '+@errMsg +' Details: ' +@errDetail
END CATCH

Print '-- Processing Indexes for database : [' + rtrim(db_name())+'] : Index count : '+ltrim(@cTemp)
LoopStart:
BEGIN TRY
WHILE EXISTS (SELECT * FROM @index_list) 
BEGIN
	SELECT TOP 1 @schemaname = schemaname, @tablename = tablename, @tableid = [tableid], @indexname = indexname, 
							@indID = indexid, @disallow_page_locks = [allow_page_locks] FROM @index_list

	IF OBJECT_ID (@schemaname + N'.' + @tablename) IS NULL 
	  BEGIN
		-- Object has been dropped since list was created
		Print '--**Error '+@schemaname + N'.' + @tablename +' has been dropped'
		-- Delete all remaining list entries for this object so we don't try to process them
		DELETE FROM @index_list WHERE schemaname = @schemaname AND [tablename] = @tablename
	  END 
	ELSE 
	  IF NOT EXISTS (SELECT * FROM sysindexes WHERE  [id] = @tableid AND indid = @indID ) 
	     BEGIN
	       -- Index has been dropped since list was created
		   Print '--**Error '+ 'Index ID ' +cast(@indID as char(3)) +':'+@indexname +' on Table:' +@schemaname+':'+@tablename+ ' does not exists or was dropped'
		   -- Delete all remaining list entries for this index so we don't try to process them
		   DELETE FROM @index_list WHERE schemaname = @schemaname AND [tablename] = @tablename AND indexid = @indID
		 END 
      ELSE 
          BEGIN
				Select @rowcnt = rowcnt FROM sysindexes WHERE  [id] = @tableid AND indid = @indID
				-- Object and index still exists, so check its fragmentation
				Insert into #dba_showcontig(LOC_SRVR_NM,LOC_SRVR_DBINST_NM,DB_TABL_CNTIG_TS, LOC_SRVR_DBINST_DB_NM, LOC_SRVR_DB_INST_DB_ID,
				SCHEMA_NM,DB_TBL_ID,DB_TABL_NM,DB_TBL_INDX_ID, DB_TABL_INDX_NM, DB_TBL_INDX_DESC 
				, PARTITION_NUM, INDX_SMP_TYP_VAL, ALLOC_UNIT_TYP_DESC, INDEX_DEPTH, INDEX_LEVEL 
				, AVG_FRAG_PCT , FRAG_CNT  , AVG_FRAG_SIZE_PG_CNT , PG_CNT, 
				AVG_PG_SPACE_USE_PCT, REC_CNT, GHOST_REC_CNT, VER_GHOST_REC_CNT, 
				MIN_REC_SIZE_BYTE_CNT , MAX_REC_SIZE_BYTE_CNT , AVG_REC_SIZE_BYTE_CNT, FWD_REC_CNT, INDX_DISALLOW_PAGE_LOCKS)
				SELECT @cSQLName,@cInstanceName,getdate(),db_name(database_id),database_id, 
				@schemaname, [object_id],@tablename,index_id,@indexname,index_type_desc,
				partition_number,@scanmode,alloc_unit_type_desc, index_depth, index_level,
				avg_fragmentation_in_percent,fragment_count,avg_fragment_size_in_pages,page_count,
				avg_page_space_used_in_percent,isnull(record_count,@rowcnt) , ghost_record_count,version_ghost_record_count,
				min_record_size_in_bytes, max_record_size_in_bytes,avg_record_size_in_bytes,forwarded_record_count,@disallow_page_locks
				FROM sys.dm_db_index_physical_stats (DB_ID(@dbName), @tableid, @indID, NULL, @scanmode)
				where index_level =0 and alloc_unit_type_desc ='IN_ROW_DATA'

		-- Print 'Done fragmentation info for = '+@dbname+':'+@schemaname+':'+@tablename+':'+@indexname+':'+cast(@indID as char(3))+ 'Time stamp : '+convert( char(12),getdate(),114)
		
	  END
	  DELETE FROM @index_list WHERE schemaname = @schemaname AND [tablename] = @tablename AND [tableid] = @tableid AND indexname = @indexname AND indexid = @indID
End	
END TRY
BEGIN CATCH
    SELECT @errNo= ERROR_NUMBER() ,@errMsg = error_message() ,@errDetail = 'Procedure:[sp_get_index_fragmentation_info]' 
													+ ' at line No:'+ cast(isnull(ERROR_LINE(),'') as char(4))
    Print '**Error while processing ' + Rtrim(cast(db_name() as char(30))) + '.'+@schemaname + 
				'.'+ @tablename + '.'+ @indexname + 'Error No: '+ rtrim(cast(@errNo as char(10)))+' Message: '+@errMsg +' Details: ' +@errDetail
				
	Set @errDetail = @errDetail+' '+@errMsg
	-- Error detected while processing the index,Delete this index and process next Index
	DELETE FROM @index_list WHERE schemaname = @schemaname AND [tablename] = @tablename AND [tableid] = @tableid AND indexname = @indexname
				 AND indexid = @indID
	goto LoopStart
END CATCH

OutputSection:
BEGIN TRY
If @printonly='Y'
		Select * from #dba_showcontig WHERE PG_CNT >= @showCntgLmtCount
else 
		-- Generate Insert command
		Select 'INSERT INTO '+@cRepoDBTable+ '(LOC_SRVR_NM,LOC_SRVR_DBINST_NM,DB_TABL_CNTIG_TS ,LOC_SRVR_DBINST_DB_NM,SCHEMA_NM,LOC_SRVR_DB_INST_DB_ID
		,DB_TABL_NM,DB_TBL_ID,DB_TBL_INDX_ID,DB_TABL_INDX_NM,DB_TBL_INDX_DESC,PARTITION_NUM,INDX_SMP_TYP_VAL,ALLOC_UNIT_TYP_DESC
		,INDEX_DEPTH,INDEX_LEVEL,AVG_FRAG_PCT,FRAG_CNT,AVG_FRAG_SIZE_PG_CNT,PG_CNT,AVG_PG_SPACE_USE_PCT
		,REC_CNT,GHOST_REC_CNT,VER_GHOST_REC_CNT,MIN_REC_SIZE_BYTE_CNT,MAX_REC_SIZE_BYTE_CNT,AVG_REC_SIZE_BYTE_CNT,
		FWD_REC_CNT,INDX_DISALLOW_PAGE_LOCKS)
     VALUES(',
		 ''''+LOC_SRVR_NM+''',' , ''''+ LOC_SRVR_DBINST_NM +''',' ,''''+CONVERT(CHAR(20),DB_TABL_CNTIG_TS,120)+''''
           ,','''+LOC_SRVR_DBINST_DB_NM +''','
           ,''''+SCHEMA_NM+''','
           ,LOC_SRVR_DB_INST_DB_ID
           ,','''+DB_TABL_NM+''','
           ,DB_TBL_ID ,','
           ,DB_TBL_INDX_ID
           ,','''+DB_TABL_INDX_NM+''','
           ,''''+DB_TBL_INDX_DESC+''','
           ,PARTITION_NUM
           ,','''+INDX_SMP_TYP_VAL+''','
           ,''''+ALLOC_UNIT_TYP_DESC+''','
           ,INDEX_DEPTH,','
           ,INDEX_LEVEL,','
           ,AVG_FRAG_PCT float,','
           ,FRAG_CNT bigint ,','
           ,AVG_FRAG_SIZE_PG_CNT float ,','
           ,PG_CNT bigint ,','
           ,AVG_PG_SPACE_USE_PCT float ,','
           ,REC_CNT bigint ,','
           ,GHOST_REC_CNT bigint ,','
           ,VER_GHOST_REC_CNT  bigint ,','
           ,MIN_REC_SIZE_BYTE_CNT int,','
           ,MAX_REC_SIZE_BYTE_CNT int ,','
           ,AVG_REC_SIZE_BYTE_CNT float,','
           ,FWD_REC_CNT bigint ,','
		   ,INDX_DISALLOW_PAGE_LOCKS bit,')' FROM #dba_showcontig WHERE PG_CNT >= @showCntgLmtCount



END TRY
BEGIN CATCH
    SELECT @errNo= ERROR_NUMBER() ,@errMsg = error_message() ,@errDetail = 'Procedure:[sp_get_index_fragmentation_info]:OutputSection' + ' at line No:'+ cast(isnull(ERROR_LINE(),'') as char(4))
    Print '**Error '+ 'Error No: '+ rtrim(cast(@errNo as char(10)))+' Message: '+@errMsg +' Details: ' +@errDetail
	Set @errDetail = @errDetail+' '+@errMsg
--	Raiserror(@errDetail,10,1) with LOG
	exec sp_T38LOGERROR 2, 'sp_T38INDEX_FRAG_INFO', @errDetail
END CATCH

-- ****************************************************************************************
-- ***	SECTION:	DONE!								***
-- ****************************************************************************************
