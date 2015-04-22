#!perl 
#* t38lstbrm - remove transaction backup files for log shipping databases.
#*
#*	$Author: A645276 $
#*	$Date: 2011/02/08 15:32:29 $
#*	$Revision: 1.1 $
#*	$Archive:   //cs01pvcs/pvcs/cm/Database/archives/Applications/LogShipping/t38lstbrm.pv_  $
#*
#* SYNOPSIS
#*	t38lstbrm -h -C destination_copy_server -S source_server -d dbname -c cfgFile -x execOpt
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
#*				provide defaults for common options.  If either servers are cluster, the config file must be used.
#*				Following parameters are excepted:
#*				LogShipSrcServer	 	-- can be overwritten by -C option
#*				LogShipSrcInstance	 	-- can be overwritten by -C option
#*				LogShipDestServer		-- can be overwritten by -S option
#*				LogShipDestInstance		-- can be overwritten by -S option
#*				LogShipDatabases		-- can be overwritten by -d option
#*				LogShipDestClstrFlg	--  Is destination server clustered? (Y/N)
#*				LogShipSrcClstrFlg	--  Is Source server clustered? (Y/N)
#*	-x execOpt	Execution option:
#*				s -- remove transaction log dumps, older than 48 hours 
#*				     from source server.
#*				d -- remove transaction log dumps, older than 48 hours 
#*				     from destination server.
#*				
#*				default is to execute all run steps.
#*	
#*	
#*	This program deletes old transacion log dumps for log shipping databases.
#*
#*	- Delete log shipping transaction log dumps, older than 48 hours from 
#*	  source server.
#*	- Delete processed files (in done directory), older than 48 hours from
#*	  destination server. Delete failed t-log restores from fail directory,
#*	  older than 168 hours (7 days). Delete unprocessed t-log files older
#*	  than 7 days.
#*
#*	Example:
#*		t38lstbrm.pl -S hst6db -C hst5db\inst1 -x s
#*
#*	 This will delete transaction log dumps, older than 
#*	48 hours for log shipping database from source servers.
#*
#***

use strict;

use File::DosGlob qw(glob);

#-- constants

use T38lib::Common qw(notifyMe notifyWSub logme warnme errme 
				stripWhitespace stripPath
				whence unc2path
				);
use T38lib::t38cfgfile qw(:CFGFILE_SUBS :CFGFILE_VARS);
use vars qw(
		$gCurrentDir $gScriptName $gScriptPath
		$opt_h $opt_c $opt_C $opt_S $opt_d $opt_x
		$gHostName @gDBList
		$gRunOpt
		$gSrvrSrc $gNetSrc $gInstSrc
		$gSrvrDest $gNetDest $gInstDest
		$gLSDBkpShr $gLSDBkpDir $gSrcClstrSrvrFlg $gDestClstrSrvrFlg
		$gNWarnings $gDBkpShr
		);

# Main

&main();

sub main {
	my $mainStatus	= 0;
SUB:
{
	unless (&housekeeping())						{ $mainStatus = 1; last SUB; }
	if ($gRunOpt =~ /s/i && !&cleanupSrcTlogs())	{ $mainStatus = 1; last SUB; }
	if ($gRunOpt =~ /d/i && !&cleanupDestTlogs())	{ $mainStatus = 1; }

	last SUB;
	
}	# SUB
# ExitPoint:
	$mainStatus = 1	if ($gNWarnings > 0);
	( $mainStatus== 0 ) ?
		logme("Finished with status $mainStatus", "done") :
		warnme("Finished with status $mainStatus", "done") ;
	exit($mainStatus);
}	# main


#######################  $Workfile:   t38lstbrm.pl  $ Subroutines  #################################


# ----------------------------------------------------------------------
#	cleanupSrcTlogs	cleanup old transaction log dumps on source server
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------

sub cleanupSrcTlogs () {
	my $dbname		= '';
	my $bkpSrcLoc	= ($gInstSrc eq '')? "\\\\$gNetSrc\\$gDBkpShr" : "\\\\$gNetSrc\\$gDBkpShr\\$gInstSrc";
	my $status	= 1;
SUB:
{
	&notifyWSub("Cleanup old transaction log dumps on $gSrvrSrc.");

	# Backup database.
	foreach $dbname (@gDBList) {
		&notifyMe("Cleanup for database $dbname");
		&delFilesNHourOld("$bkpSrcLoc\\${dbname}_log_\*\.bkp", 48);
	}

	last SUB;
}	# SUB
# ExitPoint:
	return($status);
}	# cleanupSrcTlogs

# ----------------------------------------------------------------------
#	cleanupDestTlogs	cleanup old transaction log dumps on destination
#						server
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------

sub cleanupDestTlogs () {
	my $dbname	= '';
	my $status	= 1;
SUB:
{
	&notifyWSub("Cleanup old transaction log dumps on $gSrvrSrc.");

	# Backup database.
	foreach $dbname (@gDBList) {
		&notifyMe("Cleanup for database $dbname");
		&delFilesNHourOld("$gLSDBkpDir\\tlogdone\\${dbname}_log_\*\.bkp", 48);	# done directory - 2 days
		&delFilesNHourOld("$gLSDBkpDir\\tlogfail\\${dbname}_log_\*\.bkp", 168);	# failed directory - 7 days
		&delFilesNHourOld("$gLSDBkpDir\\${dbname}_log_\*\.bkp", 168);			# Destination directory - 7 days
	}

	last SUB;
}	# SUB
# ExitPoint:
	return($status);
}	# cleanupDestTlogs


# ----------------------------------------------------------------------
#	delFilesNHourOld	delete files, older than specified number of hours
# ----------------------------------------------------------------------
#	arguments:
#		filepat	files pattern to delete
#		nhours	delete files, older than nhours
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------

sub delFilesNHourOld($$) {
	my $filepat		= shift;
	my $nhours		= shift;
	my @filelist	= ();
	my $filename	= '';
	my $deltime		= 0;		# Delete date converted to seconds since epoch.
	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
       $atime,$mtime,$ctime,$blksize,$blocks);	# File stat function call results.
	my $status	= 1;
SUB:
{
	$deltime = time - ($nhours*60*60);
	&notifyWSub("Delete $filepat files, older than " . scalar localtime($deltime));

	@filelist = glob($filepat);
	foreach $filename (@filelist) {
		($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size, $atime,$mtime,$ctime,$blksize,$blocks)
			= stat($filename);
		if ($mtime < $deltime) {
			my $pstr	= '';
			$pstr = sprintf "Delete %s, mtime: %s, size: %s,", 
				$filename, scalar localtime $mtime, $size;
			&notifyMe($pstr);
			unlink ($filename);
		}
	}

	last SUB;
}	# SUB
# ExitPoint:
	return($status);
}	# delFilesNHourOld


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
	
	$gDestClstrSrvrFlg	=	($gConfigValues{LogShipDestClstrFlg});
	$gSrcClstrSrvrFlg	=	($gConfigValues{LogShipSrcClstrFlg});


	$status	= 1;
	last SUB;
}
	return($status);	
} # getConfigFileParms


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
	$gRunOpt	= 'sd';			# default Execution options:
								#					cleanup source t-logs, 
								#					cleanup destination) t-logs.

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

	if ($opt_c && !&getConfigFileParms($opt_c)) { return 0;	}

	if($gSrcClstrSrvrFlg eq 'Y') {
		$gDBkpShr	= "t38bkp.$gConfigValues{LsSrcGroupName}"	if (defined($gConfigValues{__SharePointLsdBkpPath}) && $gConfigValues{__SharePointLsdBkpPath});
	} else { 
		$gDBkpShr	= 't38bkp';
   }

	if($gDestClstrSrvrFlg eq 'Y') {
		$gLSDBkpShr	= "$gConfigValues{__SharePointLsdBkpPath}.$gConfigValues{LsDestGroupName}"	if (defined($gConfigValues{__SharePointLsdBkpPath}) && $gConfigValues{__SharePointLsdBkpPath});
	} else { 
		$gLSDBkpShr	= 't38lsdbkp';
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

	&notifyWSub("$gHostName: Remove old tlogs from $gSrvrSrc and $gSrvrDest.");

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
#* t38lstbrm - remove transaction dump for log shipping databases.
#*
#*	$Author: A645276 $
#*	$Date: 2011/02/08 15:32:29 $
#*	$Revision: 1.1 $
#*	$Archive:   //cs01pvcs/pvcs/cm/Database/archives/Applications/LogShipping/t38lstbrm.pv_  $
#*
#* SYNOPSIS
#*	t38lstbrm -h -C destination_copy_server -S source_server -d dbname -c cfgFile -x execOpt
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
#*				provide defaults for common options.   If either servers are cluster, the config file must be used.
#*				Following parameters are excepted:
#*				LogShipSrcServer	 	-- can be overwritten by -C option
#*				LogShipSrcInstance	 	-- can be overwritten by -C option
#*				LogShipDestServer		-- can be overwritten by -S option
#*				LogShipDestInstance		-- can be overwritten by -S option
#*				LogShipDatabases		-- can be overwritten by -d option
#*				LogShipDestClstrFlg	--  Is destination server clustered? (Y/N)
#*				LogShipSrcClstrFlg	--  Is Source server clustered? (Y/N)
#*	-x execOpt	Execution option:
#*				s -- remove transaction log dumps, older than 48 hours 
#*				     from source server.
#*				d -- remove transaction log dumps, older than 48 hours 
#*				     from destination server.
#*				
#*				default is to execute all run steps.
#*	
#*	
#*	This program deletes old transacion log dumps for log shipping databases.
#*
#*	- Delete log shipping transaction log dumps, older than 48 hours from 
#*	  source server.
#*	- Delete processed files (in done directory), older than 48 hours from
#*	  destination server. Delete failed t-log restores from fail directory,
#*	  older than 168 hours (7 days). Delete unprocessed t-log files older
#*	  than 7 days.
#*
#*	Example:
#*		t38lstbrm.pl -S hst6db -C hst5db\inst1 -x s
#*
#*	 This will delete transaction log dumps, older than 
#*	48 hours for log shipping database from source servers.
#*
EOT
} #	showHelp
