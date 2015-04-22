#!perl 
#* t38initNetBackup - #<# Initiate the request for NetBackup#>#.
#*
#*	$Author: A645276 $
#*	$Date: 2011/02/08 17:12:22 $
#*	$Revision: 1.1 $
#*	$Archive:   //uxpvcs2/pvcs/projects/Database/archives/DatabaseSolutions/MSSQL/BackupAndRecovery/NetBackup/Scripts/t38inittapebackup.pv_  $
#*
#* SYNOPSIS
#*	t38initNetBackup -h -a 10 -l logfileDirSuffix -S ServerName cfgfile1.cfg cfgfile2.cfg......
#*	
#*	Where:
#*	
#*	-h			Writes help screen on standard output, then exits.
#*	-a 10			Number of log file archived, default is 7
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
#*		t38initNetBackup -a 10 -l dvd10db01 -S dvd10db01\sx01dba01 t38dba.cfg
#*
#*
#*  3/13/09 - Michael Watson - Added correct error alert for $outputFilePath variable.
#*  3/13/09 - Michael Watson - Changed the checkConfig routine for the non required parameters to just set when they are found.
#***
use strict;

use T38lib::Common qw(notifyMe notifyWSub logme warnme errme runOSCmd);
use T38lib::t38cfgfile qw(:CFGFILE_SUBS :CFGFILE_VARS);
use Getopt::Std;
use File::Basename;

# Global Variables
my ( $gCurrentDir, $gScriptName, $gScriptPath, $gNWarnings) = "";
my ($gHostName, $gNetSrvr, $gInstName, $gHostNameLC, $gnumArchive);
my ($g_bkpServerName, $g_bkpPolicy,$g_bkpSchedule,$g_bkpServerName,$g_bkpWaitForComplete,$g_bkpWaitForCompleteTime,$g_bkpEnabled)="";
my ($gT38ERROR) = $T38lib::Common::T38ERROR;

#&housekeeping();
&main();
#&checkConfig();
#&netBackup();
# Main



############################  BBY Subroutines  ####################################

sub main {
	my $mainStatus	=0;
	SUB:
	{
		unless (&housekeeping())	{ $mainStatus = 1; last SUB; }
		unless (&checkConfig())		{ $mainStatus = 1; last SUB; } 		
		unless($g_bkpEnabled eq "Y"){  &notifyWSub ("NOT ENABLED"); last SUB;	}		
		unless(&netBackup())		{ $mainStatus = 1; last SUB; } 		
		last SUB;
	}	# SUB
	
	# ExitPoint:
	$mainStatus = 1	if ($gNWarnings > 0);
	( $mainStatus== 0 ) ?
		logme("Finished with status $mainStatus", "done") :
		warnme("Finished with status $mainStatus", "done") ;
	exit($mainStatus);
}	# main


#######################  $Workfile:   t38inittapebackup.pl  $ Subroutines  #################################

# ----------------------------------------------------------------------
#	netBackup	 
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
# This routine will control the flow of the netbackup command 
#  pulling the path information from the instance passed in.  After
#  wards pass the path to the bpbackup command.
# ----------------------------------------------------------------------

sub netBackup () {
	my $status	= 1;
	my ($logininfo,$sqlFilePath, $outFilePath)="";
	my ($oSqlCommand , $val) = "";
	my @backupList = ();
	my ($osCommand,$osCommandTasks, $fileName)="";
	my ($logFileName, $outputNetBackupFileName) = "";
	my ($lfbase, $logFilePath, $lftype)  = "";
		
	Sub:{
	&notifyWSub ("STARTED");
	#get dir to save log files / output to
	#
	unless ($g_bkpEnabled eq "Y"){
		last SUB;
	}
	$logFileName = &T38lib::Common::getLogFileName($0);
	fileparse_set_fstype("MSWin32");
	($lfbase, $logFilePath, $lftype) = fileparse($logFileName, '\.[^\.]*');
	$outputNetBackupFileName = $logFilePath . "bpBackup.log";
	
	#&notifyWSub("Finding file $outputNetBackupFileName");
	if (-e $outputNetBackupFileName){
			&notifyWSub("Found backup log file $outputNetBackupFileName");
			&errme("Backup in process, found file: $outputNetBackupFileName.");
			$gNWarnings++;
			$status	= 0; 
			last SUB;
	}else{
		&notifyWSub("No backup running, OK");
	}
	
	# Program Flow 
	#
	unless (generateSqlFile( \$sqlFilePath ))		{ $status	 = 1; last SUB; } 	
	&notifyWSub("generateSqlFile returned sql file path: $sqlFilePath");
	unless (runSQL( $gHostName, $sqlFilePath, \$logininfo ))		{ $status	 = 1; last SUB; } 	
	&notifyWSub ("Path List : $logininfo");

	# Loop through list  of directories and execute each command
	#
	@backupList = split(";", $logininfo);
	
	foreach my $val (@backupList) {
		$val =~ s/\s+$//;
		unless ( &generateNetBackupCommand($val, \$osCommand)){$status =1 ; LAST SUB;}
		#this assumes you have bpbackup in the path var on the server.
		#runOSCmd();
		unless (&runOSCmd($osCommand) ) {
			&errme("Error occured with runnin OS command.");
			$gNWarnings++;
			$status	= 0; last SUB;
		}
		&notifyWSub ( "osCommand : $osCommand");
		# Commented out need to find BBTG Standard call in common.PM
		#`$osCommand`;
	}
	
	&notifyWSub ("ENDED");
	return($status);
	}
}	# net_backup


# ----------------------------------------------------------------------
#	generateNetBackupCommand	 Create Netbackup Command
# ----------------------------------------------------------------------
#	arguments:
#		$1 = backup path from sql query
#  		$2 = reference to net backup command varaible
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#  This routine will create the netbackup command.
# ----------------------------------------------------------------------

sub generateNetBackupCommand ($$) {
	my ($string , $command )= @_;
	my $status = 1;
	my ($oscommand , $outputNetBackupFileName) = "";
	my ($logFileName, $lfbase, $logFilePath, $lftype);
	my ($logFileTime) = time();

	SUB:{
	# dereference variable
	#
	$oscommand = $$command;
	&notifyWSub ( "STARTED");
		
	#get dir to save log files / output to
	#
	$logFileName = &T38lib::Common::getLogFileName($0);
	fileparse_set_fstype("MSWin32");
	($lfbase, $logFilePath, $lftype) = fileparse($logFileName, '\.[^\.]*');
	$outputNetBackupFileName = $logFilePath . "bpBackup.log";

	# Archive the input and output files
	#
	&T38lib::Common::archiveFile($outputNetBackupFileName, $gnumArchive);
	
	# Format command string
	#
	# removed -d $gHostNameLC 
		$oscommand = "bpbackup";
		&notifyWSub("CMD: $oscommand");
		&notifyWSub ("Backup Policy : $g_bkpPolicy");
		if ($g_bkpPolicy) {
				$oscommand .= " -p $g_bkpPolicy";
		}
		if ($g_bkpSchedule) {
		$oscommand .= " -s $g_bkpSchedule";
		}
		if ($g_bkpServerName) {
		$oscommand .= " -S $g_bkpServerName"	;
		}
		if ($g_bkpWaitForComplete =="1"){
			$oscommand .= " -w $g_bkpWaitForCompleteTime";
		}
		$string =~ s/^\s+//;
		$oscommand .= " -L $outputNetBackupFileName $string";
	&notifyWSub ( "Formated command = $oscommand");
		

	# set reference to formatted string
	#
	$$command  = $oscommand;

	# Exit
	#
	&notifyWSub ( "ENDED");
	return $status
	}
}# generateNetBackupCommand



# ----------------------------------------------------------------------
#	generateSqlFile	 create sql file to get backup path
# ----------------------------------------------------------------------
#	arguments:
#		$1 = backupSqlFileName reference
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
# 	Create file with SQL Statments for execution at a later time in the program flow.
# ----------------------------------------------------------------------

sub generateSqlFile ($)  {
	my ($referenceValue) = @_;
	my ($status) =1;
	my ($logFileName, $lfbase, $logFilePath, $lftype);
	my $backupSqlFileName ="";
	
	SUB:{
	&notifyWSub ( "STARTED");

	#setup get current log information to create output files in correct place
	#
	$logFileName = &T38lib::Common::getLogFileName($0);
	fileparse_set_fstype("MSWin32");
	($lfbase, $logFilePath, $lftype) = fileparse($logFileName, '\.[^\.]*');
	$backupSqlFileName = $logFilePath . "backupPath.sql";
	
	# Archive the input and output files
	#
	&T38lib::Common::archiveFile($backupSqlFileName, $gnumArchive);
	
	# Input and out files
	#
	&notifyWSub("SQL file => $backupSqlFileName");
	
	# Open file to write SQL commands
	#
	unless (open(SQL,">$backupSqlFileName")) {
		&errme("Cannot open file $backupSqlFileName: $!");
		$gNWarnings++;
		$status =0;
		last SUB;
	}
	
	# Write command to the file
	#
	print SQL "set nocount on;\n";
	print SQL "declare \@ver as char(2);\n";
	print SQL "SELECT \@ver = left(cast(SERVERPROPERTY('productversion') as varchar(24)),2);\n";
	print SQL "if '8.' =\@ver \n";
	print SQL "begin \n";
	print SQL "select distinct Reverse(substring(reverse(phyname), charindex('\\',reverse(phyname)),len(phyname))) as folder_path  from master.dbo.sysdevices where cntrltype = 2\n";
	print SQL "end else if \@ver in ('9.', '10') \n";
	print SQL "begin\n";
	print SQL "select distinct Reverse(substring(reverse(physical_name), charindex('\\',reverse(physical_name)),len(physical_name))) as folder_path from sys.backup_devices where type=2\n";
	print SQL "end else \n";
	print SQL "begin\n";
	print SQL "select null\n";
	print SQL "end;\n";
	
	# Close  file 
	#
	close(SQL);

	# set reference
	#
	$$referenceValue= $backupSqlFileName;
	
	#Exit
	#
	&notifyWSub("ENDED");
	return $status
	}
}#	generateSqlFile

# ----------------------------------------------------------------------
#	runSQL	 run the sql statement
# ----------------------------------------------------------------------
#	arguments:
#		$ Server Name
#		$ sql command file
#                  $ directory path variable reference
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
# 	Run the sql file and parse the output to return a semi-colon seperated list.
# ----------------------------------------------------------------------

sub runSQL ($$$) {
	my ($serverName, $sqlFilePath, $pathList)	= @_;
	my $status = 1;
	my $rtnCode =0;
	my @includeErr;
	my ($logFileName, $lfbase, $logFilePath, $lftype);
	my $path = "";
	my $outputFilePath = "";
	
	SUB:{
	&notifyWSub("Started");
	&notifyWSub("Parameter serverName: $serverName");
	&notifyWSub("Parameter sqlFilePath: $sqlFilePath");
	&notifyWSub("Parameter pathList: $pathList");
	
	#setup get current log information to create output files in correct place
	#

	$logFileName = &T38lib::Common::getLogFileName($0);
	fileparse_set_fstype("MSWin32");
	($lfbase, $logFilePath, $lftype) = fileparse($logFileName, '\.[^\.]*');
	$outputFilePath = $logFilePath . "backupPath.out";
	
	# Archive the input and output files
	#
	&T38lib::Common::archiveFile($outputFilePath, $gnumArchive);
	
		# run the sql file
		#
		$rtnCode  = &T38lib::Common::runSQLChk4Err($sqlFilePath, $serverName, "", $outputFilePath, "", "", "", "",\@includeErr);

		# Check for the status
		#
		&notifyWSub("Return Code from runSQLChk4Err sub = $rtnCode");
		if ( $rtnCode == 1)  {
			&notifyWSub("SQL Failed!! Check output file: $outputFilePath");
			$gNWarnings++;
			$status = 0;
			last SUB;
		}
		
	 unless (open(tmp,"< $outputFilePath"))  {
		 &notifywsub ("error opening file $outputFilePath");
		 $gNWarnings++;
		 last SUB;
	 }
		 while (<tmp>) {
		 chomp;
		 if ( (/\w+/) ) {
			 $_ = &T38lib::Common::stripWhitespace($_);
			 $path .= "$_;";
		 }
	 }
	 close(tmp);
	
	&notifyWSub ("Paths => $path ");
	&notifyWSub("ENDED");
	
	#set reference to path list
	#
	$$pathList= $path;
	
	#Exit
	#
	return $status;
	}
}	#runSQL


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
		&notifyWSub ( "STARTED");
		if (!defined($T38lib::t38cfgfile::gConfigValues{'bkpUseTapeBackup'})) {
			&notifyWSub("Exiting, Missing config value for bkpUseTapeBackup.");
			last SUB;
		} else
		{
			$g_bkpEnabled = &T38lib::Common::stripWhitespace($T38lib::t38cfgfile::gConfigValues{'bkpUseTapeBackup'});
		}
		last if ($g_bkpEnabled ne "Y");
		if (!defined($T38lib::t38cfgfile::gConfigValues{'bkpSchedule'})) {
			&warnme("Exiting, Missing config value for bkpSchedule.");
			$status = 0;
		} else
		{
				$g_bkpSchedule = &T38lib::Common::stripWhitespace($T38lib::t38cfgfile::gConfigValues{'bkpSchedule'});
		}		
		if (defined($T38lib::t38cfgfile::gConfigValues{'bkpMasterServerName'})) {
			$g_bkpServerName = &T38lib::Common::stripWhitespace($T38lib::t38cfgfile::gConfigValues{'bkpMasterServerName'});
		}
		if (defined($T38lib::t38cfgfile::gConfigValues{'bkpPolicy'})) {
				$g_bkpPolicy = &T38lib::Common::stripWhitespace($T38lib::t38cfgfile::gConfigValues{'bkpPolicy'});
		}	
		if (defined($T38lib::t38cfgfile::gConfigValues{'bkpWaitForComplete'})) {
				$g_bkpWaitForComplete = &T38lib::Common::stripWhitespace($T38lib::t38cfgfile::gConfigValues{'bkpWaitForComplete'});
		}
		if (defined($T38lib::t38cfgfile::gConfigValues{'bkpWaitForCompleteTime'})) {
				$g_bkpWaitForCompleteTime = &T38lib::Common::stripWhitespace($T38lib::t38cfgfile::gConfigValues{'bkpWaitForCompleteTime'});
		}
	
	}
	
	&notifyWSub ( "EXIT");
	return ($status)
}#	checkConfig

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



	SUB: {
		#-- show help

		if ($Getopt::Std::opt_h) { &showHelp(); exit; }

		# Open log and error files, if needed.
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
			&errme("Cannot set program log directory.");
			$gNWarnings++;
			$status = 0;
			last SUB;
		}

		#<# Change number archived logs #>#
		if($Getopt::Std::opt_a) {
			if ( $Getopt::Std::opt_a =~ /\d/) {
				if ( ($Getopt::Std::opt_a < 101) and ($Getopt::Std::opt_a > 0) ) {
					$numArchive = $Getopt::Std::opt_a;
					$logStr = $logStr . " -a $numArchive";
					$gnumArchive = $numArchive;
				}
			}
		}

		&T38lib::Common::archiveLogFile($numArchive);
		&logme("Starting $gScriptName from $gScriptPath", "started");

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
				&warnme("Globbing of Command line argument failed");
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
		
		&notifyWSub("$gHostName: #<# Running T38 template script #>#.");
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
#* t38initNetBackup - #<# Initiate the request for NetBackup#>#.
#*
#*	$Author: A645276 $
#*	$Date: 2011/02/08 17:12:22 $
#*	$Revision: 1.1 $
#*	$Archive:   //uxpvcs2/pvcs/projects/Database/archives/DatabaseSolutions/MSSQL/BackupAndRecovery/NetBackup/Scripts/t38inittapebackup.pv_  $
#*
#* SYNOPSIS
#*	t38initNetBackup -h -a 10 -l logfileDirSuffix -S ServerName cfgfile1.cfg cfgfile2.cfg......
#*	
#*	Where:
#*	
#*	-h			Writes help screen on standard output, then exits.
#*	-a 10			Number of log file archived, default is 7
#*	-l logsuffx		Optional Log File Directory suffix. This is used to
#*				ensure multiple copies of the program can run at the 
#*				same time without overwriting the log file.
#*	-S Server Name  	Name of the server
#*  	Config file name with no command line flag
#*
#*	This program will connect to your instance in the -S parameter and get the backup path.
#*   	Then send the request to netbackup for the path
#*  
#*	Example:
#*		t38initNetBackup -a 10 -l dvd10db01 -S dvd10db01\sx01dba01 t38dba.cfg
#*
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

Number of log file archived, default is 7

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
