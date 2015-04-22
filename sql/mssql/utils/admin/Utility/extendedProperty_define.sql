----------------------------------------------------
--To retrieve the descriptions of all tables:
--
--SELECT sys.objects.name AS TableName, ep.name AS PropertyName,
--       ep.value AS Description
--FROM sys.objects
--CROSS APPLY fn_listextendedproperty(default,
--                                    'SCHEMA', schema_name(schema_id),
--                                    'TABLE', name, null, null) ep
--WHERE sys.objects.name NOT IN ('sysdiagrams')
--ORDER BY sys.objects.name
--
--To retrieve the descriptions of all table columns:
--
--SELECT sys.objects.name AS TableName, sys.columns.name AS ColumnName,
--       ep.name AS PropertyName, ep.value AS Description
--FROM sys.objects
--INNER JOIN sys.columns ON sys.objects.object_id = sys.columns.object_id
--CROSS APPLY fn_listextendedproperty(default,
--                  'SCHEMA', schema_name(schema_id),
--                  'TABLE', sys.objects.name, 'COLUMN', sys.columns.name) ep
--ORDER BY sys.objects.name, sys.columns.column_id
--sp_help 'sp_addextendedproperty'

declare @owner nvarchar(256),
		@objType nvarchar(128),
		@objName nvarchar(256),
		@requestedBy nvarchar(2000),
		@tag		nvarchar(2000),
		@description nvarchar(2000)

SELECT @objType = N'VIEW'
        ,@objName = N'MyTableInfo'
        ,@owner = N'LJ Yang'
        ,@tag = N'Admin'
        ,@description = N''
        ,@requestedBy = N''

--declare @columnName nvarchar(256),
--		@columnDescription nvarchar(2000)
--
--set @columnName = N''
--set @columnDescription = N''
	
EXEC sys.sp_addextendedproperty @name=N'Owner', 
								@value=@owner, 
								@level0type=N'SCHEMA',
								@level0name=N'dbo', 
								@level1type=@objType,
								@level1name=@objName
EXEC sys.sp_addextendedproperty @name=N'RequestedBy', 
								@value=@requestedBy, 
								@level0type=N'SCHEMA',
								@level0name=N'dbo', 
								@level1type=@objType,
								@level1name=@objName
EXEC sys.sp_addextendedproperty @name=N'Description', 
								@value=@description, 
								@level0type=N'SCHEMA',
								@level0name=N'dbo', 
								@level1type=@objType,
								@level1name=@objName
EXEC sys.sp_addextendedproperty @name=N'Tag', 
								@value=@tag, 
								@level0type=N'SCHEMA',
								@level0name=N'dbo', 
								@level1type=@objType,
								@level1name=@objName
--EXEC sys.sp_addextendedproperty @name=N'Description', 
--								@value=@columnDescription, 
--								@level0type=N'SCHEMA',
--								@level0name=N'dbo', 
--								@level1type=@objType,
--								@level1name=@objName
--								@level1type='COLUMN',
--								@level1name=@columnName
--EXEC sys.sp_dropextendedproperty @name=N'Description', 
--								@level0type=N'SCHEMA',
--								@level0name=N'dbo', 
--								@level1type=@objType,
--								@level1name=@objName