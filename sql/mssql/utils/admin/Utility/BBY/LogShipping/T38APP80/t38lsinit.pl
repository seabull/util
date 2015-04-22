#!perl 
#* t38lsinit - initialize database for log shipping on secondary server.
#*
#*	$Author: A645276 $
#*	$Date: 2011/02/08 15:32:28 $
#*	$Revision: 1.1 $
#*	$Archive:   //cs01pvcs/pvcs/cm/Database/archives/Applications/LogShipping/t38lsinit.pv_  $
#*
#* SYNOPSIS
#*	t38lsinit -h -C destination_copy_server -S source_server -d dbname -c cfgFile -x execOpt
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
#*				LsdBkpDrive				-- Drive name for Log shipping backup 
#*										   files on destination server.
#*				LsdBkpPath				-- Path to Log shipping backup files
#*										   on destination server.
#*				__SharePointLsdBkpPath	-- Share name for Log shipping backup
#*										   files on destination server.
#*	-x execOpt	Execution option:
#*				s -- create shares (has to be used with -c option).
#*				b -- backup database on primary server.
#*				c -- copy backup files from primary to secondary server.
#*				r -- delete old t-logs and restore database on secondary server.
#*				e -- enable log shipping in configuration file (-c option required).
#*				default is 'scre'.
#*	
#*	
#*	This program initializes database for log shipping on secondary server.
#*
#*	Example:
#*		t38lsinit -S hst6db -C hst5db\inst1 -d MXRDB001 -x bcr
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
		$gRunOpt $gCfgFile $gDestClstrSrvrFlg $gSrcClstrSrvrFlg
		$gSrvrSrc $gNetSrc $gInstSrc
		$gSrvrDest $gNetDest $gInstDest
		$gLSSrcDBkpShr $gLSDestDBkpShr $gLSDBkpDir
		$gNWarnings
		);

# Main

&main();

sub main {
	my $mainStatus	= 0;
	my %cfgtodo		= (		# List of values to update in config file.
		LogShipEnabledFlg => 'Y', 
		);
SUB:
{
	unless (&housekeeping())						{ $mainStatus = 1; last SUB; }

	if ($gRunOpt =~ /s/i && !&createDestShare())	{ $mainStatus = 1; last SUB; }
	if ($gRunOpt =~ /b/i && !&backupSrcDb())		{ $mainStatus = 1; }
	if ($gRunOpt =~ /c/i) {
		unless (&createLSDBkpDir())					{ $mainStatus = 1; last SUB; }
		unless (&copySrcFiles())					{ $mainStatus = 1; last SUB; }
	}
	if ($gRunOpt =~ /r/i && !&restoreDestDb())		{ $mainStatus = 1; last SUB; }
	if ($gRunOpt =~ /e/i && !&updateCfgFile($gCfgFile, \%cfgtodo))
													{ $mainStatus = 1; last SUB; }

	last SUB;
	
}	# SUB
# ExitPoint:
	$mainStatus = 1	if ($gNWarnings > 0);
	( $mainStatus== 0 ) ?
		logme("Finished with status $mainStatus", "done") :
		warnme("Finished with status $mainStatus", "done") ;
	exit($mainStatus);
}	# main


#######################  $Workfile:   t38lsinit.pl  $ Subroutines  #################################


# ----------------------------------------------------------------------
#	backupSrcDb	backup log ship source databases
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
	&notifyWSub("Backup log ship source databases.");
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
#	copySrcFiles	copy account scripts from source server
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
	if($gDestClstrSrvrFlg eq 'Y') {
		$bkpSrcLoc	= ($gInstSrc eq '')? "\\\\$gNetSrc\\t38bkp.$gConfigValues{LsSrcGroupName}" : "\\\\$gNetSrc\\t38bkp.$gConfigValues{LsSrcGroupName}\\$gInstSrc";
	} else {
		$bkpSrcLoc	= ($gInstSrc eq '')? "\\\\$gNetSrc\\t38bkp" : "\\\\$gNetSrc\\t38bkp\\$gInstSrc";
	}
	&notifyWSub("Copy files from $bkpSrcLoc to $gLSDBkpDir.");

	foreach $dbname (@gDBList) {
		$filename = "$bkpSrcLoc\\${dbname}_db\.bkp";
		&notifyWSub("Copy $filename to $gLSDBkpDir.");
		$cmd = "cmd /E:on /C \"copy /Y /V $filename $gLSDBkpDir\"";
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
#	createDestShare	create destination share for backup files
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------

sub createDestShare () {
	my $cmd		= '';
	my $cmdOut	= '';
	my $fname	= '';
	my $share	= '';
	my $status	= 1;
SUB:
{
	&notifyWSub("Creating share $gLSDestDBkpShr.");
	# Create directory for LsdBkp share.
	unless (
		defined($gConfigValues{LsdBkpDrive}) && $gConfigValues{LsdBkpDrive} &&
		defined($gConfigValues{LsdBkpPath}) && $gConfigValues{LsdBkpPath}
		) {
		&errme("Cannot create $gLSDestDBkpShr share. Missing configuration information.");
		&notifyMe("Ensure -c options is used and configuration file includes LsdBkp information.");
		$status = 0; last SUB;
	}

	# Create directory using administrative share (X$) first.
	$fname = "\\\\$gNetDest\\$gConfigValues{LsdBkpDrive}\$$gConfigValues{LsdBkpPath}";
	unless (-d $fname) {
		&notifyWSub("Create directory $fname.");
		$cmd = "cmd /E:on  /C \"mkdir $fname\"";
		unless (system($cmd) == 0) {
			&errme("Problem with $cmd");
			$status = 0; last SUB;
		}
	}

	# Create share.


	if($gSrcClstrSrvrFlg eq 'Y') {

		$share = "$gLSDestDBkpShr";
		$fname = "$gConfigValues{LsdBkpDrive}:$gConfigValues{LsdBkpPath}";
		$cmd = "cluster . res \"$share\" /create /group:\"$gConfigValues{LsDestGroupName}\" /type:\"File Share\"";
		$cmdOut = `cmd /C $cmd`;
		$cmd = "cluster . res \"$share\" /priv path=\"$fname\"";
		$cmdOut = `cmd /C $cmd`;
		$cmd = "cluster . res \"$share\" /priv Sharename=$share";
		$cmdOut = `cmd /C $cmd`;
		$cmd = "cluster . res \"$share\" /priv Remark=\"This is a File Share for Log Shipping\"";
		$cmdOut = `cmd /C $cmd`;
		$cmd = "cluster . res \"$share\" /prop Description=\"This is a Clustered Share\"";
		$cmdOut = `cmd /C $cmd`;
		$cmd = "cluster . res \"$share\" /priv security=Administrators,grant,f:security";
		$cmdOut = `cmd /C $cmd`;
		$cmd = "cluster . res \"$share\" /priv ShareSubDirs=1";              #  Share all sub directories
		$cmdOut = `cmd /C $cmd`;
		$cmd = "cluster . res \"$share\" /AddDep:\"Disk $gConfigValues{LsdBkpDrive}:\"";                 # Dependency
		$cmdOut = `cmd /C $cmd`;
		$cmd = "cluster . res \"$share\" /AddDep:\"SQL Network Name ($gConfigValues{LsDestGroupName})\"";
		$cmdOut = `cmd /C $cmd`;
		$cmd = "cluster . res \"$share\" /On";
		$cmdOut = `cmd /C $cmd`;

	} else {

		$share = "\\\\$gNetDest\\$gLSDestDBkpShr";
		$fname = "$gConfigValues{LsdBkpDrive}:$gConfigValues{LsdBkpPath}";
		
		$cmd = "rmtshare $share /del";
		$cmdOut = `cmd /C $cmd`;

		$cmd = "rmtshare $share=$fname /UNLIMITED /REMARK:\"Shared by $gScriptName\" /GRANT Administrators:f /REMOVE Everyone";
		$cmdOut = `cmd /C $cmd`;    

	}

	if ($cmdOut =~ /command failed/i) {
		&errme("Problem with $cmd");
		&notifyMe("Result is:\n$cmdOut");
		$status = 0; last SUB;
	}

	last SUB;
}	# SUB
# ExitPoint:
	return($status);
}	# createDestShare

# ----------------------------------------------------------------------
#	createLSDBkpDir	create log ship destination backup directory
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
# ----------------------------------------------------------------------

sub createLSDBkpDir () {
	my $cmd		= '';
	my $status	= 1;
SUB:
{
	last SUB	if (-d $gLSDBkpDir);

	&notifyWSub("Create directory $gLSDBkpDir.");
	$cmd = "cmd /E:on  /C \"mkdir $gLSDBkpDir\"";
	unless (system($cmd) == 0) {
		&errme("Problem with $cmd");
		$status = 0; last SUB;
	}

	last SUB;
}	# SUB
# ExitPoint:
	return($status);
}	# createLSDBkpDir


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
	$gDestClstrSrvrFlg	=	($gConfigValues{LogShipDestClstrFlg});
	$gSrcClstrSrvrFlg	=	($gConfigValues{LogShipSrcClstrFlg});

	if (defined($gConfigValues{LogShipDatabases}) && $gConfigValues{LogShipDatabases}) {
		@gDBList = split(/[,\s]+/, $gConfigValues{LogShipDatabases});
	}
   
	if($gSrcClstrSrvrFlg eq 'Y') {
		$gLSSrcDBkpShr	= "$gConfigValues{__SharePointLsdBkpPath}.$gConfigValues{LsSrcGroupName}"	if (defined($gConfigValues{__SharePointLsdBkpPath}) && $gConfigValues{__SharePointLsdBkpPath});
	} else { 
		$gLSSrcDBkpShr	= $gConfigValues{__SharePointLsdBkpPath}	if (defined($gConfigValues{__SharePointLsdBkpPath}) && $gConfigValues{__SharePointLsdBkpPath});
   }
	if($gDestClstrSrvrFlg eq 'Y') {
		$gLSDestDBkpShr	= "$gConfigValues{__SharePointLsdBkpPath}.$gConfigValues{LsDestGroupName}"	if (defined($gConfigValues{__SharePointLsdBkpPath}) && $gConfigValues{__SharePointLsdBkpPath});
	} else { 
		$gLSDestDBkpShr	= $gConfigValues{__SharePointLsdBkpPath}	if (defined($gConfigValues{__SharePointLsdBkpPath}) && $gConfigValues{__SharePointLsdBkpPath});
   }
	$status	= 1;
	last SUB;
}
	return($status);	
} # getConfigFileParms


# ----------------------------------------------------------------------
#	restoreDestDb	restore log ship destination database
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
	&notifyWSub("Resotre log ship destination databases.");
	unless ($cmd = adoConnect($gSrvrDest, 'master')) { 
		&errme("adoConnect($gSrvrDest, $dbname) Failed"); 
		$status = 0; last SUB;
	}

	# Restore database.

	unless($bkpDestPath = unc2path($gNetDest, "\\\\$gNetDest\\$gLSDestDBkpShr")) {
		&errme("Cannot find share $gLSDBkpDir on $gNetDest.");
		$status = 0; last SUB;
	}

	$bkpDestPath .= ($gInstDest) ? "\\$gInstDest":"\\default";
	$bkpDestPath .= "\\$gNetSrc";
	$bkpDestPath .= ($gInstSrc) ? "\\$gInstSrc":"\\default";
	
	foreach $dbname (@gDBList) {
		# Kill users and put database into restricted mode.

#		&killDBAccess($cmd, $dbname);

		# Restore database.

		# $sql = "backup log $dbname with norecovery";  This sets the database ready for recovery
		# $sql = "backup log $dbname to disk = \'$bkpDestPath\\${dbname}_log_reset\.bkp\' with NORECOVERY";
		# &notifyMe("execSQLCmd(\$cmd, $sql))");
		# unless(&execSQLCmd($cmd, $sql)) { $status = 0; last SUB; }
		# $sql = "restore database $dbname from disk = \'$bkpDestPath\\${gDBName}_db\.bkp\' with norecovery";
		$sql = "restore database $dbname from disk = \'$bkpDestPath\\${dbname}_db\.bkp\' with standby = \'$bkpDestPath\\${dbname}_undo.ldf\'";
		&notifyMe("execSQLCmd(\$cmd, $sql))");
		unless(&execSQLCmd($cmd, $sql)) { $status = 0; last SUB; }
		# Delete old t-log dumps. They cannot be used anymore.
		unlink glob("$gLSDBkpDir\\${dbname}_log_\*\.bkp");
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
	$gRunOpt	= 'scre';		# default Execution options 
								#	create shares, 
								#	copy backup files,
								#	restore them, 
								#	enable log shipping in configuration file
	$gLSDestDBkpShr	= 't38lsdbkp';
	$gLSSrcDBkpShr	= 't38lsdbkp';
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

	if ($gRunOpt =~/[se]/i && !$opt_c) {
		&errme("Configuration file has to be used with default or -x se option.");
		return(0);
	}

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

	$gLSDBkpDir = "\\\\$gNetDest\\$gLSDestDBkpShr";
	$gLSDBkpDir .= ($gInstDest) ? "\\$gInstDest":"\\default";
	$gLSDBkpDir .= "\\$gNetSrc";
	$gLSDBkpDir .= ($gInstSrc) ? "\\$gInstSrc":"\\default";


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
#* t38lsinit - initialize database for log shipping on secondary server.
#*
#*	$Author: A645276 $
#*	$Date: 2011/02/08 15:32:28 $
#*	$Revision: 1.1 $
#*	$Archive:   //cs01pvcs/pvcs/cm/Database/archives/Applications/LogShipping/t38lsinit.pv_  $
#*
#* SYNOPSIS
#*	t38lsinit -h -C destination_copy_server -S source_server -d dbname -c cfgFile -x execOpt
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
#*				LsdBkpDrive				-- Drive name for Log shipping backup 
#*										   files on destination server.
#*				LsdBkpPath				-- Path to Log shipping backup files
#*										   on destination server.
#*				__SharePointLsdBkpPath	-- Share name for Log shipping backup
#*										   files on destination server.
#*	-x execOpt	Execution option:
#*				s -- create shares (has to be used with -c option).
#*				b -- backup database on primary server.
#*				c -- copy backup files from primary to secondary server.
#*				r -- delete old t-logs and restore database on secondary server.
#*				e -- enable log shipping in configuration file (-c option required).
#*				default is 'scre'.
#*	
#*	
#*	This program initializes database for log shipping on secondary server.
#*
#*	Example:
#*		t38lsinit -S hst6db -C hst5db\inst1 -d MXRDB001 -x bcr
#*
#*	Backup MXRDB001 database on default instance of the HST6DB server, copy backup
#*	files to \\HST5DB\t38lsdbkp\inst1\HST6DB\default directory, kills all users of
#*	the MXRDB001 and restores it from backups.
#*
EOT
} #	showHelp
