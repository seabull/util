#!perl 
#
#* t38scrlocgrp - script accounts in local groups on specific server
#*
#*	$Archive:   //cs01pvcs/pvcs/cm/Database/archives/Applications/LogShipping/t38scrlocgrp.pv_  $
#*	$Author: A645276 $
#*	$Date: 2011/02/08 17:12:23 $
#*	$Revision: 1.1 $
#*
#* SYNOPSIS
#*	t38t38scrlocgrp -h -S servername -g grouplist
#*	
#*	Where:
#*	
#*	-h			Writes help screen on standard output, then exits.
#*	serverName	Name of the server, where to enumerate local groups.
#*	groupList	File with a list of group names. If -g option is not
#*				provided, all local groups are scripted.
#*
#*	The t38scrlocgrp creates the REVLOCGROUP.CMD file with system
#*	commands, required to re-create local groups.
#*
#***

#################################################################################################
#                       																		#
#                                    START of Main Program										#
#																								#
#################################################################################################

# Turn on strict
use strict;

#-- constants

use FindBin qw($Bin $Script $RealBin $RealScript);
use lib "$Bin";
use t38revact;

# Modules used
use Win32API::Net;
use Win32::NetAdmin;
use T38lib::Common qw(notifyMe notifyWSub logme warnme errme);

use vars qw(
		$gCurrentDir $gScriptName $gScriptPath
		$opt_g $opt_h $opt_S
		$gHostName $gSrvr $gGroupListFile
		$gNWarnings
		);

# Main

&main();

sub main {
	my @users 			= ();
	my @groups			= ();
	my $groupName		= '';
	my $userName		= '';
	my $userPrefix		= '';
	my $result			= 0;
	my $mainStatus		= 0;
	my $locGrpScript	= '';
SUB:
{
	unless (&housekeeping())	{ $mainStatus = 1; last SUB; }

	$locGrpScript = $gScriptPath . LOCGRPCMD . '.cmd';
	$userPrefix = ($gSrvr) ? uc($gSrvr) : uc($gHostName);

	# Populate list of groups to script.

	if ($gGroupListFile) {
		# Get list of groups from the file.
		unless (open(T38GROUPLIST,"<$gGroupListFile")) { 
			&warnme("** ERROR** Cannot open file $gGroupListFile for reading. $!");
			$mainStatus = 1;
			last SUB;
		}

		# Read one group per line from the list.
		while (<T38GROUPLIST>) {
			# Scipp comments and blank lines.
			next if /^\s*#/;
			next if /^\s*$/;
			chomp();
			push(@groups, $_);
		}
	} else {
		# Get all local groups.
		$result = Win32API::Net::LocalGroupEnum($gSrvr, \@groups);
		if (!$result) {
			&errme("Cannot get list of groups");
			$mainStatus = 1;
			last SUB;
		}
	}


	unless (open(T38LOCGRPSCRIPT,">$locGrpScript")) { 
		&errme("** ERROR** Cannot open file $locGrpScript for writing. $!");
		$mainStatus = 1;
		last SUB;
	}

	foreach $groupName (@groups) {
		&notifyMe("Group: $groupName");
		print T38LOCGRPSCRIPT "net localgroup \"$groupName\" /add\n";

		# $result = Win32API::Net::LocalGroupGetMembers($gSrvr, $groupName, \@users);
		$result = Win32::NetAdmin::LocalGroupGetMembersWithDomain($gSrvr, $groupName, \@users);
		unless ($result) {
			&warnme("Local group $groupName is not available on server <$gSrvr>.");
			$gNWarnings++;
			next;
		}
		foreach $userName (@users) {
			&notifyMe("\t$userName");
			$userName =~ s/$userPrefix\\//i;
			print T38LOCGRPSCRIPT "net localgroup \"$groupName\" \"$userName\" /add\n";
		}
	}
	last SUB;
	
}	# SUB
# ExitPoint:
	close(T38LOCGRPSCRIPT);
	close(T38GROUPLIST);
	$mainStatus = 1	if ($gNWarnings > 0);
	( $mainStatus== 0 ) ?
		logme("Finished with status $mainStatus", "done") :
		warnme("Finished with status $mainStatus", "done") ;
	exit($mainStatus);
}	# main


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
	$opt_S	= 0;	# Server to process.

	getopts('hg:S:');

	#-- program specific initialization

	use Sys::Hostname;
	$gHostName	= hostname;
	$gNWarnings	= 0;

	#-- show help

	if ($opt_h) { &showHelp; exit; }

	# Open log and error files, if needed.

	unless (&T38lib::Common::setLogFileDir("$gScriptPath\\T38LOG\\$gScriptName")) {
		&errme("Cannot set scripts log directory.");
		return(0);
	}

	&T38lib::Common::archiveLogFile(3);
	&logme("Starting $gScriptName from $gScriptPath.", "started");


	# Validate command line arguments.

	$gSrvr	= '';
	$gSrvr	= uc($opt_S)	if ($opt_S && $opt_S ne '.');
	$gGroupListFile	= '';
	$gGroupListFile	= $opt_g	if ($opt_g);

	# Check Perl version.

	unless ( &T38lib::Common::chkPerlVer() ) {
		&notifyWSub("Wrong version of Perl!");
		&notifyWSub("This program run on Perl version 5.005 and higher.");
		&notifyWSub("Check the Perl version by running perl -v on command line.");
		return 0;
	}

	if ($gSrvr) {
		&logme("$gScriptName processing $gSrvr from $gHostName.");
	} else {
		&logme("$gScriptName processing local host from $gHostName.");
	}
	return(1);
}	# housekeeping

sub showHelp {
	print <<'EOT'
#* t38scrlocgrp - script accounts in local groups on specific server
#*
#*	$Archive:   //cs01pvcs/pvcs/cm/Database/archives/Applications/LogShipping/t38scrlocgrp.pv_  $
#*	$Author: A645276 $
#*	$Date: 2011/02/08 17:12:23 $
#*	$Revision: 1.1 $
#*
#* SYNOPSIS
#*	t38t38scrlocgrp -h -S servername -g grouplist
#*	
#*	Where:
#*	
#*	-h			Writes help screen on standard output, then exits.
#*	serverName	Name of the server, where to enumerate local groups.
#*	groupList	File with a list of group names. If -g option is not
#*				provided, all local groups are scripted.
#*
#*	The t38scrlocgrp creates the REVLOCGROUP.CMD file with system
#*	commands, required to re-create local groups.
#*
EOT
} #	showHelp
