#!perl 
#* t38monNetBackup - #<# Monitor the progress of Net Backup Reuqests#>#.
#*
#*	$Author: A645276 $
#*	$Date: 2011/02/08 17:12:21 $
#*	$Revision: 1.1 $
#*	$Archive:   //uxpvcs2/pvcs/projects/Database/archives/DatabaseSolutions/MSSQL/BackupAndRecovery/NetBackup/Scripts/t38MonNetBackup.pv_  $
#*
#* SYNOPSIS
#*	t38monNetBackup -h -a 10 -l logfileDirSuffix -S serverName cfgfile1.cfg cfgfile2.cfg......
#*	
#*	Where:
#*	
#*	-h			Writes help screen on standard output, then exits.
#*	-a 10			Number of log file archived, default is 72
#*	-l logsuffx		Optional Log File Directory suffix. This is used to
#*				ensure multiple copies of the program can run at the 
#*				same time without overwriting the log file.
#*    -S serverName    The name of the instance your are running for.
#*  	Config file name with no command line flag
#*
#*	This program will monitor the NetBackup requests that are being used for your instance.
#*  
#*	Example:
#*		t38monNetBackup -a 10 -l dvd10db01 -S dvd10db01\sx01dba01 t38dba.cfg
#*
#*
#*  3/13/09 - Michael Watson - Added a check for the minutes file open when no backup is running, so that we dont archive before the process starts
#***

use strict;

use T38lib::Common qw(notifyMe notifyWSub logme warnme errme runOSCmd);
use T38lib::t38cfgfile qw(:CFGFILE_SUBS :CFGFILE_VARS);
use Getopt::Std;
use File::Basename;
use Time::Local;
use POSIX qw(strftime);

use Win32::TieRegistry ( Delimiter=>"/", ArrayValues=>1);

#use Date::Parse;

# Global Variables
my ( $gCurrentDir, $gScriptName, $gScriptPath, $gNWarnings) = "";

my ($gHostName, $gNetSrvr, $gInstName, $gHostNameLC, $gnumArchive, $g_backupRunning);
my ( $g_bkpInitFolder, $g_bkpMonitorFolder,$g_bkpEnabled)="";
my $g_bpLogInactiveTrholdMinutes = 30;
my ($gT38ERROR) = $T38lib::Common::T38ERROR;

&main();
# Main

############################  BBY Subroutines  ####################################
sub main {
	my $mainStatus	=0;
	SUB:
	{
		unless (&housekeeping())		{ $mainStatus = 1; last SUB; }
		unless (&checkConfig())			{ $mainStatus = 1; last SUB; } 		
		unless($g_bkpEnabled eq "Y"){ last SUB;	}
		unless(&monNetBackup())	{ $mainStatus = 1; last SUB; } 		
		last SUB;
	
	}	# SUB
	# ExitPoint:
	#&notifyWSub("$gHostName: #<# Running t38monNetBackup script #>#.");
	$mainStatus = 1	if ($gNWarnings > 0);
	( $mainStatus== 0 ) ? logme("$gHostName: finished with status $mainStatus", "done") : errme("$gHostName: finished with status $mainStatus", "done") ;
	exit($mainStatus);
}	# main


#######################  $Workfile:   t38MonNetBackup.pl  $ Subroutines  #################################
# ----------------------------------------------------------------------
#	monNetBackup	 Read the net backup log file.
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
# 	Loops through the net backup command bpbackup log file written
#      in the t38monNetBackup directory.
# ----------------------------------------------------------------------

sub monNetBackup()  {
	my ($status) =1;
	my ($completed)= 0;
	my ($logFileName, $lfbase, $logFilePath, $lftype);
	my $startTime	= "";
	my $endTime		= "";
	my $fileName	= "";
	my $bpBackupLogFile ="";
	my $osCommandTasks = "";
	my @raw_data;
	my @raw_rev;
	&notifyWSub ( "STARTED");


	# Print list of running netbackup processes.
	my $bppsOut = `bpps`; &notifyWSub("bpps output:\n$bppsOut"); $bppsOut = '';

	# Print result of tasklist command. With netbackup 5.1 bpps command is not available.
	$osCommandTasks = "tasklist  /FI \"IMAGENAME eq bp*\" /FI \"IMAGENAME ne bpjava*\" /FI \"IMAGENAME ne bpinet*\" /FI \"IMAGENAME ne bpps.*\"";
	if (&runOSCmd($osCommandTasks, \$fileName) ){
		&notifyWSub("OS Task Output to file: $fileName");
		if (open(tmp,"< $fileName"))  {
			while (<tmp>) { &notifyWSub($_); };
			close(tmp);
		}
	}
		
	#setup get current log information to create output files in correct place
	#
	$logFileName = &T38lib::Common::getLogFileName($0);
	$logFileName = lc($logFileName);
	$logFileName =~ s/$g_bkpMonitorFolder/$g_bkpInitFolder/gi;
	fileparse_set_fstype("MSWin32");
	($lfbase, $logFilePath, $lftype) = fileparse($logFileName, '\.[^\.]*');
	$bpBackupLogFile = $logFilePath . "bpBackup.log";
	
	# Input and out files
	#
	&notifyWSub("Reading from backup log file => $bpBackupLogFile");
	
	# Open file to 
	#
	 unless (open(tmp,"< $bpBackupLogFile"))  {
		&logme("$gHostName: Could not find file $bpBackupLogFile");
		$status = 1;
		&notifyWSub("ENDED with status:$status");
		return $status
	 }
	 $startTime = strftime "%m/%d/%Y %H:%M:%S ", localtime(time);
	 @raw_data = <tmp>;
	 close (tmp);
	 @raw_rev = reverse(@raw_data);

	 my $line_var = "";	
	 my $firstLine = 0;
	 foreach $line_var (@raw_rev)
	 {
		chomp $line_var;
		my ( $bpStatus, $bpComp ) ;
		my $bpAbortedByClient = '';
		$bpStatus =-1;
		$_ = $line_var;
		if( /Server status = (\d{1,3})/){
		$bpStatus = $1;
		}
		$bpComp = (/the requested operation was successfully completed/);
		$bpAbortedByClient = /\d\d:\d\d:\d\d inf -.*:client process aborted$/i;
		$firstLine = /^Backup started/;
		my $msg = "";
		if (($bpComp)&&($completed == 0)){
			$msg = "$gHostName: Net Backup Completed Sucessfully";
			&notifyWSub ($msg);
			&logme ($msg);
			$completed++;
		} elsif ($bpAbortedByClient){
			$msg = "$gHostName: Backup aborted by the client";
			&notifyWSub ($msg);
			&errme ($msg);
			$gNWarnings++;
			$completed++;
		}elsif ($bpStatus > 1){
			$msg = "$gHostName: Net Backup encountered an error :$line_var";
			&notifyWSub ($msg);
			&errme ($msg);
			$gNWarnings++;
			$completed++;
		} elsif ($bpStatus == 1)	{
		$msg = "$gHostName: Net Backup encountered a file error  $line_var, check file lock and rerun job.";
			&notifyWSub ($msg);
			&errme ($msg);
			$gNWarnings++;
			$completed++;
		}elsif (($bpStatus == 0)&&($completed == 0)){
		$msg = "$gHostName: Net Backup Completed Sucessfully";
			&notifyWSub ($msg);
			&logme ($msg);
			$completed++;
		}  elsif ( $firstLine) {
			$endTime =  substr("$line_var",15);
		}
	 }

	 unless ($firstLine)  {
		&errme("$gHostName: The bpbackup.log file does not start with the correct line, this error occures when log file is archived before the veritas netbackup process has finished.");
		unless ($endTime) { $endTime = $startTime; }
		$gNWarnings++;
		$completed++;
	}
	my $diffmin = -1;
	&notifyWSub("Net Backup started at:'$endTime' & ended at:'$startTime'");
	
	my ($m, $d, $y,  $hh, $mm, $ss);
	$endTime =~ /(\d{1,2})\/(\d\d)\/(\d{2,4}) (\d+):(\d+):(\d+)/;
	($m, $d, $y, $hh, $mm, $ss) = ($1, $2, $3, $4, $5, $6);
	#timelocal year is from 1900 and month is 0 based
	my $newTime= timelocal($ss,$mm,$hh,$d,$m-1,$y-1900);
	&notifyWSub("New Time : $newTime");
	
	$startTime =~ m/(\d{1,2})\/(\d\d)\/(\d+).(\d+):(\d+):(\d+)/;
	($m, $d, $y, $hh, $mm, $ss) = ($1, $2, $3, $4, $5, $6);
	#timelocal year is from 1900 and month is 0 based
	my $newTime2 = timelocal($ss,$mm,$hh,$d,$m-1,$y-1900);
	&notifyWSub("New Time 2 : $newTime2");
	
	&notifyWSub("backup completed = $completed");
	if ($completed==0){
		$diffmin = ($newTime2 - $newTime)/60;
		&notifyWSub( "Time difference in minutes:'$diffmin'");
		&logme("$gHostName: $diffmin");
		&writeReg($diffmin);
		# This check to make sure no backup is running and the file has been open for more than 30 minutes.
		# we experience issues with the backup starting at 4:24 and the monitor starting at 4:25.  Hence archiving the file
		# becuase the backup master server had not initiated the session yet so the backup processes were not found.

		# On a multi-instance server there is no way to reliably identify if backup is running for the 
		# current instance. Try to check if there is any activity on the bpBackup.log file.

		my $bpBackupLogMtime = (stat($bpBackupLogFile))[9];
		my $now = time();
		if ( $now - $bpBackupLogMtime > $g_bpLogInactiveTrholdMinutes*60){
			&T38lib::Common::archiveFile($bpBackupLogFile, $gnumArchive);
			errme("$gHostName: We have no updates in $bpBackupLogFile for " . POSIX::floor(($now - $bpBackupLogMtime)/60) . " minutes, and there is no completion message from Net Backup.  This file will be archived." );
			$gNWarnings++;
		}
	}else{
		&notifyWSub("Backup completed, archive $bpBackupLogFile file.");
		&T38lib::Common::archiveFile($bpBackupLogFile, $gnumArchive);
		&writeReg(-1);
	}
	
	$status = 0	if ($gNWarnings > 0);
	&notifyWSub("ENDED with status:$status");
	return $status
}#	monNetBackup


# ----------------------------------------------------------------------
#	checkConfig	 create command and execute
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
# Check the values found in the t38 config file  that are expected for correct function
# ----------------------------------------------------------------------
sub checkConfig () {
	my $status = 1;
	
	SUB:
	{
		if (!defined($T38lib::t38cfgfile::gConfigValues{'bkpUseTapeBackup'})) {
			&notifyWSub("Missing config value for bkpUseTapeBackup.");
			#$status = 0;
			last SUB;	
		}else{
			$g_bkpEnabled = $T38lib::t38cfgfile::gConfigValues{'bkpUseTapeBackup'};
		}		
		if (!defined($T38lib::t38cfgfile::gConfigValues{'bkpMonitorFolder'})) {
			&notifyWSub("Missing config value for bkpMonitorFolder.");
			#$status = 0;
		}else{
			$g_bkpMonitorFolder = $T38lib::t38cfgfile::gConfigValues{'bkpMonitorFolder'};
		}		
		if (!defined($T38lib::t38cfgfile::gConfigValues{'bkpInitFolder'})) {
			&notifyWSub("Missing config value for bkpInitFolder.");
		#	$status = 0;
		}else{
			$g_bkpInitFolder = $T38lib::t38cfgfile::gConfigValues{'bkpInitFolder'};
		}

		$g_bpLogInactiveTrholdMinutes = (defined($T38lib::t38cfgfile::gConfigValues{'bkpTapebpLogInactiveTrholdMinutes'}))?
			$T38lib::t38cfgfile::gConfigValues{'bkpTapebpLogInactiveTrholdMinutes'}:
			30;

		last SUB;
	}	# SUB
	return ($status)
}#	checkConfig


# ----------------------------------------------------------------------
# writeReg
# ----------------------------------------------------------------------
#	arguments:
#		$nminrunning	number of minutes backup is running
#	return:
#		none
# ----------------------------------------------------------------------
#	Writes to T38 registry value of number of minutes tape backup is
#	running.
# ----------------------------------------------------------------------

sub
writeReg {
	my $nminrunning	= shift;
	my $subStatus	= 1;
	my $machine = (defined($gNetSrvr) && $gNetSrvr) ?  "//$gNetSrvr/" : "";
	my $swKey	= $Registry->{"${machine}LMachine/Software"};
	my $keyName	= "BestBuy/T38SQLDBAInfrastructure/NetBackup";
	my $valName	= "MinutesRun:";
SUB:
{

	# T38 Registry is structered as following
	#
	#	HEKY_LOCAL_MACHINE\Software\BestBuy\T38SQLDBAInfrastructure\NetBackup
	#		TapeBkpRunning4NMin:VSQLName_$InstanceName	= Number
	#		...
	#	For example:
	#		TapeBkpRunning4NMin:DST6DB_= 10
	#		TapeBkpRunning4NMin:LVT01DB01_SX01DBA01	= 15
	#		TapeBkpRunning4NMin:LVT01DB02_SX01DBA02	= 7
	#
	#
	
	# $valName .= ($gInstName) ? $gInstName : 'MSSQLSERVER';
	# $valName .= ($gInstName) ? "$gNetSrvr\\$gInstName" : $gNetSrvr;
	# We need to read this registry value from VBScript. 
	# Let's keep logic in VBScript simple even so it may not look the best.
	$valName .= "${gNetSrvr}_${gInstName}";
	$nminrunning = POSIX::floor($nminrunning);

	&notifyMe("${machine}LMachine/Software/$keyName/$valName = $nminrunning");

	# $Registry->{"${machine}LMachine/Software/BestBuy/T48/$ORACLE_SID/T48BKP"} = "$T48BKPDRIVE/orabkp/$ORACLE_SID";
	# my $bbyKey 	= $swKey->CreateKey("BestBuy/T48/$ORACLE_SID");
	my $bbyKey 	= $swKey->CreateKey($keyName);
	unless ($bbyKey->SetValue($valName, $nminrunning)) {
		&warnme("$gHostName: Cannot set registry value LMachine/Software/$keyName/$valName.");
		$subStatus = 0;
		last SUB;
	}

	last SUB;
}
	return($subStatus);
}	# writeReg


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
	my $numArchive = 72;
	my $status = 1;
	my $logFileName = '';
	my $logDirSuffix = '';
	my $srvrName;
	my $logStr = $0;
	my $cfgFile	= '';
	my @args = ();


	$gScriptName	= "";			# Base name of the current script.
	$gScriptPath	= ".\\";		# Directory path to current script.


	($gScriptPath, $gScriptName, $scriptSuffix) = &T38lib::Common::parseProgramName();

	#-- initialize standard options
	$logStr = $logStr . " ";

	getopts('ha:l:S:');

	$gHostName	= uc(Win32::NodeName());
	$gHostNameLC = lc(Win32::NodeName());
	$gNWarnings	= 0;

	#-- program specific initialization


	#<# $gmyGlobal	= 0;	# my global variable #>#

	#-- show help

	if ($Getopt::Std::opt_h) { &showHelp(); exit; }

	# Open log and error files, if needed.

	SUB: {
		$logFileName = $gScriptName;

		#----------------------------------------------------------------
		# Append the log file directory suffix if it was supplied 
		#----------------------------------------------------------------

		if($Getopt::Std::opt_l) {
			$logDirSuffix = $Getopt::Std::opt_l;
			$logFileName = $logFileName . $logDirSuffix;
			$logStr = $logStr . " -l $logDirSuffix";
		}

		unless (&T38lib::Common::setLogFileDir("${gScriptPath}T38LOG\\$logFileName")) {
			&errme("$gHostName: Cannot set program log directory.");
			$gNWarnings++;
			$status = 0;
			last SUB;
		}


		if($Getopt::Std::opt_a) {
			if ( $Getopt::Std::opt_a =~ /\d/) {
				if ( ($Getopt::Std::opt_a < 101) and ($Getopt::Std::opt_a > 0) ) {
					$numArchive = $Getopt::Std::opt_a;
					$logStr = $logStr . " -a $numArchive";
				}
			}
		}

		# By default set number of bpbackup log archives to be same as program log archives.
		$gnumArchive = $numArchive;

		&T38lib::Common::archiveLogFile($numArchive);
		&logme("$gHostName: Starting $gScriptName from $gScriptPath", "started");

		# Process command line Server Name and instance name
		#
		if($Getopt::Std::opt_S) {
			$srvrName = $Getopt::Std::opt_S;
			$srvrName =~ s/^\./$gHostName/;
			$gHostName = uc($srvrName);
			($gNetSrvr, $gInstName)	=	split("\\\\", $gHostName); 
			$gInstName =~ s/^\s+//g; 
			$gInstName =~ s/\s+$//g;
			$logStr = $logStr . " -S $gHostName";
		}
		else {
			$gNetSrvr = $gHostName;
		}

		# Check Perl version.

		unless ( &T38lib::Common::chkPerlVer() ) {
			&notifyWSub("Wrong version of Perl!");
			&notifyWSub("This program run on Perl version 5.005 and higher.");
			&notifyWSub("Check the Perl version by running perl -v on command line.");
			$status = 0;
			last SUB;
		}

		# Process cfg file at the end of all the command line arguments
		#
		if ( $#ARGV >= 0) {
			@args = &T38lib::Common::globbing(@ARGV);
			if ( $args[0] ne $gT38ERROR ) {
				@ARGV = @args;
			} else {
				&warnme("$gHostName: Globbing of Command line argument failed");
				$gNWarnings++;
				$status = 0; last SUB;
			}

			foreach $cfgFile (@args) {
				$logStr = $logStr . " $cfgFile";
				unless(&readConfigFile($cfgFile)) { 
					$status = 0; 
					last SUB; 
				}
			}
		}

		#<# Change number of archived bpbackup logs #>#
		if (!defined($T38lib::t38cfgfile::gConfigValues{'bkpArchiveNum'})) {
			&notifyWSub("Missing config value for bkpArchiveNum.");
		}else{
			$gnumArchive = $T38lib::t38cfgfile::gConfigValues{'bkpArchiveNum'};
			&notifyWSub("Archive set to $gnumArchive");
		}
				
		&notifyWSub("$gHostName: #<# Running t38monNetBackup script #>#.");
	}	# SUB
	# ExitPoint:

	&notifyWSub("command line: $logStr");

	return($status);

}	# housekeeping

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
#!perl 
#* t38monNetBackup - #<# Initiate the request for NetBackup#>#.
#*
#*	$Author: A645276 $
#*	$Date: 2011/02/08 17:12:21 $
#*	$Revision: 1.1 $
#*	$Archive:   //uxpvcs2/pvcs/projects/Database/archives/DatabaseSolutions/MSSQL/BackupAndRecovery/NetBackup/Scripts/t38MonNetBackup.pv_  $
#*
#* SYNOPSIS
#*	t38monNetBackup -h -a 10 -l logfileDirSuffix -S ServerName cfgfile1.cfg cfgfile2.cfg......
#*	
#*	Where:
#*	
#*	-h			Writes help screen on standard output, then exits.
#*	-a 10			Number of log file archived, default is 72
#*	-l logsuffx		Optional Log File Directory suffix. This is used to
#*				ensure multiple copies of the program can run at the 
#*				same time without overwriting the log file.
#*	-S Server Name  	Name of the server
#*  	Config file name with no command line flag
#*
#*	This program will connect to your instance in the -S parameter and get the backup path.
#*   	Then send the request to netbackup for the patyh
#*  
#*	Example:
#*		t38monNetBackup -a 10 -l dvd10db01 -S dvd10db01\sx01dba01 t38dba.cfg
#*
#*      To display help file
#* 		t38monNetBackup -h
#***
EOT
} #	showHelp


__END__

=pod

=head1 PROGRAM NAME

PROGRAM NAME - One line description of the program

=head1 SYNOPSIS

perl PROGRAM NAME -h -a 7

=head2 OPTIONS

I<PROGRAM NAME> accepts the following options:

=over 4

=item [OPTION]

DESCRIPTION OF THE OPTION

=item -h 		(Optional)

Print out a short help message, then exit.

=item -a <number> 		(Optional)

Number of log file archived, default is 72

=item OTHER OPTION 	(Required)

DESCRIPTION OF THE OPTION

=back

=head1 DESCRIPTION


=head1 EXAMPLE

perl PROGRAM NAME OPTION

DESCRIPTION OF THE COMMAND

=head1 COMPILE OPTION

=over 4

=item perl -S PerlApp.pl -f -s PROGRAMNAME.pl -e PROGRAMNAME.exe -c -v

=item using perl 5.005_03, ActivePerl Build 522

=back

=head1 BUGS

I<PROGRAMNAME.pl> has no known bugs.

=head1 REVISION HISTORY

$Revision: 1.1 $

=head1 AUTHOR

AUTHOR NAME, AUTHOR EMAIL ADDRESS

=head1 SEE ALSO

ADD ALL THE MODULES USED IN THIS PROGRAM 
T38lib::Common.pm, T38lib::t38cfgfile 
ALSO ADD ANY OTHER OS UTILITIES USED IN THIS PROGRAM

=head1 COPYRIGHT and LICENSE

This program is copyright by Best Buy Inc.

=cut
