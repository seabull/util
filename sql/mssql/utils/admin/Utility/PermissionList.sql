-- =============================================
-- Author: Alejandro Pelc
-- Create date: 02/19/2009
-- Description: List all DBs permission
--
-- =============================================
set nocount on
declare @permission table (
    Database_Name sysname,
    User_Role_Name sysname,
    Account_Type nvarchar(60),
    Action_Type nvarchar(128),
    Permission nvarchar(60),
    ObjectName sysname null,
    Object_Type nvarchar(60)
)

declare @dbs table (dbname sysname)
declare @Next sysname

insert into @dbs
    select name from sys.databases order by name

select top 1 @Next = dbname from @dbs

while (@@rowcount<>0)
begin
insert into @permission
exec('use [' + @Next + ']
declare @objects table (obj_id int, obj_type char(2))
insert into @objects
select id, xtype from master.sys.sysobjects
insert into @objects
select object_id, type from sys.objects

SELECT ''' + @Next + ''', a.name as ''User or Role Name'', a.type_desc as ''Account Type'',
d.permission_name as ''Type of Permission'', d.state_desc as ''State of Permission'',
OBJECT_SCHEMA_NAME(d.major_id) + ''.'' + object_name(d.major_id) as ''Object Name'',
case e.obj_type
when ''AF'' then ''Aggregate function (CLR)''
when ''C'' then ''CHECK constraint''
when ''D'' then ''DEFAULT (constraint or stand-alone)''
when ''F'' then ''FOREIGN KEY constraint''
when ''PK'' then ''PRIMARY KEY constraint''
when ''P'' then ''SQL stored procedure''
when ''PC'' then ''Assembly (CLR) stored procedure''
when ''FN'' then ''SQL scalar function''
when ''FS'' then ''Assembly (CLR) scalar function''
when ''FT'' then ''Assembly (CLR) table-valued function''
when ''R'' then ''Rule (old-style, stand-alone)''
when ''RF'' then ''Replication-filter-procedure''
when ''S'' then ''System base table''
when ''SN'' then ''Synonym''
when ''SQ'' then ''Service queue''
when ''TA'' then ''Assembly (CLR) DML trigger''
when ''TR'' then ''SQL DML trigger''
when ''IF'' then ''SQL inline table-valued function''
when ''TF'' then ''SQL table-valued-function''
when ''U'' then ''Table (user-defined)''
when ''UQ'' then ''UNIQUE constraint''
when ''V'' then ''View''
when ''X'' then ''Extended stored procedure''
when ''IT'' then ''Internal table''
end as ''Object Type''
FROM [' + @Next + '].sys.database_principals a 
left join [' + @Next + '].sys.database_permissions d on a.principal_id = d.grantee_principal_id
left join @objects e on d.major_id = e.obj_id
order by a.name, d.class_desc'
)
delete @dbs where dbname = @Next
select top 1 @Next = dbname from @dbs
end
set nocount off
select * from @permission


-------------------------------------------------------------------------------------------------
--
--- Recently, I faced a situation where I had to create a new database role, 
--- that would get all the permissions of an existing role, plus some additional permissions. 
--- I really didn't want to nest the roles (adding a role as a member of another role), as I prefer 
--- to keep things simple. So, I came up with a SQL script, that generates the required commands to 
--- duplicate the permissions of a specified database user or role. This script makes use of the newly 
--- added SQL Server 2005 security catalog views to recreate the permissions.
--- 
--- This script queries the following SQL Server 2005 security catalog views:
--- 
--- sys.database_role_members: This catalog view maps database users to database roles that they are members of
--- 
--- sys.database_permissions: Contains information about all the permissions held by users and roles
--- 
--- sys.objects: Contains information about all user-defined database objects
--- 
--- sys.database_principals: Contains information about all database users and database roles
--- 
--- sys.columns: Contains data about each column of an object that has columns, such as views or tables
--- 
--- Note:In SQL Server 2000, the above catalog views are not available and the equivalent system tables are: 
---         syspermissions, sysprotects, sysobjects, sysusers, syscolumns
--- 
--- To use the below script, you will have to change the values of the @OldUser and @NewUser to the names of 
--- 'the user or role from which to copy the permissions from', and 'the user or role to which to copy the permissions to' respectively.
--- 
--- Note: This script will not automatically run the commands to copy the permissions. 
---     It will simply generate the commands that are required to copy the permissions from one user or role to another user or role. 
---     You will have to copy these commands, verify the generated commands, and run those commands manually in either Query 
---     Analyzer or Management Studio. It is better to run the below script with the output set to text mode, instead of grid mode. 
---     Also note that, this script cannot be used to script permissions for fixed database roles like db_datareader and db_datawriter.
---     It is meant to script permissions for database users and user defined database roles.
--- 
--- If you just want to script the permissions of an existing user (and not copy them to a different user), 
--- then simply set the values of the variables @OldUser and @NewUser to the same user or role name.
--- 
--- The output of the script contains three sections:
--- 
--- - sp_addrolemember calls to copy the database role memberships of the specified user or role
--- 
--- - GRANT and DENY commands to copy the object level permissions of the specified user or role
--- 
--- - GRANT and DENY commands to copy the database level permissions of the specified user or role
--- 
SET NOCOUNT ON


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

-------------------------------------------------------------------------------------------------
