#!perl 
#* t38lsmondriv - log shipping monitor driver.
#*
#*	$Author: A645276 $
#*	$Date: 2011/02/08 15:32:29 $
#*	$Revision: 1.1 $
#*	$Archive:   //cs01pvcs/pvcs/cm/Database/archives/Applications/LogShipping/t38lsmondriv.pv_  $
#*
#* SYNOPSIS
#*	t38lsmondriv -h -S monitorServerName -M hpMonitorName
#*	
#*	Where:
#*	
#*	-h			Writes help screen on standard output, then exits.
#*	-S server	Name of the monitoring server. Default is local server.
#*	-M monName	Name of the HP VPO monitor as defined in HP Templates.
#*
#*	This program is executed by HP VPO monitor. It scans registry
#*	for installed instances and calls t38lsmon.pl to for each instance.
#*
#***

use strict;

#-- constants

use constant DEFAULT_INST_NM	=> 'MSSQLServer';
use constant T38CFG				=> 't38dba.cfg';
use constant ERRORDELAY			=> 99999;

use T38lib::Common qw(notifyMe notifyWSub logme warnme errme 
				stripWhitespace stripPath
				whence unc2path T38DEFAULTINSTDIR
				);

use T38lib::t38cfgfile qw(:CFGFILE_SUBS :CFGFILE_VARS);
use T38lib::bbyado qw(:BBYADO_SUBS :BBYADO_VARS);

use vars qw(
		$gCurrentDir $gScriptName $gScriptPath
		$opt_h $opt_M $opt_S
		$gHostName $gMonSrvr $gHPMonName
		$gLogShipEnabledFlg @gDBList
		$gSrvrSrc $gNetSrc $gInstSrc
		$gSrvrDest $gNetDest $gInstDest
		$gNWarnings
		);

# Main

&main();

sub main {
	my $mainStatus	= 0;
	my $cmd			= '';
	my $cmdout		= '';
	my $instName	= '';
	my @instLst		= ();
SUB:
{
	unless (&housekeeping())			{ $mainStatus = 1; last SUB; }

	# debug code: &notifyWSub("$gScriptName arguments: <" . join(', ', @ARGV) . ">");
	unless(&getSQLInstLst(\@instLst))	{ $mainStatus = 1; last SUB; }

	foreach $instName (@instLst) {
		&checkSQLinst($instName)	if ($instName);
	}
		
	last SUB;
	
}	# SUB
# ExitPoint:
	$mainStatus = 1	if ($gNWarnings > 0);
	( $mainStatus== 0 ) ?
		logme("Finished with status $mainStatus", "done") :
		warnme("Finished with status $mainStatus", "done") ;
	exit($mainStatus);
}	# main


#######################  $Workfile:   t38lsmondriv.pl  $ Subroutines  #################################


# ----------------------------------------------------------------------
#	checkSQLinst	check sql server instance
# ----------------------------------------------------------------------
#	arguments:
#		instName	SQL Server instance name
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------

sub checkSQLinst ($) {
	my $instName	= shift;
	my $status		= 1;
	my $dbname		= '';
	my $cfgFile		= '';
	my $rstrDelay	= ERRORDELAY;	# number of minutes, since last restored transaction.
	my $adocmd		= 0;		# ADO Command object handle
	my @rs			= ();		# array with result set
	my $sql			= '';		# sql command buffer
SUB:
{
	&notifyWSub("Check log shipping for $instName SQL Server instance");

	# Read default configuration file.
	$gLogShipEnabledFlg	= 0;
	$gSrvrSrc	= '';			# SQL Server name
	$gNetSrc	= '';			# SQL Server machine name
	$gInstSrc	= '';			# SQL Server instance name
	$gNetDest	= $gMonSrvr;	# SQL Server machine name
	$gInstDest	= (uc($instName) eq uc(DEFAULT_INST_NM)) ?  '' : $instName;			# SQL Server instance name
	$gSrvrDest	= ($gInstDest)? "$gNetDest\\$gInstDest": $gNetDest;
	@gDBList	= ();

	$cfgFile = "\\\\$gNetDest\\t38app80\\";
	$cfgFile = (uc($instName) eq uc(DEFAULT_INST_NM)) ?  $cfgFile . T38CFG : $cfgFile . '\\' . $instName . '\\' . T38CFG;

	unless (&getConfigFileParms($cfgFile)) {
		&sendMonValue($gHPMonName, ERRORDELAY, $gSrvrDest);
		last SUB;
	}

	unless ($gLogShipEnabledFlg) {
		# Log shipping is disabled. Return good result.
		&notifyWSub("Log shipping is disabled. No delay in restore for $gSrvrDest.");
		&sendMonValue($gHPMonName, 0, $gSrvrDest);
		last SUB;
	}

	# For each database, check log shipping restore delay.

	$gSrvrSrc = uc($gSrvrSrc);

	unless ($adocmd = adoConnect($gSrvrDest, 'master')) { 
		&errme("adoConnect($gSrvrSrc) Failed");
		$status = 0; last SUB;
	}


	foreach $dbname (@gDBList) {
		$sql	= <<"		EOT";
			select isnull(datediff(minute, max(bs.backup_finish_date), getdate()), @{[ERRORDELAY]} ) as 'RestoreDelay'
			from msdb..restorehistory rh join msdb..backupset bs on rh.backup_set_id = bs.backup_set_id
			where 
			restore_type = 'L' and rh.destination_database_name = '$dbname' 
			and upper(bs.server_name) = '$gSrvrSrc' and bs.database_name = '$dbname'
		EOT

		if (&execSQL2Arr($adocmd, $sql, \@rs) && $#rs >= 0) {
			&sendMonValue($gHPMonName, $rs[0]{RestoreDelay}, "$gSrvrDest\\$dbname");
		} else {
			&sendMonValue($gHPMonName, ERRORDELAY, "$gSrvrDest\\$dbname");
			$status = 0;
		}
	}	# end foreach $dbname

	last SUB;
}
	if ($adocmd) { $adocmd->Close(); $adocmd = 0; }
	return ($status);
}	# checkSQLinst



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

	$gLogShipEnabledFlg = (defined($gConfigValues{LogShipEnabledFlg}) && $gConfigValues{LogShipEnabledFlg} eq 'Y');

	$status	= 1;
	last SUB;
}
	return($status);	
} # getConfigFileParms



# ----------------------------------------------------------------------
#	getSQLInstLst	Get list of SQL Server instances on a server
# ----------------------------------------------------------------------
#	arguments:
#		instLst	reference to list of SQL Server instances
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------

sub getSQLInstLst ($) {
use Win32::TieRegistry ( Delimiter=>"/", ArrayValues=>0);
	my $rInstLst	= shift;
	my @instLst		= ();
	my $machine		= ($gHostName eq $gMonSrvr) ? "": "//$gMonSrvr/";
	my $keyName		= '';
	my $instName	= '';
	my $dbmsVer		= '';
	my $hKey		= 0;
	my $status		= 1;
SUB:
{
	$keyName	= "${machine}LMachine/Software/Microsoft/Microsoft SQL Server/InstalledInstances";
	if (defined($Registry->{$keyName})) {
		@instLst = split('\0', $Registry->{$keyName});
	} else {
		&errme("Cannot find installed SQL Server instances in registry.");
		$status = 0;
		last SUB;
	}

	last SUB;
}
	@{$rInstLst} = @instLst;
	return ($status);
}	# getSQLInstLst


# ----------------------------------------------------------------------
# sendMonValue
# ----------------------------------------------------------------------
#	arguments:
#		monName	monitor name
#		delay	delay value in minutes
#		object	HP VPO object name
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	Perform the initial housekeeping chores.
# ----------------------------------------------------------------------

sub sendMonValue ($$$) {
	my ($monName, 
		$delay,
		$object)	= @_;
	my $cmd			= '';
	my $cmdout		= '';

	$monName	= ($monName) ? $monName : 'bby_T38LSDELAY_QA';
	$object		= ($object) ? $object : $gMonSrvr;
	# $cmd = "opcmon bby_T38LSDELAY_QA=0 -object $gHostName\\INST1 > $gScriptPath\\T38LOG\\$gScriptName.os.out";
	$cmd = "opcmon $monName=$delay -object $object";
	$cmdout = `cmd /C \"$cmd\" 2>\&1`;
	&notifyWSub("Results of $cmd:\n$cmdout");
}	# sendMonValue

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
	$opt_S	= 0;	# Server to process.

	getopts('hS:M:');

	#-- program specific initialization

	use Sys::Hostname;
	$gHostName	= hostname;
	$gNWarnings	= 0;
	$gHPMonName	= 'bby_T38LSDELAY_QA';
	$gMonSrvr	= $gHostName;

	#-- show help

	if ($opt_h) { &showHelp; exit; }

	# Open log and error files, if needed.

	unless (&T38lib::Common::setLogFileDir("$gScriptPath\\T38LOG")) {
		&errme("Cannot set scripts log directory.");
		return(0);
	}

	&T38lib::Common::archiveLogFile(7);
	&logme("Starting $gScriptName from $gScriptPath", "started");

	$gMonSrvr	= uc($opt_S)	if ($opt_S);
	$gHPMonName	= $opt_M		if ($opt_M);

	# Check Perl version.

	unless ( &T38lib::Common::chkPerlVer() ) {
		&notifyWSub("Wrong version of Perl!");
		&notifyWSub("This program run on Perl version 5.005 and higher.");
		&notifyWSub("Check the Perl version by running perl -v on command line.");
		return 0;
	}

	&notifyWSub("$gMonSrvr: Monitor SQL Log shipping from HP VPO.");

	return(1);
}	# housekeeping
	

###	showHelp -- show help information.
###

sub showHelp {
	print <<'EOT'
#* t38lsmondriv - log shipping monitor driver.
#*
#*	$Author: A645276 $
#*	$Date: 2011/02/08 15:32:29 $
#*	$Revision: 1.1 $
#*	$Archive:   //cs01pvcs/pvcs/cm/Database/archives/Applications/LogShipping/t38lsmondriv.pv_  $
#*
#* SYNOPSIS
#*	t38lsmondriv -h -S monitorServerName -M hpMonitorName
#*	
#*	Where:
#*	
#*	-h			Writes help screen on standard output, then exits.
#*	-S server	Name of the monitoring server. Default is local server.
#*	-M monName	Name of the HP VPO monitor as defined in HP Templates.
#*
#*	This program is executed by HP VPO monitor. It scans registry
#*	for installed instances and calls t38lsmon.pl to for each instance.
EOT
} #	showHelp
