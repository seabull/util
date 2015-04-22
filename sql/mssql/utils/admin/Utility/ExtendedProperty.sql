-- Example of extended properties
SELECT isc.column_name , isc.is_nullable,
       isc.data_type, isc.character_maximum_length,
       c.object_id, c.column_id
   FROM information_schema.columns isc
   INNER JOIN sys.columns c ON isc.column_name = c.name
   AND OBJECT_NAME(c.object_id) = 'FortVault'
   AND isc.table_name = 'FortVault'
   AND OBJECTPROPERTY(c.object_id, 'IsMsShipped')=0

select * from sys.columns where OBJECT_NAME(object_id) = 'FortVault'

SELECT CAST(ex.name  AS VARCHAR(1000)) AS ext_prop_name,
   CAST(ex.value AS VARCHAR(1000)) AS ext_prop_value
   FROM  (
      SELECT c.object_id, c.column_id
         FROM information_schema.columns isc
         INNER JOIN sys.columns c ON isc.column_name = c.name
         AND OBJECT_NAME(c.object_id) = 'FortVault'
         AND isc.table_name = 'FortVault'
         AND isc.column_name = 'ObjectValue'
   ) cols
   LEFT OUTER JOIN  sys.extended_properties ex
   ON  ex.major_id = cols.object_id
   AND ex.minor_id = cols.column_id

exec sys.sp_addextendedproperty
@name = N'DBDescription',
@value = N'Fort Vault Metadata',
@level0type = N'SCHEMA', @level0name = dbo,
@level1type = N'TABLE', @level1name = FortVault

exec sp_updateextendedproperty
@name = N'DBDescription',
@value = N'Fort Vault Metadata',
@level0type = N'SCHEMA', @level0name = dbo,
@level1type = N'TABLE', @level1name = FortVault

select objType, objName, name, value
  from fn_listextendedproperty(null, 'SCHEMA', 'dbo', 'table','fortVault', null, null)