@echo off
REM $Archive:   //cs01pvcs/pvcs/cm/Database/archives/SERVERS/STORE/MLGSTORE/SetRightBT38.cvd  $
REM	$Revision: 1.1 $  
REM $Date: 2011/02/09 22:54:03 $
REM	$Author: A645276 $


c:
cd\utils\build
REM
REM Maestro things
REM Grant logon right
NtRights.exe -u maestro +r SeTcbPrivilege                      
NtRights.exe -u maestro +r SeIncreaseQuotaPrivilege            
NtRights.exe -u maestro +r SeBatchLogonRight                     
NtRights.exe -u maestro +r SeServiceLogonRight                  
NtRights.exe -u maestro +r SeInteractiveLogonRight              
NtRights.exe -u maestro +r SeAssignPrimaryTokenPrivilege    
NtRights.exe -u AppsAdminServices +r SeServiceLogonRight                   
NtRights.exe -u PROCESSReplication +r SeServiceLogonRight                   
NtRights.exe -u SQLAGENT +r SeServiceLogonRight
REM set service auto startup
sc config SQLSERVERAGENT obj= .\SQLAGENT password= DiMeThangMR
sc config "SQLSERVERAGENT" start= auto



