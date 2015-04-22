#!perl 
#* T38logerror - # Called by Store proc sp_T38LOGERROR
#*
#*	$Author: A645276 $
#*	$Date: 2011/02/08 17:12:21 $
#*	$Revision: 1.1 $
#*	$Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/DBINST/SQL90/InstallLinks/T38APP80/T38logerror.pv_  $
#*
#* SYNOPSIS
#*	T38logerror -h -a 10 -l logfileDirSuffix -S ServerName cfgfile1.cfg cfgfile2.cfg......
#*	
#*	Where:
#*	
#*	-h			Writes help screen on standard output, then exits.
#*	-a 10		Number of log file archived, default is 7
#*  -C msg		itoseverity__ErrorMsg
#*	-l logsuffx	Optional Log File Directory suffix. This is used to
#*				ensure multiple copies of the program can run at the 
#*				same time without overwriting the log file.
#*	-S 			Server Name  Name of the server
#*
#*
#*	Example:
#*		 Provide some examples, how to run your program 
#*
#*		 Call T38logerror.pl from sp_T38LOGERROR sub
#*
#*		 T38logerror.pl -C "Minor__This is a test Message"
#*		 
#*
#*
#***

use strict;

use T38lib::Common qw(notifyMe notifyWSub logme warnme errme);
use T38lib::t38cfgfile qw(:CFGFILE_SUBS :CFGFILE_VARS);
use Getopt::Std;

# Global Variables
my ( $gCurrentDir, $gScriptName, $gScriptPath, $gNWarnings) = "";
my ($gHostName, $gNetSrvr, $gInstName);
my ($gT38ERROR) = $T38lib::Common::T38ERROR;
my $gcmdlineArg = "";
my ($gitoseverity, $gerrmsg) = ("","");

# Main
&main();


############################  BBY Subroutines  ####################################

sub main {
	my $mainStatus	= 0;
	SUB:
	{
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


#######################  $Workfile:   T38logerror.pl  $ Subroutines  #################################

# ----------------------------------------------------------------------
#	doSomething		short description for the do something
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------

sub doSomething () {

	my $progName= 'opcmsg'; 
	my $osUtil = 'where';

	my $status	= 1;
	my ($cmd, $rtn, $item);



	SUB:
	{

		#foreach $item ( "osUtility", "progName") {
		#	if ( $gConfigValues{$item} eq "") {
		#		&errme("CFG file missing $item");
		#		$status = 0;
		#		last SUB;
		#	}
		#}

		&notifyWSub("doSomething started");

		$cmd = $osUtil . ' ' . $progName;

		$rtn = "";
		$rtn = `$cmd`;
		&notifyWSub("$rtn");

		# if progname is not found in the PATH variable
		# then exit out from this sub with success status
		#
		if ($rtn eq "") {
			&errme("$cmd failed");
			last SUB;
		}
		else {
			&notifyWSub("$cmd Successeded");
		}
	
		$cmd = $progName . ' ' . $gcmdlineArg;

		$rtn = "";
		$rtn = system ($cmd);
		
		if ($rtn != 0 ) {
			&errme("$cmd failed");
			$status = 0;
			last SUB;
		}
		else {
			&notifyWSub("$cmd Successeded");
		}

		last SUB;
	}	# SUB
	# ExitPoint:

	&notifyWSub("doSomething finised with $status status.");

	return($status);

}	# doSomething

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

	getopts('ha:l:S:C:');

	$gHostName	= uc(Win32::NodeName());
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
			$logStr = $logStr . " -l $logDirSuffix";
		}

		unless (&T38lib::Common::setLogFileDir("${gScriptPath}T38LOG\\$logFileName")) {
			&errme("Cannot set program log directory.");
			$status = 0;
			last SUB;
		}

		# Change number archived logs 
		#
		if($Getopt::Std::opt_a) {
			if ( $Getopt::Std::opt_a =~ /\d/) {
				if ( ($Getopt::Std::opt_a < 101) and ($Getopt::Std::opt_a > 0) ) {
					$numArchive = $Getopt::Std::opt_a;
					$logStr = $logStr . " -a $numArchive";
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

		if($Getopt::Std::opt_C) {
			($gitoseverity, $gerrmsg) =	split("__", $Getopt::Std::opt_C);
			$gcmdlineArg = "application=T38ALERT msg_grp=BBY_T38 object=T38LOGERROR severity=\"";
			$gcmdlineArg = $gcmdlineArg . $gitoseverity . "\" msg_text=\"" . $gerrmsg . "\"";
			$logStr = $logStr . " -C $gcmdlineArg";
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

		&notifyWSub("$gHostName:  Running T38logerror script .");
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
# Show Help here
#***
#* T38logerror - # Called by Store proc sp_T38LOGERROR
#*
#*	$Author: A645276 $
#*	$Date: 2011/02/08 17:12:21 $
#*	$Revision: 1.1 $
#*	$Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/DBINST/SQL90/InstallLinks/T38APP80/T38logerror.pv_  $
#*
#* SYNOPSIS
#*	T38logerror -h -a 10 -l logfileDirSuffix -S ServerName cfgfile1.cfg cfgfile2.cfg......
#*	
#*	Where:
#*	
#*	-h			Writes help screen on standard output, then exits.
#*	-a 10		Number of log file archived, default is 7
#*  -C msg		itoseverity__ErrorMsg
#*	-l logsuffx	Optional Log File Directory suffix. This is used to
#*				ensure multiple copies of the program can run at the 
#*				same time without overwriting the log file.
#*	-S 			Server Name  Name of the server
#*
#*
#*	Example:
#*		 Provide some examples, how to run your program 
#*
#*		 Call T38logerror.pl from sp_T38LOGERROR sub
#*
#*		 T38logerror.pl -C "Minor__This is a test Message"
#*		 
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
