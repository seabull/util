SELECT getdate() AS Date,
         name AS NameOfFile,
         size/128.0 AS SizeInMB,
         CAST(FILEPROPERTY(name, 'SpaceUsed' )AS int)/128.0 AS SpaceUsedInMB,
         size/128.0 -CAST(FILEPROPERTY(name, 'SpaceUsed' )AS int)/128.0 AS AvailableSpaceInMB,
         filename
FROM dbo.SYSFILES
 
exec sp_spaceused  

-- Spaceused by Tables

SELECT  object_name(id) AS name,
        indid, 
        rowcnt AS rows, 
        reserved * 8 AS reserved_kb, 
        dpages * 8 AS data_kb, 
        (sum(used) * 8) - (dpages * 8) AS index_size_kb, 
        (sum(reserved) * 8) - (sum(used) * 8) AS unused_kb 
FROM sysindexes 
WHERE indid IN (0,1) -- cluster e não cluster 
AND   OBJECTPROPERTY(id, 'IsUserTable') = 1 
GROUP BY id, indid, rowcnt, reserved, dpages 
ORDER BY rowcnt DESC

select *
  from sys.user_token

select *
  from sys.login_token
 where name like 'NA\BBY-U-TM-RASC-%'

SELECT p.sid, p.name, p.type, p.is_disabled, p.default_database_name, 
l.hasaccess, l.denylogin 
FROM sys.server_principals p 
LEFT JOIN sys.syslogins l
      ON ( l.name = p.name ) 
WHERE p.type IN ( 'S', 'G', 'U' ) 
AND p.name <> 'sa'


SELECT PRINCIPAL_ID AS [Principal ID],
 NAME AS [User],
 TYPE_DESC AS [Type Description],
 IS_DISABLED AS [Status]
FROM sys.server_principals 

sp_srvrolepermission securityadmin

Use master
GO
EXECUTE sp_addsrvrolemember
@loginame = 'UserA',
@rolename = 'bulkadmin'
GO

Use master
GO
SELECT PRINCIPAL_ID AS [Principal ID],
 NAME AS [User],
 TYPE_DESC AS [Type Description],
 IS_DISABLED AS [Status]
FROM sys.server_principals WHERE name ='UserA'
GO

SELECT
 SDP.PRINCIPAL_ID AS [Principal ID],
 SDP.NAME AS UserName,
 SDP.TYPE_DESC AS UserType, 
 SSP.NAME AS LoginName,
 SSP.TYPE_DESC AS LoginType
FROM sys.database_principals SDP
INNER JOIN sys.server_principals SSP
ON SDP.PRINCIPAL_ID = SSP.PRINCIPAL_ID
GO


-- Server roles
SELECT
 SSP.name AS [Login Name],
 SSP.type_desc AS [Login Type],
 UPPER(SSPS.name) AS [Server Role]
FROM sys.server_principals SSP
INNER JOIN sys.server_role_members SSRM
ON SSP.principal_id=SSRM.member_principal_id
INNER JOIN sys.server_principals SSPS
ON SSRM.role_principal_id = SSPS.principal_id
GO

-- Database role
SELECT
 SDP.name AS [User Name],
 SDP.type_desc AS [User Type],
 UPPER(SDPS.name) AS [Database Role]
FROM sys.database_principals SDP
INNER JOIN sys.database_role_members SDRM
ON SDP.principal_id=SDRM.member_principal_id
INNER JOIN sys.database_principals SDPS
ON SDRM.role_principal_id = SDPS.principal_id
GO

-- server level permission
SELECT * FROM sys.server_permissions
GO

-- db level permission
SELECT * FROM sys.database_permissions
GO

SELECT *
FROM fn_my_permissions(NULL, 'SERVER');

sp_srvrolepermission securityadmin

sp_dbfixedrolepermission db_owner

SELECT *
FROM fn_my_permissions('PRFDX001', 'DATABASE');  

SELECT *
FROM fn_my_permissions('dbo.EmployeeLocationCurrent', 'OBJECT') 
where permission_name not in ('SELECT', 'UPDATE','INSERT','DELETE')

-- View permissions of a user
select dp.NAME AS principal_name,
	dp.type_desc AS principal_type_desc,
	o.NAME AS object_name,
	p.permission_name,
	p.state_desc AS permission_state_desc
from    sys.database_permissions p
left    OUTER JOIN sys.all_objects o
on     p.major_id = o.OBJECT_ID
inner   JOIN sys.database_principals dp
on     p.grantee_principal_id = dp.principal_id
where p.permission_name = 'EXECUTE'
  and o.Name = 'sp_GetNextSynergyID'


------------------------------
DECLARE	@OldUser sysname, @NewUser sysname


SET	@OldUser = 'HRUser'
SET	@NewUser = 'PersonnelAdmin'


SELECT	'USE' + SPACE(1) + QUOTENAME(DB_NAME()) AS '--Database Context'


SELECT	'--Cloning permissions from' + SPACE(1) + QUOTENAME(@OldUser) + SPACE(1) + 'to' + SPACE(1) + QUOTENAME(@NewUser) AS '--Comment'


SELECT	'EXEC sp_addrolemember @rolename =' 
	+ SPACE(1) + QUOTENAME(USER_NAME(rm.role_principal_id), '''') + ', @membername =' + SPACE(1) + QUOTENAME(@NewUser, '''') AS '--Role Memberships'
FROM	sys.database_role_members AS rm
WHERE	USER_NAME(rm.member_principal_id) = @OldUser
ORDER BY rm.role_principal_id ASC


SELECT	CASE WHEN perm.state <> 'W' THEN perm.state_desc ELSE 'GRANT' END
	+ SPACE(1) + perm.permission_name + SPACE(1) + 'ON ' + QUOTENAME(USER_NAME(obj.schema_id)) + '.' + QUOTENAME(obj.name) 
	+ CASE WHEN cl.column_id IS NULL THEN SPACE(0) ELSE '(' + QUOTENAME(cl.name) + ')' END
	+ SPACE(1) + 'TO' + SPACE(1) + QUOTENAME(@NewUser) COLLATE database_default
	+ CASE WHEN perm.state <> 'W' THEN SPACE(0) ELSE SPACE(1) + 'WITH GRANT OPTION' END AS '--Object Level Permissions'
FROM	sys.database_permissions AS perm
	INNER JOIN
	sys.objects AS obj
	ON perm.major_id = obj.[object_id]
	INNER JOIN
	sys.database_principals AS usr
	ON perm.grantee_principal_id = usr.principal_id
	LEFT JOIN
	sys.columns AS cl
	ON cl.column_id = perm.minor_id AND cl.[object_id] = perm.major_id
WHERE	usr.name = @OldUser
ORDER BY perm.permission_name ASC, perm.state_desc ASC


SELECT	CASE WHEN perm.state <> 'W' THEN perm.state_desc ELSE 'GRANT' END
	+ SPACE(1) + perm.permission_name + SPACE(1)
	+ SPACE(1) + 'TO' + SPACE(1) + QUOTENAME(@NewUser) COLLATE database_default
	+ CASE WHEN perm.state <> 'W' THEN SPACE(0) ELSE SPACE(1) + 'WITH GRANT OPTION' END AS '--Database Level Permissions'
FROM	sys.database_permissions AS perm
	INNER JOIN
	sys.database_principals AS usr
	ON perm.grantee_principal_id = usr.principal_id
WHERE	usr.name = @OldUser
AND	perm.major_id = 0
ORDER BY perm.permission_name ASC, perm.state_desc ASC
------------------------------------

select *
  from sys.database_principals
 where name = 'FortVaultUser'