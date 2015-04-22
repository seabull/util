#!perl 
#* cpt38lib - Copy T38lib files to remote server.
#*
#*	$Author: A645276 $
#*	$Date: 2011/02/08 17:25:38 $
#*	$Revision: 1.1 $
#*	$Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/Utilities/cpt38lib.pv_  $
#*
#* SYNOPSIS
#*	cpt38lib -h -S server T38libPath
#*	
#*	Where:
#*	
#*	-h			Writes help screen on standard output, then exits.
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
use T38lib::Common qw(notifyMe notifyWSub logme warnme errme logEvent whence);
use File::Path;
use File::Basename;

use vars qw(
		$gScriptName $gScriptPath
		$opt_h $opt_S
		%gSysInfo
		$gNWarnings
		$gHostName $gSrvr $gT38LibDir
		);

$main::gDebug	= 0;	# Turn printing of debug information for whole program on/off.

# Main

&main();

sub main {
	my $mainStatus	= 0;
	my $perlExe		= '';
	my $libPath		= '';
	my $oscmd		= '';
	my $osout		= '';
SUB:
{
	unless (&housekeeping())	{ $mainStatus = 1; last SUB; }
	unless (&getSysInfoReg())	{ $mainStatus = 1; last SUB; }
	unless ($perlExe = &getPerlExe($gSrvr))
								{ $mainStatus = 1; last SUB; }
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
	&notifyMe("OS Command: $oscmd");
	&notifyMe("$osout");

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
			$dir =~ s/^([A-Z]):/\\\\$machine\\$1\$/;	# Replace drive name by administrative share
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

sub getSysInfoReg {
use Win32::TieRegistry ( Delimiter=>"/", ArrayValues=>0);
	my $machine	= ($gHostName eq $gSrvr) ? "": "//$gSrvr/";
	my $status	= 1;
	my $keyName	= "";
SUB:
{
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

	my $scriptSuffix	= ".pl";

	$gScriptName	= "";			# Base name of the current script.
	$gScriptPath	= ".\\";		# Directory path to current script.

	($gScriptPath, $gScriptName, $scriptSuffix) = &T38lib::Common::parseProgramName();

	#-- initialize standard options

	$opt_h	= 0;	# help option.
	$opt_S	= 0;	# Server to process.

	getopts('hS:');

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

	&T38lib::Common::archiveLogFile(7);
	&logme("Starting $gScriptName from $gScriptPath", "started");

	$gSrvr		= uc($opt_S)	if ($opt_S);

	%gSysInfo		= (
					SystemRoot				=> '',	# D:\Winnt
					ProgramFilesDir			=> '',	# D:\Program Files
					SystemDrive				=> '',	# D:
					EnvPath					=> '',	# Path enviroment variable for the scanned server
					OSVerLocal				=> '',	# 5.0, 4.0
					OSVersion				=> ''	# 5.0, 4.0
					);

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
#*	$Date: 2011/02/08 17:25:38 $
#*	$Revision: 1.1 $
#*	$Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/Utilities/cpt38lib.pv_  $
#*
#* SYNOPSIS
#*	cpt38lib -h -S server T38libPath
#*					-l{C|I|S} -c cfgFile
#*	
#*	Where:
#*	
#*	-h			Writes help screen on standard output, then exits.
#*	-S server	Name of the server where library files should be copied.
#*	T38libPath	Path to t38lib directory files.
#*	
#*	This server collects vital statistics on SQL Server machine and stores it
#*	in repostiroy database.
EOT
} #	showHelp
