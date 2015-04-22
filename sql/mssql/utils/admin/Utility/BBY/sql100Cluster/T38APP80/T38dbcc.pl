#!perl 
#* T38dbcc - T38dbcc perl script
#*
#*$Author: A645276 $
#*$Date: 2011/02/08 17:12:20 $
#*$Revision: 1.1 $
#*$Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/DBINST/SQL65/T38dbcc.pv_  $
#*
#* SYNOPSIS
#*   t38dbcc.pl -h -a10 -ldbcc -SServerName -ddatabaseName ConfigfileName(s)
#*
#*Where:
#*
#*   -h   Writes help screen on standard output, then exits.
#*   -a   10 Number of log file archived, default is 7
#*   -l   logsuffx Optional Log File Directory suffix. This is used to
#*        ensure multiple copies of the program can run at the 
#*        same time without overwriting the log file.
#*   -d   dbName	Run run dbcc on a give database name
#*   -S   Server Name 
#*
#*   Configration file or mutiple cfg files
#*
#*Example:
#*   Run dbcc on server DS01DBA using t38dba.cfg configuration file
#*      t38dbcc.pl -S DS01DBA T38dba.cfg
#*
#*   Run dbcc on server DS01DBA on database SKUDB001 using T38dba.cfg parameter
#*      t38dbcc.pl -S DS01DBA -d SKUDB001 T38dba.cfg
#*
#*   Run dbcc on server DS01DBA using T38dba.cfg and nba.cfg parameters
#*      t38dbcc.pl -S DS01DBA T38dba.cfg nba.cfg
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
sub runDBCC();

#---------------------------------------------------
# List of database that will be excluded from DBCC
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
		unless(&runDBCC())			{ $mainStatus = 1; last SUB; } 		

		last SUB;
	
	}	# SUB
	# ExitPoint:

	$mainStatus = 1	if ($gNWarnings > 0);

	( $mainStatus== 0 ) ?
		logme("Finished with status $mainStatus", "done") :
		warnme("Finished with status $mainStatus", "done") ;

	exit($mainStatus);

}	# End of main


#######################  $Workfile:   T38dbcc.pl  $ Subroutines  #################################

# ----------------------------------------------------------------------
#	RunDBCC		Run DBCC checkdb on the list of databases
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------

sub runDBCC () {

	my $status	= 1;
	my $rtnCode;
	my ($db, $dbccSQLFileName, $dbccOutputFileName); 
	my ($logFileName, $logFilePath, $lfbase, $lftype);

	my @includeErr = (911, 2502, 2503, 2504,
            		  2505, 2506, 2507, 2508,
            		  2509, 2510, 2511, 2512,
            		  2513, 2514, 2516, 2517,
            		  2521, 2522, 2523, 2524,
            		  2525, 2529, 2531, 2532,
            		  2533, 2534, 2535, 2541,
            		  2542, 2543, 2544, 2545,
            		  2546, 2547, 7930, 7931,
            		  2518, 2519);
	SUB: {
		&notifyWSub("STARTED");

		$logFileName = &T38lib::Common::getLogFileName($0);
		fileparse_set_fstype("MSWin32");
		($lfbase, $logFilePath, $lftype) = fileparse($logFileName, '\.[^\.]*');

		$dbccSQLFileName = $logFilePath . "dbcc.sql";
		$dbccOutputFileName = $logFilePath . "dbcc.out";

		# Archive the input and output files
		#
		&T38lib::Common::archiveFile($dbccSQLFileName, $gnumArchive);
		&T38lib::Common::archiveFile($dbccOutputFileName,$gnumArchive);

		# Input and out files
		#
		&notifyWSub("DBCC SQL file => $dbccSQLFileName");
		&notifyWSub("DBCC OUTPUT file => $dbccOutputFileName");

		# Do we have any databases to run dbcc on
		#
		if ($#gDBNamesToProcess < 0) {
			&notifyWSub ("No Databases to process for DBCC");
			last SUB;
		}

		# Open file to write DBCC commands
		#
		unless (open(SQL,">$dbccSQLFileName")) {
			&errme("Cannot open file $dbccSQLFileName: $!");
			$status = 0;
			last SUB;
		}
		
		# Write command to the file
		#
		print SQL "EXEC sp_T38LOGERROR 3, 'DB_CHKS', 'Started.'\n";
		print SQL "use master\n";
		print SQL "go\n";
		print SQL "SET ARITHABORT ON\n";
		print SQL "go\n";
	    print SQL "SET QUOTED_IDENTIFIER ON\n";
		print SQL "go\n";
		foreach $db (@gDBNamesToProcess) {
 			print SQL "DBCC CHECKDB($db)\n";
			print SQL "go\n";
		}
		print SQL "EXEC sp_T38LOGERROR 3, 'DB_CHKS', 'Finished.' \n";

		# Close DBCC file 
		#
		close(SQL);

		# run the DBCC sql file
		#
		$rtnCode  = &T38lib::Common::runSQLChk4Err($dbccSQLFileName, $gserverName, "", $dbccOutputFileName, "", "", "", "",\@includeErr);

		# Check for the status
		#
		&notifyWSub("Return Code from runSQLChk4Err sub = $rtnCode");
		if ( $rtnCode == 1)  {
			&notifyWSub("DBCC Failed!! Check output file: $dbccOutputFileName");
			$status = 0;
			last SUB;
		}

		last SUB;

	}	# SUB
	# ExitPoint:

	&notifyWSub("finised with $status status.");

	return($status);

}	# End of runDBCC

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
	my (@DBCCIncludeDBName) = ();
    my (@DBCCExcludeDBName) = ();
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
		# Append the log file directory suffix if supplied using
		# command line argument.
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
		# get all the databases name from the server system table
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
			@gDBNamesToProcess =  $gcmdlineDBName;
			&notifyWSub("Command line Database = $gcmdlineDBName");
			last SUB;
		}

		# For debug
		#while (($key,$value) = each(%gConfigValues)) {
		#	print "key = $key  value = $value\n";
		#}

		#----------------------------------------------------------------
		# Prepare an array of DBCC include databases
		#----------------------------------------------------------------
		$dbFound=0;
		if (defined($T38lib::t38cfgfile::gConfigValues{'T38LIST:DBCCIncludeDBName'})) {
			$aref = $T38lib::t38cfgfile::gConfigValues{'T38LIST:DBCCIncludeDBName'};
			$nvals = scalar @{$aref};
			for $i (0..$nvals-1) {
				$DBCCIncludeDBName[$i] = $$aref[$i];
			}
			&notifyWSub("Database Include List = @DBCCIncludeDBName");
		}

		#----------------------------------------------------------------
		# Prepare an array of DBCC Exclude databases
		#----------------------------------------------------------------
		$dbFound=0;
		if (defined($T38lib::t38cfgfile::gConfigValues{'T38LIST:DBCCExcludeDBName'})) {
			$aref = $T38lib::t38cfgfile::gConfigValues{'T38LIST:DBCCExcludeDBName'};
			$nvals = scalar @{$aref};
			for $i (0..$nvals-1) {
				$DBCCExcludeDBName[$i] = $$aref[$i];
			}
			&notifyWSub("Database Exclude List = @DBCCExcludeDBName");
		}

		#----------------------------------------------------------------
		# Process database name using Include and Exclude from cfg file
		# Provide a final list of databases to be process for DBCC
		#----------------------------------------------------------------

		@gDBNamesToProcess = &T38lib::Common::filterDB(\@allDBNames,\@DBCCIncludeDBName, \@DBCCExcludeDBName);

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

		# Final list of Databases to process for DBCC
		#
		@gDBNamesToProcess = @temp;

	}	# SUB
	# ExitPoint:

	&notifyWSub("command line: $logStr");
	&notifyWSub("Database Process List = @gDBNamesToProcess");

	&notifyWSub("finised with $status status.");

	return($status);

}	# End of housekeeping

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
#* T38dbcc - T38dbcc perl script
#*
#*$Author: A645276 $
#*$Date: 2011/02/08 17:12:20 $
#*$Revision: 1.1 $
#*$Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/DBINST/SQL65/T38dbcc.pv_  $
#*
#* SYNOPSIS
#*   t38dbcc.pl -h -a10 -ldbcc -SServerName -ddatabaseName ConfigfileName(s)
#*
#*Where:
#*
#*   -h   Writes help screen on standard output, then exits.
#*   -a   10 Number of log file archived, default is 7
#*   -l   logsuffx Optional Log File Directory suffix. This is used to
#*        ensure multiple copies of the program can run at the 
#*        same time without overwriting the log file.
#*   -d   dbName	Run run dbcc on a give database name
#*   -S   Server Name 
#*
#*   Configration file or mutiple cfg files
#*
#*Example:
#*   Run dbcc on server DS01DBA using t38dba.cfg configuration file
#*      t38dbcc.pl -S DS01DBA T38dba.cfg
#*
#*   Run dbcc on server DS01DBA on database SKUDB001 using T38dba.cfg parameter
#*      t38dbcc.pl -S DS01DBA -d SKUDB001 T38dba.cfg
#*
#*   Run dbcc on server DS01DBA using T38dba.cfg and nba.cfg parameters
#*      t38dbcc.pl -S DS01DBA T38dba.cfg nba.cfg
#*
#***
EOT
} #	End of showHelp


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
