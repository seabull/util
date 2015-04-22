
WITH LastBackupTaken AS (
SELECT database_name,
backup_finish_date,
RowNumber = ROW_NUMBER() OVER (PARTITION BY database_name 
                            ORDER BY backup_finish_date DESC)
FROM msdb.dbo.backupset 
)
SELECT database_name,backup_finish_date 
FROM LastBackupTaken
WHERE RowNumber = 1

