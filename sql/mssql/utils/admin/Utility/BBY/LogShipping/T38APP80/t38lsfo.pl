#!perl 
#* t38lsfo - log shipping failover.
#*
#*	$Author: A645276 $
#*	$Date: 2011/02/08 15:32:28 $
#*	$Revision: 1.1 $
#*	$Archive:   //cs01pvcs/pvcs/cm/Database/archives/Applications/LogShipping/t38lsfo.pv_  $
#*
#* SYNOPSIS
#*	t38lsfo -h cfgFile
#*	
#*	Where:
#*	
#*	-h			Writes help screen on standard output, then exits.
#*	-d dbname	Database name.
#*	cfgFile		Configuration file with log ship parameters. They
#*				provide defaults for common options.
#*				Following parameters are excepted:
#*				LogShipSrcServer	 	-- source server name
#*				LogShipSrcInstance	 	-- SQL instance name on source server
#*				LogShipDestServer		-- destination server
#*				LogShipDestInstance		-- SQL instance name on destination
#*				LogShipDatabases		-- List of databases for log shipping
#*				LogShipEnabledFlg		-- flag, indicating if log shipping
#*										   is enabled. Default is enabled.
#*	
#*	
#*	This program should be used only when primary source server is 
#*	no longer functional and secondary server has to be switched
#*	to primary role. The cfgFile name is required parameter.
#*
#*	Note: t38lsfo.pl will switch server from secondary to primary role.
#*	Switching selected databases has to be done manually and requires
#*	changes to configuration file.
#*
#*
#*	The t38lsfo.pl performs the following steps:
#*
#*	- Read configuration file.
#*	- Run t38lstrst.pl from current script directory to restore
#*	  latest transaction log dumps.
#*	- Kill all users in log shipping databases on destination server.
#*	- Switch log shipping databases to on-line mode.
#*	- Disable log shipping in configuration file.
#*	- Run t38revact4sql.pl to enable all accounts in databases.
#*	- Run full database backup for database, that were used
#*	  for log shipping.
#*
#***

use strict;

use File::DosGlob qw(glob);

#-- constants

use T38lib::Common qw(notifyMe notifyWSub logme warnme errme 
				stripWhitespace stripPath
				whence unc2path T38DEFAULTINSTDIR
				);
use T38lib::t38cfgfile qw(:CFGFILE_SUBS :CFGFILE_VARS);
use T38lib::bbyado qw(:BBYADO_SUBS :BBYADO_VARS);

use vars qw(
		$gCurrentDir $gScriptName $gScriptPath
		$opt_h
		$gHostName @gDBList $gCfgFile
		$gSrvrSrc $gNetSrc $gInstSrc
		$gSrvrDest $gNetDest $gInstDest
		$gLSDBkpShr $gLSDBkpDir
		$gNWarnings
		);

# Main

&main();

sub main {
	my $mainStatus	= 0;
	my $oscmd		= '';
	my $osout		= '';
	my %cfgtodo		= (		# List of values to update in config file.
		LogShipEnabledFlg => 'N', 
		);
SUB:
{
	unless (&housekeeping())			{ $mainStatus = 1; last SUB; }

	$oscmd = "perl ${gScriptPath}t38lstrst\.pl -c $gCfgFile";
	$osout = `cmd /C \"$oscmd\" 2>\&1`;
	&notifyMe("OS Command: $oscmd");
	&notifyMe("$osout");

	unless (&restoreDestDb())						{ $mainStatus = 1; last SUB; }
	unless (&updateCfgFile($gCfgFile, \%cfgtodo))	{ $mainStatus = 1; last SUB; };

	$oscmd = "perl ${gScriptPath}t38revact4sql\.pl -c $gCfgFile";
	$osout = `cmd /C \"$oscmd\" 2>\&1`;
	&notifyMe("OS Command: $oscmd");
	&notifyMe("$osout");

	$oscmd = "perl ${gScriptPath}T38bkp\.pl -S $gSrvrDest -c $gCfgFile -b db";
	$osout = `cmd /C \"$oscmd\" 2>\&1`;
	&notifyMe("OS Command: $oscmd");
	&notifyMe("$osout");

	last SUB;
	
}	# SUB
# ExitPoint:
	$mainStatus = 1	if ($gNWarnings > 0);
	( $mainStatus== 0 ) ?
		logme("Finished with status $mainStatus", "done") :
		warnme("Finished with status $mainStatus", "done") ;
	exit($mainStatus);
}	# main


#######################  $Workfile:   t38lsfo.pl  $ Subroutines  #################################


# ----------------------------------------------------------------------
# getConfigFileParms
# ----------------------------------------------------------------------
#	arguments:
#		cfgFile	configuration file to parse
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	Purpose: Read the provided configuration file .
#            Set up global variables with the values read from CFG file.
# ----------------------------------------------------------------------

sub getConfigFileParms($) {
	my $cfgFile	= shift;
	my $status	= 1;
SUB:
{
	unless (&readConfigFile($cfgFile)) {
		&warnme("Cannot read configuration file $cfgFile.");
		$gNWarnings++;
		$status = 0; last SUB;
	};
	$gNetSrc 	= uc($gConfigValues{LogShipSrcServer})	if (defined($gConfigValues{LogShipSrcServer}) && $gConfigValues{LogShipSrcServer});
	$gInstSrc 	= $gConfigValues{LogShipSrcInstance}		if (defined($gConfigValues{LogShipSrcInstance}) && $gConfigValues{LogShipSrcInstance});
	$gSrvrSrc 	= ($gInstSrc)? "$gNetSrc\\$gInstSrc": $gNetSrc;

	$gNetDest 	= uc($gConfigValues{LogShipDestServer})	if (defined($gConfigValues{LogShipDestServer}) && $gConfigValues{LogShipDestServer});
	$gInstDest 	= $gConfigValues{LogShipDestInstance}	if (defined($gConfigValues{LogShipDestInstance}) && $gConfigValues{LogShipDestInstance});
	$gSrvrDest	= ($gInstDest)? "$gNetDest\\$gInstDest": $gNetDest;

	if (defined($gConfigValues{LogShipDatabases}) && $gConfigValues{LogShipDatabases}) {
		@gDBList = split(/[,\s]+/, $gConfigValues{LogShipDatabases});
	}

	$status	= 1;
	last SUB;
}
	return($status);	
} # getConfigFileParms


# ----------------------------------------------------------------------
#	restoreDestDb	restore destination databases
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
#	This function is using restore database command to bring database
#	to online mode on destination server.
# ----------------------------------------------------------------------

sub restoreDestDb () {
	my $dbname		= '';
	my $cmd			= 0;		# ADO Command object handle
	my $sql			= '';		# sql command buffer
	my $status		= 0;
SUB:
{
	&notifyWSub("Resotre log ship destination databases.");
	unless ($cmd = adoConnect($gSrvrDest, 'master')) { 
		&errme("adoConnect($gSrvrDest, $dbname) Failed"); 
		$status = 0; last SUB;
	}

	# Restore database.

	foreach $dbname (@gDBList) {
		# Kill users and put database into restricted mode.

		&killDBAccess($cmd, $dbname);

		# Restore database.

		$sql = "restore database $dbname WITH RECOVERY";
		&notifyMe("execSQLCmd(\$cmd, $sql))");
		unless(&execSQLCmd($cmd, $sql)) { $status = 0; last SUB; }

		# Setup database for multi-user access.
		$sql = "alter database $dbname set MULTI_USER ";
		&notifyMe("execSQLCmd(\$cmd, $sql))");
		unless(&execSQLCmd($cmd, $sql)) { $status = 0; last SUB; }
	}

	$status	= 1;
	last SUB;
}	# SUB
# ExitPoint:
	if ($cmd) { $cmd->Close(); $cmd = 0; }
	return($status);
}	# restoreDestDb


############################  BBY Subroutines  ####################################


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

sub housekeeping { 
	use Getopt::Std;

	my $scriptSuffix;
	$gScriptName	= "";			# Base name of the current script.
	$gScriptPath	= ".\\";		# Directory path to current script.

	($gScriptPath, $gScriptName, $scriptSuffix) = &T38lib::Common::parseProgramName();

	#-- initialize standard options

	$opt_h	= 0;	# help option.

	getopts('h');

	#-- program specific initialization

	use Sys::Hostname;
	$gHostName	= hostname;
	$gSrvrSrc	= $gHostName;	# SQL Server name
	$gNetSrc	= $gHostName;	# SQL Server machine name
	$gInstSrc	= '';			# SQL Server instance name
	$gSrvrDest	= $gHostName;	# SQL Server name
	$gNetDest	= $gHostName;	# SQL Server machine name
	$gInstDest	= '';			# SQL Server instance name
	@gDBList	= ();
	$gLSDBkpShr	= 't38lsdbkp';
	$gCfgFile	= '';
	$gNWarnings	= 0;

	#-- show help

	if ($opt_h || $#ARGV == -1) { &showHelp; exit; }

	# Open log and error files, if needed.

	unless (&T38lib::Common::setLogFileDir("$gScriptPath\\T38LOG\\$gScriptName")) {
		&errme("Cannot set scripts log directory.");
		return(0);
	}

	&T38lib::Common::archiveLogFile(7);
	&logme("Starting $gScriptName from $gScriptPath", "started");

	# Overwrite default parameters from configuration file.

	$gCfgFile	= $ARGV[0];
	unless (&getConfigFileParms($gCfgFile)) { return 0;	}

	$gLSDBkpDir = "\\\\$gNetDest\\$gLSDBkpShr";
	$gLSDBkpDir .= ($gInstDest) ? "\\$gInstDest":"\\default";
	$gLSDBkpDir .= "\\$gNetSrc";
	$gLSDBkpDir .= ($gInstSrc) ? "\\$gInstSrc":"\\default";

	# Check Perl version.

	unless ( &T38lib::Common::chkPerlVer() ) {
		&notifyWSub("Wrong version of Perl!");
		&notifyWSub("This program run on Perl version 5.005 and higher.");
		&notifyWSub("Check the Perl version by running perl -v on command line.");
		return 0;
	}

	&notifyWSub("$gHostName: Switch primary from $gSrvrSrc to $gSrvrDest.");

	return(1);
}	# housekeeping
	

# ----------------------------------------------------------------------
#	debugPrintHash 
# ----------------------------------------------------------------------
#	arguments:
#		Reference to Hash
#	return:
#		none
# ----------------------------------------------------------------------
#	Print all kesy in a hash.
# ----------------------------------------------------------------------

sub debugPrintHash ($) {
	my $hashref	= shift;
	my $hKey;

	foreach $hKey (sort keys (%{$hashref})) {
		&notifyMe("\t$hKey = $$hashref{$hKey}");
	}
}	# debugPrintHash


###	showHelp -- show help information.
###

sub showHelp {
	print <<'EOT'
#* t38lsfo - restore transactions for log shipping on secondary server.
#*
#*	$Author: A645276 $
#*	$Date: 2011/02/08 15:32:28 $
#*	$Revision: 1.1 $
#*	$Archive:   //cs01pvcs/pvcs/cm/Database/archives/Applications/LogShipping/t38lsfo.pv_  $
#*
#* SYNOPSIS
#*	t38lsfo -h -C destination_copy_server -S source_server -d dbname -c cfgFile
#*	
#*	Where:
#*	
#*	-h			Writes help screen on standard output, then exits.
#*	-C server	Name of the SQL Server with destination copy. 
#*				Default is local server on default instance.
#*	-S server	Name of the Source SQL server. Default is local 
#*				server with default instance.
#*	-d dbname	Database name.
#*	-c cfgFile	Configuration file with optional parameters. They
#*				provide defaults for common options.
#*				Following parameters are excepted:
#*				LogShipSrcServer	 	-- can be overwritten by -C option
#*				LogShipSrcInstance	 	-- can be overwritten by -C option
#*				LogShipDestServer		-- can be overwritten by -S option
#*				LogShipDestInstance		-- can be overwritten by -S option
#*				LogShipDatabases		-- can be overwritten by -d option
#*				LogShipEnabledFlg		-- flag, indicating if log shipping
#*										   is enabled. Default is enabled.
#*	
#*	
#*	This program runs on scheduled intervals (every 15 minutes) to restores 
#*	transaction log dumps for log shipping on secondary server.
#*
#*	It will perform all or some the following steps:
#*
#*	- Check if log shipping is enabled. If not, just exit.
#*	- Copy completed transaction log dumps from source server to destination.
#*	  Copy only files, that are not on destination server.
#*	- Kill all users in log shipping databases on destination server.
#*	- Restore new transaction log dumps.
#*	- Move files with restored transactions to tlogdone directory.
#*	- Move files, that failed, to tlogfail directory.
#*
#*	Example 1:
#*		t38lsfo.pl -c \\%computername%\t38app80\inst1\t38dba.cfg
#*	Use configuration file t38dba.cfg for all log shipping parameters.
#*	Copy transaction log dumps for log shipping databases from source
#*	to destination. Restore transaction log dumps.
#*
#*	Example 2:
#*		t38lsfo.pl -S hst6db -C hst5db\inst1 -d ADMDB001
#*
#*	Copy transaction log dumps for ADMDB001 database on default instance 
#*	of the HST6DB server to \\HST5DB\t38lsdbkp\inst1\HST6DB\default 
#*	directory. Restore transaction log dumps on HST5DB\inst1 ADMDB001
#*	database. 
#*
EOT
} #	showHelp
