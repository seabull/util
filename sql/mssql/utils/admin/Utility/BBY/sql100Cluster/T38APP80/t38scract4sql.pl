#!perl 
#* t38scract4sql - script accounts  information for sql server.
#*
#*	$Author: A645276 $
#*	$Date: 2011/02/08 17:12:23 $
#*	$Revision: 1.1 $
#*	$Archive:   //cs01pvcs/pvcs/cm/Database/archives/Applications/LogShipping/t38scract4sql.pv_  $
#*
#* SYNOPSIS
#*	t38scract4sql -h -S source_server
#*	
#*	Where:
#*	
#*	-h			Writes help screen on standard output, then exits.
#*	-S server	Name of the Source SQL server. Default is local 
#*				server with default instance.
#*	
#*	This program scripts accounts information for sql server. It creates
#*	following scripts:
#*	REVSQLLOGINS_SQL.SQL	SQL Script to add SQL Standard login accounts.
#*	REVSQLLOGINS_NT.SQL		SQL Script to add NT login accounts.
#*	REVLOCGROUP.CMD			OS command batch script to create NT local groups,
#*							used by SQL Server.
#*
#*	Example:
#*		t38scract4sql -S hst5db\inst1
#*
#*
#***

use strict;

use FindBin qw($Bin $Script $RealBin $RealScript);
use lib "$Bin";
# use lib "$Bin/../lib";
# print "Bin: $Bin, Script: $Script, RealBin: $RealBin, RealScript: $RealScript\n";

#-- constants

use t38revact;

# Modules used

use Carp qw(croak carp);
use T38lib::Common qw(notifyMe notifyWSub logme warnme errme);
use T38lib::bbyado qw(adoConnect 
				execSQL execSQL2File execSQLBat execSQLCmd
				adoProperties adoProperties4Conn adoProperties4Rs
				isADOok showADOErrors
				);

use vars qw(
		$gCurrentDir $gScriptName $gScriptPath
		$opt_h $opt_S
		$gHostName $gSrvrSrc $gNetSrvr $gInstName
		);

$main::gDebug	= 0;	# Turn printing of debug information for whole program on/off.

# Main

&main();

sub main {
	my $mainStatus	= 0;
SUB:
{
	unless (&housekeeping())	{ $mainStatus = 1; last SUB; }

	unless (&doAccntsFromSQL())	{ $mainStatus = 1; }
	unless (&doNTGroups())		{ $mainStatus = 1; }

	last SUB;
}	# SUB
# ExitPoint:
	( $mainStatus== 0 ) ?
		logme("Finished with status $mainStatus", "done") :
		warnme("Finished with status $mainStatus", "done") ;
	exit($mainStatus);
}	# main


#######################  $Workfile:   t38scract4sql.pl  $ Subroutines  #################################

# ----------------------------------------------------------------------
#	doAccntsFromSQL	process accounts from SQL Server 
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
#	Create scripts with standard SQL server and NT accounts
# ----------------------------------------------------------------------

sub doAccntsFromSQL () {
	my $sql		= '';		# sql command buffer
	my $status	= 0;
	my $osqlBin	= "osql -b -n -w 2048 -E -S $gSrvrSrc";
	my $osCmd	= '';
SUB:
{
	$sql = "exec sp_T38help_revlogin \'sql\'";
	$osCmd = $osqlBin . " -Q \"$sql\" -o $gScriptPath" . SQLACCTSQL . '.sql';
	unless(system($osCmd) == 0) {
		&errme("Cannot get list of SQL Accounts. Review output file " . SQLACCTSQL . "\.sql");
		&notifyMe("Command line is:\n\t$osCmd");
		$status = 0; last SUB;
	}

	$sql = "exec sp_T38help_revlogin \'nt\'";
	$osCmd = $osqlBin . " -Q \"$sql\" -o $gScriptPath" . NTACCTSQL . '.sql';
	unless(system($osCmd) == 0) {
		&errme("Cannot get list of NT Accounts on SQL Server. Review output file " . NTACCTSQL . '.sql');
		&notifyMe("Command line is:\n\t$osCmd");
		$status = 0; last SUB;
	}

	$status	= 1;
	last SUB;
}	# SUB
# ExitPoint:
	return($status);
}	# doAccntsFromSQL


# ----------------------------------------------------------------------
#	doNTGroups	script NT groups, used by SQL Server 
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
#	Create scripts with standard SQL server and NT accounts
# ----------------------------------------------------------------------

sub doNTGroups () {
	my $sql		= '';					# sql command buffer
	my $cmd		= '';
	my $rematch	= uc($gNetSrvr) . "\\";	# local group names are starting with server name.
	my $fname	= '';
	my $status	= 0;
SUB:
{
# 3. Query sql server for list of local groups.
# 4. Run t38scrlocgrp.pl -? usrgrp.txt to script local groups.

	$sql = "select name from syslogins where isntgroup = 1 and upper(name) like \'" . $rematch . "%\'";
	$fname = $gScriptPath . LOCGRPCMD . '.lst';
	unless(&execSQL2File($gSrvrSrc, 'master', $sql, $fname, '', $rematch, '')) { $status = 0; last SUB; }

	$cmd = "perl ${gScriptPath}t38scrlocgrp.pl -S $gNetSrvr -g $fname";
	unless (system($cmd) == 0) {
		&errme("Problem with $cmd");
		$status = 0; last SUB;
	}

	$status	= 1;
	last SUB;
}	# SUB
# ExitPoint:
	return($status);
}	# doNTGroups


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
	$opt_S	= 0;	# Source database server name.

	getopts('hS:');

	#-- program specific initialization

	use Sys::Hostname;
	$gHostName	= hostname;
	$gSrvrSrc	= $gHostName;

	#-- show help

	if ($opt_h) { &showHelp; exit; }

	# Open log and error files, if needed.

	unless (&T38lib::Common::setLogFileDir("$gScriptPath\\T38LOG\\$gScriptName")) {
		&errme("Cannot set scripts log directory.");
		return(0);
	}

	&T38lib::Common::archiveLogFile(7);
	&logme("Starting $gScriptName from $gScriptPath", "started");

	# Validate command line arguments.

	$gSrvrSrc	= uc($opt_S)	if ($opt_S);
	$gSrvrSrc	=~ s/^\./$gHostName/;

	$gNetSrvr	= $gHostName;	# SQL Server machine name
	$gInstName	= '';			# SQL Server instance name
	($gNetSrvr, $gInstName)	=	split("\\\\", $gSrvrSrc); 
	$gInstName =~ s/^\s+//g; $gInstName =~ s/\s+$//g;

	# Check Perl version.

	unless ( &T38lib::Common::chkPerlVer() ) {
		&notifyWSub("Wrong version of Perl!");
		&notifyWSub("This program run on Perl version 5.005 and higher.");
		&notifyWSub("Check the Perl version by running perl -v on command line.");
		return 0;
	}

	&notifyWSub("$gHostName: Script accounts for $gSrvrSrc.");

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
#* t38scract4sql - script accounts  information for sql server.
#*
#*	$Author: A645276 $
#*	$Date: 2011/02/08 17:12:23 $
#*	$Revision: 1.1 $
#*	$Archive:   //cs01pvcs/pvcs/cm/Database/archives/Applications/LogShipping/t38scract4sql.pv_  $
#*
#* SYNOPSIS
#*	t38scract4sql -h -S source_server
#*	
#*	Where:
#*	
#*	-h			Writes help screen on standard output, then exits.
#*	-S server	Name of the Source SQL server. Default is local 
#*				server with default instance.
#*	
#*	This program scripts accounts information for sql server. It creates
#*	following scripts:
#*	REVSQLLOGINS_SQL.SQL	SQL Script to add SQL Standard login accounts.
#*	REVSQLLOGINS_NT.SQL		SQL Script to add NT login accounts.
#*	REVLOCGROUP.CMD			OS command batch script to create NT local groups,
#*							used by SQL Server.
#*
#*	Example:
#*		t38scract4sql -S hst5db\inst1
EOT
} #	showHelp
