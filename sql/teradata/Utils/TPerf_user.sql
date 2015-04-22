
--bteq .logon bby2/a645276,passwd  
--.logon bby2/a645276 

Select 
	Sum(CPUTime)
	, Sum(DiskIO)
	, Sum(CPUTime)*0.002702 as TPH
From DBC.AmpUsage 
Where Username = USER;

.logoff
.exit
