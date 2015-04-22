#!perl 
#* cpt38lib - Copy T38lib files to remote server.
#*
#*	$Author: A645276 $
#*	$Date: 2011/02/08 15:34:07 $
#*	$Revision: 1.1 $
#*	$Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/Utilities/cpt38lib.pv_  $
#*
#* SYNOPSIS
#*	cpt38lib -h -a nLogs -C -S server T38libPath
#*	
#*	Where:
#*	
#*	-h			Writes help screen on standard output, then exits.
#*	-a nLogs	Number of log file archived, default is 7
#*	-C			Cluster flag. If this option is enabled, files will be
#*				copied to all nodes in a cluster. Otherwise only to
#*				the node, where virtual server is currently runnning.
#*	-S server	Name of the server where library files should be copied.
#*	T38libPath	Path to t38lib directory files.
#*	
#*	Copy T38lib\*.pm files to remote server.
#*
#*	Example:
#*
#*	cpt38lib.pl -S hst6db .\T38lib
#*
#***

use strict;

#-- constants

use Win32;
use Win32::Process;
use T38lib::Common qw(notifyMe notifyWSub logme warnme errme logEvent whence getWinClusterName);
use File::Path;
use File::Basename;

use vars qw(
		$gScriptName $gScriptPath
		$opt_h $opt_S $opt_C $opt_a
		%gSysInfo
		$gNWarnings
		$gHostName $gSrvr $gT38LibDir
		$gClusterFlg
		);

$main::gDebug	= 0;	# Turn printing of debug information for whole program on/off.

# Main

&main();

sub main {
	my $mainStatus	= 0;
	my $machine		= '';
	my @srvrLst		= ();
	my $clusterName	= '';
	my @clusOut		= ();	# Results of the cluster command.
	my $i			= 0;
SUB:
{
	unless (&housekeeping())			{ $mainStatus = 1; last SUB; }

	
	if ($gClusterFlg) { $clusterName = &getWinClusterName($gSrvr); }
	
	if ($gClusterFlg && $clusterName) {
		# Get list of physical nodes for target machines.
		
		@clusOut = `cmd.exe /C CLUSTER $clusterName group $gSrvr /listowners`;


		# Output for preferred nodes is:
		#
		# Listing preferred owners for resource group 'lvt1db01':
		#
		# Preferred Owner Nodes
		# ---------------------
		# LST1DB01
		# LST1DB02

		&notifyMe ("\n" . join('', @clusOut));
		unless (
			$clusOut[1] =~ /^Listing preferred owners for resource group \'$gSrvr\':/i &&
			$clusOut[3] =~ /^Preferred Owner Nodes/i &&
			$clusOut[4] =~ /^\-+/i
		) {
			&errme("There is problem with parsing output of the cluster command to get list of preferred owners for virtual server $gSrvr.");
			$mainStatus = 1; last SUB;
		}
		for $i (5..$#clusOut) {
			$machine = $clusOut[$i];
			$machine = &T38lib::Common::stripWhitespace($machine);
			push (@srvrLst, $machine)	if ($machine =~/^\S+$/);
		}
	} else {
		push (@srvrLst, $gSrvr);
	}
	foreach $machine (@srvrLst) {
		&notifyMe("Do Machine: $machine");
		unless (&copyPerlModules($machine))	{ $mainStatus = 1; last SUB; }
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

#######################  $Workfile:   cpt38lib.pl  $ Subroutines  #################################

# ----------------------------------------------------------------------
#	copyPerlModules		copy perl modules to destination server
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
#	copy perl modules to destination server
# ----------------------------------------------------------------------

sub copyPerlModules ($) {
	my $machine	= shift;
	my $perlExe		= '';
	my $libPath		= '';
	my $oscmd		= '';
	my $osout		= '';
	my $status	= 1;
SUB:
{
	&notifyWSub("Started. Machine name is $machine.");

	%gSysInfo		= (
					SystemRoot				=> '',	# D:\Winnt
					ProgramFilesDir			=> '',	# D:\Program Files
					SystemDrive				=> '',	# D:
					EnvPath					=> '',	# Path enviroment variable for the scanned server
					OSVerLocal				=> '',	# 5.0, 4.0
					OSVersion				=> ''	# 5.0, 4.0
					);

	unless (&getSysInfoReg($machine))			{ $status = 0; last SUB; }
	unless ($perlExe = &getPerlExe($machine))	{ $status = 0; last SUB; }

	($libPath = $perlExe)	=~ s/\//\\/g;
	$libPath =~ s/\\bin\\perl.exe/\\/i;
	$libPath .= 'site\\lib\\T38lib';

	$oscmd = "mkdir \"$libPath\"";
	$osout = `cmd /E:on /C \"$oscmd\" 2>\&1`;
	&notifyMe("OS Command: $oscmd");
	&notifyMe("$osout");

	# Change the file attribute to read only
	#
	$oscmd = "attrib +r $gT38LibDir\\*.pm";
	$osout = `cmd /E:on /C \"$oscmd\" 2>\&1`;
	&notifyMe("OS Command: $oscmd");
	&notifyMe("$osout");

	# Copy the file to destination preserving the attributes
	#
	$oscmd = "xcopy /R/Y/K \"$gT38LibDir\\*.pm\" \"$libPath\"";
	$osout = `cmd /E:on /C \"$oscmd\" 2>\&1`;
	$osout =~/(\d+) File.* copied/;
	$status = ($1) ? 1:0;
	&notifyMe("OS Command: $oscmd");
	&notifyMe("$osout");


	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# copyPerlModules



# ----------------------------------------------------------------------
#	getPerlExe	Get perl.exe full file name
# ----------------------------------------------------------------------
#	arguments:
#		$machine	machine name
#	return:
#		Full Perl.exe file name.
# ----------------------------------------------------------------------

sub getPerlExe ($) {
	my $machine	= shift;
	my $perlExe	= "";
	my $dir;
SUB:
{
	if (!$machine || $gHostName eq $machine) {
		$perlExe = &whence("perl.exe");
	} else {
		# Check if file can be found on $PATH of the remote server.
	
		foreach $dir (split(';', $gSysInfo{EnvPath})) {
			$dir =~ s/[\\\/]\s*$//;					# Remove trailing directory separator.
			$dir =~ s/^([A-Za-z]):/\\\\$machine\\$1\$/;	# Replace drive name by administrative share
			if ( -e "$dir/perl.exe" ) { $perlExe = "$dir/perl.exe"; last; }
		}
	}
	last SUB;
}
	return ($perlExe);
}	# getPerlExe


# ----------------------------------------------------------------------
#	getSysInfoReg	Get system information from registry.
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	Populate global %gSysInfo structure.
# ----------------------------------------------------------------------

sub getSysInfoReg ($) {
use Win32::TieRegistry ( Delimiter=>"/", ArrayValues=>0);
	my $machine	= shift;
	my $status	= 1;
	my $keyName	= "";
SUB:
{
	$machine	= ($gHostName eq $machine) ? "": "//$machine/";

	# Various NT System information is stored in following registry entries:
	# SysterRoot: HKLM/Software/Microsoft/Windows NT/CurrentVersion/SystemRoot (D:\WinNT)
	# ProgramFilesDir: HKLM/Software/Microsoft/Windows/CurrentVersion/ProgramFilesDir (D:\Program Files)
	# OS Version: HKLM/Software/Microsoft/Windows NT/CurrentVersion/CurrentVersion (5.0, 4.0)
	# Path: HKLM/System/CurrentControlSet/Control/Session Manager/Environment/Path

	$keyName	= "${machine}LMachine/Software/Microsoft/Windows NT/CurrentVersion/SystemRoot";
	if (defined($Registry->{$keyName})) {
		$gSysInfo{SystemRoot} = $Registry->{$keyName};
	} else {
		&errme("Registry value $keyName is unaccessible.");
		$status = 0;
		last SUB;
	}

	$keyName	= "${machine}LMachine/Software/Microsoft/Windows/CurrentVersion/ProgramFilesDir";
	if (defined($Registry->{$keyName})) {
		$gSysInfo{ProgramFilesDir} = $Registry->{$keyName};
	} else {
		&errme("Registry value $keyName is unaccessible.");
		$status = 0;
		last SUB;
	}

	$keyName	= "${machine}LMachine/Software/Microsoft/Windows NT/CurrentVersion/CurrentVersion";
	if (defined($Registry->{$keyName})) {
		$gSysInfo{OSVersion} = $Registry->{$keyName};
	} else {
		&errme("Registry value $keyName is unaccessible.");
		$status = 0;
		last SUB;
	}

	$keyName	= "LMachine/Software/Microsoft/Windows NT/CurrentVersion/CurrentVersion";
	if (defined($Registry->{$keyName})) {
		$gSysInfo{OSVerLocal} = $Registry->{$keyName};
	} else {
		&errme("Registry value $keyName is unaccessible.");
		$status = 0;
		last SUB;
	}

	$gSysInfo{SystemDrive} = substr($gSysInfo{SystemRoot}, 0, 2);

	$keyName	= "${machine}LMachine/System/CurrentControlSet/Control/Session Manager/Environment/Path";
	if (defined($Registry->{$keyName})) {
		$gSysInfo{EnvPath} = $Registry->{$keyName};
	} else {
		&errme("Registry value $keyName is unaccessible.");
		$status = 0;
		last SUB;
	}

	my $envPath		= $gSysInfo{EnvPath};
	my $envVar		= '';
	my $envVarVal	= '';
	while ($gSysInfo{EnvPath} =~ /%([^%]+)%/gc) {
		$envVar		= $1;
		$envVarVal	= '';
		$envVar =~ s/%//g;
		if (uc($envVar) eq "SYSTEMDRIVE") {
			$envVarVal = $gSysInfo{SystemDrive};
		} elsif (uc($envVar) eq "SYSTEMROOT") {
			$envVarVal = $gSysInfo{SystemRoot};
		} else {
			$keyName	= "${machine}LMachine/System/CurrentControlSet/Control/Session Manager/Environment/$envVar";
			$envVarVal = $Registry->{$keyName}	if (defined($Registry->{$keyName}));
		}

		$envPath =~ s/%$envVar%/$envVarVal/g	if ($envVarVal);
	}

	$gSysInfo{EnvPath} = $envPath;

	# Debug code.

	my $debug = 0;
	if ($debug || $main::gDebug) {
		&notifyWSub("gHostname: $gHostName, gSrvr: $gSrvr");
		&notifyWSub("gSysInfo:");
		&debugPrintHash(\%gSysInfo);
	}
	# End Debug code.


	last SUB;
}
	return ($status);
}	# getSysInfoReg



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
	use Cwd;
	use Getopt::Std;

	my $numArchive		= 7;
	my $scriptSuffix	= ".pl";

	$gScriptName	= "";			# Base name of the current script.
	$gScriptPath	= ".\\";		# Directory path to current script.
	$gClusterFlg	= 0;			# Do not copy files to all nodes in a cluster.

	($gScriptPath, $gScriptName, $scriptSuffix) = &T38lib::Common::parseProgramName();

	#-- initialize standard options

	$opt_h	= 0;	# help option.
	$opt_S	= 0;	# Server to process.
	$opt_C	= 0;	# Server to process.
	$opt_a	= 0;

	getopts('a:hCS:');

	#-- program specific initialization

	$gHostName	= `hostname`; chomp($gHostName); $gHostName = uc($gHostName);
	$gSrvr		= $gHostName;
	$gT38LibDir	= '.';
	%gSysInfo	= ();
	$gNWarnings	= 0;

	#-- show help

	if ($opt_h || $#ARGV == -1 ) { &showHelp; exit; }

	$gT38LibDir	= $ARGV[0];
	$gT38LibDir	=~ s/\//\\/g;
	$gT38LibDir	=~ s/\\$//;

	# Open log file.

	unless (&T38lib::Common::setLogFileDir("${gScriptPath}T38LOG\\$gScriptName")) {
		&errme("Cannot set program log directory.");
		return 0;
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

	$gSrvr			= uc($opt_S)	if ($opt_S);
	$gClusterFlg	= 1	if ($opt_C);

	# Check Perl version.

	unless ( &T38lib::Common::chkPerlVer() ) {
		&notifyWSub("Wrong version of Perl!");
		&notifyWSub("This program run on Perl version 5.005 and higher.");
		&notifyWSub("Check the Perl version by running perl -v on command line.");
		return 0;
	}

	# Check Version of the filever program.
	# die "check filever on hst1db with long file names";

	&notifyWSub("$gHostName copy $gT38LibDir files to $gSrvr. ");

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

###


###	showHelp -- show help information.
###

sub showHelp {
	print <<'EOT'
#* cpt38lib - Copy T38lib files to remote server.
#*
#*	$Author: A645276 $
#*	$Date: 2011/02/08 15:34:07 $
#*	$Revision: 1.1 $
#*	$Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/Utilities/cpt38lib.pv_  $
#*
#* SYNOPSIS
#*	cpt38lib -h -a nLogs -C -S server T38libPath
#*	
#*	Where:
#*	
#*	-h			Writes help screen on standard output, then exits.
#*	-a nLogs	Number of log file archived, default is 7
#*	-C			Cluster flag. If this option is enabled, files will be
#*				copied to all nodes in a cluster. Otherwise only to
#*				the node, where virtual server is currently runnning.
#*	-S server	Name of the server where library files should be copied.
#*	T38libPath	Path to t38lib directory files.
#*	
#*	Copy T38lib\*.pm files to remote server.
#*
#*	Example:
#*
#*	cpt38lib.pl -S hst6db .\T38lib
#*
EOT
} #	showHelp
