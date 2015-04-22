-- To see VLF (Virtual Log File) layout
dbcc LOGINFO('PRFDB001')

-- To view log space info
dbcc sqlperf(logspace)
