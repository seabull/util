#!perl 
#* t38lstrst - restore transactions for log shipping on secondary server.
#*
#*	$Author: A645276 $
#*	$Date: 2011/02/08 15:32:29 $
#*	$Revision: 1.1 $
#*	$Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/LogShipping/t38lstrst.pv_  $
#*
#* SYNOPSIS
#*	t38lstrst -h -C destination_copy_server -S source_server -d dbname -c cfgFile
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
#*				LogShipEnabledFlg		-- flag, indicating if log shipping
#*										   is enabled. Default is enabled.
#*				LogShipDestClstrFlg	--  Is destination server clustered? (Y/N)
#*				LogShipSrcClstrFlg	--  Is Source server clustered? (Y/N)
#*	
#*	
#*	This program runs on scheduled intervals (every 15 minutes) to restores 
#*	transaction log dumps for log shipping on secondary server.
#*
#*	It will perform the following steps:
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
#*		t38lstrst.pl -c \\%computername%\t38app80\inst1\t38dba.cfg
#*	Use configuration file t38dba.cfg for all log shipping parameters.
#*	Copy transaction log dumps for log shipping databases from source
#*	to destination. Restore transaction log dumps.
#*
#*	Example 2:
#*		t38lstrst.pl -S hst6db -C hst5db\inst1 -d ADMDB001
#*
#*	Copy transaction log dumps for ADMDB001 database on default instance 
#*	of the HST6DB server to \\HST5DB\t38lsdbkp\inst1\HST6DB\default 
#*	directory. Restore transaction log dumps on HST5DB\inst1 ADMDB001
#*	database. 
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
		$opt_h $opt_c $opt_C $opt_S $opt_d
		$gHostName @gDBList
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
	unless (&housekeeping())		{ $mainStatus = 1; last SUB; }
	if (
		$opt_c && 
		(!defined($gConfigValues{LogShipEnabledFlg}) || $gConfigValues{LogShipEnabledFlg} ne 'Y')
		) {
		# Configuration file is used, but Log shipping flag is not specified or it is 'N'.
		&warnme("Nothing to do. Log Shipping is disabled in $opt_c configuration file.");
		# This is not really an error, just a warning. So exit normally.
		$mainStatus = 0;
		last SUB;
	}

	&crDir4ProcessedFiles();

	unless (&copySrcFiles())		{ $mainStatus = 1; }
	unless (&restoreDestTlog())		{ $mainStatus = 1; last SUB; }

	last SUB;
	
}	# SUB
# ExitPoint:
	$mainStatus = 1	if ($gNWarnings > 0);
	( $mainStatus== 0 ) ?
		logme("Finished with status $mainStatus", "done") :
		warnme("Finished with status $mainStatus", "done") ;
	exit($mainStatus);
}	# main


#######################  $Workfile:   t38lstrst.pl  $ Subroutines  #################################


# ----------------------------------------------------------------------
#	copySrcFiles	copy account scripts from source server
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
#	This function copies new t-log files from source server to 
#	destination.
#
#	For each database, do following steps:
#
#	- Get latest t-log dump file on destination server (processed or 
#	  not processed yet).
#	- Get name of the last completed t-log dump file on source server
#	  from msdb database.
#	- Build list of all files newer than one from destination server and
#	  older then and including one from source server.
#	- Copy all files, in the list of files to copy, to destination server
#
# ----------------------------------------------------------------------

sub copySrcFiles () {
	my $oscmd		= '';
	my $filename	= '';
	my $basename	= '';
	my $dbname		= '';
	my $bkpSrcLoc	= '';		# backup location on source server
	my $bkpSrcPath	= '';		# backup location on source server
	my @filelist	= ();
	my $newestsrc	= '';		# Latest t-log dump created on source server
	my $newestdest	= '';		# Latest t-log dump copied to destination server
	my $adocmd		= 0;		# ADO Command object handle
	my @rs			= ();		# array with result set
	my $sql			= '';		# sql command buffer
	my $status		= 1;
SUB:
{
	$bkpSrcLoc	= ($gInstSrc eq '')? "\\\\$gNetSrc\\$gDBkpShr" : "\\\\$gNetSrc\\$gDBkpShr\\$gInstSrc";
	unless($bkpSrcPath = unc2path($gNetSrc, "\\\\$gNetSrc\\$gDBkpShr")) {
		&errme("Cannot find $gDBkpShr share on $gNetSrc.");
		$status = 0; last SUB;
	}

	$bkpSrcPath .= "\\$gInstSrc" if ($gInstSrc);

	&notifyWSub("Copy files from $bkpSrcLoc to $gLSDBkpDir.");

	unless ($adocmd = adoConnect($gSrvrSrc, 'master')) { 
		&errme("adoConnect($gSrvrSrc) Failed");
		$status = 0; last SUB;
	}

	foreach $dbname (@gDBList) {
		# Find latest copied files on destination server.

		# First check destination directory, where files are processed.
		@filelist = glob("$gLSDBkpDir\\${dbname}_log_\*\.bkp");
		$newestdest = &stripPath($filelist[$#filelist])	if (@filelist);

		# Check done directory.

		@filelist = glob("$gLSDBkpDir\\tlogdone\\${dbname}_log_\*\.bkp");
		$filename = &stripPath($filelist[$#filelist]) if (@filelist);
		$newestdest = $filename	if ($filename && $filename gt $newestdest);

		# Check failed directory.

		@filelist = glob("$gLSDBkpDir\\tlogfail\\${dbname}_log_\*\.bkp");
		$filename = &stripPath($filelist[$#filelist]) if (@filelist);
		$newestdest = $filename	if ($filename && $filename gt $newestdest);

		# Now we need name of the latest t-log dump on source server.
		$sql	= <<"		EOT";
			select	max(mf.physical_device_name) as 'MaxPhyDeviceName'
			from 
				msdb..backupset bs join msdb..backupmediafamily mf on bs.media_set_id = mf.media_set_id
			where 
			bs.database_name = '$dbname'
			and bs.type = 'L' 
			and bs.server_name = \@\@servername
			and bs.backup_finish_date < getdate()
			and lower(mf.physical_device_name) like lower('$bkpSrcPath\\$dbname\[_\]log\[_\]\%')
		EOT

		unless(&execSQL2Arr($adocmd, $sql, \@rs)) { $status = 0; last SUB; }

		$newestsrc = stripWhitespace($rs[0]{MaxPhyDeviceName});
		$newestsrc = stripPath($newestsrc);

		unless ($newestsrc) {
			&warnme("Cannot find latest transaction log dump for $dbname database in msdb.");
			$gNWarnings++;
			$status = 0;
			next;
		}

		# Build a list of files that are new than last one we copied to destination server
		# and is not newer that the last completed t-log dump (we should not touch t-log
		# dump in progress).

		@filelist = glob("$bkpSrcLoc\\${dbname}_log_\*\.bkp");

		foreach $filename (reverse(@filelist)) {
			$basename = &stripPath($filename);
			next if ($basename gt $newestsrc);	# Skip to next file. SQL Server is stil using this one.
			last if ($basename eq $newestdest);	# We are done, the rest of the files are already on destination server.

			&notifyWSub("Copy $filename to $gLSDBkpDir.");
			$oscmd = "cmd /E:on /C \"copy /Y /V $filename $gLSDBkpDir\"";
			unless (system($oscmd) == 0) {
				&warnme("Problem with $oscmd");
				$gNWarnings++;
				$status = 0;
			}
		}
	}

	last SUB;
}	# SUB
# ExitPoint:
	if ($adocmd) { $adocmd->Close(); $adocmd = 0; }
	return($status);
}	# copySrcFiles


# ----------------------------------------------------------------------
#	crDir4ProcessedFiles	create directories for processed t-log dumps
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
#	This subroutine creates directory, where processed transaction log
#	dump files are moved. Successfully restored t-log dumps are moved
#	to tlogdone directory. Failed files are moved to tlogfail directory.
# ----------------------------------------------------------------------

sub crDir4ProcessedFiles () {
	my $cmd		= '';
	my $fname	= '';
	my $status	= 1;
SUB:
{
	foreach $fname	(("$gLSDBkpDir\\tlogdone", "$gLSDBkpDir\\tlogfail")) {
		unless (-d $fname) {
			&notifyWSub("Create directory $fname.");
			$cmd = "cmd /E:on  /C \"mkdir $fname\"";
			unless (system($cmd) == 0) {
				&errme("Problem with $cmd");
				$status = 0; next;
			}
		}
	}

	last SUB;
}	# SUB
# ExitPoint:
	return($status);
}	# crDir4ProcessedFiles


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



# ----------------------------------------------------------------------
#	restoreDestTlog	restore t-log for destination databases
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
#	This function restores t-log for each log shipped database on
#	destination server.
#
#	For each database, the following steps are done:
#
#	- get chronologically sorted list of t-log dumps in t38lsdbkp
#	  directory.
#	- get name of the t-log dump file, that was last restored from
#	  msdb database.
#	- restore all files newer than the last restored.
#	- move successfully restored files to done directory.
#	- move failed files to fail directory.
#
# ----------------------------------------------------------------------

sub restoreDestTlog () {
	my $dbname		= '';
	my $adocmd			= 0;		# ADO Command object handle
	my @rs			= ();		# array with result sets
	my $sqlerr		= 0;
	my $sql			= '';		# sql command buffer
	my $bkpDestPath	= '';
	my $newestrst	= '';		# Latest t-log dump, restored on destination server
	my @filelist	= ();
	my $filename	= '';
	my $basename	= '';
	my $osout		= '';
	my $status		= 1;
SUB:
{
	&notifyWSub("Resotre log ship destination databases.");

	unless ($adocmd = adoConnect($gSrvrDest, 'master')) { 
		&errme("adoConnect($gSrvrDest, $dbname) Failed");
		$status = 0; last SUB;
	}

	# Clear restore history.

	$sql = <<'EOT';
	declare @targetDate	datetime
	set @targetDate = dateadd(Month, -3,getdate())
	exec msdb..sp_delete_backuphistory @oldest_date = @targetDate
EOT
	unless(&execSQL2Arr($adocmd, $sql, \@rs)) { $status = 0; last SUB; }

	# Restore database.

	unless($bkpDestPath = unc2path($gNetDest, "\\\\$gNetDest\\$gLSDBkpShr")) {
		&errme("Cannot find share $gLSDBkpDir on $gNetDest.");
		$status = 0; last SUB;
	}

	$bkpDestPath .= ($gInstDest) ? "\\$gInstDest":"\\default";
	$bkpDestPath .= "\\$gNetSrc";
	$bkpDestPath .= ($gInstSrc) ? "\\$gInstSrc":"\\default";
	
	foreach $dbname (@gDBList) {
		#	Get name of the t-log dump file, that was last restored from
		#	msdb database.

		$sql	= <<"		EOT";
			select	max(mf.physical_device_name) as 'MaxPhyDeviceName'
			from 
				msdb..restorehistory rh join msdb..backupset bs on rh.backup_set_id = bs.backup_set_id
				join msdb..backupmediafamily mf on bs.media_set_id = mf.media_set_id
			where 
			rh.destination_database_name = '$dbname'
			and rh.restore_type = 'L' 
			and upper(bs.server_name) = upper('$gNetSrc\\$gInstSrc')
			and rh.restore_date < getdate()
			and upper(mf.physical_device_name) like upper('$bkpDestPath\\$dbname\[_\]log\[_\]\%')
		EOT

		unless(&execSQL2Arr($adocmd, $sql, \@rs)) { $status = 0; last SUB; }

		$newestrst = stripWhitespace($rs[0]{MaxPhyDeviceName});
		$newestrst = stripPath($newestrst);
		@filelist = glob("$gLSDBkpDir\\${dbname}_log_\*\.bkp");

		#	Get chronologically sorted list of t-log dumps in t38lsdbkp
		#	directory.

		# Kill users and put database into restricted mode.

		&killDBAccess($adocmd, $dbname);

		#	Restore all files newer that the last restored.

		foreach $filename (@filelist) {
			$basename = &stripPath($filename);
			next if ($basename le $newestrst);	# Skip to next file. This one is already restored.

			&notifyWSub("Restore t-log from $filename for $dbname database.");

			# $sql = "restore database $dbname from disk = \'$bkpDestPath\\$basename\' with norecovery";
			$sql = "restore transaction $dbname from disk = \'$bkpDestPath\\$basename\' with standby = \'$bkpDestPath\\${dbname}_undo.ldf\'";
			&notifyMe("execSQLCmd(\$adocmd, $sql))");
			if (&execSQLCmd($adocmd, $sql)) {
				$osout	= `cmd /E:on /C \"move /Y $gLSDBkpDir\\$basename $gLSDBkpDir\\tlogdone\"`;
			} else {
				&warnme("Problem with t-log restore. Move $basename to $gLSDBkpDir\\tlogfail directory.");
				$gNWarnings++;
				$status = 0;
				$osout	= `cmd /E:on /C \"move /Y $gLSDBkpDir\\$basename $gLSDBkpDir\\tlogfail\"`;
			}
		}	# end foreach $filename
	}	#	end foreach $dbname

	last SUB;
}	# SUB
# ExitPoint:
	if ($adocmd) { $adocmd->Close(); $adocmd = 0; }
	return($status);
}	# restoreDestTlog



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


	getopts('hc:C:d:S:');

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
	$gNWarnings	= 0;

	#-- show help

	if ($opt_h) { &showHelp; exit; }

	# Open log and error files, if needed.

	unless (&T38lib::Common::setLogFileDir("$gScriptPath\\T38LOG\\$gScriptName")) {
		&errme("Cannot set scripts log directory.");
		return(0);
	}

	&T38lib::Common::archiveLogFile(96);
	&logme("Starting $gScriptName from $gScriptPath", "started");

	# Overwrite default parameters from configuration file.

	if ($opt_c && !&getConfigFileParms($opt_c)) { return 0;	}

	# And now overwrite them from command line.
	# Validate command line arguments.
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
#* t38lstrst - restore transactions for log shipping on secondary server.
#*
#*	$Author: A645276 $
#*	$Date: 2011/02/08 15:32:29 $
#*	$Revision: 1.1 $
#*	$Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/LogShipping/t38lstrst.pv_  $
#*
#* SYNOPSIS
#*	t38lstrst -h -C destination_copy_server -S source_server -d dbname -c cfgFile
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
#*				LogShipEnabledFlg		-- flag, indicating if log shipping
#*										   is enabled. Default is enabled.
#*				LogShipDestClstrFlg	--  Is destination server clustered? (Y/N)
#*				LogShipSrcClstrFlg	--  Is Source server clustered? (Y/N)
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
#*		t38lstrst.pl -c \\%computername%\t38app80\inst1\t38dba.cfg
#*	Use configuration file t38dba.cfg for all log shipping parameters.
#*	Copy transaction log dumps for log shipping databases from source
#*	to destination. Restore transaction log dumps.
#*
#*	Example 2:
#*		t38lstrst.pl -S hst6db -C hst5db\inst1 -d ADMDB001
#*
#*	Copy transaction log dumps for ADMDB001 database on default instance 
#*	of the HST6DB server to \\HST5DB\t38lsdbkp\inst1\HST6DB\default 
#*	directory. Restore transaction log dumps on HST5DB\inst1 ADMDB001
#*	database. 
#*
EOT
} #	showHelp
