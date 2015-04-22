#!perl 
#* t38cpdb - Copy SQL Server database between servers.
#*
#*	$Author: A645276 $
#*	$Date: 2011/02/08 15:32:27 $
#*	$Revision: 1.1 $
#*	$Archive:   //cs01pvcs/pvcs/cm/Database/archives/Applications/Utilities/t38cpdb.pv_  $
#*
#* SYNOPSIS
#*	t38cpdb -h -C destination_copy_server -S source_server -d dbname -c cfgFile -x execOpt
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
#*				CPDBSrcServer	 	-- can be overwritten by -C option
#*				CPDBSrcInstance	 	-- can be overwritten by -C option
#*				CPDBDestServer		-- can be overwritten by -S option
#*				CPDBDestInstance	-- can be overwritten by -S option
#*				CPDBDatabases		-- can be overwritten by -d option
#*	-x execOpt	Execution option:
#*				b -- backup database on source server.
#*				c -- copy backup files from source to destination server.
#*				r -- restore database on destination server.
#*				default is 'bcr'.
#*	
#*	
#*	This program copies databases from source to destination servers.
#*
#*	Example:
#*		t38cpdb -S hst6db -C hst5db\inst1 -d MXRDB001 -x bcr
#*
#*	Backup MXRDB001 database on default instance of the HST6DB server, copy backup
#*	files to \\HST5DB\t38lsdbkp\inst1\HST6DB\default directory, kills all users of
#*	the MXRDB001 and restores it from backups.
#*
#***

use strict;

use File::DosGlob qw(glob);

#-- constants

use T38lib::Common qw(notifyMe notifyWSub logme warnme errme whence unc2path T38DEFAULTINSTDIR);
use T38lib::t38cfgfile qw(:CFGFILE_SUBS :CFGFILE_VARS);
use T38lib::bbyado qw(:BBYADO_SUBS :BBYADO_VARS);

use vars qw(
		$gCurrentDir $gScriptName $gScriptPath
		$opt_h $opt_c $opt_C $opt_S $opt_d $opt_x
		$gHostName @gDBList
		$gRunOpt $gCfgFile
		$gSrvrSrc $gNetSrc $gInstSrc
		$gSrvrDest $gNetDest $gInstDest
		$gDestBkpShr $gDestBkpDir
		$gNWarnings
		);

# Main

&main();

sub main {
	my $mainStatus	= 0;
SUB:
{
	unless (&housekeeping())						{ $mainStatus = 1; last SUB; }

	if ($gRunOpt =~ /b/i && !&backupSrcDb())		{ $mainStatus = 1; }
	if ($gRunOpt =~ /c/i) {
		unless (&createDestBkpDir())					{ $mainStatus = 1; last SUB; }
		unless (&copySrcFiles())					{ $mainStatus = 1; last SUB; }
	}
	if ($gRunOpt =~ /r/i && !&restoreDestDb())		{ $mainStatus = 1; last SUB; }

	last SUB;
	
}	# SUB
# ExitPoint:
	$mainStatus = 1	if ($gNWarnings > 0);
	( $mainStatus== 0 ) ?
		logme("Finished with status $mainStatus", "done") :
		warnme("Finished with status $mainStatus", "done") ;
	exit($mainStatus);
}	# main


#######################  $Workfile:   t38cpdb.pl  $ Subroutines  #################################


# ----------------------------------------------------------------------
#	backupSrcDb	backup source databases
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------

sub backupSrcDb () {
	my $dbname				= '';
	my $cmd					= 0;		# ADO Command object handle
	my $rs					= 0;		# record set handle
	my $sqlerr				= 0;
	my $sql					= '';		# sql command buffer
	my $bkpDestPath			= '';
	my $status	= 1;
SUB:
{
	&notifyWSub("Backup source databases.");
	unless ($cmd = adoConnect($gSrvrSrc, 'master')) { 
		&errme("adoConnect($gSrvrSrc) Failed"); 
		$status = 0; last SUB;
	}

	# Backup database.
	foreach $dbname (@gDBList) {
		$sql = "backup database $dbname to ${dbname}_db_bkp with init";
		&notifyMe("execSQLCmd(\$cmd, $sql))");
		unless(&execSQLCmd($cmd, $sql)) { $status = 0;}
	}

	last SUB;
}	# SUB
# ExitPoint:
	if ($cmd) { $cmd->Close(); $cmd = 0; }
	return($status);
}	# backupSrcDb



# ----------------------------------------------------------------------
#	copySrcFiles	copy backup files from source server
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
# ----------------------------------------------------------------------

sub copySrcFiles () {
	my $cmd			= '';
	my $filename	= '';
	my $dbname		= '';
	my $bkpSrcLoc	= '';		# backup location on source server
	my $status		= 1;
SUB:
{
	$bkpSrcLoc	= ($gInstSrc eq '')? "\\\\$gNetSrc\\t38bkp" : "\\\\$gNetSrc\\t38bkp\\$gInstSrc";

	&notifyWSub("Copy files from $bkpSrcLoc to $gDestBkpDir.");

	foreach $dbname (@gDBList) {
		$filename = "$bkpSrcLoc\\${dbname}_db\.bkp";
		&notifyWSub("Copy $filename to $gDestBkpDir.");
		$cmd = "cmd /E:on /C \"copy /Y /V $filename $gDestBkpDir\"";
		unless (system($cmd) == 0) {
			&warnme("Problem with $cmd");
			$gNWarnings++;
			$status = 0; last SUB;
		}
	}

	$status = 1;
	last SUB;
}	# SUB
# ExitPoint:
	return($status);
}	# copySrcFiles


# ----------------------------------------------------------------------
#	createDestBkpDir	create destination backup directory
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
# ----------------------------------------------------------------------

sub createDestBkpDir () {
	my $cmd		= '';
	my $status	= 1;
SUB:
{
	last SUB	if (-d $gDestBkpDir);

	&notifyWSub("Create directory $gDestBkpDir.");
	$cmd = "cmd /E:on  /C \"mkdir $gDestBkpDir\"";
	unless (system($cmd) == 0) {
		&errme("Problem with $cmd");
		$status = 0; last SUB;
	}

	last SUB;
}	# SUB
# ExitPoint:
	return($status);
}	# createDestBkpDir


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
	$gNetSrc 	= uc($gConfigValues{CPDBSrcServer})	if (defined($gConfigValues{CPDBSrcServer}) && $gConfigValues{CPDBSrcServer});
	$gInstSrc 	= $gConfigValues{CPDBSrcInstance}		if (defined($gConfigValues{CPDBSrcInstance}) && $gConfigValues{CPDBSrcInstance});
	$gSrvrSrc 	= ($gInstSrc)? "$gNetSrc\\$gInstSrc": $gNetSrc;

	$gNetDest 	= uc($gConfigValues{CPDBDestServer})	if (defined($gConfigValues{CPDBDestServer}) && $gConfigValues{CPDBDestServer});
	$gInstDest 	= $gConfigValues{CPDBDestInstance}	if (defined($gConfigValues{CPDBDestInstance}) && $gConfigValues{CPDBDestInstance});
	$gSrvrDest	= ($gInstDest)? "$gNetDest\\$gInstDest": $gNetDest;

	if (defined($gConfigValues{CPDBDatabases}) && $gConfigValues{CPDBDatabases}) {
		@gDBList = split(/[,\s]+/, $gConfigValues{CPDBDatabases});
	}

	$status	= 1;
	last SUB;
}
	return($status);	
} # getConfigFileParms


# ----------------------------------------------------------------------
#	restoreDestDb	restore destination database
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------

sub restoreDestDb () {
	my $dbname		= '';
	my $cmd			= 0;		# ADO Command object handle
	my $rs			= 0;		# record set handle
	my $sqlerr		= 0;
	my $sql			= '';		# sql command buffer
	my $bkpDestPath	= '';
	my $status		= 0;
SUB:
{
	&notifyWSub("Resotre databases destination.");
	unless ($cmd = adoConnect($gSrvrDest, 'master')) { 
		&errme("adoConnect($gSrvrDest, $dbname) Failed"); 
		$status = 0; last SUB;
	}

	# Restore database.

	unless($bkpDestPath = unc2path($gNetDest, "\\\\$gNetDest\\$gDestBkpShr")) {
		&errme("Cannot find share $gDestBkpShr on $gNetDest.");
		$status = 0; last SUB;
	}

	$bkpDestPath .= ($gInstDest) ? "\\$gInstDest":"\\default";
	$bkpDestPath .= "\\$gNetSrc";
	$bkpDestPath .= ($gInstSrc) ? "\\$gInstSrc":"\\default";
	
	foreach $dbname (@gDBList) {
		# Kill users and put database into restricted mode.

		&killDBAccess($cmd, $dbname);

		# Restore database.

		# $sql = "restore database $dbname from disk = \'$bkpDestPath\\${gDBName}_db\.bkp\' with norecovery";
		$sql = "restore database $dbname from disk = \'$bkpDestPath\\${dbname}_db\.bkp\'";
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
	$opt_c	= 0;	# Optional Configuration file name.
	$opt_C	= 0;	# Destination copy server.
	$opt_d	= 0;	# Database to copy.
	$opt_S	= 0;	# Source database server name.
	$opt_x	= 0;	# Optional execution steps to run.


	getopts('hc:C:d:S:x:');

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
	$gRunOpt	= 'bcr';		# default Execution options 
								# 	backup database on source server
								#	copy backup files,
								#	restore them 
	$gDestBkpShr	= 't38tmp';
	$gCfgFile	= '';
	$gNWarnings	= 0;

	#-- show help

	if ($opt_h) { &showHelp; exit; }

	# Open log and error files, if needed.

	unless (&T38lib::Common::setLogFileDir("$gScriptPath\\T38LOG\\$gScriptName")) {
		&errme("Cannot set scripts log directory.");
		return(0);
	}

	&T38lib::Common::archiveLogFile(7);
	&logme("Starting $gScriptName from $gScriptPath", "started");

	# Overwrite default parameters from configuration file.

	$gRunOpt	= $opt_x		if ($opt_x);

	if ($opt_c) {
		$gCfgFile = $opt_c;
		&getConfigFileParms($gCfgFile);
	}

	# And now overwrite them from command line.
	# Validate command line arguments.

	if ($opt_C) {
		$gSrvrDest	= uc($opt_C);
		$gSrvrDest	=~ s/^\./$gHostName/;
		($gNetDest, $gInstDest)	=	split("\\\\", $gSrvrDest); 
		$gInstDest =~ s/^\s+//g; $gInstDest =~ s/\s+$//g;
	}

	if ($opt_S) {
		$gSrvrSrc	= uc($opt_S);
		$gSrvrSrc	=~ s/^\./$gHostName/;
		($gNetSrc, $gInstSrc)	=	split("\\\\", $gSrvrSrc);
		$gInstSrc =~ s/^\s+//g; $gInstSrc =~ s/\s+$//g;
	}

	if ($opt_d) {
		@gDBList = ($opt_d);
	}

	$gDestBkpDir = "\\\\$gNetDest\\$gDestBkpShr";
	$gDestBkpDir .= ($gInstDest) ? "\\$gInstDest":"\\default";
	$gDestBkpDir .= "\\$gNetSrc";
	$gDestBkpDir .= ($gInstSrc) ? "\\$gInstSrc":"\\default";


	# If source and destination instances are the same, something is wrong.
	if ($gSrvrDest eq $gSrvrSrc) {
		&errme("Cannot copy databases from $gSrvrSrc to same instance. Review command line options.");
		return 0;
	}
	# Check if all required binaries are available.

	unless (&whence("rmtshare.exe")) {
		&errme("$gScriptName aborted. Cannot find rmtshare.exe!");
		return 0;
	}

	# Check Perl version.

	unless ( &T38lib::Common::chkPerlVer() ) {
		&notifyWSub("Wrong version of Perl!");
		&notifyWSub("This program run on Perl version 5.005 and higher.");
		&notifyWSub("Check the Perl version by running perl -v on command line.");
		return 0;
	}

	&notifyWSub("$gHostName: Copy databases from $gSrvrSrc to $gSrvrDest.");

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
#* t38cpdb - Copy SQL Server database between servers.
#*
#*	$Author: A645276 $
#*	$Date: 2011/02/08 15:32:27 $
#*	$Revision: 1.1 $
#*	$Archive:   //cs01pvcs/pvcs/cm/Database/archives/Applications/Utilities/t38cpdb.pv_  $
#*
#* SYNOPSIS
#*	t38cpdb -h -C destination_copy_server -S source_server -d dbname -c cfgFile -x execOpt
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
*	-x execOpt	Execution option:
#*				CPDBSrcInstance	 	-- can be overwritten by -C option
#*				CPDBDestServer		-- can be overwritten by -S option
#*				CPDBDestInstance	-- can be overwritten by -S option
#*				CPDBDatabases		-- can be overwritten by -d option
#*	-x execOpt	Execution option:
#*				b -- backup database on source server.
#*				c -- copy backup files from source to destination server.
#*				r -- restore database on destination server.
#*				default is 'bcr'.
#*	
#*	
#*	This program copies databases from source to destination servers.
#*
#*	Example:
#*		t38cpdb -S hst6db -C hst5db\inst1 -d MXRDB001 -x bcr
#*
#*	Backup MXRDB001 database on default instance of the HST6DB server, copy backup
#*	files to \\HST5DB\t38lsdbkp\inst1\HST6DB\default directory, kills all users of
#*	the MXRDB001 and restores it from backups.
#*
#***
EOT
} #	showHelp
