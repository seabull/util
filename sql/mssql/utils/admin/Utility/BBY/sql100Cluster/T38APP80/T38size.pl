#!perl 
#* T38size - Get Databases size
#*
#*$Author: A645276 $
#*$Date: 2011/02/08 17:12:21 $
#*$Revision: 1.1 $
#*$Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/DBINST/SQL65/T38size.pv_  $
#*
#* SYNOPSIS
#* T38size.pl -h -a 10 -l logfileDirSuffix -S ServerName cfgfile1.cfg cfgfile2.cfg...
#*
#* Where:
#*
#*   -h     Writes help screen on standard output, then exits.
#*   -a 10  Number of log file archived, default is 7
#*   -l     logsuffx	Optional Log File Directory suffix. This is used to
#*          ensure multiple copies of the program can run at the 
#*          same time without overwriting the log file.
#*   -S     Server Name  Name of the server
#*
#*  Configration file or multiple cfg files with no command line flag
#*
#*
#* Example:
#*   Run T38size.pl    (No command line parametes)
#*        perl T38size.pl
#*
#*   Run T38size.pl on Server DS3DIPK
#*        perl T38size.pl -S DS3DIPK
#*
#*   Run T38size.pl on Server DS4DBII using T38dba.cfg file as an input parameter
#*        perl T38size.pl -S DS4DBII T38dba.cfg
#*
#***

use strict;

use T38lib::Common qw(notifyMe notifyWSub logme warnme errme);
use T38lib::t38cfgfile qw(:CFGFILE_SUBS :CFGFILE_VARS);
use Getopt::Std;

# Function Prototype
sub append($);
sub chk4errs($);
sub doSomething();
sub housekeeping();
sub main();

# Global Variables
my ( $gCurrentDir, $gScriptName, $gScriptPath, $gNWarnings) = ("","","","");
my ($gserverName, $gNetSrvr, $gInstName) = ("","","");;
my ($gT38ERROR) = $T38lib::Common::T38ERROR;
my (@gDBNamesToProcess) = ();
my  $gisql = "osql -E -dmaster -n -w300"; 

#---------------------------------------------------
# List of database that will be excluded 
#---------------------------------------------------
my ($gfilterDBList) = "model|northwind|pubs|";


# Main
&main();


############################  BBY Subroutines  ####################################

sub main() {

	my $mainStatus	= 0;

	SUB: {
		unless (&housekeeping())	{ $mainStatus = 1; last SUB; }
		unless(&doSomething())	{ $mainStatus = 1; last SUB; } 		
		last SUB;
	
	}	# SUB
	# ExitPoint:


	$mainStatus = 1	if ($gNWarnings > 0);

	( $mainStatus== 0 ) ?
		logme("Finished with status $mainStatus", "done") :
		warnme("Finished with status $mainStatus", "done") ;

	exit($mainStatus);

}	# main


#######################  $Workfile:   T38size.pl  $ Subroutines  #################################

# ----------------------------------------------------------------------
#	doSomething		short description for the do something
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------

sub doSomething () {

	my $status	= 1;
	my ($dbSize, $db, $sqlCmd);
	my $ghistoryFile = "$gScriptName.out";

	$ghistoryFile = $gScriptPath . $ghistoryFile;

	SUB:
	{
		&notifyWSub("STARTED");
		&notifyWSub("History file name: $ghistoryFile");

		# Open log file 
		unless (open(AppendSizeInfo,">>$ghistoryFile")) {
			&errme("Cannot open File $ghistoryFile");
			$status = 0;
			last SUB;
		}

		# Do we have any databases to run dbcc on
		#
		if ($#gDBNamesToProcess < 0) {
			&notifyWSub ("No Databases to process...");
			last SUB;
		}

		&notifyWSub ("Start DB Size");
		&notifyWSub ("----------------");

		foreach $db (@gDBNamesToProcess) {
			$sqlCmd = "$gisql -Q \"use $db ; exec sp_T38DBSIZE\" ";
			$dbSize = `$sqlCmd`;

			unless (&chk4errs($dbSize)) { 
				&errme("$sqlCmd   FAILED");
				&errme("$dbSize");
				$status = 0;
				last SUB;
			}

			&notifyWSub ("$sqlCmd");
			&notifyWSub ("$dbSize");
			&append("$dbSize");
		}

		&notifyWSub ("Finish DBSize");

		last SUB;
	}	# SUB
	# ExitPoint:

	&notifyWSub("Finised with $status status.");
	close(AppendSizeInfo);

	return($status);

}	# doSomething

#----------------------------------------------------------------------
# Check for SQL errors  
#----------------------------------------------------------------------
sub chk4errs($) {
   my ($msg)  = @_;

   my $status	= 1;
################### Variables of errors to include/exclude ##########################
	my $lowersev = 17;	# Lowest severity level that we will report on.
								# possible serverity values are
								#	 0 - 10 are informational
								#	11 - 16 are user generated
								#	17 - 19 are hardware issues
								#	20 - +  are system fatal errors

	my @XErr = (219, 1104, 2540, 15023, 15024, 15025, 15026, 15027, 15028, 15029, 
	15029, 15030, 15031, 15032, 15034);	# errors we're not interested in

	my @IErr = ();		# Error we always want to include, regardless of sev. level.
	my ($err, $sev);  

#########################  Optional Variable Conditions  ##########################

##############################  Program Variables  ##############################

	my $noterr = join("|",@XErr);
	my $iserr  = join("|",@IErr);

	&notifyWSub("STARTED");

	if ($msg =~ m/Msg\s* (\d+),\s* Level\s*(\d+),/i) {
		($err, $sev) = ($1, $2);
		if (($sev >= $lowersev) || ($err =~ m/$iserr/))	{
			$status = 0 unless ($err =~ m/$noterr/);
		} 
	}

	&notifyWSub("Finised with $status status.");

	return ($status);
}

#--------------------------------------------------
#     append -- append message to history file
#-------------------------------------------------

sub append($) {
	my($appendmsg)  = @_;

	my($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);
	my $date;

	&notifyWSub("STARTED");

	($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);

	$date = sprintf ("%02d/%02d/%04d %02d:%02d", $mon+1, $mday, $year+1900, $hour, $min);
	printf AppendSizeInfo ("%s\n%s\n", $date, $appendmsg);

	&notifyWSub("Finised");

} # END sub append


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
	my (@allDBNames) = ();
	my ($key,$value, $aref, $nvals, $i, $db);
	my (@DBSIZEIncludeDBName) = ();
    my (@DBSIZEExcludeDBName) = ();
	my (@allDBNames) = ();
	my (@temp) = ();


	$gScriptName	= "";			# Base name of the current script.
	$gScriptPath	= ".\\";		# Directory path to current script.


	($gScriptPath, $gScriptName, $scriptSuffix) = &T38lib::Common::parseProgramName();

	#-- initialize standard options
	$logStr = $logStr . " ";

	getopts('ha:l:S:');

	$gserverName	= uc(Win32::NodeName());
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
			&errme("Cannot set program log directory.");
			$status = 0;
			last SUB;
		}

		#<# Change number archived logs #>#
		if($Getopt::Std::opt_a) {
			if ( $Getopt::Std::opt_a =~ /\d/) {
				if ( ($Getopt::Std::opt_a < 101) and ($Getopt::Std::opt_a > 0) ) {
					$numArchive = $Getopt::Std::opt_a;
					$logStr = $logStr . " -a $numArchive";
				}
			}
		}

		&T38lib::Common::archiveLogFile($numArchive);
		&notifyWSub("STARTED");
		&logme("Starting $gScriptName from $gScriptPath");

		# Process command line Server Name and instance name
		#
		if($Getopt::Std::opt_S) {
			$srvrName = $Getopt::Std::opt_S;
			$gisql = $gisql . " -S $srvrName";
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

		# For debug
		#while (($key,$value) = each(%gConfigValues)) {
		#	print "key = $key  value = $value\n";
		#}

		#----------------------------------------------------------------
		# Prepare an array databases
		#----------------------------------------------------------------
		if (defined($T38lib::t38cfgfile::gConfigValues{'T38LIST:DBSIZEIncludeDBName'})) {
			$aref = $T38lib::t38cfgfile::gConfigValues{'T38LIST:DBSIZEIncludeDBName'};
			$nvals = scalar @{$aref};
			for $i (0..$nvals-1) {
				$DBSIZEIncludeDBName[$i] = $$aref[$i];
			}
			&notifyWSub("Database Include List = @DBSIZEIncludeDBName");
		}

		#----------------------------------------------------------------
		# Prepare an array of Exclude databases
		#----------------------------------------------------------------
		if (defined($T38lib::t38cfgfile::gConfigValues{'T38LIST:DBSIZEExcludeDBName'})) {
			$aref = $T38lib::t38cfgfile::gConfigValues{'T38LIST:DBSIZEExcludeDBName'};
			$nvals = scalar @{$aref};
			for $i (0..$nvals-1) {
				$DBSIZEExcludeDBName[$i] = $$aref[$i];
			}
			&notifyWSub("Database Exclude List = @DBSIZEExcludeDBName");
		}

		#----------------------------------------------------------------
		# Process database name using Include and Exclude from cfg file
		# Provide a final list of databases to be process 
		#----------------------------------------------------------------

		@gDBNamesToProcess = &T38lib::Common::filterDB(\@allDBNames,\@DBSIZEIncludeDBName, \@DBSIZEExcludeDBName);

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

		# Final list of Databases to process 
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
#* T38size - Get Databases size
#*
#*$Author: A645276 $
#*$Date: 2011/02/08 17:12:21 $
#*$Revision: 1.1 $
#*$Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/DBINST/SQL65/T38size.pv_  $
#*
#* SYNOPSIS
#* T38size.pl -h -a 10 -l logfileDirSuffix -S ServerName cfgfile1.cfg cfgfile2.cfg...
#*
#* Where:
#*
#*   -h     Writes help screen on standard output, then exits.
#*   -a 10  Number of log file archived, default is 7
#*   -l     logsuffx	Optional Log File Directory suffix. This is used to
#*          ensure multiple copies of the program can run at the 
#*          same time without overwriting the log file.
#*   -S     Server Name  Name of the server
#*
#*  Configration file or multiple cfg files with no command line flag
#*
#*
#* Example:
#*   Run T38size.pl    (No command line parametes)
#*        perl T38size.pl
#*
#*   Run T38size.pl on Server DS3DIPK
#*        perl T38size.pl -S DS3DIPK
#*
#*   Run T38size.pl on Server DS4DBII using T38dba.cfg file as an input parameter
#*        perl T38size.pl -S DS4DBII T38dba.cfg
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
