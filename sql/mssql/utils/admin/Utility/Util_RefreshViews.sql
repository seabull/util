/*
sp_depends N'dbo.t_NotificationInstances'
sp_refreshview N''

================================================================================
    NAME        : PRefreshViews
    DESCRIPTION : Refresh all Non-Schema Bound Views
    CREATED BY  : LJ
    DATE        : 
================================================================================
*/

CREATE PROCEDURE dbo.Util_RefreshViews
AS
BEGIN

	SET NOCOUNT ON

	DECLARE @SchemaName     VARCHAR(25);
    DECLARE @ViewName	VARCHAR(100);
	DECLARE @Tmp		VARCHAR(MAX);

	DECLARE @ViewLister TABLE
	(
		SchemaName	VARCHAR(25),
        ViewName	VARCHAR(100),
		CreationDate	DATETIME
	);

	INSERT INTO @ViewLister (SchemaName, ViewName, CreationDate)
		SELECT DISTINCT S.Name, V.Name, V.create_date 
		FROM SYS.VIEWS V
		JOIN SYS.SQL_DEPENDENCIES SD 
		  ON V.OBJECT_ID = SD.OBJECT_ID
		JOIN SYS.SCHEMAS S
		  ON V.schema_id = S.schema_id 
		WHERE SD.Class = 0	   -- Class = 0 are views that are non schema bound
        ORDER BY V.create_date     -- Refreshed in the order the views were created in, to ensure no dependency issues

	DECLARE cu_ViewIterator CURSOR FOR 
		SELECT SchemaName, ViewName FROM @ViewLister
	        
	OPEN cu_ViewIterator

	FETCH NEXT FROM cu_ViewIterator INTO @SchemaName, @ViewName

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @tmp = 'EXEC sp_refreshview ''[' + @SchemaName + '].' + @ViewName + ''' '
		PRINT 'Refeshing [' + @SchemaName + '].' + @ViewName;
		BEGIN TRY
			EXEC (@tmp)
		END TRY
		BEGIN CATCH
			RAISERROR ('The previous View has Failed to be Refreshed - Please review its underlying objects ', -- Message text.
               16, -- Severity.
               1 -- State.
               );
		END CATCH;

		FETCH NEXT FROM cu_ViewIterator INTO @SchemaName, @ViewName
	END

	CLOSE cu_ViewIterator
	DEALLOCATE cu_ViewIterator
    
	SET NOCOUNT OFF
END
GO


