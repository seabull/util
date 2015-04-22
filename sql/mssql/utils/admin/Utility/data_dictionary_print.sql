
--Prints out a 'data dictionary'  for a SQL SERVER 2005 database using
--extended properties and other metadata from system views.
USE {my_database_here}
GO

DECLARE @schema            VARCHAR(300)
DECLARE @table_name        VARCHAR(300)
DECLARE @view_name         VARCHAR(300)
DECLARE @program_name      VARCHAR(300)
DECLARE @object_id         INT
DECLARE @parameter_id      INT 
DECLARE @column_name       VARCHAR(300)
DECLARE @parameter_name    VARCHAR(300)
DECLARE @ext_prop_name     VARCHAR(1000)
DECLARE @ext_prop_value    VARCHAR(1000)
DECLARE @data_type         VARCHAR(300)
DECLARE @length            VARCHAR(50)
DECLARE @required          VARCHAR(50)

PRINT '<html><head>'
--#####
--Change report style here:
PRINT '<style type="text/css">'
PRINT 'h1, h2, h3, h4 {color: #003399;background: #EEEEEE;} '
PRINT '.objectName{padding-top:25px;font-weight: bold;font-size: 130%} '
PRINT '.label {float:left;font-weight:bold;margin-left:10px;width:95px;} '
PRINT '.longLabel {float:left;font-weight:bold;margin-left:10px;width:200px;} '
PRINT '.data {style="width:200px;float:left;margin-left:20px;} '
PRINT '</style>'
--#####
PRINT '</head>'


PRINT '<body><h1 align="center">Database ' + DB_NAME() + ' as of ' + CONVERT(CHAR(19), GETDATE()) + ' </center></h1>'

-- ###############################
-- Get metadata on the database
-- ###############################

DECLARE db_props_cursor CURSOR FOR 
   SELECT CAST(name AS VARCHAR(1000)) AS ext_prop_name, 
          CAST(value AS VARCHAR(1000)) AS ext_prop_value 
     FROM fn_listextendedproperty(DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT);
    
OPEN db_props_cursor
FETCH NEXT FROM db_props_cursor INTO @ext_prop_name, @ext_prop_value
WHILE @@FETCH_STATUS = 0
BEGIN
  IF @ext_prop_value IS NULL 
     BEGIN
       SELECT @ext_prop_value = ' ';
     END
       
  PRINT N'<div class="longLabel">' +  @ext_prop_name +  ':</div>'
        +'<div>' + @ext_prop_value + '</div>'
  FETCH NEXT FROM db_props_cursor INTO @ext_prop_name, @ext_prop_value
END
CLOSE db_props_cursor
DEALLOCATE db_props_cursor
PRINT N'<hr>'


--'Table of Contents' for this document
PRINT '<p align="center"><a href="#tables">Tables</a>&nbsp;&nbsp;<a href="#views">Views</a>&nbsp;&nbsp;<a href="#programs">Programs</a></p>'


PRINT '</br></br><p style="page-break-before: always">' 




-- ###############################
-- Get metadata on the tables
-- ###############################

PRINT '<h2 align="center"><a name="tables">Tables</a></h2>'

DECLARE tablenames_cursor CURSOR FOR 
  SELECT table_name, table_schema
    FROM INFORMATION_SCHEMA.TABLES AS t 
    WHERE table_type = 'BASE TABLE'
    AND table_name <> 'sysdiagrams'
    ORDER BY table_schema,table_name

OPEN tablenames_cursor
FETCH NEXT FROM tablenames_cursor INTO @table_name,@schema
WHILE @@FETCH_STATUS = 0
BEGIN

  PRINT N'<br><div class="objectName">' +  @schema + '.' + @table_name +  '</div><br/>'

  --Get table's extended properties...
  DECLARE tablename_props_cursor CURSOR FOR 
      SELECT CAST(e.name AS VARCHAR(1000)) As ext_prop_name, 
             CAST(e.value AS VARCHAR(1000)) As ext_prop_value 
        FROM sys.tables AS t 
        LEFT OUTER JOIN sys.extended_properties AS e ON t.[object_id] = e.major_id 
        AND e.minor_id = 0
	WHERE t.name = @table_name
        ORDER BY e.name
    
  OPEN tablename_props_cursor
  FETCH NEXT FROM tablename_props_cursor INTO @ext_prop_name, @ext_prop_value
  WHILE @@FETCH_STATUS = 0
  BEGIN
    IF @ext_prop_value IS NULL 
       BEGIN
         SELECT @ext_prop_value = ' ';
       END
       
    PRINT N'<div class="longLabel">' +  @ext_prop_name +  ':</div>'
          +'<div>' + @ext_prop_value + '</div>'
    FETCH NEXT FROM tablename_props_cursor INTO @ext_prop_name, @ext_prop_value
  END
  CLOSE tablename_props_cursor
  DEALLOCATE tablename_props_cursor
  PRINT N'<hr>'
    
  DECLARE columnnames_cursor CURSOR FOR 
	SELECT cols.column_name,cols.data_type,
           CAST(cols.character_maximum_length AS VARCHAR(10)) AS max_length,
           CAST(cols.is_nullable AS VARCHAR(10)) AS required
  	  FROM  (
             SELECT isc.column_name , isc.is_nullable,
	         isc.data_type, isc.character_maximum_length, 
	         c.object_id, c.column_id 
	       FROM information_schema.columns isc
               INNER JOIN sys.columns c ON isc.column_name = c.name  
	       AND OBJECT_NAME(c.object_id) = @table_name
               AND isc.table_name = @table_name
	       AND OBJECTPROPERTY(c.object_id, 'IsMsShipped')=0
		) cols  
				    
  OPEN columnnames_cursor
  FETCH NEXT FROM columnnames_cursor INTO @column_name, @data_type, @length, @required
  WHILE @@FETCH_STATUS = 0
  BEGIN
    IF @length IS NULL 
       BEGIN
         SELECT @length = '--';
       END
		
    --Important column attributes for table columns...
	PRINT N'<div class="label">Column: </div><div class="data">' +  @column_name +  '</div>' +
           '<div  class="label">Data Type: </div><div class="data">' + @data_type + N'</div>' + 
           '<div  class="label">Max. Length: </div><div class="data">' + @length + N'</div>' +
           '<div  class="label">Nullable? : </div><div class="data">' + @required + N'</div>'
      
    --Get column's extended properties...
    DECLARE columnname_props_cursor CURSOR FOR 
	   SELECT CAST(ex.name  AS VARCHAR(1000)) AS ext_prop_name, 
  	      CAST(ex.value AS VARCHAR(1000)) AS ext_prop_value
  	    FROM  (
             SELECT c.object_id, c.column_id 
	       FROM information_schema.columns isc
              INNER JOIN sys.columns c ON isc.column_name = c.name  
	      AND OBJECT_NAME(c.object_id) = @table_name
             AND isc.table_name = @table_name
	     AND isc.column_name = @column_name
	     ) cols  
	   LEFT OUTER JOIN  sys.extended_properties ex  
	   ON  ex.major_id = cols.object_id 
	   AND ex.minor_id = cols.column_id  
                
    OPEN columnname_props_cursor
    FETCH NEXT FROM columnname_props_cursor INTO @ext_prop_name, @ext_prop_value
    WHILE @@FETCH_STATUS = 0
	BEGIN
      IF @ext_prop_value IS NULL 
         BEGIN
           SELECT @ext_prop_value = ' ';
         END
       
      PRINT N'<div class="longLabel">' +  @ext_prop_name +  ':</div>'
             + '<div>' + @ext_prop_value + '</div>'
      FETCH NEXT FROM columnname_props_cursor INTO @ext_prop_name, @ext_prop_value
    END
    CLOSE columnname_props_cursor
    DEALLOCATE columnname_props_cursor
    PRINT N'</br>'           



   	FETCH NEXT FROM columnnames_cursor INTO @column_name, @data_type, @length, @required
  END
  CLOSE columnnames_cursor
  DEALLOCATE columnnames_cursor

  FETCH NEXT FROM tablenames_cursor INTO @table_name,@schema
END

CLOSE tablenames_cursor
DEALLOCATE tablenames_cursor
PRINT '</br>'






-- ###############################
-- Get metadata on the views
-- ###############################

PRINT '</br></br><p style="page-break-before: always">' 

PRINT '<h2 align="center"><a name="views">Views</a></h2>'

DECLARE viewnames_cursor CURSOR FOR 
  SELECT table_name AS view_name,
      table_schema
    FROM INFORMATION_SCHEMA.TABLES AS t 
    WHERE table_type = 'VIEW'
    ORDER BY table_schema,table_name

OPEN viewnames_cursor
FETCH NEXT FROM viewnames_cursor INTO @view_name,@schema
WHILE @@FETCH_STATUS = 0
BEGIN
  PRINT N'<br><div class="objectName">' +  @schema + '.' + @view_name +  '</div><br/>'

  --Get view's extended properties...
  DECLARE viewname_props_cursor CURSOR FOR 
     SELECT CAST(name AS VARCHAR(1000)) As ext_prop_name,
        CAST(value AS VARCHAR(1000)) As ext_prop_value  
      FROM (
          SELECT name,value  
            FROM fn_listextendedproperty (NULL, 'schema', 'dbo', 'view', default, NULL, NULL)
            ) x
      WHERE name NOT LIKE 'MS_%'
      ORDER BY name
    
  OPEN viewname_props_cursor
  FETCH NEXT FROM viewname_props_cursor INTO @ext_prop_name, @ext_prop_value
  WHILE @@FETCH_STATUS = 0
  BEGIN
    IF @ext_prop_value IS NULL 
       BEGIN
         SELECT @ext_prop_value = ' ';
       END
       
    PRINT N'<div class="longLabel">' +  @ext_prop_name +  ':</div>'
          +'<div>' + @ext_prop_value + '</div>'
    FETCH NEXT FROM viewname_props_cursor INTO @ext_prop_name, @ext_prop_value
  END
  CLOSE viewname_props_cursor
  DEALLOCATE viewname_props_cursor
  PRINT N'<hr>'
  FETCH NEXT FROM viewnames_cursor INTO @view_name,@schema
END

CLOSE viewnames_cursor
DEALLOCATE viewnames_cursor
PRINT '</br>'




-- ##########################################################
-- Get metadata on the code (procedures, functions,...)
-- ##########################################################

PRINT '</br></br><p style="page-break-before: always">' 

PRINT '<h2 align="center"><a name="programs">Programs</a></h2>'

DECLARE program_cursor CURSOR FOR 
  SELECT specific_name AS program_name,
      specific_schema, o.object_id
    FROM Information_Schema.routines AS r INNER JOIN sys.all_objects o
    ON r.specific_name = o.name

    --NOTE: THIS EXCLUDES ALL PROCEDURES LIKE 'sp_...' OR 'fn_...'
    --These prefixes should be reserved for system program units!
    WHERE r.specific_name NOT LIKE 'sp_%'
    AND r.specific_name NOT LIKE 'fn_%'
	ORDER BY specific_schema,specific_name

OPEN program_cursor
FETCH NEXT FROM program_cursor INTO @program_name,@schema,@object_id
WHILE @@FETCH_STATUS = 0
BEGIN
	
  PRINT N'<div class="objectName">' +  @schema + '.' + @program_name +  '</div><br/>'

  --Get program's extended properties...
  DECLARE program_props_cursor CURSOR FOR 
      SELECT CAST(e.name AS VARCHAR(1000)) As ext_prop_name, 
          CAST(e.value AS VARCHAR(1000)) As ext_prop_value 
        FROM sys.all_objects s 
        LEFT OUTER JOIN sys.extended_properties AS e ON s.[object_id] = e.major_id 
        AND e.minor_id = 0
        AND OBJECTPROPERTY(s.object_id, 'IsMsShipped')=0
        WHERE s.name =  @program_name
	ORDER BY e.name
    
  OPEN program_props_cursor
  FETCH NEXT FROM program_props_cursor INTO @ext_prop_name, @ext_prop_value
  WHILE @@FETCH_STATUS = 0
    BEGIN
      IF @ext_prop_value IS NULL 
         BEGIN
           SELECT @ext_prop_value = ' ';
         END
       
      PRINT N'<div class="label">' +  @ext_prop_name +  ':</div>'
            +'<div>' + @ext_prop_value + '</div>'
      FETCH NEXT FROM program_props_cursor INTO @ext_prop_name, @ext_prop_value
    END
  CLOSE program_props_cursor
  DEALLOCATE program_props_cursor
  PRINT N'<hr>'
    
  DECLARE parameters_cursor CURSOR FOR 
    SELECT p.parameter_id,p.name AS parameter_name, 
       t.name AS data_type,
       CAST(p.max_length AS VARCHAR(10)) AS max_length
      FROM sys.all_parameters p INNER JOIN sys.systypes t
      ON p.system_type_id = t.xtype
      WHERE p.object_id = @object_id
    
  OPEN parameters_cursor
  FETCH NEXT FROM parameters_cursor INTO @parameter_id,@parameter_name, @data_type, @length
  WHILE @@FETCH_STATUS = 0
  BEGIN
    IF @length IS NULL 
       BEGIN
         SELECT @length = '--'
       END
       IF @length = -1
          BEGIN
            IF @data_type = 'xml'
               SELECT @length = ''
            ELSE
               SELECT @length = 'MAX'
            END
		
  	   --Important attributes for parameters...
	   PRINT N'<div class="label">Parameter: </div><div class="data">' +  @parameter_name +  '</div>' +
              '<div class="label">Data Type: </div><div class="data">' + @data_type + N'</div>' + 
              '<div class="label">Max. Length: </div><div class="data">' + @length + N'</div></br>' 
      
       --Get parameters' extended properties...
       DECLARE parameters_props_cursor CURSOR FOR 
	      SELECT CAST(ex.name  AS VARCHAR(1000)) AS ext_prop_name, 
   	         CAST(ex.value AS VARCHAR(1000)) AS ext_prop_value
		FROM  sys.all_parameters p LEFT OUTER JOIN sys.extended_properties ex  
   	        ON  ex.major_id = p.object_id 
		WHERE ex.minor_id = p.parameter_id  
                AND p.object_id = @object_id
                AND p.parameter_id = @parameter_id
                ORDER BY p.parameter_id
                
            OPEN parameters_props_cursor
            FETCH NEXT FROM parameters_props_cursor INTO @ext_prop_name, @ext_prop_value
            WHILE @@FETCH_STATUS = 0
	     BEGIN
              IF @ext_prop_value IS NULL 
                 BEGIN
                   SELECT @ext_prop_value = ' ';
                 END
       
              PRINT N'<div class="longLabel">' +  @ext_prop_name +  ':</div>'
                    + '<div>' + @ext_prop_value + '</div>'
              FETCH NEXT FROM parameters_props_cursor INTO @ext_prop_name, @ext_prop_value
           END
           CLOSE parameters_props_cursor
           DEALLOCATE parameters_props_cursor
           PRINT N'</br>'           

      	FETCH NEXT FROM parameters_cursor INTO @parameter_id,@parameter_name, @data_type, @length
	END
	CLOSE parameters_cursor
	DEALLOCATE parameters_cursor

    FETCH NEXT FROM program_cursor INTO @program_name,@schema,@object_id
END
CLOSE program_cursor
DEALLOCATE program_cursor


PRINT N'<br><h4>Done.</h4></body></html>'
RETURN

GO