#!perl 
#*  t38instl90 - SQL Server installation program, version 10.0.
#*	based on t38inst90.pl, Revision 1.51
#*
#*	$Author: A645276 $
#*	$Date: 2011/02/08 15:34:08 $
#*	$Revision: 1.1 $
#*	$Archive:   //uxpvcs2/pvcs/projects/Database/archives/DatabaseSolutions/MSSQL/EnvironmentStandardsAndConfigurationBuild/InstallSQLServer/SQL100/Scripts/t38instl100.pv_  $
#*
#* SYNOPSIS
#* perl T38instl90.pl -h |  -a 10 -x adfhilpstuy9 -S serverName cfgFileName.cfg
#* 
#* Commnad line
#*
#*	-h   		Writes help screen on standard output, then exit the program.
#*	-a 10		Number of log file archived, default is 7.
#*	-S server	Name of the server, where to configure SQL Server.
#*	-x steps	Execution steps option. If -x option is not provided, all steps 
#*				will be executed. Otherwise only specified steps will be done.
#*				The possible execution steps are.
#*				a - Run SQL Agent jobs.
#*				c - Install Client Components.
#*				d - Create directories for BBY SQL Server install (t38xxx).
#*				f - Copy files to T38APP80 directory.
#*				g - Upgrade SQL Server.
#*				h - Create shares for t38 directories.
#*				i - Install SQL Server.
#*				m - lock memory pages
#*				n - Add node to existing cluster
#*				l - Copy perl libraries.
#*				r - remove SQL Server node. All other options are ignored with this one.
#*				s - Setup security rights for SQL Administrators.
#*				t - Change SQL Service accounts.
#*				u - Create user databases.
#*				y - Configure system databases (run t38procs.sql, Install00 and master.sql).
#*				9 - Run post-processing scripts from Install01-99 directories.
#*
#*				NOTE: The a, d, f, h, u, y and 9 options can be run 
#*				remotely with -S serverName option. The i, n, l, c, s and t options
#*				cannot be executed remotely with this version of the program.
#*	
#* CfgFileName.cfg
#*    A configuration file used to initilize the starup parameters, Required 
#*
#*
#* Example:
#*	1) perl T38instl90.pl userdb.cfg T38app80\T38dba.cfg
#*		Run SQL server install using T38dba.cfg file to set up initial parameters
#*		and userdb.cfg to create user databases.
#*
#*	2) perl T38instl90.pl -x p T38APP80\T38dba.cfg
#*      Run only service pack install using T38dba.cfg file in directory T38APP80
#*
#*	3) perl T38instl90.pl -x h -S HST2DB \\HST2DB\f$\DBMS\T38APP80\T38dba.cfg
#*      Create t38 shares on HST2DB. Note: t38dba.cfg file on HST2DB has to exists
#*		and define all drive letters correctly for shares.
#*
#*	4) perl T38instl90.pl -x dlfhiy9 T38APP80\T38dba.cfg
#*      Install SQL Server, without creating User databases, setting up security and
#*		running SQL agent jobs. Note: t38srvstats SQL Agent job registers installed
#*		SQL Servers with central repository.
#*
#*	5) perl T38instl90.pl -h
#*		Show the help screen
#*
#***

use strict;

use T38lib::Common qw(notifyMe notifyWSub logme warnme errme escapeREChar 
						getWinClusterName getWinClusterRes
						runOSCmd adGrpName2samid adUsrName2samid);
use T38lib::t38cfgfile qw(:CFGFILE_SUBS :CFGFILE_VARS);
use T38lib::bbyado qw(:BBYADO_SUBS :BBYADO_VARS);
use Getopt::Std;
use Cwd;
use File::Path;
use File::Basename;
use Win32API::Net;
use Win32::NetAdmin;
use Win32::OLE qw(in with);
use Win32::TieRegistry ( Delimiter=>"/", ArrayValues=>0);

# Global Variables
my ( $gCurrentDir, $gScriptName, $gScriptPath, $gHostName, $gNWarnings) = "";

# Server names:
# gSrvrName		- name of the SQL Server, with instance name.
# gNetName 		- network machine name where SQL server is running. For clustered server it is virtual server name.
# gInstName		- name of SQL Server instance
# gNetNodeName	- name of the node for the server named gNetName. For clustered server it is physical node, where 
#				  virtual resource group gNetName is running. For non-clustered server it is same as gNetName.
# 
my ( $gSrvrName, $gNetName, $gInstName, $gNetNodeName);
my ( $gRunOpt);
my @gArg = ();

my ($gphyMem, $gsqlMem) = (0,0);
my ($gminSwitch, $gmaxSwitch, $gaweSwitch) = (0,0,0);
my ($gnumOfTempdbFiles) = (1);
my $gnumOfCPU = (1);
my ($gnumOfdbFiles) = (1);
my $gincludeCfgParm = "DBNAME";
my $gClustSqlInstallStat = -99;		# Cluster install status. Values are (see checkSQLInstallStatusClust sub):
									#		0	SQL Server resources are not present in $vsName group
									#			(need to create SQL Server cluster)
									#		1	All SQL Server resources are present in $vsName group and 
									#			current node owns the disk.
									#		2	All SQL Server resources are present in $vsName group and 
									#			current node does not own the disk.
									#		3	All SQL Server resources are present in $vsName group but
									#			current node is not part of the group (need to run addnode process).
									#		-1	Some but not all SQL Server resources are present in $vsName
									#			group (SQL Is partially install error).
									#		-2	Status is unknown due to execution error
									#		-99 Not a clustered install



my $gPgmRevision = '$Revision: 1.1 $';		# Program revision from PVCS
my $T38ERROR = $T38lib::Common::T38ERROR;			

# use constant SETUP_TIMEOUT	=> 120;			# Time out value for setup the sql server
use constant SETUP_TIMEOUT	=> 480;			# Time out value for setup the sql server (8 hours)
use constant DBCRSZNAME		=> 'dbcrsz';	# Base file name for database create script

my %gCharSO = ();

# Sort order for SQL install
#
$gCharSO {'binary'}     {'850'} {'Y'}	= "SQL_Latin1_General_Cp850_BIN";		# { SortId => 40
$gCharSO {'binary2'}    {'850'} {'Y'}	= "SQL_Latin1_General_Cp850_BIN2";		# { SortId => 40
$gCharSO {'dictionary'} {'850'} {'Y'}	= "SQL_Latin1_General_Cp850_CS_AS";		# { SortId => 41
$gCharSO {'dictionary'} {'850'} {'N'}	= "SQL_Latin1_General_Cp850_CI_AS";		# { SortId => 42 
$gCharSO {'binary'}     {'ISO'} {'Y'}	= "SQL_Latin1_General_BIN";				# { SortId => 50
$gCharSO {'dictionary'} {'ISO'} {'Y'}	= "SQL_Latin1_General_CP1_CS_AS";		# { SortId => 51
$gCharSO {'dictionary'} {'ISO'} {'N'}	= "SQL_Latin1_General_CP1_CI_AS";		# { SortId => 52

# Function declaration in alphabetical order
#
sub adAddAccount2LocGrp($$;$);			# active directory add account to local group
sub buildMaster();						# Change master database properties
sub buildSQLDirs();						# Build directories needed for the install
sub buildSetup($$); 					# Build ISS file for unattended install
sub buildSharePointsClusW2k8();			# Build file share resource for Virtual Server on Windows 2008 cluster.
sub buildSharePoints();					# Create all the share points for support
sub buildSharePointsClus();				# Build file share resource for Virtual Server	
sub buildUserDb();						# Generate SQL for any user database creation
sub changeSAPassword();					# Change sa password after the install
sub checkSQLInstallStatusClust ();		# check SQL Install Status in a cluster
sub checkSystem();						# Check the box for SQL install
sub copyT38lib();						# Copy t38lib modules to Perl site directory
sub generateTempSaPwd();				# Hemanth: Generate a temporary sa password to be used with the installation process.
sub getClusSQLNodes ($$);				# get list of nodes for SQL Server resource
sub getNode4VClusterRsrcGrp ($$);		# get node name resource group in windows cluster 
sub getInstallerPwd ($$);				# get password for installer account
sub getInstPortNum();                   # Get port number for installing an instance
sub getSAPwd ($);						# Get initial sa password from repository
sub getSQLInstallSetupExe100($$);		# Get SQL Server installation setup.exe Path
sub getSysCPU();						# Get number of CPU on the box
sub getSysMemory();                     # Get physical memory of the box
sub getSysVerReg(;$);					# Get OS major version number from registry.
sub grantAdminAccounts();				# Grant permissions to known admin accounts
sub installSQL();						# Install SQL (Server 2008, ...)
sub installSQLClientTools ();			# Install SQL Server Client Tools
sub installSQL100Client ();				# Install SQL Server 10.0 (SQL 2008) client
sub installSQL100Server();				# Install SQL Server 100.
sub installUserDb ();					# Install user databases
sub mkdir($);							# User system command to create directory path
sub moveSQLScripts();					# Move any maintenance script to proper directory 
sub notifyFile ($);						# Print notifications from the file
sub prepareConfigParms ();				# Prepare configuration parameters
sub removeNode();						# Remove SQL Server node.
sub removeNodeSQL100();					# Remove SQL 2008 node.
sub resetSQLServicesAccounts ();		# reset SQL Server Services accounts
sub restartSQLServices ();				# Restart MSSQL related services
sub restartSQLServicesClus ();			# restart MSSQL related services in a cluster
sub runPostInstallScripts ();			# Run post install scripts from Install01 - 99 directories
sub runScriptsDir($;$);					# Run a given script or all the scripts in a directory
sub setLockMemoryPrivilege();           # Set sql server account to lock Memory, only valid when AWE is on
sub setMemoryAWESwitch();               # Set up switches for memory and AWE
sub setEnvPath ();						# set environment path
sub startSQLServices ();				# Start MSSQL related services
sub stopSQLServices ();					# Stop MSSQL related services
sub testConfigParm();					# Test all the parameters read from CFG files
sub upgradeSQL();					# Upgrade SQL (Server 2008, ...)
sub upgrade2SQL100Server();				# Upgrade to SQL Server 10.0.
sub verifyADGroupName ($);				# verify Active Directory group name
sub verifyDiskResClus ($$\$); 			# verify Disk Resources are using standard name in a cluster

# Main
&main();

############################  BBY Subroutines  ####################################

sub main {
	my $mainStatus			= 0;
	my $sqlInstallStatus	= 0;
	my ($cmdLine, $tmpout) = ("", "");
SUB:
{
	unless (&housekeeping())	{ $mainStatus = 1; last SUB; }
	
	# Get Cluster install status.
	if ($gConfigValues{SQLVirtualName}) {
		$gClustSqlInstallStat = &checkSQLInstallStatusClust();
	} else {
		$gClustSqlInstallStat = -99;
	}

	if ($gRunOpt =~ /r/) {				# Create SQL Server Support directories
		unless (&removeNode())	{ $mainStatus = 1;}
		last SUB;
	}

	if (!$gRunOpt || $gRunOpt =~ /[di]/) {				# Create SQL Server Support directories
		&buildSQLDirs();
	}

	# If we are not required to install SQL Server, exit the program.
	# Otherwise check if SQL is installed and continue.

	if (!$gRunOpt || $gRunOpt =~ /[^d]/) {
		# Run options are not provided or it has some options, other then [d].
		$sqlInstallStatus = &checkSystem();
	} else {
		# We have only d run option. Exit the program.
		last SUB;
	}

	if ((!$gRunOpt || $gRunOpt =~ /[in]/) && ($sqlInstallStatus == 0 || $gClustSqlInstallStat == 3) ) {	# Install SQL Server
		# install SQL Server software
		unless (&installSQL())				{ $mainStatus = 1; last SUB; }

		# Set the SQL install status, so the other part can be done
		$sqlInstallStatus = 1;
	}

	if ($gRunOpt =~ /[g]/) {	# Upgrade SQL Server
		if ($sqlInstallStatus != -1) {
			&errme("To upgrade, older Version of Microsoft SQL Server has to be installed on $gSrvrName. Check installed versin.");
			$mainStatus = 1; last SUB;
		}

		# install SQL Server software
		unless (&upgradeSQL())				{ $mainStatus = 1; last SUB; }

		# Set the SQL install status, so the other part can be done
		$sqlInstallStatus = 1;
	}

	if ($sqlInstallStatus == -1) {
		&errme("Older Version of Microsoft SQL Server installed on $gSrvrName ");
		$mainStatus = 1; last SUB;
	}

	if (($gRunOpt !~ /^[in]$/) && $sqlInstallStatus != 1) {
		# If we Installing new SQL Server or adding node,  this warning can be ignored.
		# If we are installing other steps, we cannot proceed, unless SQL is running.
		&errme("Cannot proceed. SQL Server is not installed");
		$mainStatus = 1; last SUB;
	}

	# At this point SQL Server is installed and we can continue with other components,
	# which are dependent on SQL Server services or Virtual Resource Group
	# for SQL Server.

	if (!$gRunOpt || $gRunOpt =~ /c/) {
		unless(&installSQLClientTools())	{ $gNWarnings++; }	# SQL Client tool will return an error if they already installed.
	}

	if (!$gRunOpt || $gRunOpt =~ /l/) {
		unless(&copyT38lib())	{ $mainStatus = 1; last SUB; }
	}

	if (!$gRunOpt || $gRunOpt =~ /f/) {					# copy SQL maintenance scripts from t38app80 directory
		&moveSQLScripts();
	}

	# At this time $gScriptName cannot install Service Pack. Use slipstream install.
	# if (!$gRunOpt || $gRunOpt =~ /[pi]/) {					# Install Service Pack
		## install service pack upgrade if necessary
		# unless (&installServicePack())	{ $mainStatus = 1; last SUB; }
	#}

	if (!$gRunOpt || $gRunOpt =~ /y/) {
		unless (&runScriptsDir('install\\T38procs.sql'))	{ $mainStatus = 1; last SUB; }
		unless (&runScriptsDir("INSTALL00"))				{ $mainStatus = 1; last SUB; }
		unless (&buildMaster())								{ $mainStatus = 1; last SUB; }
		unless (&runScriptsDir('INSTALLWRK\\master.sql'))	{ $mainStatus = 1; last SUB; }
	}

	if (!$gRunOpt || $gRunOpt =~ /m/) {
		unless (&setLockMemoryPrivilege())	{ $mainStatus = 1; last SUB; }
	}

	# Test if services still have to be restarted here or only at the end is OK.
	#if (!$gRunOpt || $gRunOpt =~ /[piy]/) {
		# If we are installing SQL Server or Service pack, restart services.
		#	unless ( &restartSQLServices() )	{ $mainStatus = 1; last SUB; }
	#}

	if (!$gRunOpt || $gRunOpt =~ /u/) {					# create user database scripts
		unless (&installUserDb())	{ $mainStatus = 1; last SUB; }
	}

	if (!$gRunOpt || $gRunOpt =~ /9/) {					# Run install scripts from Install01 - 99 directories
		sleep 20;
		unless (&runPostInstallScripts())	{ $mainStatus = 1; last SUB; }
	}

	if (!$gRunOpt || $gRunOpt =~ /s/) {					# Do security setup

		unless (&grantAdminAccounts()) {
			&warnme("Fail to add Administrative Accounts");
			$gNWarnings++;
		}
		$cmdLine = "cmd /c perl T38APP80\\T38ADSec.pl -c T38APP80\\T38dba.cfg -S $gSrvrName -p";

		if ( system($cmdLine) != 0 ) {
			&warnme("Fail to run $cmdLine");
			$gNWarnings++;
		}

		unless (&changeSAPassword()) {
			&warnme("Fail to change sa password");
			$gNWarnings++;
		}
	}

	if (!$gRunOpt || $gRunOpt =~ /t/) {				# Reset SQL Server service accounts.
		unless (&resetSQLServicesAccounts()) {
			&warnme("Fail to reset SQL Services Accounts");
			$gNWarnings++;
		}
	}

	if (!$gRunOpt || $gRunOpt =~ /[pinyst]/) {
		# If we are installing SQL Server or Service pack, restart services.
		# When service accounts are reset, SQL Agent will be off-line.
		# Services should also be restarted after accounts are reset.
		unless ( &restartSQLServices() )	{ $mainStatus = 1; last SUB; }
	}

	if (!$gRunOpt || $gRunOpt =~ /h/) {					# Build all the share points
		unless (&buildSharePoints())	{ $mainStatus = 1; last SUB; }
	}

	if (!$gRunOpt || $gRunOpt =~ /a/) {					# Run script from install directory T38runAgentJobs.sql
		unless (&runScriptsDir('install\\T38runAgentJobs.sql'))	{ $mainStatus = 1; last SUB; }
	}

	if ( $gConfigValues{SecurityGroupLocation} =~ /S/i ) {		# Run script to grant special permission if store server
		unless (&runScriptsDir('install\\GrantViewServerState.sql'))	{ $mainStatus = 1; last SUB; }
	}

	# If reboot flag is set to Y then reboot the box
	# cfg file has the reboot flag default value is N, means do NOT reboot
	#
	if ( $gConfigValues{RebootFlag} =~ /y/i ) {
		&notifyWSub("User requested to reboot $gNetName.");
		if (uc($gHostName) ne uc($gNetName)) {
			&warnme("This program cannot reboot remote machine.");
			$gNWarnings++;
		} else {
			&notifyWSub("DONE of main program: $0");
			&notifyWSub("Rebooting the Box");
			&T38lib::Common::rebootLocalMachine();
		}
	}

	last SUB;

}	# SUB
# ExitPoint:

	$mainStatus = 2	if ($gNWarnings > 0);

	if ( $mainStatus== 0 ) {
		&notifyWSub("The $gScriptName completed successfully.");
		&logme("Finished with status $mainStatus", "done");
	} elsif ( $mainStatus== 1 ) {
		&notifyWSub("The $0 program completed with critical errors.");
		&errme("Finished with status $mainStatus", "done");
		&T38lib::Common::errorTrap();
	} elsif ( $mainStatus== 2 ) {
		&notifyWSub("The $0 program completed with $gNWarnings warnings.");
		$tmpout = &T38lib::Common::getLogFileName($0);
		&notifyWSub("Check the log file: $tmpout");
		&warnme("Finished with status $mainStatus", "done");
		&T38lib::Common::warningTrap();
	}
	exit($mainStatus);

}	# main


#######################  $Workfile:   t38instl100.pl  $ Subroutines  #################################

# ----------------------------------------------------------------------
#	adAddAccount2LocGrp		active directory add account to local group
# ----------------------------------------------------------------------
#	arguments:
#		accntName	active directory account name as "domain\account"
#		grpName		local machine group name
#		srvrName	optional server name, default is local server
#	return:
#		1			Success
#		0			Failure
# ----------------------------------------------------------------------
#	Add active directory account to local group.
# ----------------------------------------------------------------------

sub adAddAccount2LocGrp($$;$) {
	my $accntName	= shift;
	my $grpName		= shift;
	my $srvrName	= shift;
	my $domain		= '';
	my $usrShortName= '';
	my $usrName		= '';
	my $usrAdsPath	= '';		# ADSI Path for the user
	my $grpAdsPath	= '';		# ADSI Path for the group
	my $hUsr		= 0;		# ADSI object for the user
	my $hGrp		= 0;		# ADSI object for the group
	my $member		= 0;		# Member of the grou object
	my $matched		= 0;		# matched flag
	my $status		= 1;

SUB:
{
	unless ($srvrName) { $srvrName = $gHostName; }
	&notifyWSub("Started. Account Name: $accntName, Group: $grpName, Server: $srvrName.");
	($domain, $usrName) = split(/\\/, $accntName);
	unless ($domain && $usrName) {
		&errme("$accntName is invalid. It has to be in the following form: DomainName\\UserName");
		$status = 0; last SUB;
	}

	unless ($usrShortName = &adGrpName2samid("$domain\\$usrName")) {
		&errme("$accntName is invalid.");
		$status = 0; last SUB;
	}
	
	&notifyMe("Adding account: $domain\\$usrShortName");
	$usrAdsPath = "WinNT://$domain/$usrShortName";

	unless ($hUsr = Win32::OLE->GetObject($usrAdsPath)) {
		&errme("Unable to get ADSI object for $usrAdsPath");
		$status = 0; last SUB;
	}

	&notifyMe("User Name = $hUsr->{Name}, Class = $hUsr->{Class}, Schema = $hUsr->{Schema}");

	## Debug code to view properties of the object
	#my $schmobj = 0;
	#unless ($schmobj = Win32::OLE->GetObject($hUsr->{Schema})) {
	#	&errme("Unable to retrieve schema object for $usrAdsPath");
	#	$status = 0; last SUB;
	#}
	#print join("\n",@{$schmobj->{MandatoryProperties}},
	#                @{$schmobj->{OptionalProperties}}),"\n";

	# foreach my $i (@{$schmobj->{MandatoryProperties}}, @{$schmobj->{OptionalProperties}}) {
	#   print "$i:\t".$hUser->Get($i)."\n";
	# }


	# $grpAdsPath="WinNT://LST01DB01/Administrators";
	$grpAdsPath="WinNT://$srvrName/$grpName";
	unless ($hGrp = Win32::OLE->GetObject($grpAdsPath)) {
		&errme("Unable to get ADSI object for $grpAdsPath");
		$status = 0; last SUB;
	}

	&notifyMe("Group Name = $hGrp->{Name}, Class = $hGrp->{Class}");

	# Check if our account is already member of the group.
	foreach $member (in $hGrp->Members()) {
		# Debug code: &notifyMe("\t$member->{Name}");
		if ((lc($member->{Name}) eq lc($accntName)) or (lc($member->{Name}) eq lc($usrShortName))) {
				&notifyMe("\t\t Matched $accntName or $usrShortName");
				$matched = 1;
		}
	}

	if (!$matched) {
		&notifyMe("Adding $usrAdsPath to $grpAdsPath");
		$hGrp->Add($usrAdsPath);
		if (Win32::OLE->LastError()) {
			&errme(Win32::OLE->LastError());
			$status = 0; last SUB;
		}
	} 
	# Debug code:
	#else {
	#	&notifyMe( "Remove $usrAdsPath from $grpAdsPath");
	#	$hGrp->Remove($usrAdsPath);
	#	if (Win32::OLE->LastError()) {
	#		&errme(Win32::OLE->LastError());
	#		$status = 0; last SUB;
	#	}
	#}

	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
} # end sub adAddAccount2LocGrp


#------------------------------------------------------------------------------
# Purpose: Build Master
# Return:
#		1	Success
#		0	Failure
#------------------------------------------------------------------------------
sub buildMaster() {

	&T38lib::Common::notifyMe("[buildMaster] START - Build Master Database");

	my $master	= "${gScriptPath}INSTALLWRK\\master";
	my ($i, $sqlLine, $fileName, $tempdbPath, $deviceName);
	my @adrs	= ();		
	my ($name,$path,$ext);
	my $dbHandle	= 0;

	system("cmd /C del $master.old") if (-s "$master.old");
	system("cmd /C rename $master.sql master.old") if (-s "$master.sql");

	unless (open(MASTER, ">$master.sql")) { 
		&errme("Cannot open file $master.sql for writing. $!"); 
		return(0);
	}

print MASTER <<"EOT";

/*********************************************************************************/
/* MASTER DATABASE CREATE SCRIPT:                                                */
/* SQL Server "master" DATABASE                                                  */
/* BEST BUY CO, INC.                                                             */
/*-------------------------------------------------------------------------------*/
/* This file is created by $0, $gPgmRevision */

/*********************************************************************************/

set QUOTED_IDENTIFIER off
go

/* Check for correct version of the SQL Server */
if 
	(select \@\@version) not like '%Microsoft SQL Server  2000%' and
	(select \@\@version) not like '%Microsoft SQL Server % - 9.00.%' and
	(select \@\@version) not like '%Microsoft SQL Server % - 10.0.%'

begin
	RAISERROR('This script is for Microsoft SQL Server  2000 and above', 10, 127) with log
end
GO

PRINT ''
PRINT ''
PRINT '<<<< master >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
PRINT ''

USE master
GO

if (not exists (select 1 from sysdevices where name = 'master_db_bkp'))
	EXEC sp_addumpdevice 'disk', 'master_db_bkp', '$gConfigValues{DumpDevicesDrive}:$gConfigValues{DumpDevicesPath}\\master_db.bkp', 2
GO

if (not exists (select 1 from sysdevices where name = 'master_log_bkp'))
EXEC sp_T38CRBKP \@dbname = 'master', \@bkptype = 'log'
GO

EOT

	if (defined($gSystemDb{'master'})) {
		my $dbName		= 'master';
		my $dataName	= 'master';
		my $logName		= 'mastlog';
		my $dataSize	= $gSystemDb{$dbName}{'DataSize'};
		my $logSize		= $gSystemDb{$dbName}{'LogSize'};
		my $dataBackup	= $gSystemDb{$dbName}{'dataBackup'};
		my $logBackup	= $gSystemDb{$dbName}{'LogBackup'};
		my $truncLog	= $gSystemDb{$dbName}{'TruncLog'};
		my $selectInto	= $gSystemDb{$dbName}{'SelectInto'};
		my $backupPath	= ($gConfigValues{DumpDevicesDrive}) ?
					"$gConfigValues{DumpDevicesDrive}:$gConfigValues{DumpDevicesPath}\\$dataBackup.bkp" :
					"\\\\$gConfigValues{DumpDevicesSrvr}$gConfigValues{DumpDevicesPath}\\$dataBackup";

print MASTER <<"EOT";

exec ("use $dbName exec sp_T38ALTERDB \@filename = $dataName, \@filesize = $dataSize, \@filetype = 'D'")
exec ("use $dbName exec sp_T38ALTERDB \@filename = $logName, \@filesize = $logSize, \@filetype = 'L'")


ALTER DATABASE $dbName
MODIFY FILE
	(NAME = $dataName,
	FILEGROWTH = 10MB)
GO

ALTER DATABASE $dbName
MODIFY FILE
	(NAME = $logName,
	FILEGROWTH = 10MB)
GO

EOT
	} ####################### if (defined($gSystemDb{'master'}) #######################


	if (defined($gSystemDb{'msdb'})) {
		my $dbName		= 'msdb';
		my $dataName	= 'MSDBData';
		my $logName		= 'MSDBLog';
		my $dataSize	= $gSystemDb{$dbName}{'DataSize'};
		my $logSize		= $gSystemDb{$dbName}{'LogSize'};
		my $dataBackup	= $gSystemDb{$dbName}{'DataBackup'};
		my $logBackup	= $gSystemDb{$dbName}{'LogBackup'};
		my $truncLog	= $gSystemDb{$dbName}{'TruncLog'};
		my $selectInto	= $gSystemDb{$dbName}{'SelectInto'};
		my $backupPath	= ($gConfigValues{DumpDevicesDrive})?
					"$gConfigValues{DumpDevicesDrive}:$gConfigValues{DumpDevicesPath}\\$dataBackup.bkp" :
					"\\\\$gConfigValues{DumpDevicesSrvr}$gConfigValues{DumpDevicesPath}\\$dataBackup.$gNetName.bkp";

		print MASTER <<"EOT";

exec ("use $dbName exec sp_T38ALTERDB \@filename = $dataName, \@filesize = $dataSize, \@filetype = 'D'")
exec ("use $dbName exec sp_T38ALTERDB \@filename = $logName, \@filesize = $logSize, \@filetype = 'L'")

if (not exists (select 1 from sysdevices where name = 'msdb_db_bkp'))
EXEC sp_T38CRBKP \@dbname = 'msdb', \@bkptype = 'db'
GO

if (not exists (select 1 from sysdevices where name = 'msdb_log_bkp'))
EXEC sp_T38CRBKP \@dbname = 'msdb', \@bkptype = 'log'
GO

ALTER DATABASE $dbName
MODIFY FILE
	(NAME = $dataName,
	FILEGROWTH = 10MB)
GO

ALTER DATABASE $dbName
MODIFY FILE
	(NAME = $logName,
	FILEGROWTH = 10MB)
GO

EOT

	} ####################### if (defined($gSystemDb{'msdb'}) #######################

	if (defined($gSystemDb{'tempdb'})) {
		my $dbName		= 'tempdb';
		my $dataName	= 'tempdev';
		my $logName		= 'templog';
		my $dataSize	= $gSystemDb{$dbName}{'DataSize'};
		my $logSize		= $gSystemDb{$dbName}{'LogSize'};
		my $truncLog	= $gSystemDb{$dbName}{'TruncLog'};
		my $selectInto	= $gSystemDb{$dbName}{'SelectInto'};
		

	# Set tempdb files according to the number of CPU on the server
	#
    if ( (defined($gConfigValues{'NumoftempdbFiles'}) ) and ($gConfigValues{'NumoftempdbFiles'} > 0) ) {
		$gnumOfTempdbFiles = $gConfigValues{'NumoftempdbFiles'};
	}
	else {
		unless (&getSysCPU()) {
			&T38lib::Common::warnme("sub getSysCPU failed");
			&T38lib::Common::warnme("Can not get number of CPUs on the box");
			$gNWarnings++;
			$gnumOfTempdbFiles = 1
		}
		&notifyWSub("Number of CPU on the box = $gnumOfTempdbFiles");
	}


	if ( ($dbHandle = &adoConnect($gSrvrName, "tempdb")) == 0 ) {
		&T38lib::Common::warnme("Can not connect to $gSrvrName to get tempdb path");
		$gNWarnings++;
		$gnumOfTempdbFiles = 1
	}
	else {
		unless( execSQL2Arr($dbHandle,
			"select filename from tempdb..sysfiles where fileid = 1 ", \@adrs,)) { 
			&T38lib::Common::warnme("Can not get tempdb file path");
			$gNWarnings++;
			$gnumOfTempdbFiles = 1
		}
		$tempdbPath	= $adrs[0]{filename};
		$tempdbPath =~ s/^\s*//g;							# Remove all leading white spaces
	   	$tempdbPath =~ s/\s*$//g;							# Remove all trailing white spaces
		($name,$path,$ext) = fileparse("$tempdbPath",'\.[^\.]*');
	}
	if ($dbHandle) { $dbHandle->Close(); $dbHandle = 0; }

	# Calculate tempdb file size according to number of CPU
	# number of tempdb files = number of CPU on the box
	#
	$dataSize = int($dataSize/$gnumOfTempdbFiles);

print MASTER <<"EOT";

use $dbName
GO

exec ("use $dbName exec sp_T38ALTERDB \@filename = $dataName, \@filesize = $dataSize, \@filetype = 'D'")
exec ("use $dbName exec sp_T38ALTERDB \@filename = $logName, \@filesize = $logSize, \@filetype = 'L'")
CHECKPOINT
GO

ALTER DATABASE $dbName
MODIFY FILE
	(NAME = $dataName,
	FILEGROWTH = 32MB)
GO

ALTER DATABASE $dbName
MODIFY FILE
	(NAME = $logName,
	FILEGROWTH = 32MB)
GO

EOT

$gnumOfTempdbFiles -= 1;

# Build Alter Database ADD files sql in the while loop 
# to add new files to tempdb.  
#

$i = 2;
while ($gnumOfTempdbFiles > 0 ) {
	$sqlLine= "";
	$fileName = "";
	$deviceName = "";

	$deviceName = sprintf("%s%02d", "tempdb_00_", $i);
	$fileName = sprintf("%s%02d%s", "tempdb_00_", $i, ".ndf");

	# Alter tempdb database to add more files
	#
	$sqlLine = "if not exists (select 1 from tempdb..sysfiles where name = '$deviceName')\n";
	$sqlLine = $sqlLine . "begin\n";
	$sqlLine = $sqlLine . "	ALTER DATABASE $dbName\n";
	$sqlLine = $sqlLine . "	ADD FILE\n";
	$sqlLine = $sqlLine . "		(NAME = $deviceName,\n";
	$sqlLine = $sqlLine . "		FILENAME = '" . $path . $fileName . "',\n";
	$sqlLine = $sqlLine . "		SIZE = $dataSize,\n";
	$sqlLine = $sqlLine . "		FILEGROWTH = 32MB)\n";
	$sqlLine = $sqlLine . "end\n";
	$sqlLine = $sqlLine . "else if (select size from tempdb..sysfiles where name = '$deviceName') < $dataSize/8*1024\n";
	$sqlLine = $sqlLine . "begin\n";
	$sqlLine = $sqlLine . "	ALTER DATABASE $dbName\n";
	$sqlLine = $sqlLine . "	MODIFY FILE\n";
	$sqlLine = $sqlLine . "		(NAME = $deviceName,\n";
	$sqlLine = $sqlLine . "		SIZE = $dataSize,\n";
	$sqlLine = $sqlLine . "		FILEGROWTH = 32MB)\n";
	$sqlLine = $sqlLine . "end\n";
	print MASTER $sqlLine;
	print MASTER "GO\n";

	$i++;
	$gnumOfTempdbFiles--;
}

} ####################### if (defined($gSystemDb{'tempdb'}) #######################

print MASTER <<"EOT";

use master
GO

/* Set all of the system parameters (Optimize the database) */
PRINT ''
PRINT 'Turn Advanced Server Options On'
go
EXEC sp_configure 'show advanced options', 1
go
reconfigure
go

EOT

# Set minimum memory for SQL Server
#
if ($gminSwitch != 0 ) {
print MASTER <<"EOT";

PRINT ''
PRINT 'Configuring $gConfigValues{SQLMinMemory} megabytes of minimum server memory'
go
EXEC sp_configure 'min server memory', $gConfigValues{SQLMinMemory}
go
reconfigure
go
EOT
}

# Set maximum memory for SQL Server
#
if ($gmaxSwitch != 0 ) {
	print MASTER <<"EOT";

PRINT ''
PRINT 'Configuring $gConfigValues{SQLMaxMemory} megabytes of Maximum server memory'
go
EXEC sp_configure 'max server memory', $gConfigValues{SQLMaxMemory}
go
reconfigure
go
EOT
}

# AWE enabled
#
if ($gaweSwitch != 0 ) {
	print MASTER <<"EOT";

PRINT ''
PRINT 'Configuring AWE enable'
go
EXEC sp_configure 'awe enabled', 1
go
reconfigure
go
sp_configure 'set working set size', 0
go
reconfigure
go
EOT
}

	my $instPrtNum = 0;
	
	if ( $gConfigValues{SQLInstanceName}) {
		$instPrtNum = &getInstPortNum();
		if ($instPrtNum == 0 ) {
			&T38lib::Common::warnme("sub getInstPortNum Can not find a free port: $instPrtNum");
			$gNWarnings++;
		}
	}

	if ($instPrtNum) {	
		print MASTER <<"EOT";
PRINT ''
PRINT 'Set port number for named instances ...'
PRINT ''

declare \@port varchar(256)

exec xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\\Microsoft\\MSSQLServer\\MSSQLServer\\SuperSocketNetLib\\Tcp\\IPAll', N'TcpPort', \@port output , 'no_output'

if (\@port is NULL)
begin
	RAISERROR ('Set SQL Server port number to %s', 10, 1, '$instPrtNum')
	exec xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\\Microsoft\\MSSQLServer\\MSSQLServer\\SuperSocketNetLib\\Tcp\\IPAll', N'TcpPort', REG_SZ, N'$instPrtNum'
end
GO
EOT
		} # if $instPrtNum

		# Allow xp_cmdshell to run
		print MASTER <<"EOT";
PRINT ''
PRINT 'Allow xp_cmdshell to run'
PRINT ''
EXEC sp_configure 'xp_cmdshell',1
GO
reconfigure
GO

PRINT ''
PRINT 'Allowing remote admin connections ...'
PRINT ''
EXEC sp_configure 'remote admin connections', 1
GO
RECONFIGURE
GO

EOT


	# Set backup compression.

	if ( (defined($gConfigValues{'BKPCompressSysDefault'}) ) and (uc($gConfigValues{'BKPCompressSysDefault'}) eq 'Y') ) {
	print MASTER <<"EOT";
PRINT ''
PRINT 'Set default backup compression'
PRINT ''
exec sp_configure 'backup compression default', 1
reconfigure
GO
EOT
	} # set backup compressions

	print MASTER <<"EOT";
PRINT ''
PRINT 'Optimizing the database ...'
PRINT ''
EXEC sp_configure 'remote access', 1
go
reconfigure
go



PRINT ''
PRINT 'Dumping database master to master_db_bkp'
BACKUP DATABASE master TO master_db_bkp with init
GO

PRINT ''
PRINT 'MASTER DATABASE SCRIPT COMPLETE'
PRINT ''
GO
EOT
	close (MASTER);

	&notifyWSub("DONE - Build Master Database");
	return(1);

} # end sub buildMaster


#------------------------------------------------------------------------------
# Purpose: Build UserDB
#------------------------------------------------------------------------------
sub buildUserDb() {

	my $dbcrszbase	= DBCRSZNAME;
	my $dbcrsz	= "${gScriptPath}INSTALLWRK\\$dbcrszbase";
	my ($dbcid,$dbid,$mdfpath,$ndfpath,$ldfpath, $typedb, $DBCreator, $DBApp, $DBDesc);
	my ($brand) = "Null";
	my ($szdb,$szlog,$phydmp,$dbName,$truncLog,$selectInto);
	my (@DbNames) = ();


	&notifyWSub("START - Build user Database");
	
	system("cmd /C del $dbcrsz.old") if (-s "$dbcrsz.old");
	system("cmd /C rename $dbcrsz.sql $dbcrszbase.old") if (-s "$dbcrsz.sql");

	unless (open(DBCRSZ,">$dbcrsz.sql")) { 
		&errme("Cannot open file $dbcrsz.sql for writing. $!"); 
		return(0);
	}

    if ( (defined($gConfigValues{'NumofdbFiles'}) ) and ($gConfigValues{'NumofdbFiles'} > 0) ) {
		$gnumOfdbFiles = $gConfigValues{'NumofdbFiles'};
	}
	else {
		$gnumOfdbFiles = $gnumOfCPU/2;
		$gnumOfdbFiles = sprintf("%.0f", $gnumOfdbFiles);
	}
print DBCRSZ <<"EOT";
/*********************************************************************************/
/* CREATE USER DATABASES SCRIPT:  $dbcrsz.sql                                    */
/* BEST BUY CO, INC.                                                             */
/*-------------------------------------------------------------------------------*/
/* This file is created by $0, $gPgmRevision */
EOT

	if (defined ($gConfigValues{"T38LIST:$gincludeCfgParm"}) ) {
		push (@DbNames, @{$gConfigValues{"T38LIST:$gincludeCfgParm"}});
	}

	foreach $dbName (@DbNames) {
		if ( $dbName =~ m/^(\S{3})D(B|R|X)(\d{3})(\S{3})$/ ) {
			$dbcid=$1;
			$dbcid =~ tr/A-Z/a-z/;		# make the dbcid string all lower case
			$typedb = $2;
			$dbid = $3;
			$brand = $4;
		}
		elsif ( $dbName =~ m/^(\S{3})D(B|R|X)(\d{3})$/ ) {
			$dbcid=$1;
			$dbcid =~ tr/A-Z/a-z/;		# make the dbcid string all lower case
			$typedb = $2;
			$dbid = $3;
		}
		else {
				print "Error\n";
		}

     	$szdb 		= $gConfigValues{"USERDB:DataSize:$dbName"};
		$szlog 		= $gConfigValues{"USERDB:LogSize:$dbName"};
		$truncLog   = $gConfigValues{"USERDB:TruncLog:$dbName"};
		$selectInto = $gConfigValues{"USERDB:SelectInto:$dbName"};
		$DBCreator	= $gConfigValues{"USERDB:DBCreator:$dbName"};
		$DBApp		=  $gConfigValues{"USERDB:AppName:$dbName"};
		$DBDesc		=  $gConfigValues{"USERDB:DBDesc:$dbName"};

		$mdfpath="$gConfigValues{MdfDrive}:$gConfigValues{MdfPath}\\";
		$ndfpath="$gConfigValues{NdfDrive}:$gConfigValues{NdfPath}\\";
		$ldfpath="$gConfigValues{LdfDrive}:$gConfigValues{LdfPath}\\";
		$phydmp="$gConfigValues{DumpDevicesDrive}:$gConfigValues{DumpDevicesPath}\\";

		$truncLog	= 
			($truncLog eq "\$none") ?
				$truncLog:
			($truncLog == 1) ?
				"true" :
				"false";
		$selectInto	= 
			($selectInto eq "\$none") ?
				$selectInto:
			($selectInto == 1) ?
				"true" :
				"false";

print DBCRSZ "use master\n";
print DBCRSZ "GO\n";

print DBCRSZ "print ''\n";
print DBCRSZ "print 'SA is creating database for $dbName.  This will take awhile...'\n";
print DBCRSZ "GO\n";

print DBCRSZ "EXEC sp_T38CRDB\n";
print DBCRSZ "	\@dbcid='$dbcid',\n";
print DBCRSZ "	\@dbid=$dbid,\n";
print DBCRSZ "	\@mdfpath='$mdfpath',\n"; 
print DBCRSZ "	\@ndfpath='$ndfpath',\n"; 
print DBCRSZ "	\@ldfpath='$ldfpath',\n"; 
print DBCRSZ "	\@szdb=$szdb,\n"; 
print DBCRSZ "	\@szlog=$szlog,\n"; 
print DBCRSZ "	\@phydmp='$phydmp',\n";
print DBCRSZ "  \@backupsets = 1,\n";
print DBCRSZ "  \@ndffiles = $gnumOfdbFiles,\n";
print DBCRSZ "  \@typedb = '$typedb',\n";
print DBCRSZ "  \@brand = $brand,\n";
print DBCRSZ "  \@DBcreator = '$DBCreator',\n";
print DBCRSZ "  \@DBapp = '$DBApp',\n";
print DBCRSZ "  \@DBdesc = '$DBDesc'\n";
print DBCRSZ "GO\n";

print DBCRSZ "print ''\n";
if ($truncLog ne "\$none") {
	print DBCRSZ "print 'Changing the logger options for $dbName databases.'\n";
	print DBCRSZ "GO\n";

	print DBCRSZ "EXEC sp_dboption $dbName, 'trunc. log on chkpt.', $truncLog\n";
	print DBCRSZ "GO\n";
}

if ($selectInto ne "\$none") {
	print DBCRSZ "print 'Changing the bulkcopy options for $dbName databases.'\n";
	print DBCRSZ "GO\n";
	print DBCRSZ "EXEC sp_dboption $dbName, 'select into/bulkcopy', $selectInto\n";
	print DBCRSZ "GO\n";
}

print DBCRSZ "USE $dbName\n";
print DBCRSZ "GO\n";

print DBCRSZ "CHECKPOINT\n";
print DBCRSZ "GO\n";

	} # end of foreach loop

close (DBCRSZ);

	&notifyWSub("DONE - Build user Database");
	return(1);

} # end sub buildUserDb


# ----------------------------------------------------------------------
#	buildSetup		Build the setup.iss file
# ----------------------------------------------------------------------
#	arguments:
#		setupTpl	template file name
#		setupIss	output file name
#	return:
#		none
# ----------------------------------------------------------------------
#	Build the setup.iss file and replace variables with values
#	from cfg files
# ----------------------------------------------------------------------

sub buildSetup($$) {
	my ($setupTpl, $setupIss) = @_;
	my $status	= 1;
	my ($tmpStatus, $var, $instPrtNum);

SUB:
{
	$setupTpl = "${gScriptPath}install\\" . $setupTpl;
	$setupIss = "${gScriptPath}INSTALLWRK\\" . $setupIss;

	&T38lib::Common::notifyWSub("START - Build iss file.");

	$gConfigValues{gIssCollationName} = 
	$gCharSO{$gConfigValues{SortOrder}}{$gConfigValues{CharSet}}{$gConfigValues{CaseSensitive}};

	# if we have an instance name
	#
	if ( $gConfigValues{SQLInstanceName}) {
		$instPrtNum = &getInstPortNum();
		if ($instPrtNum == 0 ) {
			&T38lib::Common::warnme("sub getInstPortNum Can not find a free port: $instPrtNum");
			$gNWarnings++;
		}

		$gConfigValues{gIssInstanceName} = $gConfigValues{SQLInstanceName};
		$gConfigValues{gIssTCPPort}	= $instPrtNum;
		$gConfigValues{gIssPipeName} = "pipe\\MSSQL\$$gConfigValues{SQLInstanceName}";
	}
	else { 
		$gConfigValues{gIssInstanceName} = "MSSQLSERVER";
		$gConfigValues{gIssTCPPort}	     = 1433;
		$gConfigValues{gIssPipeName}	 = "pipe";
	}

	&T38lib::Common::notifyWSub ("preparing to build the $setupIss file at ${gScriptPath}install directory");

	unless (open(SETUP,">$setupIss")) {
		&T38lib::Common::errme("Cannot open file $setupIss for writing. $!."); 
		$status = 0; last SUB;
	}
	unless (open(SETUPTPL,"<$setupTpl")) { 
		&T38lib::Common::errme("Cannot open file $setupTpl for reading. $!."); 
		$status = 0; last SUB;
	}

	while (<SETUPTPL>) {
		foreach $var (/\$\{([^\s\}]+)\}/g) {
			if (defined($gConfigValues{$var})) { 
				s/\$\{$var\}/$gConfigValues{$var}/; 
			}
			else {
				s/\$\{(\S+)\}/#UNDEFINED#/; 
				&T38lib::Common::warnme("Variable gConfigValues{$var} is undefined in cfg file for $setupTpl.");
				$gNWarnings++;
			}
		}
		print SETUP;
	}


	&notifyWSub ("new $setupIss file is created at ${gScriptPath}INSTALLWRK directory");
	last SUB;
}	# SUB
# ExitPoint:
	close (SETUP);
	close (SETUPTPL);

	&notifyWSub("Done. Status: $status.");
	return($status);
} # end sub buildSetup

#Hemanth:
# ----------------------------------------------------------------------
#	generateTempSaPwd		generate temporary sa password to be used 
#							with the installation process.
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		password string
# ----------------------------------------------------------------------
#	generate temporary password
# ----------------------------------------------------------------------
sub generateTempSaPwd(){
	
	my @charsUpper = ("A".."Z");
	my @charsLower = ("a".."z");
	my @charsDigs = (0..9);
	my @charsOther = split(",", "\!,\@,\#,\$,\%,\^,\&,\_,\*,\-");
	my @chars = ();
	push @chars, (@charsUpper, @charsLower, @charsDigs);
	my ($password, $tpassword) ;
	my $matchFound = 0;
	
	&T38lib::Common::notifyWSub ("generating temp sa password: STARTED");
	#rand only works on integers so when we pass it an array, it 
	#does random selection of an element from an array (just
	#the index number). We use map to generate eight random indices 
	#into @chars, extract the corresponding characters with
	#a slice, and join them together to form the random password
	$password = join("", @chars[map{rand @chars}(1..16)]);

	#First check is to verify if the password starts with an 
	#alphabet (any alphabet) just to avoid problems if we plan to 
	#use this on a non-windows system. We use POSIX style character 
	#class names like [:alpha:],[:upper:] to make our life easier

	unless ($password =~ /^[[:alpha:]]/) {
		$password = $charsLower[rand @charsLower] . $password;
	}
	unless ($password =~ /[[:upper:]]/) {
		$password .= $charsUpper[rand @charsUpper];
	}
	unless ($password =~ /[[:digit:]]/) {
		$password .= $charsDigs[rand @charsDigs];
	}
	while($password !~ /[!@\#\$%\^&\*\_\-]{2}/) {
		$password .= $charsOther[rand @charsOther];
	}
	return($password);
}


# ----------------------------------------------------------------------
#	getClusSQLNodes	get list of nodes for SQL Server resource
# ----------------------------------------------------------------------
#	arguments:
#		$vsName	virtual resource group name for SQL Server
#		$rNodes	reference to array with nodes
#	return:
#		1			Success
#		0			Failure
# ----------------------------------------------------------------------
#	Get list of nodes for SQL Server resource.
# ----------------------------------------------------------------------

sub getClusSQLNodes ($$) {
	my ($vsName, $rNodes)	= @_;
	my $resName		= '';
	my $sqlResName	= '';
	my $resPatt		= '';
	my $resType		= '';
	my @resList		= ();
	my $clusterName	= 0;
	my $cmd			= '';
	my $cmdout		= '';
	my @clusOut		= ();	# Results of the cluster command.
	my $i			= 0;
	my $status		= 1;
SUB:
{
	&notifyWSub("Started. Resource Group is $vsName.");

	unless( $clusterName = &getWinClusterName($vsName)) {
		&errme("Cannot get Cluster Name for virtual server $vsName.");
		$status = 0; last SUB;
	}
	unless ($clusterName = &getWinClusterRes ($vsName, \@resList, $clusterName) ) {
		&errme("Cannot get list of resources for virtual server $vsName on '$clusterName' cluster.");
		$status = 0; last SUB;
	}

	# Looking for SQL Server resource.
	#
	# SQL Server (TSQ9)    RVT1DB1              RST1DB2         Online       #

	$resType = '';
	foreach $resName (@resList) {
		$resPatt = &escapeREChar($resName);
		# Check resource type.
		$cmd = "cluster $clusterName resource \"$resName\" /prop";
		$cmdout = `$cmd`;
		&notifyWSub ("cmd = $cmd");
		&notifyWSub ("cmdout = $cmdout");
	   
		# S  SQL Server (TSQ9)    Type                           SQL Server
		if ($cmdout =~ /S\s+$resPatt\s+Type\s+(.+)\s+\n/i) {
			$resType = $1;
		} else {
			&errme("Cannot find type record for resource $resName.");
			$status = 0; last SUB;
		}

		if (lc($resType) eq 'sql server') {
			# Exit the loop.
			$sqlResName = $resName;
			last;
		} else {
			# This is not a SQL resource. Clear out type.
			$resType 	= '';
			$sqlResName = '';
		}
	} # foreach $resName


	if (!$sqlResName || (lc($resType) ne 'sql server')) {
		&errme("Cannot find SQL Server resource for $vsName group");
		$status = 0; last SUB;
	}

	# Get list of physical nodes.
	
	$cmd = "cmd.exe /C CLUSTER $clusterName resource \"$sqlResName\" /listowners";
	&notifyWSub("$cmd");
	@clusOut = `$cmd`;


	# Output for preferred nodes is:
	#
	# Listing possible owners for resource 'SQL Server (SX01DBA03)':
	# Possible Owner Nodes
	# --------------------
	# LST01DB02
	# LST01DB01

	&notifyMe ("\n" . join('', @clusOut));
	unless (
		$clusOut[1] =~ /^Listing possible owners for resource \'$resPatt\':/i &&
		$clusOut[2] =~ /^Possible Owner Nodes/i &&
		$clusOut[3] =~ /^\-+/i
	) {
		&errme("There is problem with parsing output of the cluster command to get list of possible owners for $resName.");
		$status = 0; last SUB;
	}
	for $i (4..$#clusOut) {
		$clusOut[$i] = &T38lib::Common::stripWhitespace($clusOut[$i]);
		push @{$rNodes}, $clusOut[$i];
	}

}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# getClusSQLNodes


# ----------------------------------------------------------------------
#	getNode4VClusterRsrcGrp		get node name resource group in windows cluster
# ----------------------------------------------------------------------
#	arguments:
#		$rsGroupName	windows cluster name
#	return:
#		nodeName	Success
#		0			Failure
# ----------------------------------------------------------------------
#	get node names for windows cluster
# ----------------------------------------------------------------------

sub getNode4VClusterRsrcGrp ($$) {
	my ($rsGroupName) = @_;
	my @clusOut	= ();
	my $clusterName	='';
	my $machine	= '';
	my $i;
	my $status	= 1;
SUB:
{
	&notifyWSub("Started. Cluster Resource Group Name: $rsGroupName");

	# This sub will be called before VIP address is created
	# for the virtual server. So we can't get a cluster name
	# since we cannot connect to virtual IP.
	# Try to extract cluster name from resource group name.

	($clusterName = $rsGroupName) =~ s/\d+$//g;

	# Get list of physical nodes for target machines.
	
	@clusOut = `cmd.exe /C CLUSTER $clusterName group $rsGroupName`;


	# Output for preferred nodes is:
	#
	# /.../Install>cluster rvt1db group rvt1db1
	# Listing status for resource group 'rvt1db1':
	#
	# Group                Node            Status
	# -------------------- --------------- ------
	# rvt1db1              RST1DB1         Online 
	#  

	# Remove blank lines from @clusOut.

	for ($i = 0; $i < scalar @clusOut;) {
		( $clusOut[$i] =~ /^\s*$/) ? splice (@clusOut, $i, 1) : $i++;
	}

	&notifyMe ("\n" . join('', @clusOut));
	unless (
		$clusOut[0] =~ /^Listing status for resource group .$rsGroupName./i &&
		$clusOut[1] =~ /^Group +Node +Status/i &&
		$clusOut[2] =~ /^\-+/i
	) {
		&errme("There is problem with parsing output of the cluster command to get list of nodes for virtual server $clusterName.");
		$status = 0; last SUB;
	}
	$clusOut[3] =~ /^$rsGroupName\s+(\S+)\s+/i;
	$machine = $1;
	if ($machine !~/^\S+$/) {
		&errme("Problem with parsing machine name: $clusOut[3].");
		last SUB;
	}
	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($machine);
}	# getNode4VClusterRsrcGrp


# ----------------------------------------------------------------------
#	getInstallerPwd		get password for installer account
# ----------------------------------------------------------------------
#	arguments:
#		$rpasswd	reference to password string
#		$raccnt		reference to account string
#	return:
#		1		Success
#		0		Failure
# ----------------------------------------------------------------------
#	get password for installer account
# ----------------------------------------------------------------------

sub getInstallerPwd ($$) {
	my $rpasswd	= shift;
	my $raccnt	= shift;
	my $status	= 1;
	my $instlservicecode	= '';
	my $sql		= '';
	my $adocmd	= 0;		# ADO Command object handle
	my @rs		= ();		# record set
	my $key = '';
	my $envCode	= 'NP';
	my $secGrpLoc	= 'CORP';
SUB:
{
	&notifyWSub("Started.");


	$key = "SecurityGroupLocationDesc_" . $gConfigValues{SecurityGroupLocation};
	$secGrpLoc = $gConfigValues{$key};
	$key = "Environment2ChrCode_" . $gConfigValues{EnvironmentType};
	$envCode = $gConfigValues{$key};

	unless ($secGrpLoc && $envCode) {
		&errme("Configuration parameter file is invalid. Check SecurityGroupLocationDesc_x and Environment2ChrCode_x parameters.");
		$status = 0; last SUB;
	}

	# Installer service name is similar to CORPSQLNPSL1INST
	$instlservicecode = $secGrpLoc . "SQL" . $envCode . "SL" . $gConfigValues{SecurityDataSensitivity} . "INST";

	$sql = "exec T38GETACCOUNT \@serviceName = '$instlservicecode'";

	unless ($adocmd = adoConnect($gConfigValues{SQLInstallPwdSrvr}, $gConfigValues{SQLInstallPwdDB}, 0, 1)) { 
		&errme("adoConnect($gConfigValues{SQLInstallPwdSrvr}) Failed to establish secured connection.");
		$status = 0; last SUB;
	}

	unless (&execSQL2Arr($adocmd, $sql, \@rs))  { $status = 0; last SUB; }
	unless(defined($rs[0])) {
		&errme("Cannot get password for $instlservicecode from $gConfigValues{SQLInstallPwdSrvr}.$gConfigValues{SQLInstallPwdDB}");
		$status = 0; last SUB;
	}

	$$rpasswd	= &T38lib::Common::stripWhitespace($rs[0]{''});
	$$raccnt	= &T38lib::Common::stripWhitespace($rs[0]{'ACCOUNT'});
	@rs = ();

	last SUB;
}	# SUB
# ExitPoint:
	if ($adocmd) { $adocmd->Close(); $adocmd = 0; }
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# getInstallerPwd


#------------------------------------------------------------------------------
#	Purpose: Get the port number for the instance
#
#	Input:	None
#	Output:	Default port number which is 63519 if no instance is found
#	        else give the port number that is not being used by any installed
#	        instance(s)
#
#	        0 Failure
#------------------------------------------------------------------------------
sub getInstPortNum() {

	my %instList = ();
	my %portList = ();
	my ($key, $value, $portNum);
	my $vSrvrSeqNo	= 0;
	my $startPortNum = 63518;
	my $instPortNum = $startPortNum;
	# my $instPortNum = "63518";

	# Get all the instances in the server where we are installing an instance
	#

	&T38lib::Common::notifyWSub("START - Get port number for instance");

	if ($gConfigValues{SQLVirtualName} 
		and $gConfigValues{SQLVirtualName} =~/(\d+)$/
		and $1 < 17) {
		# We are installing on a cluster and we have valid server sequence numbers.
		$vSrvrSeqNo = $1;
		$instPortNum = $startPortNum + $vSrvrSeqNo - 1;
	}

	if (&T38lib::Common::pingServer($gNetNodeName) != 0) {
		# We can't get to the registry for the server. It could be Virtual SQL Server
		# that we did not install yet, so there is no VIP.
		# For now assume port 63518.

		&notifyWSub("Done. Instance port number: $instPortNum");
		return($instPortNum);
	}

	&T38lib::Common::getSQLInstLst(\%instList, $gNetNodeName);

	# If hash has an instance then we have to get the port number and find a free
	# one from the range of 63518 - 63534 prot numbers
	#
	if (defined (%instList) ) {
		while (($key,$value) = each(%instList)) {
			# Ignore the default instance
			if ($key =~ /MSSQLServer/i ) {
				delete $instList{$key};
			}
			else {
				$portNum = &T38lib::Common::getSqlPort($gNetNodeName,$key);
				$portList{$portNum} = $key;
			}
		}

		# For debugging, uncomment this three lines
		#	while (($key,$value) = each(%portList)) {
		#	print "**$key = $value**\n";
		#}

		# First check if port we would like to use is available.

		if (!defined ($portList{$instPortNum}) ) {
			# Port is not in use.
			return($instPortNum);
		} elsif (uc($portList{$instPortNum}) eq uc($gConfigValues{SQLInstanceName}) ) {
			# Port is in use, but it is same instance as we need to use.
			# This should be our port.
			return($instPortNum);
		}

		# Port we need is already in use. Find first available.

		$instPortNum = $startPortNum;

		# Check to see what port is used by the instance and keep
		# going through the range to find a free one
		#
		while ( defined ($portList{$instPortNum}) ) {
			$instPortNum++;
		}

		# If we cross our upper limit of port number then assign the port
		# number to 0 which mean we fail to find a free port
		$instPortNum = 0 if ($instPortNum > 63534); 

	}

	&notifyWSub("Done. Instance port number: $instPortNum");

	# Return the result	
	#
	return($instPortNum);
	
} # end sub getInstPortNum


# ----------------------------------------------------------------------
#	getSAPwd		get sa password
# ----------------------------------------------------------------------
#	arguments:
#		$rpasswd	reference to password string
#	return:
#		1		Success
#		0		Failure
# ----------------------------------------------------------------------
#	get sa password
# ----------------------------------------------------------------------

sub getSAPwd ($) {
	my $rpasswd	= shift;
	my $status	= 1;
	my $serviceName			= '';
	my $sql		= '';
	my $adocmd	= 0;		# ADO Command object handle
	my @rs		= ();		# record set
	my $key		= '';
SUB:
{
	&notifyWSub("Started.");

	# Service name looks like "sa:CORPSQLINSTALLER"
	$key = "SecurityGroupLocationDesc_" . $gConfigValues{SecurityGroupLocation};
	$serviceName = "sa:" . $gConfigValues{$key} . "SQLINSTALLER";
	$sql = "exec T38GETACCOUNT \@serviceName = '$serviceName'";

	unless ($adocmd = adoConnect($gConfigValues{SQLInstallPwdSrvr}, $gConfigValues{SQLInstallPwdDB}, 0, 1)) { 
		&errme("adoConnect($gConfigValues{SQLInstallPwdSrvr}) Failed to establish secured connection.");
		$status = 0; last SUB;
	}

	unless (&execSQL2Arr($adocmd, $sql, \@rs))  { $status = 0; last SUB; }
	unless(defined($rs[0])) {
		&errme("Cannot get password for $serviceName from $gConfigValues{SQLInstallPwdSrvr}.$gConfigValues{SQLInstallPwdDB}");
		$status = 0; last SUB;
	}

	$$rpasswd	= &T38lib::Common::stripWhitespace($rs[0]{''});
	@rs = ();

	last SUB;
}	# SUB
# ExitPoint:
	if ($adocmd) { $adocmd->Close(); $adocmd = 0; }
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# getSAPwd

# ----------------------------------------------------------------------
#	getSQLInstallSetupExe100		Get SQL Server installation setup.exe path
# ----------------------------------------------------------------------
#	arguments:
#		$rsetupPath	reference to variable with path to SQL Server setup directory
#		$rsetupExe	reference to variable with full name of the SQL Server setup.exe program
#		$rinstCUFlg	reference to install CU flag
#	return:
#		path	Success
#		0		Failure
# ----------------------------------------------------------------------
# 	This subroutine returns path to SQL Server installation setup.exe
# ----------------------------------------------------------------------
sub getSQLInstallSetupExe100($$) {
	my $rsetupPath		= shift;
	my $rsetupExe		= shift;
	my $rinstCUFlg		= shift;
	my $setupDirName	= '.\\';			# Default T38 Directory name for SQL Install
	my $setupPath		= $setupDirName;	;# Actual Path to SQL Server install Program
	my $setupExe		= 'setup.exe';
	my $installCUFlg	= 0;
	my $sqlSPVer		= '1600';
	my $status			= 1;
SUB:
{
	&notifyWSub("START - Get SQL 2008 Installation CD Path");
	# Configure Setup directory.
	# BBY Standard directories for SQL Server 2005 CD Images is based on
	# SQL Server edition.
	#
	#	\\cs01corp\Root\Apps\Corp\IS\Dept\apps\sqldba\SQL2008
	#								\SQL08CDProd
	#											\SQL2008_ent
	#											\SQL2000_std

	$setupDirName = ($gConfigValues{SQLSrvrEdition} =~ /enterprise/) ? 
		"SQL2008_ent" : "SQL2008_std";

	if ($gConfigValues{SQLServiceVersion} ne $gConfigValues{SPVersion}) {
		# Get slipstream install path.
		if ($gConfigValues{SPVersion} =~ /10\.0\.(\d+)\./) {
			$sqlSPVer = $1;
		} else {
			&errme ("Invalid SPVersion parameter in configuration file ($gConfigValues{SPVersion})");
			$status = 0;
			$setupPath = 0;
			$setupExe = 0;
			last SUB;
		}
		$setupDirName .= "_slipstream" . $sqlSPVer;
	}
	
	$setupDirName = "SQL2008\\SQL08CDProd\\$setupDirName"; 
	if ( -s "$gConfigValues{SQLInstallPath}\\$setupDirName\\$setupExe") {
		# Setup program found in SQL Server CD Image which is located in BBY standard sub-directory,
		# defined in configuration file.
		$setupPath = "$gConfigValues{SQLInstallPath}\\$setupDirName\\";
	} 
	elsif ( -s "$gConfigValues{SQLInstallPath}\\$setupExe") {
		# Use SQL Server CD Image, located in directory defined in configuration file.
		$setupPath = "$gConfigValues{SQLInstallPath}\\";
	} else {
		&errme ("Can not find file $setupExe. Was trying in \"$gConfigValues{SQLInstallPath}\" and \"$gConfigValues{SQLInstallPath}\\$setupDirName\"");
		$status = 0;
		$setupPath = 0;
		$setupExe = 0;
		last SUB;
	}

	# If CU folder exists, we are installing Cumulative Update. Set the flag.

	if ( -s "$setupPath\\CU\\$setupExe" ) {
		$installCUFlg = 1;
	}


	$setupExe = $setupPath . $setupExe;

	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	if ($status) {
		$$rsetupPath = $setupPath;
		$$rsetupExe = $setupExe;
		$$rinstCUFlg = $installCUFlg;
	}
	return($status);
}	# getSQLInstallSetupExe100



# ----------------------------------------------------------------------
#	buildSharePoints		Build share points
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
sub buildSharePoints() {

	use Win32::NetResource;

	my $status		= 1;
	my ($shareInfo, $tmp, $parm, $result, $key);
	my $shareName	= '';
	my $osVer = 0;
SUB:
{
	&notifyWSub("START - Build Share points");
	$osVer = getSysVerReg(); #Returns OS Version (Success); 0 (Failure);
	if($osVer > 0 && $osVer < 6){ #Anything below Windows 2008.
		if ( $gConfigValues{SQLVirtualName}) {
			$status = buildSharePointsClus();
			last SUB;
		}
	}elsif($osVer >= 6){
		if ($gConfigValues{SQLVirtualName}){
			$status = buildSharePointsClusW2k8();
			last SUB;
		}
	}
	
	# Delete share points, Just to make sure that these share point are not there.
	# if they are there, delete them

	foreach $key ((
			'DumpDevices',		# Database and T-Log Backups
			'Mdf',				# System and user data
			'Ndf', 				# Optional user data contained in databases
			'Ldf',				# Database Transection log
			'Trc',				# SQL Trace file
			'Tmp',				# Temporary Work File
			'SQLDataRoot',		# Master and Other System Databases Live
			'SQLApp',			# SQL Server Binaries
			'DBAUtils'			# DBA Maintenance Scripts
		)) {

		$shareName	= $gConfigValues{'__SharePoint' . $key . 'Path'};

		$tmp = "$gConfigValues{$key . 'Drive'}";
		$tmp = $tmp . ":";
		$tmp = $tmp . "$gConfigValues{'share' . $key . 'Path'}";

		$shareInfo = {
			'path' => "$tmp",
			'netname' => "$shareName",
			'remark' => "Shared by $gScriptName",
		};

		Win32::NetResource::NetShareDel($shareName, $gNetName);
		if ( Win32::NetResource::NetShareAdd($shareInfo, $parm, $gNetName) ) {
			&notifyWSub("Successfully created shared $shareName on $gNetName.");
		} 
		else {
			&errme("Problem with share $shareName for $gNetName");
			$status = 0;
		}
		$tmp = "rmtshare ";
		$tmp = $tmp . "\\\\";
		$tmp = $tmp . "$gNetName";
		$tmp = $tmp . "\\";
		$tmp = $tmp . "$shareName";
		$tmp = $tmp . " /UNLIMITED";
		$tmp = $tmp . " /GRANT";
		$tmp = $tmp . " Administrators:f";
		$tmp = $tmp . " /REMOVE";
		$tmp = $tmp . " EVERYONE";
	
		&notifyWSub("Modify permission to share point $shareName");
		$result = system("cmd /C $tmp");
		if ( $result != 0 ) {
			&errme("Can not modify permission to $shareName");
			$status = 0;
		}
	}

	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# buildSharePoints

# ---------------------------------------------------------------------------------------
#	build2k8SharePointsClus	Build file share resource for Virtual Server in Windows 2008
# ---------------------------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
sub buildSharePointsClusW2k8() {
	my $status			= 1;
	my ($result, $key)	= 0;
	my $clusterName		= 0;
	my $vsName			= $gConfigValues{SQLVirtualName};	# Virtual Server name.
	my $resResult		= 0;	# Results from cluster res command.
	my $shareName		= '';
	my $fsShareName		= '';
	my $sharePath		= '';
	my $shareUncPath	= '';
	my $driveName		= '';
	my $sqlResNetName	= '';	# SQL Server cluster resource Network Name.
	my $adgrpBase		= '';	# Active Directory group base name, without permission: BBY-R-SQLCORPCLUSTER-T38SYS-FP-.
	my $adgrpNameR		= '';	# Active Directory group name for Read access.
	my $adgrpNameF		= '';	# Active Directory group name for Full access.
	my $adgrpPath		= '';
	my $securityProp	= '';
	my $resDiskName		= '';	# Resource Disk Name.
	my $vmDiskName		= '';	# Veritas Volume Manager Resource Disk Name.
	my $oscmd			= '';
SUB:
{
	&notifyWSub("START - Build File Share resource for Virtual Server $gConfigValues{SQLVirtualName}.");
	unless( $clusterName = &getWinClusterName($vsName)) {
			&errme("Cannot get Cluster Name for virtual server $vsName.");
			$status = 0; last SUB;
		}

	$resResult = `cmd.exe /C CLUSTER $clusterName RESOURCE /prop`;

	# Get SQL Server Cluster resource Network Name. Look for result line
	# T  Resource             		  Name                           Value
	# -- ---------------------------- --------------------- 		 -----------------------
	# S  SQL Network Name(LVT3DB5) 	  Type                           Network Name
	unless ($resResult =~ /\nS\s+(\S+.*\($vsName\))\s+Type\s+Network Name/i) {
		&errme("SQL Server is not installed correctly for Virtual Server $vsName. Missing Network Name resource.");
		$status = 0; last SUB;
	}

	$sqlResNetName = $1;

	unless (&verifyDiskResClus($clusterName, $vsName, \$vmDiskName)) {
		&errme("Verification for Disk Resource failed. Review all disk resource names for $vsName cluster group.");
		$status = 0; last SUB;
	}
	
	
	
	foreach $key ((
				'DumpDevices',		# Database and T-Log Backups
				'Mdf',				# System and user data
				'Ndf', 				# Optional user data contained in databases
				'Ldf',				# Database Transection log
				'Trc',				# SQL Trace file
				'Tmp',				# Temporary Work File
				'SQLDataRoot',		# Master and Other System Databases Live
				# 'SQLApp',			# SQL Server Binaries are not shared disk. Do not create share for now.
				'DBAUtils'			# DBA Maintenance Scripts
			)) {
				
				$shareName	= "$gConfigValues{'__SharePoint' . $key . 'Path'}\.$gConfigValues{SQLVirtualName}"; #t38mdf.DVD34DB07
				$driveName	= $gConfigValues{$key . 'Drive'}; #will be populated from t38dba.cfg. $driveName='M'
				$sharePath	= "$driveName:$gConfigValues{'share' . $key . 'Path'}"; # this should basically come out as 'M:\DBMS\t38mdf'
																					# did not find key by name 'shareMdfPath' in
																					# t38cfgfile.pm or t38dba.cfg. Populate from?
				$adgrpBase	= "BBY-R-SQLCORPCLUSTER-$gConfigValues{'__SharePoint' . $key . 'Path'}-FP-"; #$gConfigValues{'_SharePoint'.$k3y.'Path'} = t38Mdf
				$shareUncPath	= "\\\\$vsName\\$driveName\$$gConfigValues{'share' . $key . 'Path'}"; #\\DVD34DB07\M$\DBMS\t38mdf
				
				#Set the fileserver name according to the convention: FileServer.$resourceGroupName.$diskName. 
				$fsShareName = "FileServer\.$vsName\.Disk\ $driveName:"; #Should come out as FileServer.DVD34DB07.Disk M:
				
				#Validate the ad group names use the base naming convention.
				($adgrpNameF, $adgrpPath) = &verifyADGroupName("${adgrpBase}F");
				unless ($adgrpNameF) {
					&errme("Invalid group name ${adgrpBase}F.");
					$status = 0; last SUB;
				}
				($adgrpNameR, $adgrpPath) = &verifyADGroupName("${adgrpBase}R");
				unless ($adgrpNameR) {
					&errme("Invalid group name ${adgrpBase}R.");
					$status = 0; last SUB;
				}
				
				$resResult = `cmd.exe /C CLUSTER $clusterName RESOURCE /prop`;
				# Check if file server resource is already created. We need to do this inside the loop.
				# T  Resource             		  Name                           Value
				# -- ---------------------------- --------------------- 		 -----------------------
				# S  FileServer.DVD34DB07.Disk M: Type                           File Server
				# --------------------------------------------------------------------------------------
				# Create the File Server share and add dependecies for the disk drive and SQL network name.
				unless($resResult =~ /\nS\s+$fsShareName\s+Type\s+File Server/i) {
					&notifyWSub("Creating resource $fsShareName on $vsName");
					$oscmd = "CLUSTER $clusterName RESOURCE \"$fsShareName\" /Create /Group:$vsName /Type:\"File Server\"";
					unless(&runOSCmd($oscmd)) {
						&errme("Cannot create File Share resource for $fsShareName.");
						$status = 0;
						last SUB;
					}
					
					&notifyWSub("Creating dependency for resource $fsShareName on \"$sqlResNetName\"");
					$oscmd = "CLUSTER $clusterName RESOURCE \"$fsShareName\" /adddep:\"$sqlResNetName\"";
					unless(&runOSCmd($oscmd)) {
						&errme("Cannot create dependency for $fsShareName on \"$sqlResNetName.\"");
						$status = 0;
						last SUB;
					}
					&notifyWSub("Creating dependency for resource $fsShareName on \"Disk $driveName:\"");
					$oscmd = "CLUSTER $clusterName RESOURCE \"$fsShareName\" /adddep:\"Disk $driveName:\"";
					unless(&runOSCmd($oscmd)) {
						&errme("Cannot create dependency for $fsShareName on \(Disk $driveName:\)");
						$status = 0;
						last SUB;
					}
					$oscmd = "CLUSTER $clusterName RESOURCE \"$fsShareName\" /online";
					unless(&runOSCmd($oscmd)) {
						&errme("Cannot bring $fsShareName online in Cluster: $clusterName.");
						$status = 0;
						last SUB;
					}
				}
				
				# The file server is already created, we create the file share resource.
				# The resource type "File Share" is not valid in Win 2008 cluster. So we will use rmtshare
				# to create a file share.
				$oscmd = "rmtshare \\\\$vsName\\$shareName=$sharePath /REMOVE Everyone /GRANT $adgrpNameF:F /GRANT Administrators:F /GRANT $adgrpNameR:R /remark:\"Cluster Share created by t38instl100.pl\"";
				unless(&runOSCmd($oscmd)) {
					&errme("Cannot create File Share for $shareName.");
					$status = 0;
					last SUB;
				}
				
				# Grant NTFS permissions on the share path for the appropriate groups.
				$oscmd = "ICACLS $sharePath /grant:r $adgrpNameF:(CI)(OI)F /T";
				unless(&runOSCmd($oscmd)) {
					&errme("Could not grant permission on $sharePath for $adgrpNameF.");
					$status = 0;
					last SUB;
				}
				$oscmd = "ICACLS $sharePath /grant:r $adgrpNameR:(CI)(OI)R /T";
				unless(&runOSCmd($oscmd)) {
					&errme("Could not grant permission on $sharePath for $adgrpNameR.");
					$status = 0;
					last SUB;
				}
			}
		
	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	#buildSharePointsClusW2k8

# ----------------------------------------------------------------------
#	buildSharePointsClus	Build file share resource for Virtual Server
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
sub buildSharePointsClus() {

	my $status			= 1;
	my ($result, $key)	= 0;
	my $clusterName		= 0;
	my $vsName			= $gConfigValues{SQLVirtualName};	# Virtual Server name.
	my $resResult		= 0;	# Results from cluster res command.
	my $shareName		= '';
	my $sharePath		= '';
	my $shareUncPath	= '';
	my $driveName		= '';
	my $sqlResNetName	= '';	# SQL Server cluster resource Network Name.
	my $adgrpBase		= '';	# Active Directory group base name, without permission: BBY-R-SQLCORPCLUSTER-T38SYS-FP-.
	my $adgrpNameR		= '';	# Active Directory group name for Read access.
	my $adgrpNameF		= '';	# Active Directory group name for Full access.
	my $adgrpPath		= '';
	my $securityProp	= '';
	my $resDiskName		= '';	# Resource Disk Name.
	my $vmDiskName		= '';	# Veritas Volume Manager Resource Disk Name.
	my $oscmd			= '';
	my $osout			= '';
	my $pat				= '';	# match pattern for RE.
SUB:
{
	&notifyWSub("START - Build File Share resource for Virtual Server $gConfigValues{SQLVirtualName}.");

	unless( $clusterName = &getWinClusterName($vsName)) {
		&errme("Cannot get Cluster Name for virtual server $vsName.");
		$status = 0; last SUB;
	}

	$resResult = `cmd.exe /C CLUSTER $clusterName RESOURCE /prop`;


	# Get SQL Server Cluster resource Network Name. Look for result line
	# S  SQL Network Name(LVT3DB5) Type                           Network Name


	unless ($resResult =~ /\nS\s+(\S+.*\($vsName\))\s+Type\s+Network Name/i) {
		&errme("SQL Server is not installed correctly for Virtual Server $vsName. Missing Network Name resource.");
		$status = 0; last SUB;
	}

	$sqlResNetName = $1;

	unless (&verifyDiskResClus($clusterName, $vsName, \$vmDiskName)) {
		&errme("Verification for Disk Resource failed. Review all disk resource names for $vsName cluster group.");
		$status = 0; last SUB;
	}

	foreach $key ((
			'DumpDevices',		# Database and T-Log Backups
			'Mdf',				# System and user data
			'Ndf', 				# Optional user data contained in databases
			'Ldf',				# Database Transection log
			'Trc',				# SQL Trace file
			'Tmp',				# Temporary Work File
			'SQLDataRoot',		# Master and Other System Databases Live
			# 'SQLApp',			# SQL Server Binaries are not shared disk. Do not create share for now.
			'DBAUtils'			# DBA Maintenance Scripts
		)) {

		$shareName	= "$gConfigValues{'__SharePoint' . $key . 'Path'}\.$gConfigValues{SQLVirtualName}";
		$driveName	= $gConfigValues{$key . 'Drive'};
		$sharePath	= "$driveName:$gConfigValues{'share' . $key . 'Path'}";
		$adgrpBase	= "BBY-R-SQLCORPCLUSTER-$gConfigValues{'__SharePoint' . $key . 'Path'}-FP-";
		$shareUncPath	= "\\\\$vsName\\$driveName\$$gConfigValues{'share' . $key . 'Path'}";

		($adgrpNameF, $adgrpPath) = &verifyADGroupName("${adgrpBase}F");
		unless ($adgrpNameF) {
			&errme("Invalid group name ${adgrpBase}F.");
			$status = 0; last SUB;
		}

		($adgrpNameR, $adgrpPath) = &verifyADGroupName("${adgrpBase}R");
		unless ($adgrpNameR) {
			&errme("Invalid group name ${adgrpBase}R.");
			$status = 0; last SUB;
		}

		# Check if file share resource is already created.

		unless ($resResult =~ /\nS\s+$shareName\s+Type\s+File Share/i) {
			$oscmd = "CLUSTER $clusterName RESOURCE $shareName /Create /Group:$vsName /Type:\"File Share\"";
			unless(&runOSCmd($oscmd)) {
				&errme("Cannot create File Share resource for $shareName.");
				$status = 0;
				last SUB;
			}
		}

		unless(&runOSCmd("CLUSTER $clusterName RESOURCE $shareName /PrivProp ShareName=\"$shareName\"")) {
			$status = 0; last SUB;
		}
		unless(&runOSCmd("CLUSTER $clusterName RESOURCE $shareName /PrivProp Path=\"$sharePath\"")) {
			$status = 0; last SUB;
		}
		unless(&runOSCmd("CLUSTER $clusterName RESOURCE $shareName /PrivProp:Maxusers /USEDEFAULT")) {
			$status = 0; last SUB;
		}

		# $securityProp	= "security=$adgrpNameR,grant,R,$adgrpNameF,grant,F,Everyone,revoke:security";
		$securityProp	= "security=Everyone,set,R,Everyone,grant,C:security";
		unless(&runOSCmd("CLUSTER $clusterName RESOURCE $shareName /PrivProp $securityProp")) {
		 	$status = 0; last SUB;
		}

		# Create dependency for share on a disk resource.

		$resDiskName = ($vmDiskName)? $vmDiskName : "Disk $driveName:";
		
		# Before adding dependency on a disk, check if it is already created.
	
		$result = `cmd.exe /C CLUSTER $clusterName RESOURCE $shareName /ListDep`;
		if ($result !~ /\n$resDiskName\s+$vsName\s/i) {
			&notifyWSub("Creating dependency for resource $shareName on $resDiskName");
			unless(&runOSCmd("CLUSTER $clusterName RESOURCE $shareName /AddDependency:\"$resDiskName\"")) {
				$status = 0; last SUB;
			}
		}

		$pat = quotemeta ($sqlResNetName);
		if ($result !~ /\n$pat\s+$vsName\s/i) {
			&notifyWSub("Creating dependency for resource $shareName on $sqlResNetName");
			unless(&runOSCmd("CLUSTER $clusterName RESOURCE $shareName /AddDependency:\"$sqlResNetName\"")) {
				$status = 0; last SUB;
			}
		}

		unless(&runOSCmd("CLUSTER $clusterName RESOURCE $shareName /on")) {
			$status = 0; last SUB;
		}

		# It is recommended by Microsoft to use NTFS permissions on file system instead of the File Share.
		# Set permissions on files in the share path.

		unless(&runOSCmd("xcacls $shareUncPath /e /t /r Everyone /y")) {
			$status = 0; last SUB;
		}
		unless(&runOSCmd("xcacls $shareUncPath /e /t /r Users /y")) {
			$status = 0; last SUB;
		}
		unless(&runOSCmd("xcacls $shareUncPath /e /t /g $adgrpNameR:R /y")) {
			$status = 0; last SUB;
		}
		unless(&runOSCmd("xcacls $shareUncPath /e /t /g $adgrpNameF:F /y")) {
			$status = 0; last SUB;
		}
	}

	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# buildSharePointsClus

#------------------------------------------------------------------------------
#	Purpose: Build directories 
#
#------------------------------------------------------------------------------
sub buildSQLDirs() {
	my $crtDir	="";
	my $key		= "";

	&notifyWSub("START - Building Directories.");

	foreach $key ((
			'DumpDevices',		# Database and T-Log Backups
			'Mdf',				# System and user data
			'Ndf', 				# Optional user data contained in databases
			'Ldf',				# Database Transection log
			'Trc',				# SQL Trace file
			'Tmp',				# Temporary Work File
			'SQLDataRoot',		# Master and Other System Databases Live
			'SQLApp',			# SQL Server Binaries
			'DBAUtils'			# DBA Maintenance Scripts
		)) {
		$crtDir = ( uc($gHostName) eq uc($gNetNodeName) ) ?
			"$gConfigValues{$key . 'Drive'}:$gConfigValues{$key . 'Path'}":
			"\\\\$gNetNodeName\\$gConfigValues{$key . 'Drive'}\$$gConfigValues{$key . 'Path'}";

		&mkdir($crtDir) unless ( -d $crtDir);
	}


	&notifyWSub("DONE  - Building Directories.");

} # end sub buildSQLDirs


#------------------------------------------------------------------------------
# Purpose: Change sa password after the install of SQL Server
#------------------------------------------------------------------------------
sub changeSAPassword() {

	my ($subStatus) = 1;
	my $srvrName	= $gSrvrName;
	my $logFileName	= '';
	my $sql			= '';
	my $cmd			= '';
	my $rs			= 0;
	my $conn		= 0;
	my $srvrColName = '';
	my $cmd2		= 0;
	my $conn2		= 0;
	my $sqlerr2		= 0;
	my $newPass		= '';
	my @rs			= ();
	my $sqlerr	= 0;

	&T38lib::Common::notifyWSub("SUB STARTED");

	SUB: {

		# Get a connection to the password repository server and the use the correct database
		#
		unless ($cmd2 = adoConnect($gConfigValues{SQLInstallPwdSrvr}, $gConfigValues{SQLInstallPwdDB})) {
			&T38lib::Common::errme("Cannot open connection to $gConfigValues{SQLInstallPwdSrvr}");
			$subStatus = 0;
			last SUB;
		}

		unless ( $gConfigValues{SQLPwdDBPassPhrase} ) {
			&errme("Configuration variable SQLPwdDBPassPhrase is not valid.");
			$subStatus = 0;
			last SUB;
		}

		&T38lib::Common::notifyWSub("Processing Server Name: $srvrName");

		# Open ado connection to the server
		#
		unless ($cmd = adoConnect("$srvrName", 'master')) {
			&T38lib::Common::errme("Cannot open connection to  $srvrName");
			&T38lib::Common::notifyWSub("Password NOT Changed for: $srvrName");
			$subStatus = 0;
			next;
			#last SUB;
		}

		$conn = $cmd->{ActiveConnection};
		$sqlerr = $conn->Errors;

		$sql =  
			"DECLARE \@password varchar(64)\n" .
			"DECLARE \@passenc varbinary(148)\n" .
			"DECLARE \@pwdstr varchar(148)\n" .
			"select \@password = newid()\n" .
			"EXEC sp_password NULL, \@password, sa\n";

		$sql = $sql . "select \@passenc = EncryptByPassPhrase(\'$gConfigValues{SQLPwdDBPassPhrase}\', \@password)\n"; 
		$sql = $sql . "exec sp_T38hexadecimal \@passenc, \@pwdstr output\n";
		$sql = $sql . "select \@pwdstr password";
		
		#&T38lib::Common::notifyMe("$sql"); 
		$cmd->{CommandText} = $sql;

		unless ($rs = $cmd->Execute()) { 
			&T38lib::Common::errme("Error in SQL"); 
			&T38lib::Common::notifyMe("\n$sql"); 
			&T38lib::Common::notifyWSub("Password NOT Changed for: $srvrName");
			&showADOErrors($sqlerr); 
			$subStatus = 0; 
			next;
			#last SUB; 
		}

		while($rs && !$rs->EOF) {
			$newPass = $rs->Fields('password')->Value if (defined($rs->Fields('password')));
			$rs->MoveNext;
			$rs = $rs->NextRecordset;
		}

		#&T38lib::Common::notifyWSub("$newPass");

		$sql = "SELECT SERVERPROPERTY('ServerName') as ServerName";

		unless(&execSQL2Arr($cmd, $sql, \@rs)) { $subStatus = 0; last SUB; }
		unless(defined($rs[0])) {
			&errme("Cannot get Server name for $srvrName.");
			&T38lib::Common::notifyWSub("Password NOT Changed for: $srvrName");
			$subStatus = 0; 
			next;
			#last SUB;
		}
		$srvrName = &T38lib::Common::stripWhitespace($rs[0]{ServerName});
		@rs = ();

		&T38lib::Common::notifyWSub("$srvrName -- sa password changed");
		$srvrColName = "sa:".$srvrName;


		# Call sub to update repository here
		#
		$conn2 = $cmd2->{ActiveConnection};
		$sqlerr2 = $conn2->Errors;

		$sql = "EXEC T38UPDINSACCOUNT '$srvrColName', 'SA', $newPass";

		#&T38lib::Common::notifyMe("$sql"); 
		$cmd2->{CommandText} = $sql;

		unless ($cmd2->Execute()) { 
			&T38lib::Common::errme("Error in SQL"); 
			&T38lib::Common::notifyWSub("Password NOT Changed for: $srvrName");
			&T38lib::Common::notifyMe("\n$sql"); 
			&showADOErrors($sqlerr2); 
			$subStatus = 0; 
			last SUB; 
		}

	}	# SUB
	# ExitPoint:

	if ($rs)	{ $rs->Close(); $rs = 0; }			# shut down the recordset
	if ($cmd)	{ $cmd->Close(); $cmd = 0; }
	if ($conn)	{ $conn->Close(); $conn = 0; }		# close the data source

	if ($cmd2)	{ $cmd2->Close(); $cmd2 = 0; }
	if ($conn2)	{ $conn2->Close(); $conn2 = 0; }		# close the data source

					
	&T38lib::Common::notifyWSub("SUB DONE");

	return $subStatus;
} # end sub changeSAPassword


# ----------------------------------------------------------------------
#	checkNodeInVGroup		check if node is preferred owner for the group
# ----------------------------------------------------------------------
#	arguments:
#		$nodeName	node name
#	return:
#		0	Error exit
#		-1	Node is not one of the prefferred owners for the group
#		1	Node is one of the prefferred owners for the group
# ----------------------------------------------------------------------
#	check if node is preferred owner for the SQL cluster group.
# ----------------------------------------------------------------------

sub checkNodeInVGroup ($) {
	my $nodeName	= shift;
	my $vsName		= $gConfigValues{SQLVirtualName};
	my $status		= -1;
	my $machine		= '';
	my $clusterName	= '';
	my @clusOut		= ();	# Results of the cluster command.
	my $i			= 0;
SUB:
{
	&notifyWSub("Started - Node name is $nodeName, resource group name is $vsName.");
	unless( $clusterName = &getWinClusterName($gNetNodeName)) {
		&errme("Cannot get Cluster Name for virtual server $vsName.");
		$status = 0; last SUB;
	}
	@clusOut = `cmd.exe /C CLUSTER $clusterName group $vsName /listowners`;


	# Output for preferred nodes is:
	#
	# Listing preferred owners for resource group 'lvt1db01':
	#
	# Preferred Owner Nodes
	# ---------------------
	# LST1DB01
	# LST1DB02

	&notifyMe ("\n" . join('', @clusOut));
	unless (
		$clusOut[1] =~ /^Listing preferred owners for resource group \'$vsName\':/i &&
		$clusOut[3] =~ /^Preferred Owner Nodes/i &&
		$clusOut[4] =~ /^\-+/i
	) {
		&errme("There is problem with parsing output of the cluster command to get list of preferred owners for virtual server $vsName.");
		$status = 0; last SUB;
	}
	for $i (5..$#clusOut) {
		$machine = $clusOut[$i];
		$machine = &T38lib::Common::stripWhitespace($machine);
		if (uc($machine) eq uc($nodeName) ) {
			$status = 1;
			last SUB;
		}
	}

	$status = -1;
	last SUB;

}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# checkNodeInVGroup

# ----------------------------------------------------------------------
#	checkSQLInstallStatusClust	check SQL Install Status in a cluster	
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		0	SQL Server resources are not present in $vsName group
#			(need to create SQL Server cluster)
#		1	All SQL Server resources are present in $vsName group and 
#			current node owns the disk.
#		2	All SQL Server resources are present in $vsName group and 
#			current node does not own the disk.
#		3	All SQL Server resources are present in $vsName group but
#			current node is not part of the group (need to run addnode process).
#		-1	Some but not all SQL Server resources are present in $vsName
#			group (SQL Is partially install error).
#		-2	Status is unknown due to execution error
# ----------------------------------------------------------------------
#	This subroutine checks SQL Server install status in a cluster.
# ----------------------------------------------------------------------

sub checkSQLInstallStatusClust () {
	my $vsName	= $gConfigValues{SQLVirtualName};
	my $resName	= '';
	my $resPatt	= '';
	my $resType	= '';
	my @resList	= ();
	my $clusterName	= 0;
	my $cmd		= '';
	my $cmdout	= '';
	my @clusOut	= ();	# Results of the cluster command.
	my $i		= 0;
	my $sqlInstalledCurNodeFlg	= 0; # Is SQL Installed on current node flag.
	my $status	= 0;
	my $resCreatedFlgs= 0;	# Resources created flags: 
							# 0x1 = Network Name
							# 0x2 = IP Address
							# 0x4 = SQL Server
							# 0x8 = SQL Agent
							# 0xF = All are set
SUB:
{
	&notifyWSub("Started. Resource Group is $vsName.");

	unless( $clusterName = &getWinClusterName($gNetNodeName)) {
		&errme("Cannot get Cluster Name for virtual server $vsName.");
		$status = -2; last SUB;
	}
	unless ($clusterName = &getWinClusterRes ($vsName, \@resList, $clusterName) ) {
		&errme("Cannot get list of resources for virtual server $vsName on '$clusterName' cluster.");
		$status = -2; last SUB;
	}

	# Resources with the following names are present when SQL Server is installed.
	#
	# SQL Network Name (RVT1DB1) RVT1DB1              RST1DB2         Online #
	# SQL IP Address 1 (RVT1DB1) RVT1DB1              RST1DB2         Online #
	# SQL Server (TSQ9)    RVT1DB1              RST1DB2         Online       #
	# SQL Server Agent (TSQ9) RVT1DB1              RST1DB2         Online    # 

	foreach $resName (@resList) {
		$resPatt = &escapeREChar($resName);
		# Check resource type.
		$cmd = "cluster $clusterName resource \"$resName\" /prop";
		$cmdout = `$cmd`;
		&notifyWSub ("cmd = $cmd");
		&notifyWSub ("cmdout = $cmdout");
	   
		# S  SQL Server (TSQ9)    Type                           SQL Server
		if ($cmdout =~ /S\s+$resPatt\s+Type\s+(.+)\s+\n/i) {
			$resType = $1;
		} else {
			&errme("Cannot find type record for resource $resName.");
			$status = -2; last SUB;
		}

		# Get number of installed resources. 
		# If all 4 required resources are created, we can assume SQL is installed.
		# If none of 4 required resources are created, SQL Server is not installed.
		# If some of the resources are installed but not all of them, something is wrong.

		$resCreatedFlgs |= 0x1 if (lc($resType) eq 'network name');
		$resCreatedFlgs |= 0x2 if (lc($resType) eq 'ip address');
		$resCreatedFlgs |= 0x4 if (lc($resType) eq 'sql server');
		$resCreatedFlgs |= 0x8 if (lc($resType) eq 'sql server agent');

		if (lc($resType) eq 'sql server') {
			# Check if current node is in a list of possible owners (if SQL can run on current node).
			# Get list of physical nodes for target machines.
			
			$cmd = "cmd.exe /C CLUSTER $clusterName resource \"$resName\" /listowners";
			@clusOut = `$cmd`;
	
	
			# Output for preferred nodes is:
			#
			# Listing possible owners for resource 'SQL Server (SX01DBA03)':
			# Possible Owner Nodes
			# --------------------
			# LST01DB02
			# LST01DB01
	
			&notifyMe ("\n" . join('', @clusOut));
			unless (
				$clusOut[1] =~ /^Listing possible owners for resource \'$resPatt\':/i &&
				$clusOut[2] =~ /^Possible Owner Nodes/i &&
				$clusOut[3] =~ /^\-+/i
			) {
				&errme("There is problem with parsing output of the cluster command to get list of possible owners for $resName.");
				$status = -2; last SUB;
			}
			for $i (4..$#clusOut) {
				$clusOut[$i] = &T38lib::Common::stripWhitespace($clusOut[$i]);
				if ($sqlInstalledCurNodeFlg = (uc($clusOut[$i]) eq uc($gHostName))) {
						last;
				}
			}
		} # Check if SQL Server is installed on current node.
	} # foreach $resName

	if (($resCreatedFlgs & 0xF) == 0) {
		$status = 0;
		last SUB;
	} elsif (($resCreatedFlgs & 0xF) != 0xF) {
		$status = -1;
		last SUB;
	} else {
		$status = 
			($gHostName eq $gNetNodeName) ? 1:	# SQL is installed and it is running on current node
			($sqlInstalledCurNodeFlg)? 2:		# SQL is installed, current node is part of the cluster, but SQL is running on another node
			3;									# SQL is installed but current node is not part of the cluster
		last SUB;
	}

}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# checkSQLInstallStatusClust


#------------------------------------------------------------------------------
#	Purpose: Check the box to see if SQL Server has been installed or it is
#            running before trying to install SQL software again. 
#
#	Input Argument :	None
#	Return:	$sqlInstallStatus
#			0 => No SQL Server is installed on the box
#			1 => SQL Server is installed, run the later half
#		   -1 => Older version of SQL is Installed.
#		   -2 => Newer version of SQL is Installed.
#------------------------------------------------------------------------------
sub checkSystem() {

	my $sqlInstallStatus	= 0;
	my ($sqlMajorVer, $sqlMinorVer, $sqlSPVer, $sqlVersion);


	&T38lib::Common::notifyWSub("START - Check if SQL Installed.");

	# check the SQL Server version	
	$sqlVersion= (&T38lib::Common::pingServer($gNetName) == 0) ?
		&T38lib::Common::getSqlCurVer($gConfigValues{SQLInstanceName}, $gNetName):0;
	($sqlMajorVer, $sqlMinorVer, $sqlSPVer) = split('\.', $sqlVersion);

 	# if $sqlMajorVer is zero then no SQL server is installed
 	if ($sqlMajorVer == 0 ) {
		&T38lib::Common::notifyWSub ("Microsoft SQL Server version $gConfigValues{SQLServiceVersion} is NOT installed on $gSrvrName");
		&T38lib::Common::notifyWSub ("Install Microsoft SQL Server version $gConfigValues{SQLServiceVersion}");
		$sqlInstallStatus = 0;
	}
	# SQL server is installed Run the later half
	elsif ( $sqlMajorVer == $gConfigValues{SQLServiceVersion} ) {
		&T38lib::Common::notifyWSub ("Microsoft SQL Server version $sqlVersion is installed on $gSrvrName");
		$sqlInstallStatus = 1;
	}
	# Older Version of SQL Server is installed.
	elsif ( $sqlMajorVer < $gConfigValues{SQLServiceVersion} ) {
		&T38lib::Common::notifyWSub ("Microsoft SQL Server version $sqlVersion is installed on $gSrvrName");
		&T38lib::Common::notifyWSub ("Older version of Microsoft SQL Server installed");
		$sqlInstallStatus = -1;
	}
	# Newer Version of SQL Server is installed.
	elsif ( $sqlMajorVer > $gConfigValues{SQLServiceVersion} ) {
		&T38lib::Common::notifyWSub ("Microsoft SQL Server version $sqlVersion is installed on $gSrvrName");
		&T38lib::Common::notifyWSub ("Newer version of Microsoft SQL Server installed");
		$sqlInstallStatus = -2;
	}

	&T38lib::Common::notifyWSub("DONE - Check if SQL Installed.");
	
	return $sqlInstallStatus;

} # end sub checkSystem 


# ----------------------------------------------------------------------
#	copyT38lib		copy t38lib modules to Perl site directory
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------

sub copyT38lib () {
	my $status		= 1;
	my $libPath		= '';
	my $oscmd		= '';
	my $tmpout		= '';
	my $t38libdir	= "${gScriptPath}T38lib";
SUB:
{
	&notifyWSub("Started.");

	if ( (uc($gHostName) ne uc($gNetName)) || $gConfigValues{SQLVirtualName} ) {
		# We are installing on remote server or clustered server.
		$oscmd = "cmd /c perl cpt38lib.pl -C -S $gNetName $t38libdir";

		if ( system($oscmd) != 0 ) {
			&warnme("Fail to install Perl libraries with $oscmd");
			$gNWarnings++;
			$status = 0;
		}
		last SUB;
	}

	# We are running locally on a server. Just install Perl library.

	# Copy T38lib libraries to default perl lib directory
	# Get the Perl lib path from global variable @INC 
	# Create a directory under Perl lib path call T38lib
	# Copy all the file under T38lib
	#
	foreach (@INC) {
		$libPath=$_;
		last if ( /site/i )
	}

	$libPath .= '/T38lib';

	unless ( mkpath("$libPath") ) {
		&notifyWSub("mkpath failed. $libPath");
		&notifyWSub("or directory is already there try copying the module file");
	}

	$libPath =~ s|/|\\|g;		# Change unix like path to windows path

	$tmpout = &T38lib::Common::getLogFileName($0);
	$tmpout .= '.copyT38lib';
	&T38lib::Common::archiveFile($tmpout, 7);

	# Copy the file to destination preserving the attributes

	$oscmd = "xcopy /R/Y/K/I \"$t38libdir\\*.pm\" \"$libPath\" ";
	&notifyWSub($oscmd);
	if (system("cmd /E:on /C \"$oscmd\" > \"$tmpout\" 2>\&1") != 0) {
		&warnme("copy T38lib libraries files failed");
		&notifyFile($tmpout);
		$status = 0;
		last SUB;
	}

	# Change the file attribute to read only

	$oscmd = "attrib +r \"$libPath\\*.pm\"";
	&notifyWSub($oscmd);
	if (system("cmd /E:on /C \"$oscmd\" > \"$tmpout\" 2>\&1") != 0) {
		&warnme("Cannot change attributes for T38lib libraries files.");
		&notifyFile($tmpout);
		$status = 0;
		last SUB;
	}

	unlink ($tmpout);
	last SUB;
}	# SUB
# ExitPoint:

	&notifyWSub("Done. Status: $status.");

	return($status);

}	# copyT38lib


# ----------------------------------------------------------------------
#	grantAdminAccounts	Grant permissions to known admin accounts
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		1			Success
#		0			Failure
# ----------------------------------------------------------------------
#	Grant permissions to known admin accounts
# ----------------------------------------------------------------------
sub grantAdminAccounts() {
	my @srvrList	= ();
	my $server		= '';
	my $sql			= '';
	my $accntName	= '';
	my $accntBase	= '';
	my $key			= '';
	my $status		= 1;
SUB:
{
	&notifyWSub("Started.");

	# Grant SA rights in SQL Server.
	foreach $accntBase ((
			'ADSQLGroupSQLAccountsSA_',
			'ADSQLGroupDBAAccountsSA_'
		)) {

		$key = "$accntBase" . $gConfigValues{SecurityGroupLocation} . $gConfigValues{EnvironmentType} . $gConfigValues{SecurityDataSensitivity};
		unless ( $gConfigValues{$key} ) { next;	}
		$accntName = $gConfigValues{$key};
		$sql = "xp_grantlogin [$accntName], admin";
		&notifyWSub("execSQL($gConfigValues{gSQLConnectName}, '', $sql)");
		unless (execSQL($gConfigValues{gSQLConnectName}, '', $sql)) {
			&warnme("execSQL call failed.");
			$gNWarnings++;
		}
	}

	# Grant OS rights on each node for SQL Server.

	if ($gConfigValues{SQLVirtualName}) {
		# Clustered install.
		unless (&getClusSQLNodes($gConfigValues{SQLVirtualName}, \@srvrList)) {
			&errme("Cannot get list of nodes for virtual server $gConfigValues{SQLVirtualName}.");
			$status = 0; last SUB;
		}
	} else {
		push @srvrList, $gNetName;
	}

	foreach $accntBase ((
			'ADSQLGroupSQLAccountsOS_',
			'ADSQLGroupDBAAccountsOS_'
		)) {
		$key = "$accntBase" . $gConfigValues{SecurityGroupLocation} . $gConfigValues{EnvironmentType} . $gConfigValues{SecurityDataSensitivity};
		unless ( $gConfigValues{$key} ) { next;	}
		$accntName = $gConfigValues{$key};

		foreach $server (@srvrList) {
			unless (&adAddAccount2LocGrp($accntName, 'Administrators', $server)) {
				&warnme("execSQL call failed.");
				$gNWarnings++;
			}
		}
	}
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# grantAdminAccounts


# ----------------------------------------------------------------------
#	installSQL		Install SQL (Server 2000, msde, Yukon, ...)
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
#	Install SQL (Server 2000, msde, Yukon, ...)
# ----------------------------------------------------------------------

sub installSQL () {
	my $status	= 1;
SUB:
{
	&notifyWSub("Started.");

	if ($gConfigValues{SQLServiceVersion} =~ /^10\.0\./) {
		# SQL 10 install.
		$status = &installSQL100Server();
		last SUB;
	}

}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# installSQL


# ----------------------------------------------------------------------
#	installSQLClientTools		Install SQL Server Client Tools
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
#	Install SQL Client Tools
# ----------------------------------------------------------------------

sub installSQLClientTools () {
	my $status	= 1;
SUB:
{
	&notifyWSub("Started.");

	if ($gConfigValues{SQLServiceVersion} =~ /^10\.0\./) {
		# SQL 10 install.
		$status = &installSQL100Client();
		last SUB;
	}

}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# installSQLClientTools


# ----------------------------------------------------------------------
#	installSQL100Client		Install SQL Server 10.0 (SQL 2008) client
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
#	Install SQL Server 10.0 (SQL 2008) client Tools
# ----------------------------------------------------------------------

sub installSQL100Client () {
	my $status			= 1;
	my $sqlInstallStat	= 0;
	my $setupExe		= 'setup.exe';		;# Actual Path to SQL Server install Program
	my $setupPath		= '.\\';
	my $sqlInstCfgTpl	= 'ConfigurationFile.SlipStream.ClientTools.tpl.ini';
	my $sqlInstCfgIni	= "ConfigurationFile.SlipStream.ClientTools.${gNetName}_${gInstName}.ini";
	my $sqlInstCUCfgTpl	= 'ConfigurationFile.SlipStreamCU.ClientTools.tpl.ini';
	my $sqlInstCUCfgIni	= "ConfigurationFile.SlipStreamCU.ClientTools.${gNetName}_${gInstName}.ini";
	my $installCUFlg	= 0;	# Run Cumulative Update install.
 	my $result			= 0;
	my $log_filename	= '';
	my $serviceName		= '';
	my $cmd				= '';	# OS command
	my $cnt				= 0;
 	my @ServicestoStop	= ();
	my @tmp 			= ();
	my $keyName			= '';
SUB:
{
	if ($gConfigValues{SQLVirtualName}) {
		my $checkNodeInVGroupStat = -1;
		unless ($checkNodeInVGroupStat = &checkNodeInVGroup($gHostName)) {
			&errme("Cannot check if current node is in owners list for SQL Resource group $gConfigValues{SQLVirtualName}");
			$status = 0; last SUB;
		}
		unless ($checkNodeInVGroupStat == 1) {
			&warnme("This program cannot install SQL Server remotely. Current node $gHostName has to be one of the owners for resource group $gConfigValues{SQLVirtualName}");
			$gNWarnings++;
			last SUB;
		}
	} elsif (uc($gHostName) ne uc($gNetNodeName)) {		
		# This check will apply to non-clustered install.
		&warnme("This program cannot install SQL Server remotely.");
		$gNWarnings++;
		last SUB;
	}

	# Check if SQL Tools already installed.
	
	if ( 
		($keyName = "LMachine/SOFTWARE/Microsoft/Microsoft SQL Server/100/Tools/Setup/SQL_SSMS_Adv/FeatureList") && 
		defined($Registry->{$keyName})) {
		# if set to all of the following, SQL_SSMS_Adv=3 SQL_Tools_ANS=3 SQL_PowerShell_Tools_ANS=3
		# it is already installed.
		if ( 
			($Registry->{$keyName} =~ /\bSQL_SSMS_Adv=3\b/i) &&
			($Registry->{$keyName} =~ /\bSQL_Tools_ANS=3\b/i) &&
			($Registry->{$keyName} =~ /\bSQL_PowerShell_Tools_ANS=3\b/i) ) {
			&notifyMe("SQL Client tools already installed.");
			last SUB;
		}
	}
	 
	if (!($gConfigValues{SPVersion}) || ($gConfigValues{SQLServiceVersion} eq $gConfigValues{SPVersion})) {
		&warnme("This program can install RTM version of SQL Server at this time. We can only install SlipStream Service Pack.");
		$gNWarnings++;
		last SUB;
	}
	
	&notifyWSub("START - Install SQL Server Client Tools.");

	# Setup SQL 2008 global parameters.

	unless (&getSQLInstallSetupExe100(\$setupPath, \$setupExe, \$installCUFlg)) { $status = 0; last SUB; }
	if ($installCUFlg) {
		$sqlInstCfgTpl = $sqlInstCUCfgTpl;
		$sqlInstCfgIni = $sqlInstCUCfgIni;
	}

	$gConfigValues{gIssSQLSetupPath} = $setupPath;

	# if setup90iss.tpl file is not found display error and quit the program
	#
	unless (-s "${gScriptPath}install\\${sqlInstCfgTpl}" ) {
		&errme("Cannot find file ${gScriptPath}install\\${sqlInstCfgTpl}" );
		$status = 0; last SUB;
	}
	
	# build the setup.iss for an un-attend sql server installation
	unless (&buildSetup($sqlInstCfgTpl, $sqlInstCfgIni ))	{ $status = 0; last SUB; }

	# Stop required services.
	@ServicestoStop = split('\,', $gConfigValues{ServicesDown});

	foreach $serviceName (@ServicestoStop) {
		$tmp[$cnt] = &T38lib::Common::stripWhitespace($serviceName);
		$cnt += 1;
	}
	@ServicestoStop = @tmp;

	foreach $serviceName (@ServicestoStop) {
		&T38lib::Common::stopServiceWithDepend($serviceName);
	}

	# Run SQL Server setup command.

  	&notifyWSub("preparing to install SQL Server.");
	$log_filename=$ENV{ProgramFiles} . "\\Microsoft SQL Server\\100\\Setup Bootstrap\\LOG\\Summary.txt";
	&notifyWSub("SQL Setup Install log file: $log_filename");

	$cmd = "\"$setupExe\" /q /Configurationfile=\"${gScriptPath}INSTALLWRK\\$sqlInstCfgIni\"";

	&notifyWSub("Starting installation of SQL Server 2008. Command line is:\ncmd /C $cmd");
	$result = system("cmd /C $cmd");
	$cmd = '';

	&notifyWSub("SQL Server 2008 setup program finished.");

	&notifyWSub("return code of the setup command = $result");

	if ( $result == 0 ) {
		&notifyWSub("Installation of SQL Server Client successful.");
		unless(&setEnvPath())	{ $status = 0; last SUB; } 
	} else {
		&errme("Installation of SQL Server Client failed. Check $log_filename.");
		$status = 0; last SUB;
	}					

	&notifyWSub("DONE  - Install SQL Server Client Tools.");

	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# installSQL100Client


# ----------------------------------------------------------------------
#	installSQL100Server		Install SQL Server 10.0 (SQL 2008)
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
#	Install SQL Server 10.0 (SQL 2008)
# ----------------------------------------------------------------------

sub installSQL100Server () {

	my $status			= 1;
	my $setupExe		= 'setup.exe';		;# Actual Path to SQL Server install Program
	my $setupPath		= '.\\';
	my $installCUFlg	= 0;	# Run Cumulative Update install.
	my $sapwd			= '';
	my $sqlInstCfgTpl	= ''; 
	my $sqlInstCfgIni	= ''; 
	my $sqlCrStalCfgTpl = 'ConfigurationFile.SlipStream.InstallStandAlone.tpl.ini'; #Hemanth: Adding the sample configuration template file name
	my $sqlCrStalCfgIni = "ConfigurationFile.SlipStream.InstallStandAlone.${gNetName}_${gInstName}.ini";#Hemanth: Adding the sample configuration ini file name
	my $sqlCrClusCfgTpl	= 'ConfigurationFile.SlipStream.InstallCluster.tpl.ini';
	my $sqlCrClusCfgIni	= "ConfigurationFile.SlipStream.InstallCluster.${gNetName}_${gInstName}.ini";
	my $sqlAddNodeCfgTpl	= 'ConfigurationFile.SlipStream.AddNode.tpl.ini';
	my $sqlAddNodeCfgIni	= "ConfigurationFile.SlipStream.AddNode.${gNetName}_${gInstName}.ini";
	my $sqlCrStalCUCfgTpl = 'ConfigurationFile.SlipStreamCU.InstallStandAlone.tpl.ini'; #Hemanth: Adding the sample configuration template file name
	my $sqlCrStalCUCfgIni = "ConfigurationFile.SlipStreamCU.InstallStandAlone.${gNetName}_${gInstName}.ini";#Hemanth: Adding the sample configuration ini file name
	my $sqlCrClusCUCfgTpl	= 'ConfigurationFile.SlipStreamCU.InstallCluster.tpl.ini';
	my $sqlCrClusCUCfgIni	= "ConfigurationFile.SlipStreamCU.InstallCluster.${gNetName}_${gInstName}.ini";
	my $sqlAddNodeCUCfgTpl	= 'ConfigurationFile.SlipStreamCU.AddNode.tpl.ini';
	my $sqlAddNodeCUCfgIni	= "ConfigurationFile.SlipStreamCU.AddNode.${gNetName}_${gInstName}.ini";
	my $installerPwd	= '';
	my $installer		= '';
 	my $result			= 0;
	my $log_filename	= '';
	my $serviceName		= '';
	my $cmd				= '';	# OS command
	my $prncmd			= '';	# OS command with passwords blanked out for printing in log file.
	my $cnt				= 0;
	my $key				= '';
	my $errflg			= 0;
 	my @ServicestoStop	= ();
	my @tmp 			= ();
	my $clusterName		= 0;
	my $osVer			= 0;
	my $vsName			= '';	# Virtual Server name.
SUB:
{

	if ($gConfigValues{SQLVirtualName}) {
		my $checkNodeInVGroupStat = -1;
		unless ($checkNodeInVGroupStat = &checkNodeInVGroup($gHostName)) {
			&errme("Cannot check if current node is in owners list for SQL Resource group $gConfigValues{SQLVirtualName}");
			$status = 0; last SUB;
		}
		unless ($checkNodeInVGroupStat == 1) {
			&warnme("This program cannot install SQL Server remotely. Current node $gHostName has to be one of the owners for resource group $gConfigValues{SQLVirtualName}");
			$gNWarnings++;
			last SUB;
		}
	} else {
		#Hemanth: We will be most probably removing this check.
		#&warnme("This program can install only clustered SQL Server at this time.");
		#$gNWarnings++;
		#last SUB;

		# This check will apply to non-clustered install.
		if (uc($gHostName) ne uc($gNetNodeName)) {
			&warnme("This program cannot install SQL Server remotely.");
			$gNWarnings++;
			last SUB;
		}
	}

	#Hemanth: Do we need this check in place? 
	if (!($gConfigValues{SPVersion}) || ($gConfigValues{SQLServiceVersion} eq $gConfigValues{SPVersion})) {
		&warnme("This program can install RTM version of SQL Server at this time. We can only install SlipStream Service Pack.");
		$gNWarnings++;
		last SUB;
	}
	
	&notifyWSub("START - Install SQL Server.");

	# Setup SQL 2008 global parameters.

	unless (&getSQLInstallSetupExe100(\$setupPath, \$setupExe, \$installCUFlg)) { $status = 0; last SUB; }
	#Hemanth: We need to make changes here.
	if ( $gConfigValues{SQLVirtualName}) {
		# Verify all SQL 2008 parameters for clustered install are valid.

		$errflg = 0;
		foreach $key ((
				'SQLClustNetworkName',
				'SQLVIP',
				'SQLInstallPwdSrvr',
				'SQLInstallPwdDB'
			)) {
			if ( !($gConfigValues{$key}) ) {
				&errme("Configuration variable $key is not valid.");
				$errflg = 1;
			}
		}
		if ($errflg) {
			$status = 0; last SUB;
		}

		$vsName = $gConfigValues{SQLVirtualName};


		unless( $clusterName = &getWinClusterName($gNetNodeName)) {
			&errme("Cannot get Cluster Name for virtual server $vsName.");
			$status = 0; last SUB;
		}
		if ($gClustSqlInstallStat == -2 || $gClustSqlInstallStat == -1) {
			# There was a problem in checkSQLInstallStatusClust. Error is already reported.
			# Just exit.
			$status = 0; last SUB;
		} elsif ($gClustSqlInstallStat == 1 || $gClustSqlInstallStat == 2) {
			&warnme("SQL Server \"$gConfigValues{SQLVirtualName}\" already installed on this cluster.");
			$gNWarnings++;
			last SUB;
		}

		if ($gClustSqlInstallStat == 0) {
			# SQL is not created in a Cluster. Install on a first node.
			&notifyMe("Creating new cluster \"$gConfigValues{SQLVirtualName}\"");
			$sqlInstCfgTpl = ($installCUFlg) ? $sqlCrClusCUCfgTpl : $sqlCrClusCfgTpl;
			$sqlInstCfgIni = ($installCUFlg) ? $sqlCrClusCUCfgIni : $sqlCrClusCfgIni;
		} elsif ($gClustSqlInstallStat == 3) {
			# Add node to existing cluster.
			&notifyMe("Add current node to existing cluster \"$gConfigValues{SQLVirtualName}\"");
			$sqlInstCfgTpl = ($installCUFlg) ? $sqlAddNodeCUCfgTpl : $sqlAddNodeCfgTpl;
			$sqlInstCfgIni = ($installCUFlg) ? $sqlAddNodeCUCfgIni : $sqlAddNodeCfgIni;
		}

		$gConfigValues{gIssSQLVirtualName} = $vsName;
		$gConfigValues{gIssSQLVIP} = $gConfigValues{SQLVIP};
		($gConfigValues{gIssSQLNetworkName} = $gConfigValues{SQLClustNetworkName}) =~ s/__T38NUMBERSIGN__/#/g;	# For now do it here. Long term, modify t38cfgfile.pm to handle # character.
		$key = "ADSQLGroupSQLAccounts4msi_" . $gConfigValues{SecurityGroupLocation} . $gConfigValues{EnvironmentType} . $gConfigValues{SecurityDataSensitivity};
		if (defined($gConfigValues{$key})) {
			$gConfigValues{gIssSQLClusterGroup} = $gConfigValues{$key};
			$gConfigValues{gIssAgtClusterGroup} = $gConfigValues{$key};
		} else {
			&errme("$key is not configured in parameters file.");
			$status = 0; last SUB;
		}
		# $gConfigValues{gIssSQLBrowserAccount} = $gConfigValues{SQLClustInstAcct};
		unless (&getInstallerPwd(\$installerPwd, \$installer)) {
			&errme("Cannot get installer information.");
			$status = 0; last SUB;
		}
		$gConfigValues{gIssSQLAccount} = $installer;
		$gConfigValues{gIssAgtAccount} = $installer;
	} else {#Hemanth: Start SQL 2008 standalone parameters
		#Hemanth: We might want to change this for Louiseville RDC.
		unless (&getInstallerPwd(\$installerPwd, \$installer)) {
			&errme("Cannot get installer information.");
			$status = 0; last SUB;
		}
		#Hemanth: We might have change this in the near future
		if($gClustSqlInstallStat == -99){
			&notifyMe("Creating new Instance: \"$gConfigValues{SQLInstanceName}\"");
			$sqlInstCfgTpl = ($installCUFlg) ? $sqlCrStalCUCfgTpl : $sqlCrStalCfgTpl;
			$sqlInstCfgIni = ($installCUFlg) ? $sqlCrStalCUCfgIni : $sqlCrStalCfgIni;
		}
		$gConfigValues{gIssSQLAccount} = $installer;#Hemanth: These are probably not needed as we use "NT Authority\System"
		$gConfigValues{gIssAgtAccount} = $installer;#Hemanth: as the default options on a stand-alone install.
		if (!$gConfigValues{SQLInstanceName}) {$gConfigValues{SQLInstanceName} ='MSSQLSERVER';}
		$gConfigValues{gIssInstanceName} = $gConfigValues{SQLInstanceName};	
	}#Hemanth: End SQL 2008 standalone parameters

	$key = "ADSQLGroupDBAAccountsSA_" . $gConfigValues{SecurityGroupLocation} . $gConfigValues{EnvironmentType} . $gConfigValues{SecurityDataSensitivity};
	if (defined($gConfigValues{$key})) {
		$gConfigValues{gIssSQLAdmins} = $gConfigValues{$key};
	} else {
		&errme("$key is not configured in parameters file.");
		$status = 0; last SUB;
	}

	$gConfigValues{gIssSQLSetupPath} = $setupPath;

	# if setup90iss.tpl file is not found display error and quit the program
	#
	unless (-s "${gScriptPath}install\\${sqlInstCfgTpl}" ) {
		&errme("Cannot find file ${gScriptPath}install\\${sqlInstCfgTpl}" );
		$status = 0; last SUB;
	}
	
	# build the setup.iss for an un-attend sql server installation
	unless (&buildSetup($sqlInstCfgTpl, $sqlInstCfgIni ))	{ $status = 0; last SUB; }

	# Stop required services.
	@ServicestoStop = split('\,', $gConfigValues{ServicesDown});

	foreach $serviceName (@ServicestoStop) {
		$tmp[$cnt] = &T38lib::Common::stripWhitespace($serviceName);
		$cnt += 1;
	}
	@ServicestoStop = @tmp;

	foreach $serviceName (@ServicestoStop) {
		&T38lib::Common::stopServiceWithDepend($serviceName);
	}

	#Hemanth: Get temporary sa password.
	$sapwd = &generateTempSaPwd();
	if($sapwd eq '') { $status = 0; last SUB;} else {&T38lib::Common::notifyWSub ("generating temp sa password: DONE");}
	
	# Run SQL Server setup command.
  	&notifyWSub("preparing to install SQL Server.");
	$log_filename=$ENV{ProgramFiles} . "\\Microsoft SQL Server\\100\\Setup Bootstrap\\LOG\\Summary.txt";
	&notifyWSub("SQL Setup Install log file: $log_filename");

	if (!$vsName) {
		#Hemanth: The below lines will probably be uncommented for the stand-alone install.
		$cmd = "\"$setupExe\" /q /Configurationfile=\"${gScriptPath}INSTALLWRK\\$sqlInstCfgIni\" ";
		$prncmd	= $cmd;
		$cmd	.= "/SAPWD=\"$sapwd\"";
		#Hemanth: For testing only.print "$cmd\n";
		$prncmd	.= 
				"/SAPWD=\"xxxxxx\""; #Hemanth: uncommented the lines
		#&errme("At this point can install only clustered SQL Server");
		#$status = 0; last SUB;

	} else {
		if ($gClustSqlInstallStat == 0) {
			# SQL is not created in a Cluster. Install on a first node.
			unless (&getSAPwd(\$sapwd)) {
				&errme("Cannot get sa password from repository.");
				$status = 0; last SUB;
			}
			$cmd = "\"$setupExe\" /q /Configurationfile=\"${gScriptPath}INSTALLWRK\\$sqlInstCfgIni\" ";
			$prncmd	= $cmd;
			$cmd	.=
				"/SQLSVCPASSWORD=\"$installerPwd\" /AGTSVCPASSWORD=\"$installerPwd\" /SAPWD=\"$sapwd\"";
			$prncmd	.= 
				"/SQLSVCPASSWORD=\"xxxxxx\" /AGTSVCPASSWORD=\"xxxxxx\" /SAPWD=\"xxxxxx\"";
		} elsif ($gClustSqlInstallStat == 3) {
			# Add node to existing cluster.
			$cmd = "\"$setupExe\" /q /Configurationfile=\"${gScriptPath}INSTALLWRK\\$sqlInstCfgIni\" ";
			$prncmd	= $cmd;
			$cmd	.=
				"/SQLSVCPASSWORD=\"$installerPwd\" /AGTSVCPASSWORD=\"$installerPwd\"";
			$prncmd	.= 
				"/SQLSVCPASSWORD=\"xxxxxx\" /AGTSVCPASSWORD=\"xxxxxx\"";
		}
	}

	&notifyWSub("Starting installation of SQL Server 2008. Command line is:\ncmd /C $prncmd");
	$result = system("cmd /C $cmd");
	$cmd = '';
	$prncmd = '';

	&notifyWSub("SQL Server 2008 setup program finished.");

	&notifyWSub("return code of the setup command = $result");

	if ( $result == 0 ) {
		&notifyWSub("Installation of SQL Server successful.");
		if ($gClustSqlInstallStat == 0 && $vsName) {
			$osVer = getSysVerReg($gHostName); #Returns OS Version (Success); 0 (Failure);
			if($osVer > 0 && $osVer < 6){
				$cmd = "CLUSTER $clusterName res \"SQL Network Name ($vsName)\" /priv RequireKerberos=0";
				unless(&runOSCmd($cmd)) {
					&errme("Cannot change Kerberos option for $vsName.");
					$status = 0; last SUB;
				}
			}
			
			$cmd = "CLUSTER $clusterName group $vsName /online";
			unless(&runOSCmd($cmd)) {
				&errme("Cannot bring $vsName online.");
				$status = 0; last SUB;
			}
		}
		unless(&setEnvPath())	{ $status = 0; last SUB; } 
	} else {
		&errme("Installation of SQL Server failed. Check $log_filename.");
		$status = 0; last SUB;
	}					

	&notifyWSub("DONE  - Install SQL Server.");

	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# installSQL100Server


# ----------------------------------------------------------------------
#	installUserDb		install user databases
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	install user databases
# ----------------------------------------------------------------------

sub installUserDb () {
	my $status	= 1;
	my $dbName	= '';
SUB:
{
	&notifyWSub("Started.");
	unless (&buildUserDb())	{ $status = 0; last SUB; }
	unless (&runScriptsDir('INSTALLWRK\\' . DBCRSZNAME . '.sql')) { $status = 0; last SUB; }
	# Run any customize scripts for database that have created.
	# 
	foreach $dbName (keys %gUserDb) { 
		if ( -d "USERDB\\$dbName") {
			unless (&runScriptsDir("USERDB\\$dbName")) { $status = 0; last SUB; }
		} else {
			&notifyWSub("Can not find directory USERDB\\$dbName");
		}

	}
	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# installUserDb


#------------------------------------------------------------------------------
# Purpose: creates a directory
#
#	Input Arguments:	path with the drive letter, example c:\dbms\t38bkps
#	Return:				None
#------------------------------------------------------------------------------
sub mkdir($) {
  	my ($path) = shift;
	my $oscmd		= '';
	my $osout		= '';

	$oscmd = "mkdir \"$path\"";
	$osout = `cmd /E:on /C \"$oscmd\" 2>\&1`;
	&notifyMe("OS Command: $oscmd");
	&notifyMe("$osout");

	&notifyWSub("[mkdir] ** ERROR ** try to create $path directory failed.") unless ( -d $path);
} # end sub mkdir


#------------------------------------------------------------------------------
# Purpose: Copy Maintenance scripts to destination directory.
#------------------------------------------------------------------------------
sub moveSQLScripts() {
	my $status		= 1;
	my $cmd			= '';
	my $tmpout		= '';
SUB:
{
	&notifyWSub("START - copy maintenance scripts");

	$cmd = "xcopy /R/Y/K/I/Q ";
	$cmd = $cmd . "${gScriptPath}T38APP80\\*.* ";
	if ( uc($gHostName) eq uc($gNetName) ) {
		$cmd = $cmd . "$gConfigValues{DBAUtilsDrive}:";
		$cmd = $cmd . "$gConfigValues{DBAUtilsPath}\\";
	} else {
		$cmd = $cmd . "\\\\$gNetName\\$gConfigValues{DBAUtilsDrive}\$";
		$cmd = $cmd . "$gConfigValues{DBAUtilsPath}\\";
	}

	$tmpout = &T38lib::Common::getLogFileName($0);
	$tmpout .= '.moveSQLScripts';
	&T38lib::Common::archiveFile($tmpout, 7);

	# Copy the file to destination preserving the attributes

	&notifyWSub($cmd);
	if (system("cmd /E:on /C \"$cmd\" > \"$tmpout\" 2>\&1") == 0) {
		&notifyWSub("Copied scripts.");
		&notifyFile($tmpout);
	} else {
		&warnme("Copy command failed.");
		&notifyFile($tmpout);
		$gNWarnings++;
		last SUB;
	}

	unlink ($tmpout);
	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
} # end sub moveSQLScripts

# ----------------------------------------------------------------------
#	notifyFile		print notifications from the file
# ----------------------------------------------------------------------
#	arguments:
#		fname	file name to read notification messages
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	print notifications from the file
# ----------------------------------------------------------------------

sub notifyFile ($) {
	my $fname	= shift;
	my $status	= 1;
SUB:
{
	unless (open(TMP,"< $fname"))  {
		&warne("Cannot open $fname for reading.  $!");
		$status = 0; last SUB;
	}
	while (<TMP>) {
		&notifyMe($_);
	}

	last SUB;
}	# SUB
# ExitPoint:
	close(TMP);
	return($status);
}	# notifyFile



# ----------------------------------------------------------------------
#	prepareConfigParms		prepare configuration parameters
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
#	prepare configuration parameters
# ----------------------------------------------------------------------

sub prepareConfigParms () {
	my $status	= 1;
	my $cfgFile;
SUB:
{
	&notifyWSub("Started.");

	foreach $cfgFile (@gArg)	{
		unless(&readConfigFile($cfgFile)) { $status = 0; last SUB; }
	}

	unless(&testConfigParm())  { $status = 0; last SUB; }	# Validate the configuration parameters


	# Print all the values read from cfg file for Testing only
	# my($k, $v);
	# while ( ($k, $v) = each(%gConfigValues) ) {
	#	print "$k = $v\n";
	# }


	# Copy all the path information to hash because these will change if we have
	# an instance.  These path are used in creating share points.
	#
	$gConfigValues{shareDumpDevicesPath}	= $gConfigValues{DumpDevicesPath};
	$gConfigValues{shareMdfPath}				= $gConfigValues{MdfPath};
	$gConfigValues{shareNdfPath}				= $gConfigValues{NdfPath};
	$gConfigValues{shareLdfPath}				= $gConfigValues{LdfPath};
	$gConfigValues{shareTrcPath}		 		= $gConfigValues{TrcPath};
	$gConfigValues{shareTmpPath}				= $gConfigValues{TmpPath};
	$gConfigValues{shareSQLDataRootPath}	= $gConfigValues{SQLDataRootPath};
	$gConfigValues{shareDBAUtilsPath}		= $gConfigValues{DBAUtilsPath};
	$gConfigValues{shareSQLAppPath}			= $gConfigValues{SQLAppPath};

	# Initialize SQL Connection name.

	$gConfigValues{gSQLConnectName}	= ( uc($gHostName) eq uc($gNetName) ) ? "." : $gNetName;


	# if we are installing an instance add instance name to variable names.
	# The $ sign between MSSQL and instance Name is part of the service name
	#
	if($gConfigValues{SQLInstanceName}) {
		$gConfigValues{SQLServiceName} 	= "MSSQL\$" . $gConfigValues{SQLInstanceName};
		$gConfigValues{gSQLConnectName}	.= "\\$gConfigValues{SQLInstanceName}"; 
		$gConfigValues{SQLAgentName}	= "SQLAgent\$" . $gConfigValues{SQLInstanceName}; 
		$gConfigValues{SQLFTEName}		.= "\$" . $gConfigValues{SQLInstanceName};

		$gConfigValues{DBAUtilsPath}	= "$gConfigValues{DBAUtilsPath}\\$gConfigValues{SQLInstanceName}";
		$gConfigValues{MdfPath}			= "$gConfigValues{MdfPath}\\$gConfigValues{SQLInstanceName}";
		$gConfigValues{NdfPath}			= "$gConfigValues{NdfPath}\\$gConfigValues{SQLInstanceName}";
		$gConfigValues{LdfPath}			= "$gConfigValues{LdfPath}\\$gConfigValues{SQLInstanceName}";
		$gConfigValues{DumpDevicesPath}	= "$gConfigValues{DumpDevicesPath}\\$gConfigValues{SQLInstanceName}";
	}

	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# prepareConfigParms


# ----------------------------------------------------------------------
#	removeNode		Remove SQL Server Node
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
#	Remove SQL Server Node
# ----------------------------------------------------------------------

sub removeNode () {
	my $status	= 1;
SUB:
{
	&notifyWSub("Started.");

	if ($gConfigValues{SQLServiceVersion} =~ /^10\.0\./) {
		# SQL 10 install.
		$status = &removeNodeSQL100();
		last SUB;
	}

}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# removeNode


# ----------------------------------------------------------------------
#	removeNodeSQL100		Remove SQL Server SQL 2008 Node
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
#	Remove SQL Server 2008 Node
# ----------------------------------------------------------------------

sub removeNodeSQL100 () {
	my $status	= 1;
	my $setupExe		= 'setup.exe';		;# Actual Path to SQL Server install Program
	my $setupPath		= '.\\';
	my $installCUFlg	= 0;	# Run Cumulative Update install.
 	my $log_filename	= '';
	my $cmd		= '';	# OS command
SUB:
{
	&notifyWSub("START - Remove SQL Server from node $gHostName.");
	unless ($gInstName) {
		&errme("Missing instance name parameter.");
		$status = 0; last SUB;
	}

	# $gClustSqlInstallStat = &checkSQLInstallStatusClust();
	if ($gClustSqlInstallStat == -2 || $gClustSqlInstallStat == -1) {
		# There was a problem in checkSQLInstallStatusClust. Error is already reported.
		# Just exit.
		$status = 0; last SUB;
	} elsif ($gClustSqlInstallStat == 0) {
		&notifyMe("SQL Server \"$gConfigValues{SQLVirtualName}\" is not installed. Nothing to do.");
		last SUB;
	} elsif ($gClustSqlInstallStat == 3) {
		&notifyMe("SQL Server \"$gConfigValues{SQLVirtualName}\" is not installed on current node. Nothing to do.");
		last SUB;
	}

	unless (&getSQLInstallSetupExe100(\$setupPath, \$setupExe, \$installCUFlg)) {
		&errme("Cannot get path for SQL Server installer");
		$status = 0; last SUB;
	}

  	&notifyWSub("preparing to remove node $gHostName for SQL Server instance $gInstName.");

	$cmd = "\"$setupExe\" /q /ACTION=RemoveNode /INSTANCENAME=$gInstName";
	unless(&runOSCmd($cmd)) {
		&errme("Problem with removing current node from a cluster.");
		my $log_filename=$ENV{ProgramFiles} . "\\Microsoft SQL Server\\100\\Setup Bootstrap\\LOG\\Summary.txt";
		&errme("Check SQL Server log file for details: $log_filename");
		$status = 0;
		last SUB;
	}

	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# removeNodeSQL100


# ----------------------------------------------------------------------
#	resetSQLServicesAccounts		reset SQL Server Services accounts
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	reset SQL Server Services accounts
# ----------------------------------------------------------------------

sub resetSQLServicesAccounts () {
	my $status	= 1;
	my $clusterName = '';
	my $cmd			= '';	# OS command
	my $cnt = 0;
	my $key = '';
	my $envCode			= 'NP';			# Environment code (Examples are: NPSLS, PLSL1).
	my $secGrpLoc		= 'CORP';
	my ($sqlMajorVer, $sqlMinorVer, $sqlSPVer, $sqlVersion);


SUB:
{
	&notifyWSub("Started.");
	# check the SQL Server version	
	$sqlVersion= (&T38lib::Common::pingServer($gNetName) == 0) ?
		&T38lib::Common::getSqlCurVer($gConfigValues{SQLInstanceName}, $gNetName):0;
	($sqlMajorVer, $sqlMinorVer, $sqlSPVer) = split('\.', $sqlVersion);


 	if ($sqlMajorVer <= 9 ) {
		&errme ("Invalid version of SQL Server ($sqlVersion) on $gSrvrName");
		$status = 0; last SUB;
	}

	if (uc($gHostName) ne uc($gNetNodeName)) {
		if ($clusterName = &getWinClusterName($gNetNodeName)) {
			&warnme("Virtual SQL Server $gNetName is not runnning on a current node. Move resource group to current node and run again.");
		} else {
			&warnme("This program cannot change service accounts remotely.");
		}
		$status = 0; $gNWarnings++;
		last SUB;
	}

	foreach $key ((
			'SQLInstallPwdSrvr',
			'SQLInstallPwdDB'
		)) {
		if ( !($gConfigValues{$key}) ) {
			&errme("Configuration variable $key is not valid.");
			$status = 0; last SUB;
		}
	}

	$key = "SecurityGroupLocationDesc_" . $gConfigValues{SecurityGroupLocation};
	$secGrpLoc = $gConfigValues{$key};	# CORP|INET|STORE|...
	$key = "Environment2ChrCode_" . $gConfigValues{EnvironmentType};
	$envCode = $gConfigValues{$key};

	unless ($secGrpLoc && $envCode) {
		&errme("Configuration parameter file is invalid. Check SecurityGroupLocationDesc_x and Environment2ChrCode_x parameters.");
		$status = 0; last SUB;
	}

	# Installer service name is similar to CORPSQLNPSL1INST
	$envCode = $envCode . "SL" . $gConfigValues{SecurityDataSensitivity};

	if ($sqlMajorVer == 10) {
		$cmd = "${gScriptPath}INSTALL\\t38setsqlacct2008.exe " . 
			"-S $gConfigValues{gSQLConnectName} " .
			"-r $gConfigValues{SQLInstallPwdSrvr} " .
			"-d $gConfigValues{SQLInstallPwdDB} " .
			"-l $secGrpLoc " .
			"-e $envCode " .
			"-t 12";
	} else {
		# We should never reach this code, but just in case same check above is deleted.
		&errme ("Invalid version of SQL Server ($sqlVersion) on $gSrvrName");
		$status = 0; last SUB;
	}

	unless(&runOSCmd($cmd)) {
		&errme("Could not change SQL Services accounts with $cmd command.");
		$status = 0; last SUB;
	}

	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# resetSQLServicesAccounts


# ----------------------------------------------------------------------
#	restartSQLServices		restart MSSQL related services
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
#	restart MSSQL related services
# ----------------------------------------------------------------------

sub restartSQLServices () {
	my $status	= 1;
SUB:
{
	if ( $gConfigValues{SQLVirtualName}) {
		$status = restartSQLServicesClus();
		last SUB;
	}
	
	if (uc($gHostName) ne uc($gNetName)) {
		&warnme("Run $gScriptName locally on $gNetName to control services.");
		$gNWarnings++; last SUB;
	}

	if (&T38lib::Common::stopServiceWithDepend($gConfigValues{SQLServiceName}) != 1) { 
		&errme("Cannot stop $gConfigValues{SQLServiceName} service."); 
		$status = 0; last SUB;
	}

	if ( &T38lib::Common::startService($gConfigValues{SQLServiceName}) != 1 ) {
		&errme("Cannot start $gConfigValues{SQLServiceName} service."); 
		$status = 0; last SUB;
	}

	if (&T38lib::Common::startService($gConfigValues{SQLAgentName}) != 1) { 
		&errme("Cannot start $gConfigValues{SQLAgentName} service."); 
		$status = 0; last SUB;
	}


	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# restartSQLServices



# ----------------------------------------------------------------------
#	restartSQLServicesClus	restart MSSQL related services in a cluster
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
#	restart MSSQL related services in a cluster
# ----------------------------------------------------------------------

sub restartSQLServicesClus () {
	my $status		= 1;
	my $clusterName	= 0;
	my $vsName		= $gConfigValues{SQLVirtualName};
	my $cmd			= 0;
	my $cmdout		= 0;
SUB:
{
	unless( $clusterName = &getWinClusterName($vsName)) {
		&errme("Cannot get Cluster Name for virtual server $vsName.");
		$status = 0; last SUB;
	}
	$cmd = "cluster $clusterName group $vsName /offline";
	$cmdout = `$cmd`;
	&notifyWSub ("cmd = $cmd");
	&notifyWSub ("cmdout = $cmdout");
   
	$cmd = "cluster $clusterName group $vsName /online";
	$cmdout = `$cmd`;
	&notifyWSub ("cmd = $cmd");
	&notifyWSub ("cmdout = $cmdout");
	unless ($cmdout =~ /$vsName\s+\S+\s+online/i) {
		&errme("Cannot bring virtual server $vsName online.");
		$status = 0; last SUB;
	}

	sleep 60;
	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# restartSQLServices



# ----------------------------------------------------------------------
#	runPostInstallScripts		Run post install scripts
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	Run post install scripts from Install01 - 99 directories
# ----------------------------------------------------------------------

sub runPostInstallScripts () {
	my $dir	= '';
	my $lcdir	= '';
	my @alldir	= ();
	&notifyWSub("Started.");

	# Find any directory call INSTALL01 through INSTALL99 
	# and run all the scripts in these directories.
	#
	if (opendir(CURDIR, $gScriptPath)) {
		@alldir = readdir (CURDIR);
		closedir(CURDIR);

		foreach $dir (@alldir) {
      		if (-d $dir) {
				$lcdir = lc($dir);
         		if ( ($lcdir =~ /^install\d\d$/) and ($lcdir ne "install00") ) {
					unless (&runScriptsDir("$dir"))	{ return(0); }
         		}
      		}
		}
	}
	else {
		&T38lib::Common::warnme("Can not open directory: $gScriptPath");
		$gNWarnings++;
	}
	&notifyWSub("Done.");
	return(1);
}	# runPostInstallScripts


#------------------------------------------------------------------------------
#	Purpose: Run all the script in the given directory.
#	
#	Input Argumrnt: Directory name or a file name
#	Output:         0 = failure, 1 = success.
#------------------------------------------------------------------------------
sub runScriptsDir($;$) {

	my ($dfName, $noErrorChk ) = @_;

	my $status	= 1;
	my (@scripts) = ();
	my ($progName, $cmdLine, $result, $path, $name, $ext, $outFileName);
	my $curDir = CWD::getcwd(); #Get the cur dir. 
SUB:
{

	&notifyWSub("Started.");

	$dfName = "$gScriptPath" . $dfName;			# Combine the current directory with the post build script directory

	&notifyWSub("Running scripts from $dfName");

	if ( -d "$dfName") {
		unless (opendir(GIVENDIR, $dfName)) {
			&T38lib::Common::warnme("Can not open directory: $dfName");
			$gNWarnings++;
			last SUB;
		}
		#Change the directory to the post build script directory.
		unless(chdir($dfName)){
			&T38lib::Common::warnme("Cannot set directory to: $dfName");
			$gNWarnings++;
			last SUB;
		}
		
		foreach (readdir (GIVENDIR)) {
			unless (-d "$dfName\\$_") {				# File is not a directory
				push (@scripts, "$dfName\\$_");		# Push only the file name not the path
			}
		}
		closedir(GIVENDIR);
	}
	elsif ( -s "$dfName") {
		push (@scripts, $dfName);			
	}
	else {
		&warnme("Invalid program to run: $dfName");
		$gNWarnings++;
		last SUB;
	}

	@scripts = sort(@scripts);

	if ( defined (@scripts) ) {
		foreach $progName (@scripts) {

			($name,$path,$ext) = fileparse("$progName","");
			$name =~ /\.([^\.]+)$/;
			$ext = lc($1);
	    	$ext =~ s/^\s*//g;							# Remove all leading white spaces
	    	$ext =~ s/\s*$//g;							# Remove all trailing white spaces

			if ( ($ext eq "bat") or ( $ext eq "cmd") or ($ext eq "exe") ) {
				if (uc($gHostName) ne uc($gNetName)) {
					&warnme("Run $gScriptName locally on $gNetName to execute $progName.");
					$gNWarnings++;
					next;
				}
				$cmdLine = "$progName";
				$result = system("cmd /C start /wait $cmdLine");

				if ( $result == 0 ) {
					&notifyWSub("Command = $cmdLine");
					&notifyWSub("result code from system command = $result");
					&notifyWSub("script ran successfully");
				}
				else {
					&notifyWSub("Command = $cmdLine");
					&notifyWSub("result code from system command = $result");
					&warnme("script failed"); $gNWarnings++;
					$status = 0; last SUB;
				}
			}
			elsif ( $ext eq "pl" ) {
				if (uc($gHostName) ne uc($gNetName)) {
					&warnme("Run $gScriptName locally on $gNetName to execute $progName.");
					$gNWarnings++;
					next;
				}
				$cmdLine = "perl $progName";
				$result = system("cmd /C start /wait $cmdLine");

				if ( $result == 0 ) {
					&notifyWSub("Command = $cmdLine");
					&notifyWSub("result code from system command = $result");
					&notifyWSub("script ran successfully");
				}
				else {
					&notifyWSub("Command = $cmdLine");
					&notifyWSub("result code from system command = $result");
					&errme("script failed");
					$status = 0; last SUB;
				}
			} elsif ( $ext eq "sql" ) {
				($name,$path,$ext) = fileparse("$progName","\.sql");
				$outFileName = $path . $name . "\.out";
				$cmdLine = "sqlcmd -E -S$gConfigValues{gSQLConnectName} -i$progName -o$outFileName -w 2048";
				$result = system("cmd /C start /wait $cmdLine");

				if ( $result == 0 ) {
					&notifyWSub("Command = $cmdLine");
					&notifyWSub("result code from system command = $result");
					&notifyWSub("script ran successfully");
				} else {
					&notifyWSub("Command = $cmdLine");
					&notifyMe("result code from system command = $result");
					&errme("script failed");
					$status = 0; last SUB;
				}

				if ($noErrorChk) {
					next;
				}

				unless (open(OUTFILE, "<$outFileName")) { 
					&errme("Cannot open file $outFileName for reading. $!"); 
					$status = 0; last SUB;
				}

				&notifyWSub("Checking $outFileName for errors.");

				while (<OUTFILE>) {
					if ( (/Msg\s+\d+/i) || (/Error:\s+\d+/i) || (/SQL Server does not exist/i) || (/access denied\./i) ) {
						&errme("Error found at $. running $progName, script terminated");
						&errme("View $outFileName for information");
						$status = 0; last SUB;
					}	
				}	
				&notifyWSub("No error found in $outFileName");

			} else {
				&notifyWSub("Invalid program ext to run: $progName");
				&notifyWSub("extension is $ext");
			}
		}
	}
	#Change the directory back to the original working dir ex: C:\DBINST\SX01DBA01
	unless(chdir($curDir)){
		&T38lib::Common::warnme("Cannot set directory to: $curDir");
		$gNWarnings++;
		last SUB;
	}
		
	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);

}	# End of runScriptsDir


# ----------------------------------------------------------------------
#	setEnvPath		set environment path
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
#	Set environment path
# ----------------------------------------------------------------------

sub setEnvPath () {
	my $status	= 1;
	my $envPath	= '';
SUB:
{
	&notifyWSub("Started.");
	# Get path information from registry and set environment variable PATH
	#
	$envPath = &T38lib::Common::getEnvPathVar();
	if ( ($envPath != -1) or ($envPath ne $T38ERROR) ) {
		$ENV{"PATH"} = $envPath;
	}
	else {
		&errme("Error getting the Full Path. fullPath = $envPath");
		$status = 0; last SUB;
	}


	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status. Path: $envPath.");
	return($status);
}	# setEnvPath


# ----------------------------------------------------------------------
#	startSQLServices		start critical MSSQL related services
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
#	start MSSQL related services
# ----------------------------------------------------------------------

sub startSQLServices () {
	my $status	= 1;
	my $clusterName	= 0;
	my $vsName		= $gConfigValues{SQLVirtualName};
	my $cmd			= 0;
	my $cmdout		= 0;
SUB:
{
	if ( $gConfigValues{SQLVirtualName}) {
		unless( $clusterName = &getWinClusterName($vsName)) {
			&errme("Cannot get Cluster Name for virtual server $vsName.");
			$status = 0; last SUB;
		}
		$cmd = "cluster $clusterName group $vsName /online";
		$cmdout = `$cmd`;
		&notifyWSub ("cmd = $cmd");
		&notifyWSub ("cmdout = $cmdout");
		unless ($cmdout =~ /$vsName\s+\S+\s+online/i) {
			&errme("Cannot bring virtual server $vsName online.");
			$status = 0; last SUB;
		}
	} else {
		if ( &T38lib::Common::startService($gConfigValues{SQLServiceName}, $gNetName) != 1 ) {
			&errme("Cannot start $gConfigValues{SQLServiceName} service."); 
			$status = 0; last SUB;
		}

		if (&T38lib::Common::startService($gConfigValues{SQLAgentName}, $gNetName) != 1) { 
			&errme("Cannot start $gConfigValues{SQLAgentName} service."); 
			$status = 0; last SUB;
		}
	}

	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# startSQLServices



# ----------------------------------------------------------------------
#	stopSQLServices		stop critical MSSQL related services
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
#	stop MSSQL related services
# ----------------------------------------------------------------------

sub stopSQLServices () {
	my $status	= 1;
SUB:
{
	if ( $gConfigValues{SQLVirtualName}) {
		unless( &T38lib::Common::clusGrpSrvcsStop($gConfigValues{SQLVirtualName})) {
			&errme("Cannot stop SQL Server services for virtual server $gConfigValues{SQLVirtualName}.");
			$status = 0; last SUB;
		}
	} else {
		if ( &T38lib::Common::stopServiceWithDepend($gConfigValues{SQLFTEName}, $gNetName) ) {
			&notifyWSub("$gConfigValues{SQLFTEName} STOPED");
		} else {
			&errme("$gConfigValues{SQLServiceName} NOT STOPED");
			$status = 0; last SUB;
		}
		
		if ( &T38lib::Common::stopServiceWithDepend($gConfigValues{SQLServiceName}, $gNetName) ) {
			&notifyWSub("$gConfigValues{SQLServiceName} STOPED");
		} else {
			&errme("$gConfigValues{SQLServiceName} NOT STOPED");
			$status = 0; last SUB;
		}
	}

	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# stopSQLServices



#------------------------------------------------------------------------------
#	Purpose: Test all the configuration parameters to make sure they are there
#            Future processing relies on these parameters.
#------------------------------------------------------------------------------
sub testConfigParm() {

	my $status 	= 1; 				# initialize $status to no errors found
	my $hkey	= '';
	my (@DbNames) = ();
	my $db = '';

	&notifyWSub("START - Validating configuration parameter.");
  
	if (defined ($gConfigValues{"T38LIST:$gincludeCfgParm"}) ) {
		push (@DbNames, @{$gConfigValues{"T38LIST:$gincludeCfgParm"}});
	}

	foreach $db (@DbNames) {
    	if  ($gConfigValues{"USERDB:DataSize:$db"} eq "") {
			&errme("Configuration variable USERDB:DataSize:$db is undefined in cfg file");
			$status = 0;
		}

    	if  ($gConfigValues{"USERDB:LogSize:$db"} eq "") {
			&errme("Configuration variable USERDB:LogSize:$db is undefined in cfg file");
			$status = 0;
		}

    	if  ($gConfigValues{"USERDB:TruncLog:$db"} eq "") {
			&errme("Configuration variable USERDB:TruncLog:$db is undefined in cfg file");
			$status = 0;
		}
		
    	if  ($gConfigValues{"USERDB:SelectInto:$db"} eq "") {
			&errme("Configuration variable USERDB:SelectInto:$db is undefined in cfg file");
			$status = 0;
		}

    	if  ($gConfigValues{"USERDB:DBCreator:$db"} eq "") {
			&errme("Configuration variable USERDB:DBCreator:$db is undefined in cfg file");
			$status = 0;
		}

    	if  ($gConfigValues{"USERDB:DBCreator:$db"} eq "") {
			&errme("Configuration variable USERDB:DBCreator:$db is undefined in cfg file");
			$status = 0;
		}

    	if  ($gConfigValues{"USERDB:AppName:$db"} eq "") {
			&errme("Configuration variable USERDB:AppName:$db is undefined in cfg file");
			$status = 0;
		}

    	if  ($gConfigValues{"USERDB:DBDesc:$db"} eq "") {
			&errme("Configuration variable USERDB:DBDesc:$db is undefined in cfg file");
			$status = 0;
		}
	}

    if ( ($gConfigValues{EnvironmentType} eq "") || ($gConfigValues{EnvironmentType} !~ /[a-z]/i) )  { 	
		&errme("Configuration variable EnvironmentType is undefined in cfg file.");
		$status = 0;
	}

    if ( !defined($gConfigValues{SecurityGroupLocation} ) || (!$gConfigValues{SecurityGroupLocation} ) )  {
		$gConfigValues{SecurityGroupLocation} = 'C';
		$hkey = "SecurityGroupLocationDesc_" . $gConfigValues{SecurityGroupLocation};
		if ( !defined($gConfigValues{$hkey}) ) {
			$gConfigValues{$hkey} = "CORP";
		}
	} else {
		$hkey = "SecurityGroupLocationDesc_" . $gConfigValues{SecurityGroupLocation};
		if ( !defined($gConfigValues{$hkey}) ) {
			&errme("Configuration variable $hkey is undefined in cfg file.");
			$status = 0;
		}
	}

    if ( !defined($gConfigValues{SecurityDataSensitivity} ) || (!$gConfigValues{SecurityDataSensitivity} ) )  {
		$gConfigValues{SecurityDataSensitivity} = 'S';
	}
	
    if ( ($gConfigValues{DumpDevicesDrive} eq "") || ($gConfigValues{DumpDevicesDrive} !~ /[a-z]/i) ) {
		&errme("Configuration variable DumpDevicesDrive is undefined in cfg file.");
		$status = 0;
	}

   if ( ($gConfigValues{MdfDrive} eq "") || ($gConfigValues{MdfDrive} !~ /[a-z]/i) ) { 	
		&errme("Configuration variable MdfDrive is undefined in cfg file.");
		$status = 0;
	}

    if ( ($gConfigValues{NdfDrive} eq "") || ($gConfigValues{NdfDrive} !~ /[a-z]/i) ) { 	
		&errme("Configuration variable NdfDrive is undefined in cfg file.");
		$status = 0;
	}

    if ( ($gConfigValues{LdfDrive} eq "") || ($gConfigValues{LdfDrive} !~ /[a-z]/i) ) { 	
		&errme("Configuration variable LdfDrive is undefined in cfg file.");
		$status = 0;
	}

    if ( ($gConfigValues{TrcDrive} eq "") || ($gConfigValues{TrcDrive} !~ /[a-z]/i) ) { 	
		&errme("Configuration variable TrcDrive is undefined in cfg file.");
		$status = 0;
	}

    if ( ($gConfigValues{TmpDrive} eq "") || ($gConfigValues{TmpDrive} !~ /[a-z]/i) ) { 	
		&errme("Configuration variable TmpDrive is undefined in cfg file.");
		$status = 0;
	}

    if ( ($gConfigValues{SQLDataRootDrive} eq "") || ($gConfigValues{SQLDataRootDrive} !~ /[a-z]/i) ) { 	
		&errme("Configuration variable SQLDataRootDrive is undefined in cfg file.");
		$status = 0;
	}

    if ( ($gConfigValues{DBAUtilsDrive} eq "") || ($gConfigValues{DBAUtilsDrive} !~ /[a-z]/i) ) { 	
		&errme("Configuration variable SQLDataRootDrive is undefined in cfg file.");
		$status = 0;
	}

    if ( ($gConfigValues{SQLAppDrive} eq "") || ($gConfigValues{SQLAppDrive} !~ /[a-z]/i) ) { 	
		&errme("Configuration variable SQLAppDrive is undefined in cfg file.");
		$status = 0;
	}

	if ( ($gConfigValues{SQLInstanceName}) and ($gConfigValues{SQLInstanceName} =~ /\s/) ) {
		&errme("Configuration variable SQLInstanceName is not valid.");
		$status = 0;
	}

	if ( ($gConfigValues{SQLVirtualName}) and ($gConfigValues{SQLVirtualName} =~ /\s/) ) {
		&errme("Configuration variable SQLVirtualName is not valid.");
		$status = 0;
	}

	if ( ($gConfigValues{SQLVirtualName}) and (!$gConfigValues{SQLInstanceName}) ) {
		#Hemanth: Possibly need to add the default instance logic here.
		#something to the effect of $gConfigValues{SQLInstanceName} = 'MSSQLSERVER'
		&errme("Cannot install cluster virtual server $gConfigValues{SQLVirtualName} with default instance name.");
		$status = 0;
	}

	# T38dba cfg file check
	#
	if ($gConfigValues{SQLSrvrEdition} !~ /^(server|enterprise)$/i) {
		&errme("Configuration variable SQLSrvrEdition is missing or invalid in cfg file.");
		$status = 0;
	}

	if ($gConfigValues{SortOrder} eq "") {
		&errme("Configuration variable SortOrder is undefined in cfg file.");
		$status = 0;
	}

	if ($gConfigValues{CharSet} eq "") {
		&errme("Configuration variable CharSet is undefined in cfg file.");
		$status = 0;
	}

	if ($gConfigValues{CaseSensitive} eq "") {
		&errme("Configuration variable CaseSensitive is undefined in cfg file.");
		$status = 0;
	}

	if ( ! (defined ($gCharSO{$gConfigValues{SortOrder}}{$gConfigValues{CharSet}}{$gConfigValues{CaseSensitive}})) ) {
		&errme("Invalid collation (SortOrder=$gConfigValues{SortOrder}, CharSet=$gConfigValues{CharSet}, CaseSensitive=$gConfigValues{CaseSensitive}) ");
		&errme("combination is defined in cfg file.");
		$status = 0;
	}

	if (defined ($gConfigValues{SQLMemory}) ) {
		&errme("Configuration variable SQLMemory is used in OLD T38DBA.cfg File.");
		&errme("Use the NEW T38DBA.cfg File form PVCS");
		$status = 0;
	}

	if ($gConfigValues{SQLMinMemory} eq "") {
		&errme("Configuration variable SQLMinMemory is undefined in cfg file.");
		$status = 0;
	}

	if ($gConfigValues{SQLMaxMemory} eq "") {
		&errme("Configuration variable SQLMaxMemory is undefined in cfg file.");
		$status = 0;
	}

	if ($gConfigValues{OSMemory} eq "") {
		&errme("Configuration variable OSMemory is undefined in cfg file.");
		$status = 0;
	}

	if ($gConfigValues{RebootFlag} eq "") {
		$gConfigValues{RebootFlag} = "N";
	}

	if ($gConfigValues{DumpDevicesPath} eq "") {
		&errme("Configuration variable DumpDevicesPath is undefined in cfg file.");
		$status = 0;
	}

	if ($gConfigValues{MdfPath} eq "") {
		&errme("Configuration variable MdfPath is undefined in cfg file.");
		$status = 0;
	}

	if ($gConfigValues{NdfPath} eq "") {
		&errme("Configuration variable NdfPath is undefined in cfg file.");
		$status = 0;
	}

	if ($gConfigValues{LdfPath} eq "") {
		&errme("Configuration variable LdfPath is undefined in cfg file.");
		$status = 0;
	}

	if ($gConfigValues{TrcPath} eq "") {
		&errme("Configuration variable TrcPath is undefined in cfg file.");
		$status = 0;
	}

	if ($gConfigValues{TmpPath} eq "") {
		&errme("Configuration variable TmpPath is undefined in cfg file.");
		$status = 0;
	}

	if ($gConfigValues{SQLDataRootPath} eq "") {
		&errme("Configuration variable SQLDataRootPath is undefined in cfg file.");
		$status = 0;
	}

	if ($gConfigValues{DBAUtilsPath} eq "") {
		&errme("Configuration variable DBAUtilsPath is undefined in cfg file.");
		$status = 0;
	}

	if ($gConfigValues{DBAUtilsPath} !~ /^\\/) {
		&errme("Configuration variable DBAUtilsPath is invalid in cfg file. Path has to start at the root (\\)");
		$status = 0;
	}

	if ($gConfigValues{SQLAppPath} eq "") {
		&errme("Configuration variable SQLAppPath is undefined in cfg file.");
		$status = 0;
	}

	if ($gConfigValues{SQLInstallPath} eq "") {
		&errme("Configuration variable SQLInstallPath is undefined in cfg file.");
		$status = 0;
	}

	if ($gConfigValues{__SharePointDumpDevicesPath} eq "") {
		&errme("Configuration variable __SharePointDumpDevicesPath is undefined in cfg file.");
		$status = 0;
	}

	if ($gConfigValues{__SharePointMdfPath} eq "") {
		&errme("Configuration variable __SharePointMdfPath is undefined in cfg file.");
		$status = 0;
	}

	if ($gConfigValues{__SharePointNdfPath} eq "") {
		&errme("Configuration variable __SharePointNdfPath is undefined in cfg file.");
		$status = 0;
	}

	if ($gConfigValues{__SharePointLdfPath} eq "") {
		&errme("Configuration variable __SharePointLdfPath is undefined in cfg file.");
		$status = 0;
	}

	if ($gConfigValues{__SharePointTrcPath} eq "") {
		&errme("Configuration variable __SharePointTrcPath is undefined in cfg file.");
		$status = 0;
	}

	if ($gConfigValues{__SharePointTmpPath} eq "") {
		&errme("Configuration variable __SharePointTmpPath is undefined in cfg file.");
		$status = 0;
	}

	if ($gConfigValues{__SharePointSQLDataRootPath} eq "") {
		&errme("Configuration variable __SharePointSQLDataRootPath is undefined in cfg file.");
		$status = 0;
	}

	if ($gConfigValues{__SharePointDBAUtilsPath} eq "") {
		&errme("Configuration variable __SharePointDBAUtilsPath is undefined in cfg file.");
		$status = 0;
	}

	if ($gConfigValues{__SharePointSQLAppPath} eq "") {
		&errme("Configuration variable __SharePointSQLAppPath is undefined in cfg file.");
		$status = 0;
	}

	if ($gConfigValues{SQLServiceName} eq "") {
		&errme("Configuration variable SQLServiceName is undefined in cfg file.");
		$status = 0;
	}
	if ($gConfigValues{SQLServiceVersion} eq "") {
		&errme("Configuration variable SQLServiceVersion is undefined in cfg file.");
		$status = 0;
	}
	if ($gConfigValues{SQLAgentName} eq "") {
		&errme("Configuration variable SQLAgentName is undefined in cfg file.");
		$status = 0;
	}
	
	if ($status == 0) {
		&errme("Missing/Invalid configuration parameters. CHECK CFG FILES");
	}

	&notifyWSub("DONE - Validating configuration parameter.");
	return($status);
} # end sub testConfigParm


# ----------------------------------------------------------------------
#	upgradeSQL	upgrade SQL Server
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
#	Upgrade SQL Server
# ----------------------------------------------------------------------

sub upgradeSQL () {
	my $status	= 1;
SUB:
{
	&notifyWSub("Started.");

	if ($gConfigValues{SQLServiceVersion} =~ /^10\.0\./) {
		# SQL 10 install.
		$status = &upgrade2SQL100Server();
		last SUB;
	}

}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# upgradeSQL


# ----------------------------------------------------------------------
#	upgrade2SQL100Server		Upgrade to SQL 2008
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
#	Upgrade to SQL Server 2008 
# ----------------------------------------------------------------------

sub upgrade2SQL100Server () {
	my $status	= 1;
	my $setupExe		= 'setup.exe';		;# Actual Path to SQL Server install Program
	my $setupPath		= '.\\';
	my $sqlInstCfgTpl	= 'ConfigurationFile.SlipStream.UpgradeCluster.tpl.ini';
	my $sqlInstCfgIni	= "ConfigurationFile.SlipStream.UpgradeCluster.${gNetName}_${gInstName}.ini";
	my $sqlInstCUCfgTpl	= 'ConfigurationFile.SlipStreamCU.UpgradeCluster.tpl.ini';
	my $sqlInstCUCfgIni	= "ConfigurationFile.SlipStreamCU.UpgradeCluster.${gNetName}_${gInstName}.ini";
	my $installCUFlg	= 0;	# Run Cumulative Update install.
 	my $result			= 0;
	my $log_filename	= '';
	my $serviceName		= '';
	my $cmd				= '';	# OS command
	my $cnt				= 0;
 	my @ServicestoStop	= ();
	my @tmp 			= ();
	my $keyName			= '';
SUB:
{
	if ($gConfigValues{SQLVirtualName}) {
		my $checkNodeInVGroupStat = -1;
		unless ($checkNodeInVGroupStat = &checkNodeInVGroup($gHostName)) {
			&errme("Cannot check if current node is in owners list for SQL Resource group $gConfigValues{SQLVirtualName}");
			$status = 0; last SUB;
			&warnme("This program cannot install SQL Server remotely. Current node $gHostName has to be one of the owners for resource group $gConfigValues{SQLVirtualName}");
			$gNWarnings++;
			last SUB;
		}
		unless ($gClustSqlInstallStat == 1 || $gClustSqlInstallStat == 2 || $gClustSqlInstallStat == 3) {
			&errme("To upgrade, older Version of Microsoft SQL Server has to be installed on $gSrvrName. Check if version older than SQL 2008 is installed on the current node.");
			$status = 0; last SUB;
		}
	} elsif (uc($gHostName) ne uc($gNetNodeName)) {		
		# This check will apply to non-clustered install.
		&warnme("This program cannot install SQL Server remotely.");
		$gNWarnings++;
		$status = 0; last SUB;
	}

	if (!($gConfigValues{SPVersion}) || ($gConfigValues{SQLServiceVersion} eq $gConfigValues{SPVersion})) {
		&warnme("This program can install RTM version of SQL Server at this time. We can only install SlipStream Service Pack.");
		$gNWarnings++;
		$status = 0; last SUB;
	}
	
	&notifyWSub("START - Upgrade to SQL Server.");

	# Setup SQL 2008 global parameters.

	unless (&getSQLInstallSetupExe100(\$setupPath, \$setupExe, \$installCUFlg)) { $status = 0; last SUB; }
	if ($installCUFlg) {
		$sqlInstCfgTpl = $sqlInstCUCfgTpl;
		$sqlInstCfgIni = $sqlInstCUCfgIni;
	}

	$gConfigValues{gIssSQLSetupPath} = $setupPath;

	# if setup90iss.tpl file is not found display error and quit the program
	#
	unless (-s "${gScriptPath}install\\${sqlInstCfgTpl}" ) {
		&errme("Cannot find file ${gScriptPath}install\\${sqlInstCfgTpl}" );
		$status = 0; last SUB;
	}
	
	# build the setup.iss for an un-attend sql server installation
	unless (&buildSetup($sqlInstCfgTpl, $sqlInstCfgIni ))	{ $status = 0; last SUB; }

	# Stop required services.
	@ServicestoStop = split('\,', $gConfigValues{ServicesDown});

	foreach $serviceName (@ServicestoStop) {
		$tmp[$cnt] = &T38lib::Common::stripWhitespace($serviceName);
		$cnt += 1;
	}
	@ServicestoStop = @tmp;

	foreach $serviceName (@ServicestoStop) {
		&T38lib::Common::stopServiceWithDepend($serviceName);
	}

	# Run SQL Server setup command.

  	&notifyWSub("preparing to install SQL Server.");
	$log_filename=$ENV{ProgramFiles} . "\\Microsoft SQL Server\\100\\Setup Bootstrap\\LOG\\Summary.txt";
	&notifyWSub("SQL Setup Install log file: $log_filename");

	$cmd = "\"$setupExe\" /q /Configurationfile=\"${gScriptPath}INSTALLWRK\\$sqlInstCfgIni\"";

	&notifyWSub("Starting installation of SQL Server 2008. Command line is:\ncmd /C $cmd");
	$result = system("cmd /C $cmd");
	$cmd = '';

	&notifyWSub("SQL Server 2008 setup program finished.");

	&notifyWSub("return code of the setup command = $result");

	if ( $result == 0 ) {
		&notifyWSub("Upgrade of SQL Server successful.");
		unless(&setEnvPath())	{ $status = 0; last SUB; } 
	} else {
		&errme("Upgrade of SQL Server failed. Check $log_filename.");
		$status = 0; last SUB;
	}					

	&notifyWSub("DONE  - Upgrade SQL Server 2008.");

	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# upgrade2SQL100Server



# ----------------------------------------------------------------------
#	verifyADGroupName		verify Active Directory group name
# ----------------------------------------------------------------------
#	arguments:
#		grpName	active directory group name
#	return:
#		(adGrpName, ADsPath):	success
#		(0, 0):			fail
# ----------------------------------------------------------------------
#	verify Active Directory group name
# ----------------------------------------------------------------------

sub verifyADGroupName ($) {
	my $grpName		= shift;
	my $adHndl		= 0;		# ADO connection object handle
	my $sqlerr		= 0;
	my $ADsPath		= 0;
	my $adGrpName	= 0;
	my $domName		= &T38lib::Common::stripWhitespace($T38lib::t38cfgfile::gConfigValues{ADPath});
	my @adrs		= ();		# Active directory result set
SUB:
{
	&notifyWSub("verifyADGroupName $grpName");
	unless ($domName =~ s|(LDAP://[^/]+)/.*$|$1|) {
		&errme("Invalid active directory path ADPath = <$domName> in configuration file.");
		last SUB;
	}


	if ( ($adHndl = &adConnect()) == 0 ) {
		&errme("Can not get a connection to Active Directory.");
		last SUB;
	}
	
	unless( execSQL2Arr($adHndl, 
		"select name, ADsPath " .
		"from '$domName' " .
		"Where " .
		" name = '" . $grpName . "' " .
		"",
		\@adrs,
	)) { last SUB; }
	$ADsPath	= $adrs[0]{ADsPath}	if ($adrs[0]{ADsPath});
	$adGrpName	=$adrs[0] {name}	if ($adrs[0]{name});

	last SUB;
}	# SUB
# ExitPoint:
	# close the data source .
	if ($adHndl)	{ $adHndl->Close(); $adHndl = 0; }

	&notifyWSub("verifyADGroupName finised. Result is ($adGrpName, $ADsPath).");
	return($adGrpName, $ADsPath);
}	# verifyADGroupName


# ----------------------------------------------------------------------
#	verifyDiskResClus		verify Disk Resources are using standard
#							names in a cluster group
# ----------------------------------------------------------------------
#	arguments:
#		$clusterName	cluster name
#		$resGrp			resource group name
#		\$diskResName	Disk Resource Name
#	return:
#		1:	success
#		0:	fail
# ----------------------------------------------------------------------
#	Verify Disk Resources are using standard names in a cluster group.
#	This subroutine verifies that Disk resource name in a cluster is
#	using standard naming conventions:
#	Resources with type of the "Physical Disk" will be named "Disk X:",
#	where X is drive letter for the disk.
#	Resources with type of the "Volume Manager Disk Group" will use one
#	of the following nameing conventions:
#	1) Same as "Physical Disk" type resource "Disk X:",
#	where X is drive letter for the disk.
#	2) "RGroupName Disk", where RGroupName is resource group name. This 
#	resource group will be set for all Physical Disks that belong to that
#	resource group.
#
#	Subroutine will validate the following conditions:
#	- Resource group has to contain at least one resource of type
#		"Physical Disk" or "Volume Manager Disk Group".
#	- Resource group cannot contain both "Physical Disk" and
#		"Volume Manager Disk Group" resources.
#	- If Only one "Volume Manager Disk Group" resource is created in
#		resource group, it's name will be returned by the subroutine.
#	- If Multiple "Volume Manager Disk Group" resource are created in
#		resource group, they have to use the "Disk X:" convention.
#	- Multiple "Physical Disk" resource can be created in resource group,
#		using the "Disk X:" convention.
#	- "Physical Disk" resource has to be named "Disk X:", where X is one
#		character drive name.
#	If resource type for disk is "Volume Manager Disk Group", and there is
#	only one resource of this type, subroutine
#	will set $diskResName to the name of the resource, otherwise it is null.
#	If any validation failed, returned status is 0.
# ----------------------------------------------------------------------

sub verifyDiskResClus ($$\$) {
	my $clusterName	= shift;
	my $resGrp		= shift;
	my $refDiskName	= shift;
	my $resDiskName	= '';
	my $nPhyDisk	= 0;		# Number of physical disk resources.
	my $nVMDisk		= 0;		# Number of volume manager disk resources.
	my $nVMDiskOld	= 0;		# Number of volume manager disk resources with old naming convention "RVT1DB1 Disk".
	my @allRes		= ();
	my $resResult	= 0;
	my $resName		= 0;
	my $nodeName	= 0;
	my $resStatus	= 0;
	my $resDiskType	= 0;
	my $status		= 1;
SUB:
{
	&notifyWSub("Started.");

	@allRes = `cmd.exe /C CLUSTER $clusterName RESOURCE`;
	foreach (@allRes) {
		($resName, $nodeName, $resStatus) = 0;
		if (/^(.*)$resGrp\s+(\S+)\s+(\S+)\s*$/i) {
			($resName, $nodeName, $resStatus) = ($1, $2, $3);
			$resName = &T38lib::Common::stripWhitespace($resName);
			# Debug: &notifyMe("Resource Name: $resName, Node: $nodeName, Resource Status: $resStatus.");

			$resResult = `cmd.exe /C CLUSTER $clusterName RESOURCE \"$resName\" /prop`;
			# Get SQL Server Cluster resource Disk. Look for result line
			# S  Disk O:              Type                           Physical Disk

			if (($resName !~ /^Disk .: MP/) # Skip mount points
				&& ($resResult =~ /\nS\s+$resName\s+Type\s+(Physical Disk|Volume Manager Disk Group)/i) ) {
				$resDiskType = $1;
				&notifyMe("Disk Resource \"$resName\" is found with resource type of $resDiskType");
				if ($resDiskType eq 'Volume Manager Disk Group') {
					$nVMDisk++;
					if ($resName =~ /^$resGrp Disk$/i) {
						# Old standard for Volume Manager Disk was to use disk name such as "RVT1DB1 Disk"
						$nVMDiskOld++;
						$resDiskName = $resName;
					} elsif ($resName !~ /^Disk [A-Z]:$/i) {
						&warnme("Volume manager disk $resName has invalid name in Resource group $resGrp. Name has to be formated as \"Disk X:\", where X is drive name.");
						$gNWarnings++; $status = 0;
					}
				} else {
					$nPhyDisk++;
					if ($resName !~ /^Disk [A-Z]:$/i) {
						&warnme("Physical disk $resName has invalid name in Resource group $resGrp. Name has to be formated as \"Disk X:\", where X is drive name.");
						$gNWarnings++; $status = 0;
					}
				}
			}
		}
	}

	# Validate disk resources are setup correctly.

	if ($nVMDisk == 0 && $nPhyDisk == 0) {
		&warnme("Resource group $resGrp does not have Physical Disk or Volume Manager Disk Group resources. Add disk resources to the group.");
		$gNWarnings++; $status = 0; last SUB;
	}

	if ($nVMDisk != 0 && $nPhyDisk != 0) {
		&warnme("Resource group $resGrp has both Physical Disk and Volume Manager Disk Group resources. Program doesn't know which resource type to use.");
		$gNWarnings++; $status = 0; last SUB;
	}

	if ($nVMDiskOld > 1) {
		&warnme("Resource group $resGrp has more then one Volume Manager Disk Group resource. Program doesn't know which disk resource to use.");
		$gNWarnings++; $status = 0; last SUB;
	}
	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	$$refDiskName = $resDiskName	if ($status == 1 && $resDiskName);
	return($status);
}	# verifyDiskResClus




# ----------------------------------------------------------------------
# housekeeping
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	Perform the initial housekeeping chores.
# ----------------------------------------------------------------------

sub housekeeping() { 

	my $scriptSuffix;
	my $numArchive = 7;
	my $status = 1;

	$gScriptName	= "";			# Base name of the current script.
	$gScriptPath	= ".\\";		# Directory path to current script.


	($gScriptPath, $gScriptName, $scriptSuffix) = &T38lib::Common::parseProgramName();

	#-- initialize standard options

	getopts('ha:S:x:');

	$gHostName	= uc(Win32::NodeName());
	$gSrvrName	= $gHostName;	# SQL Server name
	$gNetName	= $gHostName;	# SQL Server machine name
	$gInstName	= '';			# SQL Server instance name
	$gNWarnings	= 0;

	#-- program specific initialization

	$gRunOpt		= '';

	#-- show help

	if ($Getopt::Std::opt_h) { &showHelp(); exit; }

	# Open log and error files, if needed.

	SUB: {
		unless (&T38lib::Common::setLogFileDir("${gScriptPath}T38LOG")) {
			&errme("Cannot set program log directory.");
			$status = 0;
			last SUB;
		}

		if($Getopt::Std::opt_a) {
				if ( $Getopt::Std::opt_a =~ /\d/) {
					if ( ($Getopt::Std::opt_a < 101) and ($Getopt::Std::opt_a > 0) ) {
						$numArchive = $Getopt::Std::opt_a;
					}
				}
			}

		&T38lib::Common::archiveLogFile($numArchive);
		&logme("Starting $gScriptName from $gScriptPath on $gHostName server.", "started");
		&notifyWSub("Domain Name: " . &Win32::DomainName() . " User Name: " . &Win32::LoginName());
		&notifyWSub("Current directory: " .  &Win32::GetCwd());

		&notifyWSub("Checking logged on users for $gHostName.");
		my %users	= ();
		my $key	= '';
		Win32::NetAdmin::LoggedOnUsers($gHostName, \%users);
		foreach $key (keys %users) {
			&notifyWSub("Users($key): $users{$key}");
		}

		if($Getopt::Std::opt_x) {
			if ($Getopt::Std::opt_x =~ /^[acdfghimnlprstuy9]+$/) {
				$gRunOpt = $Getopt::Std::opt_x;
			} else {
				&errme("Invalid -x options. Allowed values are acdfghimnlprstuy9.");
				$status = 0;
				last SUB;
			}
		}

		if ($Getopt::Std::opt_S) {
			$gSrvrName	= uc($Getopt::Std::opt_S);
			$gSrvrName	=~ s/^\./$gHostName/;
			($gNetName, $gInstName)	=	split("\\\\", $gSrvrName);
			$gInstName =~ s/^\s+//g; $gInstName =~ s/\s+$//g;
		}

		if ($#ARGV < 0 ) {
			&showHelp();
			&errme("Missing configuration file.");
			$status = 0;
			last SUB;
		} else {
			# Expand command line arguments, perform globbing.
			# If command line contain any wild characters then expand 
			#
			@gArg = &T38lib::Common::globbing(@ARGV);
			if ( $gArg[0] ne $T38ERROR ) {
				@ARGV = @gArg;
			} else {
				&warnme("Globbing of Command line argument failed");
				$status = 0; last SUB;
			}
		}	# endif $#ARGV != 0

		# Check Perl version.

		unless ( &T38lib::Common::chkPerlVer() ) {
			&notifyWSub("Wrong version of Perl!");
			&notifyWSub("This program run on Perl version 5.005 and higher.");
			&notifyWSub("Check the Perl version by running perl -v on command line.");
			$status = 0;
			last SUB;
		}

		# Check existence of commonly used files.

		# Check for rmtshare.exe file in the path.  If this file is not found then
		# exit the program with error. 
		# This is a utility program came with NT Resource Kit which is needed for the
		# Install program to work properly.
		#
		my $fileverexe	= &T38lib::Common::whence("rmtshare.exe");
		unless ($fileverexe) {
			&errme("Can not find rmtshare.exe file.");
			&T38lib::Common::notifyWSub("Make sure rmtshare.exe file located in path variable directories.");
			$status = 0;
		}

		# Check for sc.exe file in the path.  If this file is not found then
		# exit the program with error. 
		#
		$fileverexe	= &T38lib::Common::whence("sc.exe");
		unless ($fileverexe) {
			&errme("Can not find sc.exe file.");
			&T38lib::Common::notifyWSub("Make sure sc.exe file located in path variable directories.");
			$status = 0;
		}

		# Check for ntrights.exe file in the path. If this file is not found
		# then exit the program with error.
		#
		$fileverexe	= &T38lib::Common::whence("ntrights.exe");
		unless ($fileverexe) {
			&errme("Can not find ntrights.exe file.");
			&T38lib::Common::notifyWSub("Make sure ntrights.exe file located in path variable directories.");
			$status = 0;
		}

		last SUB	unless $status;

		# If program is running second time in same session, preset environment path will not in
		# newly installed SQL Server path. Set it based on what is in global environment.
		unless(&setEnvPath())	{ $status = 0; last SUB; } 

		# Prepare configuration parameters.
		unless(&prepareConfigParms())	{ $status = 0; last SUB; }

		# Setup $gSrvrName to match config file.
		
		if ($gConfigValues{SQLVirtualName} ) {

			# Validate all parameters if installing for a cluster server.

			unless ($gConfigValues{SQLInstanceName} ) {
				&errme("Missing instance name for the clustered virtual server. Add SQL Server instance name and re-run.");
				$status = 0; last SUB;
			}

			if ( $Getopt::Std::opt_S ) {
				# If command line -S option is 
				# used, it has to match Virtual Server and instance names in 
				# configuration file.
				unless (
					$gNetName eq uc($gConfigValues{SQLVirtualName}) &&
					$gInstName eq uc($gConfigValues{SQLInstanceName}) ) {
					&errme("Virtual SQL Name\\Instance name has to match command line option -S when installing for a clustered server.");
					$status = 0; last SUB;
				}
			} else {
				# -S Option is not in use, for a clustered server, have to set
				# $gNetName and $gInstName.
				$gNetName	= uc($gConfigValues{SQLVirtualName});
				$gInstName	= uc($gConfigValues{SQLInstanceName});
				$gSrvrName	= uc("$gNetName\\$gInstName");
			}
			unless ( $gNetNodeName = &getNode4VClusterRsrcGrp($gNetName) ) {
				&errme("Cannot get physical node name for virtual server $gNetName in a cluster install.");
				$status = 0; last SUB;
			}
			$gConfigValues{gSQLConnectName}	= $gSrvrName; 
		} else { # Non-clustered install
			# Validate instance name matches command line option.

			if ( $Getopt::Std::opt_S && 
				($gInstName ne uc($gConfigValues{SQLInstanceName}) ) ) {
					&errme("Instance name in configuration file has to match command line option -S.");
					$status = 0; last SUB;
			}
			if (!$Getopt::Std::opt_S) {
				# Command line options -S is not used. Setup gInstName and gSrvrName from config file.
				if ( $gConfigValues{SQLInstanceName}) {
					$gInstName	= uc($gConfigValues{SQLInstanceName});
					$gSrvrName	= uc("$gNetName\\$gInstName");
				}
			}
			$gNetNodeName = $gNetName;
		}


		unless (&setMemoryAWESwitch()) {
			&T38lib::Common::errme("Cannot set Memory and AWE switch");
			$status = 0;
			last SUB;
		}

		&notifyWSub("$gHostName: Running T38 SQL install script for server $gSrvrName. Execution options are <$gRunOpt>.");
		#Hemanth: &notifyWSub("\nStatus at the end of housekeping: $status");
	}	# SUB
	# ExitPoint:

	return($status);

}	# housekeeping

#------------------------------------------------------------------------------------------
#	Purpose: Set SQL Memroy properly, If given Max memory > 3 Gig then set AWE switch
#	         Set global variable to setup memory and AWE switch
#
#	Input Argument: None
#	Output: 1 OK
#			0 failed 
#------------------------------------------------------------------------------------------
sub setMemoryAWESwitch() {

	my $subStatus = 1;

	&T38lib::Common::notifyWSub("SUB STARTED");

	BLOCK: {
		$gphyMem = &getSysMemory();

		if ($gphyMem == 0) {
			&T38lib::Common::notifyWSub("sub getSysMemory failed, system memory = $gphyMem");
			$subStatus = 0;
			last BLOCK;
		}

		$gsqlMem = $gphyMem - $gConfigValues{OSMemory};


		if ($gsqlMem <= 0) {
			&T38lib::Common::notifyWSub("There is no memory for SQL Server, SQL Server Memory = $gsqlMem");
			$subStatus = 0;
			last BLOCK;
		}


		# Set up the Memory and AWE switches
		
		# Condition 1: Min = 0 and Max = 0
		#
		if ( ($gConfigValues{SQLMinMemory} == 0) and ($gConfigValues{SQLMaxMemory} == 0) ) {
			$gminSwitch = 0;
			$gmaxSwitch = 0;
			$gaweSwitch = 0;
			last BLOCK;
		}

		# Condition 2: Min > 0 and Max = 0
		#
		if ( ($gConfigValues{SQLMinMemory} > 0) and ($gConfigValues{SQLMaxMemory} == 0) ) {
			# if Min > physical memory
			if ($gConfigValues{SQLMinMemory} > $gsqlMem) {
				&T38lib::Common::notifyWSub("SQL Min memory ($gConfigValues{SQLMinMemory}) MB > physical memory ($gsqlMem) MB");
				$subStatus = 0;
				last BLOCK;
			}

			if (defined($gConfigValues{SQLInstallx64flg}) && (uc($gConfigValues{SQLInstallx64flg}) eq 'Y') ) {
				$gminSwitch = 1;
				last BLOCK;
			}

			# if Min < 3 Gig
			if ($gConfigValues{SQLMinMemory} <= 3072) {
				$gminSwitch = 1;
				$gmaxSwitch = 0;
				$gaweSwitch = 0;
				last BLOCK;
			}

			# if Min >= 3 Gig
			if ($gConfigValues{SQLMinMemory} > 3072 ) {
				$gConfigValues{SQLMaxMemory} = $gConfigValues{SQLMinMemory};
				$gminSwitch = 1;
				$gmaxSwitch = 1;
				$gaweSwitch = 1;
				last BLOCK
			}
			last BLOCK;
		}

		# Condition 3: Max > 0 and Min = 0
		#
		if ( ($gConfigValues{SQLMaxMemory} > 0) and ($gConfigValues{SQLMinMemory} == 0) ) {
			# if Max > physical memory
			if ($gConfigValues{SQLMaxMemory} > $gsqlMem) {
				&T38lib::Common::notifyWSub("SQL Max memory ($gConfigValues{SQLMaxMemory}) MB > physical memory ($gsqlMem) MB");
				$subStatus = 0;
				last BLOCK;
			}

			if (defined($gConfigValues{SQLInstallx64flg}) && (uc($gConfigValues{SQLInstallx64flg}) eq 'Y') ) {
				$gmaxSwitch = 1;
				last BLOCK;
			}

			if ($gConfigValues{SQLMaxMemory} <= 3072) {
				$gminSwitch = 0;
				$gmaxSwitch = 1;
				$gaweSwitch = 0;
				last BLOCK;
			}

			if ($gConfigValues{SQLMaxMemory} > 3072) {
				$gminSwitch = 0;
				$gmaxSwitch = 1;
				$gaweSwitch = 1;
				last BLOCK;
			}
			last BLOCK;
		}

		# Condition 4: Min > 0 and Max > 0

		if ( ($gConfigValues{SQLMinMemory} > 0) and ($gConfigValues{SQLMaxMemory} > 0) ) {
			# if Max > physical memory
			if ($gConfigValues{SQLMaxMemory} > $gsqlMem) {
				&T38lib::Common::notifyWSub("SQL Max memory ($gConfigValues{SQLMaxMemory}) MB > physical memory ($gsqlMem) MB");
				$subStatus = 0;
				last BLOCK;
			}

			if ($gConfigValues{SQLMinMemory} > $gConfigValues{SQLMaxMemory}) {
				&T38lib::Common::notifyWSub("SQL Min memory ($gConfigValues{SQLMinMemory}) MB > sql Max memory ($gConfigValues{SQLMaxMemory}) MB,");
				$subStatus = 0;
				last BLOCK;
			}

			if (defined($gConfigValues{SQLInstallx64flg}) && (uc($gConfigValues{SQLInstallx64flg}) eq 'Y') ) {
				$gmaxSwitch = 1;
				$gminSwitch = 1;
				last BLOCK;
			}

			if ($gConfigValues{SQLMaxMemory} <= 3072) {
				$gminSwitch = 1;
				$gmaxSwitch = 1;
				$gaweSwitch = 0;
				last BLOCK;
			}

			if ($gConfigValues{SQLMinMemory} > 3072) {
				$gminSwitch = 1;
				$gmaxSwitch = 1;
				$gaweSwitch = 1;
				last BLOCK;
			}
			last BLOCK;
		}


	} # end of BLOCK

	$gaweSwitch = 0	if (defined($gConfigValues{SQLInstallx64flg}) && (uc($gConfigValues{SQLInstallx64flg}) eq 'Y') );
	&T38lib::Common::notifyWSub("SUB DONE");

	return($subStatus);	

} # end sub 

#------------------------------------------------------------------------------
#	Purpose: Set SQL Server account to lock memory pages only valid 
#	         when AWE switch is on.
#
#	Input:	None
#	Output:	1 OK, 0 Failure
#------------------------------------------------------------------------------
sub setLockMemoryPrivilege() {

	my $subStatus	= 1;
	my $key			= '';
	my $cmd			= '';
	my $scOutput	= '';
	my $sqlAcct		= '';
	my $tmpAcct 	= '';
	my $domainName	= '';
	my $result		= 0;

	&T38lib::Common::notifyWSub("SUB STARTED");
	BLOCK: {
		# Make sure that AWE switch is set else don't do any thing
		#
		if ((defined($gConfigValues{SQLInstallx64flg}) && (uc($gConfigValues{SQLInstallx64flg}) eq 'Y')) || $gaweSwitch != 0 ) {

			&T38lib::Common::notifyWSub("Set lock memory pages permissions for SQL Server services");
			# Set service name properly for SQL Server or an instance
			#
			if ($gInstName ne "") {
				$cmd = "sc \\\\$gHostName qc mssql\$";
				$cmd = $cmd . $gInstName;
			}
			else {
				$cmd = "sc \\\\$gHostName qc mssqlserver";
			}

			# Run the sc command to get the account name used to start the SQL server	
			#
			&T38lib::Common::notifyWSub("$cmd");
			$scOutput = `$cmd`;

			# Extract the sQL account name from the output or failed	
			#
			if ($scOutput =~ /SERVICE_START_NAME\s+:\s+(\S+)/i ) {
				$sqlAcct = $1;
			}
			else {
				&T38lib::Common::notifyWSub("$cmd failed");
				&T38lib::Common::notifyWSub("$scOutput");
				$subStatus = 0 ;
				last BLOCK;
			}

			# If the account name is local system then set account name to system
			#
			if ($sqlAcct =~ /LocalSystem/i ) {
				$sqlAcct = "System";
			}

			if (length($sqlAcct) > 20) {
				$tmpAcct 	= '';
				($domainName = $sqlAcct) =~ s/\\.*$//;
				unless ($domainName) {
					&T38lib::Common::notifyWSub("Account \"$sqlAcct\" is to long and cannot get domain name for it.");
					$subStatus = 0 ;
					last BLOCK;
				}
				unless ($tmpAcct = &adUsrName2samid($sqlAcct) ) {
					&T38lib::Common::notifyWSub("Account \"$sqlAcct\" is to long and cannot get short name for it.");
					$subStatus = 0 ;
					last BLOCK;
				}

				$sqlAcct = $domainName . "\\" . $tmpAcct;
			}

			# Give SQL account privilege to lock memory pages using ntrights command
			#
			$cmd = "ntrights -u $sqlAcct -m \\\\$gHostName +r SeLockMemoryPrivilege";
			&T38lib::Common::notifyWSub("$cmd");

			# Run the ntrights command and make sure that it is successful.
			#
			$result = system ("cmd /C $cmd");
			if ($result != 0 ) {
				&T38lib::Common::notifyWSub("$cmd failed");
				$subStatus = 0 ;
				last BLOCK;
			}

			# Set lock memory pages rights for all SQL Server service accounts.

			$key = "ADSQLGroupSQLAccountsOS_" . $gConfigValues{SecurityGroupLocation} . $gConfigValues{EnvironmentType} . $gConfigValues{SecurityDataSensitivity};
			if (defined($gConfigValues{$key})) {
				$sqlAcct = $gConfigValues{$key};
			} else {
				&T38lib::Common::errme("$key is not configured in parameters file.");
				$subStatus = 0 ;
				last BLOCK;
			}

			if (length($sqlAcct) > 20) {
				$tmpAcct 	= '';
				($domainName = $sqlAcct) =~ s/\\.*$//;
				unless ($domainName) {
					&T38lib::Common::notifyWSub("Account \"$sqlAcct\" is to long and cannot get domain name for it.");
					$subStatus = 0 ;
					last BLOCK;
				}
				unless ($tmpAcct = &adGrpName2samid($sqlAcct) ) {
					&T38lib::Common::notifyWSub("Account \"$sqlAcct\" is to long and cannot get short name for it.");
					$subStatus = 0 ;
					last BLOCK;
				}

				$sqlAcct = $domainName . "\\" . $tmpAcct;
			}

			
			# Give SQL account privilege to lock memory pages using ntrights command
			#
			$cmd = "ntrights -u $sqlAcct -m \\\\$gHostName +r SeLockMemoryPrivilege";
			&T38lib::Common::notifyWSub("$cmd");

			# Run the ntrights command and make sure that it is successful.
			#
			$result = system ("cmd /C $cmd");
			if ($result != 0 ) {
				&T38lib::Common::notifyWSub("$cmd failed");
				$subStatus = 0 ;
				last BLOCK;
			}

		}
		else {
			&T38lib::Common::notifyWSub("AWE Switch is OFF");
			last BLOCK;
		}

	} # End of BLOcK

	&T38lib::Common::notifyWSub("SUB DONE");

	# Return the result	
	#
	return($subStatus);
	
} # end sub setLockMemoryPrivilege

# ----------------------------------------------------------------------
#	getSysVerReg	Get OS Major version from registry.
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		int		Version Number (if 0, then error)
# ----------------------------------------------------------------------
#	Return an intiger representing the version number of the OS
# ----------------------------------------------------------------------
sub getSysVerReg (;$){
	#Optional, declared above-> use Win32::TieRegistry ( Delimiter=>"/", ArrayValues=>0);

	# if you do not want to use the virtual name, pass in the physical server name
	my $machine = shift;

	my $status = 1;
	my @verFields = ();
	my $osVersion	= 0;
	my $keyName	= "";
	SUB:
	{
		&notifyWSub("Started.");
		unless ($machine) {
			$machine	= ($gHostName eq $gNetName) ? "": "//$gNetName/";
		} else {
			$machine = "//$machine/";
		}
		# OS Version: HKLM/Software/Microsoft/Windows NT/CurrentVersion/CurrentVersion
		$keyName	= "${machine}LMachine/Software/Microsoft/Windows NT/CurrentVersion/CurrentVersion";
		if (defined($Registry->{$keyName})) {
			$osVersion = $Registry->{$keyName};
			@verFields = split(/\./,$osVersion);
			$osVersion = int($verFields[0]); # We only need the major version of the OS.
		} else {
			&errme("Registry value $keyName is unaccessible.");
			$status = 0;
			last SUB;
		}
		last SUB;
	}

	&notifyWSub("Done");
	if(defined($osVersion)){
			return ($osVersion);
	} else{
			return($status);
	}
}	# getSysVerReg

#------------------------------------------------------------------------------------------
#	Purpose: Get System memory
#
#	Input Argument: None
#	Output:  Physical Memory in Mega Byte OK, 0 Failed
#------------------------------------------------------------------------------------------
sub getSysMemory() {
	my $phyMem	= 0;
	my ($WMI, $os_set, $Services, $os);

	&T38lib::Common::notifyWSub("SUB STARTED");

	BLOCK: {
		unless ($WMI = Win32::OLE->new('WbemScripting.SWbemLocator') ) {
			&T38lib::Common::notifyWSub("WMI OLE failed");
			last BLOCK;
		}

		unless ($Services = $WMI->ConnectServer($gNetNodeName) )  {
			&T38lib::Common::notifyWSub("WMI Can not connect to $gNetNodeName");
			last BLOCK;
		}

		$os_set = $Services->InstancesOf("Win32_ComputerSystem");

		# Get Total physical memroy in Bytes
		foreach $os (in($os_set)) {
			$phyMem = $os->{'TotalPhysicalMemory'};

			# Convet the memory in Kilo Bytes
			$phyMem = ($phyMem/1024);

			# Convet the memory in Mega Bytes and round it
			$phyMem = int($phyMem/1024);
		}

	} # End of BLOCK

	&T38lib::Common::notifyWSub("SUB DONE");

	return($phyMem);	

} # end sub getSysMemory

# ----------------------------------------------------------------------
#	Get System CPU info using WMI
# ----------------------------------------------------------------------
#	arguments:
#		None
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	Populate global variable gnumOfTempdbFiles with the number of CPU
# ----------------------------------------------------------------------
sub getSysCPU() {
	my $status			= 1;
	my ($WMI, $Services, $sys_set, $sys);

	&T38lib::Common::notifyWSub("SUB STARTED");

	BLOCK: {

		unless ($WMI = Win32::OLE->new('WbemScripting.SWbemLocator') ) {
			$status = 0;
			last BLOCK;
		}

		unless ($Services = $WMI->ConnectServer($gNetName) )  {
			$status = 0;
			last BLOCK;
		}

		# Gather Computer System Information
		$sys_set = $Services->InstancesOf("Win32_ComputerSystem");

		foreach $sys (in($sys_set)) {  
			$gnumOfTempdbFiles = $sys->{'NumberOfProcessors'};
			$gnumOfCPU = $gnumOfTempdbFiles;
		}

		last BLOCK;
	} # End of BLOCK

	&T38lib::Common::notifyWSub("SUB DONE");

	return ($status);

} # End of getSysCPU

# ----------------------------------------------------------------------
# showHelp
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
sub showHelp() {
	print <<'EOT'
#*  t38instl90 - SQL Server installation program, version 90.
#*	based on t38inst80.pl, Revision 1.13
#*
#*	$Author: A645276 $
#*	$Date: 2011/02/08 15:34:08 $
#*	$Revision: 1.1 $
#*	$Archive:   //uxpvcs2/pvcs/projects/Database/archives/DatabaseSolutions/MSSQL/EnvironmentStandardsAndConfigurationBuild/InstallSQLServer/SQL100/Scripts/t38instl100.pv_  $
#*
#* SYNOPSIS
#* perl T38instl90.pl -h |  -a 10 -x adfhilpstuy9 -S serverName cfgFileName.cfg
#* 
#* Commnad line
#*
#*	-h   		Writes help screen on standard output, then exit the program.
#*	-a 10		Number of log file archived, default is 7.
#*	-S server	Name of the server, where to configure SQL Server.
#*	-x steps	Execution steps option. If -x option is not provided, all steps 
#*				will be executed. Otherwise only specified steps will be done.
#*				The possible execution steps are.
#*				a - Run SQL Agent jobs.
#*				c - Install Client Components.
#*				d - Create directories for BBY SQL Server install (t38xxx).
#*				f - Copy files to T38APP80 directory.
#*				g - Upgrade SQL Server.
#*				h - Create shares for t38 directories.
#*				i - Install SQL Server.
#*				m - lock memory pages
#*				n - Add node to existing cluster
#*				l - Copy perl libraries.
#*				s - Setup security rights for SQL Administrators.
#*				t - Change SQL Service accounts.
#*				u - Create user databases.
#*				y - Configure system databases (run t38procs.sql, Install00 and master.sql).
#*				9 - Run post-processing scripts from Install01-99 directories.
#*
#*				NOTE: The a, d, f, h, u, y and 9 options can be run 
#*				remotely with -S serverName option. The i, l, c, s and t options
#*				cannot be executed remotely with this version of the program.
#*	
#* CfgFileName.cfg
#*    A configuration file used to initilize the starup parameters, Required 
#*
#*
#* Example:
#*	1) perl T38instl90.pl userdb.cfg T38app80\T38dba.cfg
#*		Run SQL server install using T38dba.cfg file to set up initial parameters
#*		and userdb.cfg to create user databases.
#*
#*	2) perl T38instl90.pl -x p T38APP80\T38dba.cfg
#*      Run only service pack install using T38dba.cfg file in directory T38APP80
#*
#*	3) perl T38instl90.pl -x h -S HST2DB \\HST2DB\f$\DBMS\T38APP80\T38dba.cfg
#*      Create t38 shares on HST2DB. Note: t38dba.cfg file on HST2DB has to exists
#*		and define all drive letters correctly for shares.
#*
#*	4) perl T38instl90.pl -x dlfhiy9 T38APP80\T38dba.cfg
#*      Install SQL Server, without creating User databases, setting up security and
#*		running SQL agent jobs. Note: t38srvstats SQL Agent job registers installed
#*		SQL Servers with central repository.
#*
#*	5) perl T38instl90.pl -h
#*		Show the help screen
#*
EOT
} #	showHelp


__END__

=pod

=head1 NAME

t38instl90.pl - Install and configure Microsoft SQL Server

=head1 SYNOPSIS

perl T38instl90.pl -h |  -a 10 -x adfhilpsuy9 -S serverName t38dba.cfg

=head2 OPTIONS

I<t38instl90.pl> accepts the following options:

=over 4

=item [OPTION]

DESCRIPTION OF THE OPTION

=item -h 		(Optional)

Print out a short help message, then exit.

=item -a <number> 		(Optional)

Number of log file archived, default is 7

=item -S <name> 		(Optional)

Name of the server, where to configure SQL Server. Default is
local server.


=item -x executionSteps		(Optional)

Execution steps option. If -x option is not provided, all steps 
will be executed. Otherwise only specified steps will be done.
The possible execution steps are:

	a - Run SQL Agent jobs.
	b - Remove buildin admin accounts from SQL Server
	d - Create directories for BBY SQL Server install (t38xxx).
	f - Copy files to T38APP80 directory.
	h - Create shares for t38 directories.
	i - Install SQL Server.
	l - Copy perl libraries.
	p - Install Service Pack.
	s - Setup security rights for SQL Administrators.
	t - Change SQL Service accounts.
	u - Create user databases.
	y - Configure system databases (run t38procs.sql, Install00 and master.sql).
	9 - Run post-processing scripts from Install01-99 directories.

B<NOTE:> The a, d, f, h, u, y and 9 options can be executed 
remotely with -S serverName option. The i, l, p and s options
cannot be executed remotely with this version of the program.


=item OTHER OPTION 	(Required)

DESCRIPTION OF THE OPTION

=item t38dba.cfg 	(Required)

Configuration file where the program read it initial parameters


=back

=head1 DESCRIPTION

The purpose for the program is to install SQL Server, service pack
and setup all Best Buy Database maintenance jobs. If requested,
program will create user databases and run optional scripts from
Install01 - Install99 directories. 

=head1 EXAMPLES

=over 4

=item Example 1:

C<perl T38instl90.pl userdb.cfg T38app80\T38dba.cfg>

Run SQL server install using T38dba.cfg file to set up initial parameters
and userdb.cfg to create user databases.

=item Example 2:

C<perl T38instl90.pl -x p T38APP80\T38dba.cfg>

Run only service pack install using T38dba.cfg file in directory T38APP80

=item Example 3:

C<perl T38instl90.pl -x h -S HST2DB \\HST2DB\f$\DBMS\T38APP80\T38dba.cfg>

Create t38 shares on HST2DB. B<Note:> t38dba.cfg file on HST2DB has to exists
and define all drive letters correctly for shares.

=item Example 4:

C<perl T38instl90.pl -x dlfhiy9 T38APP80\T38dba.cfg>

Install SQL Server, without creating User databases, setting up security and
running SQL agent jobs. Note: t38srvstats SQL Agent job registers installed
SQL Servers with central repository.

=item Example 5:

C<perl T38instl90.pl -h>

Show the help screen

=back

=head1 COMPILE OPTION

=over 4

=item perl -S PerlApp.pl -f -s t38instl90.pl -e t38instl90.exe -c -v

=item using perl 5.005_03, ActivePerl Build 522

=back

=head1 BUGS

I<t38instl100.pl> has no known bugs.

=head1 REVISION HISTORY

$Revision: 1.1 $

=head1 AUTHOR

Asif Kaleem, asif.kaleem@bestbuy.com
Michael Royzman, Michael.Royzman@bestbuy.com


=head1 SEE ALSO

Common.pm
Getopt::Std
File::Basename
Cwd
File::Path

=head1 COPYRIGHT and LICENSE

This program is copyright by BestBuy Inc.

=cut
