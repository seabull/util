:connect dvr31db05\pl01le101
select @@servername, serverproperty('ComputerNamePhysicalNetBIOS ') as ComputerName -- return physical server name
-- exec xp_cmdshell 'logman stop T38DVR31DB05 -s DVR31DB05'
exec xp_cmdshell 'logman stop T38DVR31DB05 -s DSR31DB02'
waitfor delay '00:00:15'
exec xp_cmdshell 'logman start T38DVR31DB05 -s DSR31DB02'
exec xp_cmdshell 'logman query -S DSR31DB02'
go

:connect dvr31db04\pl01lx101
select @@servername, serverproperty('ComputerNamePhysicalNetBIOS ') as ComputerName -- return physical server name
exec xp_cmdshell 'logman stop T38DVR31DB04 -s DSR31DB02'
waitfor delay '00:00:15'
exec xp_cmdshell 'logman start T38DVR31DB04 -s DSR31DB02'
exec xp_cmdshell 'logman query -S DSR31DB02'
go

:connect dvr32db03\pl01lb101
select @@servername, serverproperty('ComputerNamePhysicalNetBIOS ') as ComputerName -- return physical server name
-- exec xp_cmdshell 'logman query'
exec xp_cmdshell 'logman stop T38DVR32DB03 -s DSR32DB02'
waitfor delay '00:00:15'
exec xp_cmdshell 'logman start T38DVR32DB03 -s DSR32DB02'
exec xp_cmdshell 'logman query -S DSR32DB02'
go