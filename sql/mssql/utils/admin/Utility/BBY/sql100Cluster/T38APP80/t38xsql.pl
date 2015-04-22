#!perl 
#*  t38xsql - execute sql script with error checking..
#*
#*	$Author: A645276 $
#*	$Date: 2011/02/08 17:12:24 $
#*	$Revision: 1.1 $
#*	$Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/Utilities/t38xsql.pv_  $
#*
#* SYNOPSIS
#*	t38xsql -h | -i input file -o output file -q query -S server name -U username -P password -m moreopt -d dbName -l lowestsevirity -a 3 -A 7
#*	
#*	Where:
#*	
#*	-h		Writes help screen on standard output, then exits.
#*	-a		Number of log file archived, default is 7
#*	-A		Number of output files to archive, default is 7
#*	-m		Allows more command line switches for osql.exe.
#*	-h		Write this documentation on standard output, then exit.
#*	-i		Input file with SQL Script.
#*			This option or -q option must be present.
#*	-o		Output file.  Where found errors are saved.
#*	-q		Query command is run in place of scanning an input file.
#*	-S		optional server name
#*	-U		optional username
#*	-P		optional password
#*	-d		optional database name
#*	-l		lowest exceptable sevirity for error checking (default is 11).
#*
#*
#*	NOTE: either -i or -q option must be defined, but not both.  
#*	      Process will quit otherwise. -o option must defined 
#*	      in order to execute with the -q option.
#*
#*	Example: 
#*	1. Scan a file for errors, write those errors to an outfile.
#*		T38xsql.pl -i error.sql -o error.out
#*
#*		
#*	2. Run a query and send to output file.	
#*       perl T38xsql.pl -q "select @@version" -o error.out
#*	NOTE: in order to execute a query, have to explicitly specify perl interpreter.
#*	In this case cannot use file associations, since spaces in a sql statement will
#*	be interpreted as parameters.
#*	
#*
#***

use strict;

use T38lib::Common qw(notifyMe notifyWSub logme warnme errme);
use T38lib::t38cfgfile qw(:CFGFILE_SUBS :CFGFILE_VARS);
use Getopt::Std;
use File::Basename;

# Global Variables
my ( $gCurrentDir, $gScriptName, $gScriptPath, $gHostName, $gNWarnings) = "";
my (
	$gSqlIn, $gSqlOut, $gSqlQuery, 
	$gSrvrName, $gUserName, $gPassword, 
	$gMoreOpt, $gDbName, $gLowestSev, $gNarcOut) = 0;

# Main
&main();


############################  BBY Subroutines  ####################################

sub main {
	my $mainStatus	= 0;
	SUB:
	{
		unless (&housekeeping())	{ $mainStatus = 1; last SUB; }
		unless(&runsql())	{ $mainStatus = 1; last SUB; } 		
		last SUB;
	
	}	# SUB
	# ExitPoint:


	$mainStatus = 1	if ($gNWarnings > 0);

	( $mainStatus== 0 ) ?
		logme("Finished with status $mainStatus", "done") :
		warnme("Finished with status $mainStatus", "done") ;

	exit($mainStatus);

}	# main


#######################  $Workfile:   t38xsql.pl  $ Subroutines  #################################

# ----------------------------------------------------------------------
#	runsql		run requested sql code
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------

sub runsql () {
	my $status		= 1;
	my $runcmdstat	= 0;
	my @srvrNames	= ();
	my $serverName	= '';
	my $sqlinput	= ($gSqlIn) ? $gSqlIn : $gSqlQuery;
	my $sqlOutput 	= $gSqlOut;
	my $sqlTmpBase	= "$gScriptName.tmp";
	my $sqlTmp		= $sqlTmpBase;
	my ($logFileName, $lfbase, $logFilePath, $lftype);

	SUB:
	{
		&notifyWSub("runsql started");

		if ( -s $gSrvrName ) {
			# Server name is name of the file with servers.
			unless (open (INPUT, "<$gSrvrName") ) { 
				&errme("Cannot open file: $gSrvrName");
				$status = 0; last SUB;
			}

			while (<INPUT>) {
				chomp;
				$_ =~ s/^\s+//;		# Remove leading white spaces
				$_ =~ s/\s+$//;		# Remove trailing white spaces
				if ( /^#/ || /^\s*$/) {
					next;
				}
				push(@srvrNames, $_); 
			}
			close (INPUT);
		} else {
			push(@srvrNames, $gSrvrName);	# push the server name to our array
		}


		# Set output file name as runSQLChk4Err does.

		$logFileName = &T38lib::Common::getLogFileName($0);
		fileparse_set_fstype("MSWin32");
		($lfbase, $logFilePath, $lftype) = fileparse($logFileName, '\.[^\.]*');
		$sqlOutput	= $logFilePath . $gSqlOut;
		$sqlTmp		= $logFilePath . $sqlTmpBase;

		unless (&T38lib::Common::archiveFile($sqlOutput, $gNarcOut)) {
			&warnme("Cannot create archive files for $sqlOutput");
			$status = 0; last SUB;
		}

		foreach $serverName (@srvrNames) {
			chomp($serverName);

			&notifyWSub("Running '$sqlinput' for $serverName.");
			$runcmdstat = &T38lib::Common::runSQLChk4Err($sqlinput, $serverName, $gDbName, $sqlTmpBase, $gUserName, $gPassword, $gLowestSev, $gMoreOpt);

			unless (open (TEMP, "<$sqlTmp") ) {
				&errme("Cannot open file: $sqlTmp");
				$status = 0; next;
			}

			unless (open (SQLOUT, ">>$sqlOutput") ) {
				&errme("Cannot open output file $sqlOutput.");
				$status = 0; next;
			}

			if (scalar(@srvrNames) > 1) { print SQLOUT "Results for Server $serverName:\n"; }
			while (<TEMP>) {
				print SQLOUT;
			}
			close SQLOUT;
			close TEMP;

			# Check for errors.
			if ($runcmdstat != 0) {
				&errme("Error running SQL for $serverName in $sqlinput. Review $sqlOutput");
				$status = 0; next;
			}
			unlink($sqlTmp);
		}


		&notifyWSub("The runsql completed. Log file is $sqlOutput.");

		last SUB;
	}	# SUB
	# ExitPoint:

	&notifyWSub("runsql finised with status  $status.");
	return($status);

}	# runsql

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
	my $numArchive = 3;
	my $status = 1;

	$gScriptName	= "";			# Base name of the current script.
	$gScriptPath	= ".\\";		# Directory path to current script.


	($gScriptPath, $gScriptName, $scriptSuffix) = &T38lib::Common::parseProgramName();

	#-- initialize standard options

	getopts('ha:A:i:o:S:U:P:m:d:l:q:');

	use Sys::Hostname;
	$gHostName	= hostname;
	$gNWarnings	= 0;

	#-- program specific initialization


	#-- show help

	if ($Getopt::Std::opt_h) { &showHelp(); exit; }

	# Open log and error files, if needed.

	SUB: {
		# Has to setup log file later in a code, when output file name is available.
		# Log file has to be created, based on output file name, instead of the 
		# script name. Otherwise all jobs that run SQL Scripts with t38xsql will
		# try to write to same log file.

		$gSqlIn		= ($Getopt::Std::opt_i) ? $Getopt::Std::opt_i: 0;
		$gSqlOut	= ($Getopt::Std::opt_o) ? $Getopt::Std::opt_o: 0;
		$gSqlQuery	= ($Getopt::Std::opt_q) ? $Getopt::Std::opt_q: 0;
		$gSrvrName	= ($Getopt::Std::opt_S) ? $Getopt::Std::opt_S: $gHostName;
		$gUserName	= ($Getopt::Std::opt_U) ? $Getopt::Std::opt_U: 0;
		$gPassword	= ($Getopt::Std::opt_P) ? $Getopt::Std::opt_P: 0;
		$gMoreOpt	= ($Getopt::Std::opt_m) ? $Getopt::Std::opt_m: 0;
		$gDbName	= ($Getopt::Std::opt_d) ? $Getopt::Std::opt_d: 0;
		$gLowestSev	= ($Getopt::Std::opt_l) ? $Getopt::Std::opt_l: 11;
		$gNarcOut	= ($Getopt::Std::opt_A) ? $Getopt::Std::opt_A: 7;

		unless ($gSqlIn xor $gSqlQuery)	{
			&errme("Have to provide sql statement or script on a command line, but not both.");
			$status = 0; last SUB;
		}

		if ($gSqlQuery && ! $gSqlOut) {
			&errme("Have to provide output file name (-o) with sql statement (-q).");
			$status = 0; last SUB;
		}

		unless ($gSqlOut) {
			($gSqlOut = $gSqlIn) =~ s/\.[^\.]*$/.out/;
		}

		if ($gSqlIn && ($gSqlIn eq $gSqlOut)) {
			&errme("Input and output file cannot have the same name.");
			$status = 0; last SUB;
		}

		fileparse_set_fstype("MSWin32");
		my ($sqlobase, $sqloPath, $sqlotype) = fileparse($gSqlOut, '\.[^\.]*');
		$gSqlOut = $sqlobase . $sqlotype;

		if ($gSqlOut =~ /[\\\/:]/) {
			&errme("Output file name $gSqlOut has to be base file name. Cannot include special path characters [\\/:].");
			$status = 0; last SUB;
		}

		# Now we should have valid output file. Setup log files.

		unless (&T38lib::Common::setLogFileDir("${gScriptPath}T38LOG\\$sqlobase")) {
			&errme("Cannot set program log directory.");
			$status = 0;
			last SUB;
		}

		if($Getopt::Std::opt_a) {
			if ( $Getopt::Std::opt_a =~ /\d/) {
				if ( ($Getopt::Std::opt_a < 101) and ($Getopt::Std::opt_a > 0) ) {
					$numArchive = $Getopt::Std::opt_a;
				}
			}
		}

		&T38lib::Common::archiveLogFile($numArchive);
		&logme("Starting $gScriptName from $gScriptPath", "started");

		# Continue with input validation.

		if ($gUserName xor $gPassword) {
			&errme("Both user name and password has to be provided or none.");
			$status = 0; last SUB;
		}

		if ($gSqlIn && !-s $gSqlIn) {
			&errme("Missing input file $gSqlIn.");
			$status = 0; last SUB;
		}

		# Check Perl version.

		unless ( &T38lib::Common::chkPerlVer() ) {
			&notifyWSub("Wrong version of Perl!");
			&notifyWSub("This program run on Perl version 5.005 and higher.");
			&notifyWSub("Check the Perl version by running perl -v on command line.");
			$status = 0;
			last SUB;
		}

		&notifyWSub("$gHostName: Running T38xsql -i $gSqlIn -o $gSqlOut -q $gSqlQuery -S $gSrvrName -U $gUserName -m $gMoreOpt -d $gDbName -l $gLowestSev -A $gNarcOut.");
	}	# SUB
	# ExitPoint:

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
#*  t38xsql - execute sql script with error checking..
#*
#*	$Author: A645276 $
#*	$Date: 2011/02/08 17:12:24 $
#*	$Revision: 1.1 $
#*	$Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/Utilities/t38xsql.pv_  $
#*
#* SYNOPSIS
#*	t38xsql -h | -i input file -o output file -q query -S server name -U username -P password -m moreopt -d dbName -l lowestsevirity -a 3 -A 7
#*	
#*	Where:
#*	
#*	-h		Writes help screen on standard output, then exits.
#*	-a		Number of log file archived, default is 7
#*	-A		Number of output files to archive, default is 7
#*	-m		Allows more command line switches for osql.exe.
#*	-h		Write this documentation on standard output, then exit.
#*	-i		Input file with SQL Script.
#*			This option or -q option must be present.
#*	-o		Output file.  Where found errors are saved.
#*	-q		Query command is run in place of scanning an input file.
#*	-S		optional server name
#*	-U		optional username
#*	-P		optional password
#*	-d		optional database name
#*	-l		lowest exceptable sevirity for error checking (default is 11).
#*
#*
#*	NOTE: either -i or -q option must be defined, but not both.  
#*	      Process will quit otherwise. -o option must defined 
#*	      in order to execute with the -q option.
#*
#*	Example: 
#*	1. Scan a file for errors, write those errors to an outfile.
#*		T38xsql.pl -i error.sql -o error.out
#*
#*		
#*	2. Run a query and send to output file.	
#*       perl T38xsql.pl -q "select @@version" -o error.out
#*	NOTE: in order to execute a query, have to explicitly specify perl interpreter.
#*	In this case cannot use file associations, since spaces in a sql statement will
#*	be interpreted as parameters.
#*	
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
