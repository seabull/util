#!perl 
#* T38stats - T38stats perl script
#*
#*$Author: A645276 $
#*$Date: 2011/02/08 17:12:21 $
#*$Revision: 1.1 $
#*$Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/DBINST/SQL65/T38stats.pv_  $
#*
#* SYNOPSIS
#*   T38stats.pl -h -a 10 -l -S ServerName -d databaseName ConfigfileName
#*
#*Where:
#*
#*   -h   Writes help screen on standard output, then exits.
#*   -a	  10 Number of log file archived, default is 7
#*   -l   logsuffx Optional Log File Directory suffix. This is used to
#*        ensure multiple copies of the program can run at the 
#*        same time without overwriting the log file.
#*   -d   dbName	Run Update Stats on a give database name
#*   -S   Server Name 
#*
#*   Configration file or mutiple cfg files
#*
#*Example:
#*   Run stats on server DS01DBA using t38dba.cfg configuration file
#*      t38stats.pl -S DS01DBA T38dba.cfg
#*
#*   Run stats on server DS01DBA on database SKUDB001 using T38dba.cfg parameter
#*      t38stats.pl -S DS01DBA -d SKUDB001 T38dba.cfg
#*
#*   Run stats on server DS01DBA using T38dba.cfg and nba.cfg parameters
#*      t38stats.pl -S DS01DBA T38dba.cfg nba.cfg
#*
#***

use strict;

use T38lib::Common qw(notifyMe notifyWSub logme warnme errme);
use T38lib::t38cfgfile qw(:CFGFILE_SUBS :CFGFILE_VARS);
use Getopt::Std;
use File::Basename;

# Global Variables
my ( $gCurrentDir, $gScriptName, $gScriptPath, $gserverName, $gNWarnings) = ("","","","","");
my ($gNetSrvr, $gInstName)	=("","");	
my $gcmdlineDBName = ("");
my ($gT38ERROR) = $T38lib::Common::T38ERROR;
my (@gDBNamesToProcess) = ();
my $gnumArchive = 7;

# Function Prototype
sub housekeeping();
sub runStats();

#---------------------------------------------------
# List of database that will be excluded from Update Stats
#---------------------------------------------------
my ($gfilterDBList) = "model|tempdb|northwind|pubs";

# Main
&main();

############################  BBY Subroutines  ####################################

sub main {
	my $mainStatus	= 0;
	SUB:
	{
		unless (&housekeeping())	{ $mainStatus = 1; last SUB; }
		unless(&runStats())			{ $mainStatus = 1; last SUB; } 		

		last SUB;
	
	}	# SUB
	# ExitPoint:

	$mainStatus = 1	if ($gNWarnings > 0);

	( $mainStatus== 0 ) ?
		logme("Finished with status $mainStatus", "done") :
		warnme("Finished with status $mainStatus", "done") ;

	exit($mainStatus);

}	# main


#######################  $Workfile:   T38stats.pl  $ Subroutines  #################################

# ----------------------------------------------------------------------
#	runStats		Run Update Stats 
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------

sub runStats () {

	my $status	= 1;
	my $rtnCode;
	my ($db, $statsSQLFileName, $statsOutputFileName); 
	my ($logFileName, $lfbase, $logFilePath, $lftype);

	# errors we're not interested in
	my @excludeErr = (219, 1104, 2540, 15023, 
			    	  15024, 15025, 15026, 15027, 
					  15028, 15029, 15029, 15030, 
					  15031, 15032, 15034);	

	my @includeErr = ();

	SUB: {
		&notifyWSub("STARTED");


		$logFileName = &T38lib::Common::getLogFileName($0);
		fileparse_set_fstype("MSWin32");
		($lfbase, $logFilePath, $lftype) = fileparse($logFileName, '\.[^\.]*');

		$statsSQLFileName = $logFilePath . "stats.sql";
		$statsOutputFileName = $logFilePath . "stats.out";

		# Archive the input and output files
		#
		&T38lib::Common::archiveFile($statsSQLFileName, $gnumArchive);
		&T38lib::Common::archiveFile($statsOutputFileName,$gnumArchive);


		# Input and output files
		&notifyWSub("STATS SQL file => $statsSQLFileName");
		&notifyWSub("STATS OUTPUT file => $statsOutputFileName");

		# Do we have any databases to process
		#
		if ($#gDBNamesToProcess < 0) {
			&notifyWSub ("No Databases to process for update Stats");
			last SUB;
		}

		# Open file to write SQL commands
		#
		unless (open(SQL,">$statsSQLFileName")) {
			&errme("Cannot open file $statsSQLFileName: $!");
			$status = 0;
			last SUB;
		}
		
		# Write command to the file to update stats
		#
		print SQL "EXEC sp_T38LOGERROR 3, 'T38STATS', 'Started.'\n";
		print SQL "set nocount on\n";
		print SQL "go\n";

		foreach $db (@gDBNamesToProcess) {
			print SQL "EXEC sp_T38LOGERROR 3, 'T38STATS', 'Updating statistics for database $db'\n";
			print SQL "USE $db \n";
			print SQL "go\n";
			print SQL "exec sp_updatestats\n";
		}
			
		print SQL "set nocount off \n";
		print SQL "go\n";
    	print SQL "EXEC sp_T38LOGERROR 3, 'T38STATS', 'Finished.' \n";


		# Close SQL file 
		#
		close(SQL);

		# run the sql file
		#
		$rtnCode=&T38lib::Common::runSQLChk4Err($statsSQLFileName,$gserverName,"",$statsOutputFileName,"","","","",\@includeErr,\@excludeErr);

		# Check for the status
		#
		&notifyWSub("Return Code from runSQLChk4Err sub = $rtnCode");
		if ( $rtnCode == 1)  {
			&notifyWSub("STATS Failed!!");
			$status = 0;
			last SUB;
		}

		last SUB;

	}	# SUB
	# ExitPoint:

	&notifyWSub("finised with $status status.");

	return($status);

}	# 

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
	my $status = 1;
	my $srvrName;
	my $logFileName = '';
	my $logDirSuffix = '';
	my $logStr = $0;
	my ($key,$value, $aref, $nvals, $i, $db);
	my ($dbFound) = (0);
	my (@STATSIncludeDBName) = ();
    my (@STATSExcludeDBName) = ();
	my (@allDBNames) = ();
	my (@temp) = ();
	my @args = ();
	my $cfgFile	= '';

	$gScriptName	= "";			# Base name of the current script.
	$gScriptPath	= ".\\";		# Directory path to current script.

	$logStr = $logStr . " ";

	($gScriptPath, $gScriptName, $scriptSuffix) = &T38lib::Common::parseProgramName();

	#-- initialize standard options

	getopts('ha:l:d:S:');

	$gserverName	= uc(Win32::NodeName());
	$gNWarnings	= 0;

	#-- program specific initialization

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
		}

		# Set Log file directory
		#
		unless (&T38lib::Common::setLogFileDir("${gScriptPath}T38LOG\\$logFileName")) {
			&errme("Cannot set program log directory.");
			$status = 0;
			last SUB;
		}

		# Change number archived logs
		#
		if($Getopt::Std::opt_a) {
			$logStr = $logStr . " -a $GetOpt::Std::opt_a";
			if ( $Getopt::Std::opt_a =~ /\d/) {
				if ( ($Getopt::Std::opt_a < 101) and ($Getopt::Std::opt_a > 0) ) {
					$gnumArchive = $Getopt::Std::opt_a;
				}
			}
		}

		&T38lib::Common::archiveLogFile($gnumArchive);

		# Process command line database name here
		#
		if($Getopt::Std::opt_d) {
			$gcmdlineDBName = $Getopt::Std::opt_d;
			$logStr = $logStr . " -d $gcmdlineDBName";
		}

		# Process command line Server Name and instance name
		#
		if($Getopt::Std::opt_S) {
			$srvrName = $Getopt::Std::opt_S;
			$srvrName =~ s/^\./$gserverName/;
			$gserverName = uc($srvrName);
			($gNetSrvr, $gInstName)	=	split("\\\\", $gserverName); 
			$gInstName =~ s/^\s+//g; 
			$gInstName =~ s/\s+$//g;
			$logStr = $logStr . " -S $gserverName";
		}
		else {
			$gNetSrvr = $gserverName;
		}

		# Check Perl version.
		#
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

		&logme("Starting $gScriptName from $gScriptPath", "started");
		&notifyWSub("STARTED");

		#----------------------------------------------------------------
		# get all the databases name from the server system tables.
		#----------------------------------------------------------------
		@allDBNames=&T38lib::Common::getDBNames($gserverName);
		if ( $allDBNames[0] eq "$gT38ERROR" ) {
			&errme("Call to &T38lib::Common::getDBNames($gserverName) failed.");
			$status = 0;
			last SUB;
		}
		&notifyWSub("Databases on $gserverName: @allDBNames");

		#----------------------------------------------------------------
		# Make sure the command line database is a valid database on
		# the server
		#----------------------------------------------------------------
		$dbFound=0;
		if($gcmdlineDBName ne "") {
			foreach $db (@allDBNames) {
				if ( $db eq $gcmdlineDBName ) {
					$dbFound = 1;
					last;
				}
			}
			if ( $dbFound == 0 ) {
				&errme("Command Line database $gcmdlineDBName not found on server $gserverName");
				@gDBNamesToProcess = ();
				$status = 0;
				last SUB;
			}
			@gDBNamesToProcess = $gcmdlineDBName;
			&notifyWSub("Command line Database = $gcmdlineDBName");
			last SUB;
		}

		# For debug
		#while (($key,$value) = each(%gConfigValues)) {
		#	print "key = $key  value = $value\n";
		#}

		#----------------------------------------------------------------
		# Prepare an array of STATS include databases
		#----------------------------------------------------------------
		$dbFound=0;
		if (defined($T38lib::t38cfgfile::gConfigValues{'T38LIST:STATSIncludeDBName'})) {
			$aref = $T38lib::t38cfgfile::gConfigValues{'T38LIST:STATSIncludeDBName'};
			$nvals = scalar @{$aref};
			for $i (0..$nvals-1) {
				$STATSIncludeDBName[$i] = $$aref[$i];
			}
			&notifyWSub("Database Include List = @STATSIncludeDBName");
		}

		#----------------------------------------------------------------
		# Prepare an array of STATS Exclude databases
		#----------------------------------------------------------------
		$dbFound=0;
		if (defined($T38lib::t38cfgfile::gConfigValues{'T38LIST:STATSExcludeDBName'})) {
			$aref = $T38lib::t38cfgfile::gConfigValues{'T38LIST:STATSExcludeDBName'};
			$nvals = scalar @{$aref};
			for $i (0..$nvals-1) {
				$STATSExcludeDBName[$i] = $$aref[$i];
			}
			&notifyWSub("Database Exclude List = @STATSExcludeDBName");
		}

		#----------------------------------------------------------------
		# Process database name using Include and Exclude from cfg file
		# Provide a final list of databases to be process for STATS
		#----------------------------------------------------------------

		@gDBNamesToProcess = &T38lib::Common::filterDB(\@allDBNames,\@STATSIncludeDBName, \@STATSExcludeDBName);

		#----------------------------------------------------------------
		# Filter database that we don't want to do dump
		# example tempdb, model ....
		#----------------------------------------------------------------
		@temp = ();
		foreach $db (@gDBNamesToProcess) {	
			unless ($db =~ /^($gfilterDBList)$/i ) {
				push (@temp, $db);
			}
		}
		@gDBNamesToProcess = ();

		# Final list of Databases to process for STATS
		#
		@gDBNamesToProcess = @temp;

	}	# SUB
	# ExitPoint:

	&notifyWSub("command line: $logStr");
	&notifyWSub("Database Process List = @gDBNamesToProcess");

	&notifyWSub("finised with $status status.");

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
#* T38stats - T38stats perl script
#*
#*$Author: A645276 $
#*$Date: 2011/02/08 17:12:21 $
#*$Revision: 1.1 $
#*$Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/DBINST/SQL65/T38stats.pv_  $
#*
#* SYNOPSIS
#*   T38stats.pl -h -a 10 -l -S ServerName -d databaseName ConfigfileName
#*
#*Where:
#*
#*   -h   Writes help screen on standard output, then exits.
#*   -a	  10 Number of log file archived, default is 7
#*   -l   logsuffx Optional Log File Directory suffix. This is used to
#*        ensure multiple copies of the program can run at the 
#*        same time without overwriting the log file.
#*   -d   dbName	Run Update Stats on a give database name
#*   -S   Server Name 
#*
#*   Configration file or mutiple cfg files
#*
#*Example:
#*   Run stats on server DS01DBA using t38dba.cfg configuration file
#*      t38stats.pl -S DS01DBA T38dba.cfg
#*
#*   Run stats on server DS01DBA on database SKUDB001 using T38dba.cfg parameter
#*      t38stats.pl -S DS01DBA -d SKUDB001 T38dba.cfg
#*
#*   Run stats on server DS01DBA using T38dba.cfg and nba.cfg parameters
#*      t38stats.pl -S DS01DBA T38dba.cfg nba.cfg
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
