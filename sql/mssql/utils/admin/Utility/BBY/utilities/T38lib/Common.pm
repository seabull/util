#!perl

#------------------------------------------------------------------------------
# PVCS info
#
# $Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/Utilities/T38lib/Common.pv_  $
# $Author: A645276 $
# $Date: 2011/02/08 17:25:25 $ 
# $Revision: 1.1 $
#------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# $Workfile:   Common.pm  $
#
# $Log: Common.pm,v $
# Revision 1.1  2011/02/08 17:25:25  A645276
# init check in
#
# 
#    Rev 1.59   Dec 29 2010 10:31:44   a191197
# Added:
# isX64Process() -> checks if we are running a 64bit version of perl.
# Changed:
# The way registry is accessed on 64bit machines. We will not be using reg.exe on 64-bit machines and instead will use Win32::TieRegistry to read the registry.
# 
#    Rev 1.58   Mar 03 2010 13:18:46   tsmmxr
# Added adActName2samid, adGrpName2samid and adUsrName2samid subs.
# 
#    Rev 1.57   Mar 02 2010 23:14:34   a413061
# Changes to setIsqlBin,runsqlchk4err and getDevice modules.
# 1)setIsqlBin module -Added logic to process “SQLCMD” as input. Global variable $gisqlBin will hold value 2 if SQLCMD is to be used
# 2) runsqlchk4err = Use sqlcmd 3) getDBNames = removed the ‘use master’ line.
#    Rev 1.56   Feb 05 2010 15:14:46   tsmmxr
# Added cluster name as optional parameter to the getWinClusterRes subroutine. If virtual instance has no network resource we cannot get list of resources only based on virtual group name. Have to have cluster name in this case. Old behavior is preserved by making cluster name optional parameter.
# 
#    Rev 1.55   Aug 11 2009 14:52:20   tsmmxr
# Updated getSQLInst4VirtualSrvr to work with SQL 2008
# 
#    Rev 1.54   Sep 22 2008 10:37:04   tsmmxr
# Changes to runSQLChk4Err sub.
# 
# 1) When rotating $outFN file name, have to check in correct path. 
# 2) Added the $errFN file. When osql command fails due to OS error, the $outFN file may not be created. Redirect output of the osql $errFN as well.
# 
#    Rev 1.53   May 04 2007 13:06:48   tsmmxr
# Added filterList subroutine. It performs similar function to filetDb, execpt it does not assume list of database names.
# 
#    Rev 1.52   May 01 2007 16:09:52   tsmmxr
# Prototype for runSQLChk4Err was missing last argument. Added it to avoid warnings.
# 
#    Rev 1.51   Apr 30 2007 16:58:28   tsmmxr
# Added "force print headers" option to the runSQLChk4Err sub.
# 
#    Rev 1.50   Dec 14 2006 10:35:18   tsmask
# Added new code to run for 64 bit OS
# 
#    Rev 1.49   Oct 17 2006 11:42:14   tsmask
# Fix runsqlchk4err sub for temp file path
# 
#    Rev 1.48   Oct 11 2006 11:54:32   tsmask
# Added filterDB sub and fix runSQLChk4Err sub.
# 
#    Rev 1.47   Sep 25 2006 17:11:52   tsmmxr
# Added runOSCmd subroutine.
# 
#    Rev 1.46   Jun 26 2006 16:42:56   tsmmxr
# Fixed bugs in regReadValExe: The reg.exe command line was missing separator. Pattern was not matching correct result. Mis-spelled stripWhitespace subroutine name.
# 
#    Rev 1.45   Jun 26 2006 15:51:22   tsmmxr
# Added regReadValExe to read value from windows registry, using reg.exe.
# Modified getSQLInstLst subroutine to use regReadValExe if running on x64 processor.
# 
#    Rev 1.44   Jun 23 2006 14:56:26   tsmmxr
# Fixed typo for stopServiceWithDepend in Export_OK section.
# Modified stopServiceWithDepend and findDependentService to accept optional machine name parameter.
# 
#    Rev 1.43   Jun 20 2006 18:14:44   tsmmxr
# Added subs to stop/start resources in a cluster.
# 
#    Rev 1.42   Mar 08 2006 13:16:26   tsmmxr
# Added getWinClusterNodes subroutine to get list of nodes on a windows cluster.
# 
#    Rev 1.41   Jan 03 2006 17:33:40   tsmmxr
# Updated getSQLInst4VirtualSrvr subroutine to work with SQL 2005.
# 
#    Rev 1.40   Nov 11 2005 15:47:26   tsmask
# updated pingserver function with new checks
# 
#    Rev 1.39   Aug 24 2005 14:51:36   tsmask
# Fix an error in deleting tmp files with process ID in runSQLChk4Err sub
# 
#    Rev 1.38   May 20 2005 09:17:44   tsmask
# Added a new function to display warning 
# 
#    Rev 1.37   May 12 2005 14:06:58   tsmask
# Bug fix in getsqlcsdver
# 
#    Rev 1.36   May 10 2005 11:43:40   tsmask
# Fix a bug in getsqlver using @@version using SP4 install
# 
#    Rev 1.35   Apr 22 2005 09:46:44   tsmmxr
# Added getSQLInst4VirtualSrvr sub.
# 
#    Rev 1.34   Feb 18 2005 10:26:20   tsmmxr
# Added subroutine getWinClusterName to get cluster name for the virtual server name.
# 
#    Rev 1.33   Feb 18 2005 09:50:12   tsmask
# Added a sub to get port number of instances
# 
#    Rev 1.32   Dec 01 2004 09:41:14   tsmask
# Change StartService and StopService sub to add an additional optional parameter called Server Name
# 
#    Rev 1.31   Jul 27 2004 15:09:36   tsmask
# A bug is fixed in sub setlogfiledir and runsqlchk4err has problem with directory name that have spaces.  This problem is also fix.
# 
#    Rev 1.30   Jan 09 2004 18:33:54   TSMMXR
# If cmd shell is defined to AutoRun programs, defined in registry, getEnvPathVar was getting wrong path. The AutoRun program echos it's own strings as part of the path from the registry.
# 
# Fixed getEnvPathVar to ignore programs, stAutoRun
# 
#    Rev 1.29   Sep 26 2003 09:07:32   TSMASK
# Fix bugs in getdbnames and other function which create a temp file.
# 
#    Rev 1.28   Aug 28 2003 13:06:28   TSMASK
# added login so the tmp file that common.pm create is created in the log file directory.
# 
#    Rev 1.27   Jun 26 2003 11:12:18   TSMASK
# Added a new function called pingServer
# 
#    Rev 1.26   22 Jan 2003 14:33:16   TSMASK
# Fix bugs in function chksql4err
# 
#    Rev 1.25   22 Jan 2003 10:36:16   TSMASK
# Add new function for 6.5 compatibility.  Fix bug with runSQLChk4Err sub.
# 
#    Rev 1.24   13 Jan 2003 15:50:54   TSMMXR
# Added getSQLInstLst and getSqlVerReg subroutines.
# 
# Existing SQL version routines are trying to use SQL Server function to get this information.  The getSqlVerReg is using only machine registry to determine SQL Server version number.
# 
#    Rev 1.23   09 Jan 2003 16:08:20   TSMASK
# Fix some very crutial bugs in sub runSQLChk4Err
# 
#    Rev 1.22   21 Dec 2002 08:24:24   TSMASK
# Added return status for function archiveFile
# 
#    Rev 1.21   18 Dec 2002 13:47:52   TSMASK
# Added another function to archive any given file.
# 
#    Rev 1.20   23 Oct 2002 14:50:44   TSMASK
# Added two new sub called runSQLChk4Err, sendMsg2Monitor
# 
#    Rev 1.19   26 Sep 2002 17:16:16   TSMASK
# Strange bug in findDependentServices, change a loop and now it works.
# 
#    Rev 1.18   26 Sep 2002 12:20:04   TSMASK
# Add some debug code in findDependentService, start and stop services.
# 
#    Rev 1.17   19 Sep 2002 16:36:16   TSMASK
# Fix getLogFileName sub
# 
#    Rev 1.16   22 Aug 2002 17:30:10   TSMMXR
# 1. Added setLogFileDir subroutine. It will allow calling program  to change default location for log files. getLogFileName is changed to first check if default location is changed.
# 
# 2. Updated print statement in notifyMe. It was printing message as part of the format string. Made message text an argument to the function. This is done to deal with problems, when message text includes formating characters such as %s.
# 
#    Rev 1.15   12 Aug 2002 17:35:16   TSMMXR
# Added unc2path subroutine.
# Added T38DEFAULTINSTDIR constant.
# 
#    Rev 1.14   01 Aug 2002 10:08:08   TSMMXR
# Log file was created in the current working directory. If this directory is not the same as perl scripts location, it will cause a problem. Log files should always be created in same directory where perl script is located. 
# 
# Changed getLogFileName to return name of the file, with the path information.
# 
#    Rev 1.13   17 Jul 2002 11:56:30   tsmmxr
# added optional Machine name parameter to getServiceStatus, getSqlCSDVer and getSqlCurVer functions.
# 
#    Rev 1.12   06 Mar 2002 16:05:04   TSMASK
# Fix spelling mistake of getServiceStatus in EXPORT_OK array.
# 
#    Rev 1.11   06 Mar 2002 15:42:40   TSMASK
# Added new functions. Fix GetSQLVersion and getSQLCSDVersion functions.
# 
#    Rev 1.10   08 Feb 2002 11:18:38   TSMASK
# Make change to startService, stopService, stopServiceWithDepend and  findDependetService so it can work properly with instance name.
# 
#    Rev 1.9   Dec 06 2001 09:53:38   TSMASK
# Ignore the case while matching the service names.
# 
#    Rev 1.8   Nov 21 2001 18:54:02   TSMMXR
# Added parseProgramName and archiveLogFile.
# 
#    Rev 1.7   Nov 19 2001 17:33:20   TSMMXR
# Added following functions:
# 
# sub notifyWSub ($;$);
# sub logme ($;$);
# sub warnme ($;$);
# sub errme ($;$);
# 
#    Rev 1.5   Aug 08 2001 09:44:02   TSMMXR
# Fixed problem with whence. If directory from $PATH has trailing separator, remove it.
# 
#    Rev 1.4   Aug 07 2001 13:55:26   TSMMXR
# Added logEvent and whence subs.
# 
#    Rev 1.3   Aug 06 2001 11:51:50   TSMASK
# Added T38ERROR error string
# 
#    Rev 1.2   Jul 17 2001 09:23:58   TSMMXR
# Added PVCS keywords: $Workfile, $Log.
# Changed $VERSION to PVCS keyworkd.
#
# Script Name:  Common.pm 
#
# History:
#   Initials  Date             Description of change
#
#-------------------------------------------------------------------------------

# Setting the default package to 
package T38lib::Common;

use Cwd;
use File::Basename;
use Win32;
use Win32::Service;
use Win32::Registry;
use Win32::TieRegistry ( Delimiter=>"/", ArrayValues=>0);
use Win32API::File qw( :ALL );
use Carp qw(croak carp);

# Use the Perl library's Exporter module.
require Exporter;

# Turn on strict
use strict;

# Declaration of package variables.
use vars qw($VERSION $gLogFileDir  $gisqlBin @ISA @EXPORT @EXPORT_OK $T38ERROR %EXPORT_TAGS);

# Subclass Exporter and AutoLoader
@ISA = qw(Exporter AutoLoader);

# Add the names of functions and other package variables that we want to
# export by default.
# Item to export into caller namespace by default.
#@EXPORT = qw(notifyMe errorTrap);

# Add the names of functions and other package variables that we want to 
# exported on request.
@EXPORT_OK =	qw( adActName2samid adGrpName2samid adUsrName2samid
					notifyMe notifyWSub logEvent logme warnme errme errorTrap warningTrap
					escapeREChar chkx64 clusGrpSrvcsStop clusResStart clusResStop
					findDependentService filterDB filterList getDBNames getDrives getEnvPathVar 
					parseProgramName archiveFile archiveLogFile getServiceStatus
					getLogFileName getSqlCSDVer getSqlCurVer getSQLInstLst getSqlVerReg
					getSQLInst4VirtualSrvr getWinClusterName getWinClusterNodes getWinClusterRes
					globbing chkPerlVer isX64Process readINI setIsqlBin pingServer getSqlPort
					rebootLocalMachine regReadValExe runOSCmd runSQLChk4Err 
					sendMsg2Monitor setLogFileDir
					startService stopService stopServiceWithDepend stripFileExt 
					stripPath stripWhitespace unc2path whence T38DEFAULTINSTDIR
					DEFAULT_MSINST_NM
				);

# All names of EXPORT and EXPORT_OK in EXPORT_TAGS{tag} anonymous list
# Define names for sets of symbols
#%EXPORT_TAGS = (T1 => [qw(findDependentService notifyMe)],
#			    T2 => [qw(getSqlCurVer getSqlCSDVer stripFileExt stripPath stripWhitespace)]);
			    
# A version number that you should increment every time you generate a new
# release of the module.
$VERSION	= do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf '%d'.'.%02d'x$#r,@r};
$T38ERROR="__T38ERROR__";
$gLogFileDir="";
$gisqlBin=1; 					# gisqlBin=1 means use osql, 0 means use isql

#-- constants

use constant T38DEFAULTINSTDIR	=> 'default';	# Default instance directory name on SQL 2000 Server.
use constant DEFAULT_MSINST_NM	=> 'MSSQLServer';

# Function declaration in alphabetical order in Common.pm
# Total 18 subs in this module

sub adActName2samid ($);
sub adGrpName2samid ($);
sub adUsrName2samid ($);
sub archiveFile($$);
sub archiveLogFile($);
sub chkPerlVer();
sub chkx64(;$);
sub clusGrpSrvcsStop ($);
sub clusResStart ($$$);
sub clusResStop ($$$);
sub errorTrap();
sub escapeREChar($);
sub findDependentService($;$);
sub filterDB (\@\@\@);
sub filterList(\@\@\@);
sub getDBNames($);
sub getDrives(;$);
sub getEnvPathVar();
sub getLogFileName($);
sub getServiceStatus($;$);
sub getSqlCSDVer(;$$);
sub getSqlCurVer(;$$);
sub getSQLInstLst ($;$);
sub getSQLInst4VirtualSrvr($);
sub getSqlVerReg(;$$);
sub getSqlPort(;$$);
sub getWinClusterName(;$);
sub getWinClusterNodes($$);
sub getWinClusterRes ($$;$);
sub globbing(\@);
sub isX64Process();
sub logEvent ($$;$); 
sub notifyMe($);
sub notifyWSub ($;$);
sub logme ($;$);
sub warnme ($;$);
sub errme ($;$);
sub parseProgramName();
sub pingServer($);
sub readINI($$$);
sub rebootLocalMachine();
sub regReadValExe($$;$);
sub runOSCmd ($;$);
sub runSQLChk4Err($;$$$$$$$\@\@$);
sub sendMsg2Monitor($$$);
sub setIsqlBin($);
sub setLogFileDir($);
sub startService($;$);
sub stopService($;$);
sub stopServiceWithDepend($;$);
sub stripFileExt($);
sub stripPath($);
sub stripWhitespace($);
sub unc2path($$);
sub whence ($);
sub warningTrap();


# ----------------------------------------------------------------------
#	adActName2samid		active directory Account Name to samid
# ----------------------------------------------------------------------
#	arguments:
#		$adUsrName	active directory account name
#		$adActType	active directory account type (1 = Group, 2 = User)
#	return:
#		samid		Success
#		0			Failure
# ----------------------------------------------------------------------
#	Get samid (short pre-windows 2000 name) for active directory name
# ----------------------------------------------------------------------
sub adActName2samid ($) {
	my ($adActName, $adActType) = @_;
	my $samid	= 0;
	my ($logFileName, $base, $logFilePath, $type);
	my $outfilename	= '';
	my $oscmd	= '';
	my @cmdout	= ();
SUB:
{
	unless ($adActType == 1 || $adActType == 2) {
		&errme("Invalid account type $adActType");
		$samid = 0; last SUB;
	}
	$adActName =~ s/^.*\\//;
	
	# Set output file name
	$logFileName = &T38lib::Common::getLogFileName($0);
	fileparse_set_fstype("MSWin32");
	($base, $logFilePath, $type) = fileparse($logFileName, '\.[^\.]*');
	$outfilename = $logFilePath . 'adActName2samid.' . $$ . '.out';

	$oscmd = ($adActType == 1)?
		"dsquery group -name $adActName domainroot -o samid":
		"dsquery user -name $adActName domainroot -o samid";

	unless(&runOSCmd($oscmd, \$outfilename)) {
		last SUB;
	}
	
	unless (open OSOUT, "<$outfilename") {
		&errme("Cannot open $outfilename for reading.");
		last SUB;
	}
	@cmdout = <OSOUT>;
	close(OSOUT); unlink($outfilename);
	chomp @cmdout; 
	$samid = $cmdout[0];
	$samid =~ s/^\"//; $samid =~ s/\"$//;
	if (!$samid or length($samid) > 20 or defined($cmdout[1])) {
		&errme("Error with command $oscmd.\noutput is \n" . join("\n", @cmdout));
		$samid = 0; last SUB;
	}

	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $samid.");
	return($samid);
}	# adActName2samid


# ----------------------------------------------------------------------
#	adGrpName2samid		active directory Group Name to samid
# ----------------------------------------------------------------------
#	arguments:
#		$adGrpName	active directory group name
#	return:
#		samid		Success
#		0			Failure
# ----------------------------------------------------------------------
#	Get samid (short pre-windows 2000 name) for active directory name
# ----------------------------------------------------------------------
sub adGrpName2samid ($) {
	my ($adGrpName) = @_;
	my $samid	= 0;
SUB:
{
	&notifyWSub("START - account name: $adGrpName.");
	unless($samid = &adActName2samid($adGrpName, 1)) {
		last SUB;
	}
	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $samid.");
	return($samid);
}	# adGrpName2samid


# ----------------------------------------------------------------------
#	adUsrName2samid		active directory User Name to samid
# ----------------------------------------------------------------------
#	arguments:
#		$adUsrName	active directory user name
#	return:
#		samid		Success
#		0			Failure
# ----------------------------------------------------------------------
#	Get samid (short pre-windows 2000 name) for active directory name
# ----------------------------------------------------------------------
sub adUsrName2samid ($) {
	my ($adUsrName) = @_;
	my $samid	= 0;
SUB:
{
	&notifyWSub("START - account name: $adUsrName.");
	unless($samid = &adActName2samid($adUsrName, 2)) {
		last SUB;
	}
	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $samid.");
	return($samid);
}	# adUsrName2samid


# ----------------------------------------------------------------------
# archiveFile -- archive any given file
# ----------------------------------------------------------------------
#	arguments:
#	Input:
#		$fileName	File name to keep
#		$nFiles		number of files to keep.
#	Output:			Status 1 OK, 0 Fail	
# ----------------------------------------------------------------------
sub archiveFile($$) {
	my ($archiveFileName, $numArchives) = @_;

	my ($archiveFullName,$archiveBaseName,$archivePath,$archiveSuffix,$newName,$oldName)="";
	my ($currentDir) = ".";
	my ($i) = 0;
	my ($status) = 1;

	$currentDir = Cwd::getcwd();

	$archiveFullName = $archiveFileName;
	
	# First normalize archiveFullName to start with directory name.
	#
	if ($archiveFullName !~ /^\\|.:/) { 
		$archiveFullName = "$currentDir" . "\\" . "$archiveFullName";
	}

	$archiveFullName =~ s|\\|/|g;	# Convert DOS directory delimiters to UNIX.
	($archiveBaseName, $archivePath, $archiveSuffix) = fileparse($archiveFullName, '\..*');
	$archivePath =~ s/\//\\/g;

	$newName = sprintf("${archiveBaseName}\.%03d$archiveSuffix", $numArchives);

	for ($i = $numArchives - 1; $i > 0 ; $i-- ) {
		$oldName = sprintf("${archiveBaseName}\.%03d$archiveSuffix", $i);
		if (-f "$archivePath$oldName") {
			$status = rename ("$archivePath$oldName", "$archivePath$newName");
		}
		$newName = $oldName;
	}

	if ( -f $archiveFullName ) {
		$status = rename ("$archiveFullName", "$archivePath$newName");
	}

	return ($status);

}	# End of archiveFile

# ----------------------------------------------------------------------
# archiveLogFile -- archive log file
# ----------------------------------------------------------------------
#	arguments:
#	Input:
#		$nFiles		number of files to keep.
#	Output:			Status 1 OK, 0 Fail	
# ----------------------------------------------------------------------
sub archiveLogFile($) {
	my $nFiles		= shift;
	my $logFileName	= '';
	my $logFileBase	= '';
	my $logSuffix	= "\.log";
	my $newName			= '';
	my $oldName			= '';
	my $i				= 0;
	my $status = 1;

	$logFileName = &T38lib::Common::getLogFileName($0);
	($logFileBase = $logFileName) =~ s/$logSuffix$//i;

	$newName = sprintf("${logFileBase}\.%03d$logSuffix", $nFiles);
	for ($i = $nFiles - 1; $i > 0 ; $i-- ) {
		$oldName = sprintf("${logFileBase}\.%03d$logSuffix", $i);
		if (-f $oldName) {
			# &T38lib::Common::notifyMe ("rename $oldName $newName");
			$status = rename ($oldName, $newName);
		}
		$newName = $oldName;
	}

	if (-f $logFileName) {
		# &T38lib::Common::notifyMe ("rename $logFileName $newName");
		$status = rename ($logFileName, $newName);
	}

	return ($status);

}	# End of archiveLogFile

#------------------------------------------------------------------------------
# 	Purpose:	This function is used to make sure that we have new version of 
#				perl i.e. 5.005 or higher
#
# 	Input:		None
# 	Output: 	1 or Perl version on the box
#				1 mean version is 5.005 or higher		
#				Perl version mean older version
#
#------------------------------------------------------------------------------
sub chkPerlVer() {
	my $status;
	my ($correctRevision, $correctVersion) = ("5", "005");

	# $] hold the perl version in the format 5.00503
	my ($revision, $version, $subversion) = ($] =~ /^(\d+)\.(\d{3})(\d*)$/);

	if ( ($revision eq $correctRevision) && ( $version ge $correctVersion ) ) {
		$status = 1;	
	}
	else {
		$status = $revision . "." . $version; 
	}

	return $status

} # End of chkPerlVer

#------------------------------------------------------------------------------
# 	Purpose:	check to to see if 64 bit OS
#
# 	Input:		Server Name (optional)
# 	Output: 	1 if 64 bit OS
# 				0 if other than 64 bit
#
#------------------------------------------------------------------------------
sub chkx64(;$) {
	my $srvrName	= shift;

	my $x64Flg		= 0;
	my $regSrvrRoot	= (!$srvrName || (uc($srvrName) eq uc(Win32::NodeName()))) ? "": "//$srvrName/";
	my $keyName;

	$keyName	= "${regSrvrRoot}LMachine/System/CurrentControlSet/Control/Session Manager/Environment/PROCESSOR_ARCHITECTURE";
	$x64Flg = (defined($Registry->{$keyName}) && (uc($Registry->{$keyName}) eq 'AMD64') ) ? 1 : 0;

	return ($x64Flg);

} # End of chkx64

#------------------------------------------------------------------------------
# 	Purpose:	check to to see if running using 64 bit perl
#
# 	Output: 	1 if 64 bit of perl
# 				0 if other than 64 bit
#
#------------------------------------------------------------------------------
sub isX64Process() {
	my $x64Flg		= 0;
	my $perlArch = `cmd /C perl -V:archname`;
	my $sysArch = `cmd /C SystemInfo|FindStr /I /C:"System type"`;
	
	if($perlArch =~/(64)/ && $sysArch=~/(64)/){ 
	#perlarch contains -> 'MSWin32-x(86|64)-multi-thread', the architecture is either x86 or x64.
	#sysarch contains -> "System type: x64-based PC
		$x64Flg = 1;
	}
	return ($x64Flg);
} # End of isX64Process

# ----------------------------------------------------------------------
#	clusGrpSrvcsStop		Take offline all service resources in a cluster group
# ----------------------------------------------------------------------
#	arguments:
#		$vsName		cluster virtual server name
#	return:
#		1			Success
#		0			Failure
# ----------------------------------------------------------------------
#	Take offline all service resources in a cluster group
# ----------------------------------------------------------------------
sub clusGrpSrvcsStop ($) {
	my ($vsName) = @_;
	my $resName	= '';
	my $resPatt	= '';
	my $resType	= '';
	my @resList	= ();
	my $clusterName	= 0;
	my $cmd		= '';
	my $cmdout	= '';
	my $status	= 1;
SUB:
{
	&notifyWSub("Started. Group Name: $vsName.");
	unless ($clusterName = &getWinClusterRes ($vsName, \@resList) ) {
		&errme("Cannot get list of resources for virtual server $vsName.");
		$status = 0; last SUB;
	}

	foreach $resName (@resList) {
		$resPatt = &escapeREChar($resName);
		# Check resource type.
		$cmd = "cluster $clusterName resource \"$resName\" /prop";
		$cmdout = `$cmd`;
		&notifyWSub ("cmd = $cmd");
		&notifyWSub ("cmdout = $cmdout");
	   
		# S  SQL Server (TSQ9)    Type                           SQL Server
		if ($cmdout =~ /S\s+$resPatt\s+Type\s+(.+)\s+\n/i) {
			$resType = $1;
		} else {
			&errme("Cannot find type record for resource $resName.");
			$status = 0; last SUB;
		}
		if (
			( lc($resType) eq 'sql server') ||
			( lc($resType) eq 'sql server agent') ||
			( lc($resType) eq 'generic service')
			) {
			unless (&clusResStop ($clusterName, $vsName, $resName) ) {
				&errme("Cannot stop $resName in $vsName group on a $clusterName cluster.");
				$status = 0; last SUB;
			}
		}

	}

	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# clusGrpSrvcsStop


# ----------------------------------------------------------------------
#	clusResStart		Bring online clustered resource
# ----------------------------------------------------------------------
#	arguments:
#		$clusterName	cluster name
#		$vsName			virtual server name
#		$resName		resource name in $vsName group
#	return:
#		1			Success
#		0			Failure
# ----------------------------------------------------------------------
#	Bring online clustered resource
# ----------------------------------------------------------------------

sub clusResStart ($$$) {
	my ($clusterName, $vsName, $resName) = @_;
	my $resPatt	= &escapeREChar($resName);
	my $cmd		= '';
	my $cmdout	= '';
	my $status	= 1;
SUB:
{
	&notifyWSub("Started. Cluster Name: $clusterName, Group Name: $vsName, resource: $resName");

	$cmd = "cluster $clusterName resource \"$resName\" /online";
	$cmdout = `$cmd`;
	&notifyWSub ("cmd = $cmd");
	&notifyWSub ("cmdout = $cmdout");
   
	unless ($cmdout =~ /$resPatt\s+$vsName\s+\S+\s+Online/i) {
		&errme("Cannot bring virtual server $vsName online.");
		$status = 0; last SUB;
	}

	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# clusResStart


# ----------------------------------------------------------------------
#	clusResStop		Take offline clustered resource
# ----------------------------------------------------------------------
#	arguments:
#		$clusterName	cluster  name
#		$vsName			virtual server name
#		$resName		resource name on a cluster
#	return:
#		1			Success
#		0			Failure
# ----------------------------------------------------------------------
#	Take offline clustered resource
# ----------------------------------------------------------------------

sub clusResStop ($$$) {
	my ($clusterName, $vsName, $resName) = @_;
	my $resPatt	= &escapeREChar($resName);
	my $cmd		= '';
	my $cmdout	= '';
	my $status	= 1;
SUB:
{
	&notifyWSub("Started. Cluster Name: $clusterName, Group Name: $vsName, resource: $resName");

	$cmd = "cluster $clusterName resource \"$resName\" /offline";
	$cmdout = `$cmd`;
	&notifyWSub ("cmd = $cmd");
	&notifyWSub ("cmdout = $cmdout");
   
	unless ($cmdout =~ /$resPatt\s+$vsName\s+\S+\s+Offline/i) {
		&errme("Cannot take $resName resource offline.");
		$status = 0; last SUB;
	}

	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# clusResStop


#------------------------------------------------------------------------------
#	Purpose: Notify the error and die
# 
#	Input:	None
#	Output:	None
#			
#------------------------------------------------------------------------------
sub errorTrap() {

	&notifyMe("**********************************************************************");
	&notifyMe("*                                                                    *");
	&notifyMe("*        A critical error has occurred while running the script      *");
	&notifyMe("*                                                                    *");
	&notifyMe("*             Certain processes have not completed !!                *");
	&notifyMe("*                                                                    *");
	&notifyMe("*                   Aborting the Process ...                         *");
	&notifyMe("*                                                                    *");
	&notifyMe("**********************************************************************");

	croak;

} 	# End of errorTrap

#------------------------------------------------------------------------------
#	Purpose: Notify the Warning
# 
#	Input:	None
#	Output:	None
#			
#------------------------------------------------------------------------------
sub warningTrap() {

	&notifyMe("**********************************************************************");
	&notifyMe("*                                                                    *");
	&notifyMe("*         Warning(s) has occurred while running the script           *");
	&notifyMe("*                                                                    *");
	&notifyMe("*        Certain processes have not completed successfully !!        *");
	&notifyMe("*                                                                    *");
	&notifyMe("**********************************************************************");

} 	# End of warningTrap

# ----------------------------------------------------------------------
#	escapeREChar		escape special RegExp characters
# ----------------------------------------------------------------------
#	arguments:
#		$string
#	return:
#		$string with special characters escaped
# ----------------------------------------------------------------------
#	escape special RegExp characters
# ----------------------------------------------------------------------

sub escapeREChar ($) {
	my $instring	= shift;
	$instring =~  s/([^\w\s])/\\$1/g;
	return($instring);
}	# escapeREChar




#------------------------------------------------------------------------------
#	Purpose: Find dependent services of a given service.
# 
#	Input: 	Service Name, Server Name (Optional)
#	Output:	An array of dependent service names
#			In case of an error return global variable $T38ERROR=__T38ERROR__
#			if no dependent service(s) found return array[0]="zero"
#------------------------------------------------------------------------------
sub findDependentService($;$) {
	my $serviceName = shift;	# Get the input parameter
	my $machine		= shift;

	my $found=0;				# Flag used to see if service is found.
	my @depService=("zero");	# Array used to store all the dependent services.
	my @depSerList = ();		# Array to store list of dependent services
	my $cnt=0;				   	# Counter
	my (%serviceList);			# Hash to store all the services.
	my (%valueList);			# Hash to store all the values
	
	my ($key, $value, $SerKey, $i, $j, $p);
	my $hNode	= 0;			# Hash for machine registry.

	if ($machine eq "") {
		$machine = Win32::NodeName(); 			# Get the machine name
	}

	Win32::Service::GetServices($machine, \%serviceList);
	if ( ! defined(%serviceList) ) {
		@depService = ($T38ERROR);
		return @depService;
	}

	foreach $value (values %serviceList) {
		if ( (lc($value)) eq (lc($serviceName)) ){
			$found = 1;		# Found the service;
			last;			# Terminate the While loop (No need to search any more).
		}
	}
	
	# Not a valid service, No need to look for dependent services return zero
	if ( $found == 0 ) {
		return @depService;
	}

	# Service found proceed to find dependent service(s).
	while (($key,$value) = each(%serviceList)) {
		$p="SYSTEM\\CurrentControlSet\\Services\\$value";

		if (
			$main::HKEY_LOCAL_MACHINE->Connect ($machine, $hNode) && 
			$hNode->Open($p, $SerKey ) ) {
			%valueList=();							# Initialized the array
			$SerKey->GetValues(\%valueList);		# Get sub keys and values -hash ref

			foreach $j ( sort (keys( %valueList))) {
				if ( ($j =~ /\bDependOnService\b/i) && ($valueList{$j}[2] ne "") ) {
				   	@depSerList = split( /\x00/, $valueList{$j}[2]);
					foreach $i ( @depSerList ) {
						if ( (lc($i)) eq (lc($serviceName)) ) {
							$depService[$cnt]=$value;
							$cnt++;
						}
					}
				}
			}
		}
		else {
			croak "[T38lib::Common::findDependentService]: Can not open $p\n";
		}
	}	
	$SerKey->Close();		
	$hNode->Close();

	# Debug code
	#	&notifyWSub("Service Name: $serviceName");
	#	foreach (@depService) {
	#		&notifyWSub("Dependent Service Name: $_");
	#	}
	#	&notifyWSub("End of dependent serives listing");

	return @depService;

}	# End of findDependentService

# ----------------------------------------------------------------------
# filterDB -- Process Include and exclude DBs from master db list 
# ----------------------------------------------------------------------
#	arguments:
#	Input:
#		\@		Array ref of All the databases on the server
#		\@		Array ref of All the databases that have to be INCLUDED
#		\@		Array ref of All the databases that have to be EXCLUDED
#
#	Output:			Array of databases 
#				In case of an error $T38ERROR = __T38ERROR__
#
#
# ALLDB		IncludeDB	ExcludeDB	Rtn Value
#  Y			N			N		All DB
#  Y			Y			N		IncludeDB - not in AllDB - AllDB
#  Y			N			Y    	AllDB  - ExcludeDB
#  Y			Y			Y		IncludeDB - not in all DB - ExcludeDB
# ----------------------------------------------------------------------
sub filterDB (\@\@\@) {
	my ($alldb, $incDB, $excDB) = @_;

	my ($i, $nvals, $db);
	my ($allDBNameList, $excludeDBNameList) = ("","");
	my @masterArray = ();
	my @temp = ();

	SUB: {
		# Assign all the database on the server 
		# to master array and create a string of 
		# all the databases deliminated by "|"
		# If this array is empty then $T38ERROR="__T38ERROR__"
		#
		$nvals = scalar @{$alldb};
		if ( $nvals > 0 ) {
			for $i (0..$nvals-1) {
				$masterArray[$i] = $$alldb[$i];
				$allDBNameList = $allDBNameList . $$alldb[$i] . "|";
			}
		}
		else {
			$masterArray[0] = $T38ERROR;
			last SUB;
		}

		# if Include is given
		# Check to see if include database are 
		# in the list of all the db on the server
		# if this is the case make this the master Array
		$nvals = scalar @{$incDB};
		if ( $nvals > 0 ) {
			for $i (0..$nvals-1) {
				if ($$incDB[$i] =~ /^($allDBNameList)$/ ) {
					push (@temp, $$incDB[$i]);
				}
			}
			@masterArray = ();
			@masterArray = @temp;
		}

		# If exclude is given, create exclude db string
		# deliminated by "|"
		# Exclude these databases from the master list
		$nvals = scalar @{$excDB};
		if ( $nvals > 0 ) {
			for $i (0..$nvals-1) {
				$excludeDBNameList = $excludeDBNameList . $$excDB[$i] . "|";
			}

			@temp = ();
			foreach $db (@masterArray) {	
				unless ($db =~ /^($excludeDBNameList)$/ ) {
					push (@temp, $db);
				}
			}
			@masterArray = @temp;
		}
	}

	return @masterArray;
}

# ----------------------------------------------------------------------
# filterList -- Process Include and exclude DBs from master db list 
# ----------------------------------------------------------------------
#	arguments:
#	Input:
#		\@		Array ref of All the databases on the server
#		\@		Array ref of All the databases that have to be INCLUDED
#		\@		Array ref of All the databases that have to be EXCLUDED
#
#	Output:			Array of databases 
#				In case of an error $T38ERROR = __T38ERROR__
#
#
# ALLDB		IncludeDB	ExcludeDB	Rtn Value
#  Y			N			N		All DB
#  Y			Y			N		IncludeDB X AllDB
#  Y			N			Y    	AllDB  - ExcludeDB
#  Y			Y			Y		IncludeDB - not in all DB - ExcludeDB
# ----------------------------------------------------------------------
sub filterList (\@\@\@) {
	my ($allobj, $inclst, $exclst) = @_;

	my $i			= 0;
	my $j			= 0;
	my $nvalouter	= 0;
	my $nvalinner	= 0;
	my @result		= ();

	# my ($allDBNameList, $excludeDBNameList) = ("","");
	# my @temp = ();

	# Process include list
	$nvalouter = scalar @{$inclst};
	$nvalinner = scalar @{$allobj};

	if ($nvalouter == 0) {
		# The inclst is empty. Just move all objects to the result.
		push @result, @{$allobj};
	} else {
		# We have to include all objects that are in include list
		# and all objects list.
		for $i (0..$nvalouter-1) {
			for $j (0..$nvalinner-1) {
				if ($$inclst[$i] eq $$allobj[$j]) {
					push @result, $$inclst[$i];
					last;
				}
			}
		}
	}

	# Process exclude list

	$nvalouter = scalar @{$exclst};

	for $i (0..$nvalouter - 1) {
		for $j (0..$#result) {
			($result[$j] eq $$exclst[$i]) ? splice (@result, $j, 1) : $j++;
		}
	}

	return @result;
}	# filterList

#------------------------------------------------------------------------------
# Purpose:	Get all the logical drive and their type
#
#	Input:		
#		ALL:	For all the drives
#		CDR:	For all the CDROM drives
#		FIX:	For all the fix drives
#		RAM:	For All the RAM DISK drives
#		REM:	For all removeable drives
#		RMT:	For all the remote drives
#		
#	Output:		Return a sorted array with all drive letters. Example c:\
#
#------------------------------------------------------------------------------
sub getDrives(;$) {
	my $option = shift;

	$option="all" unless defined $option;


	my %Types = (
  		0 => 'DRIVE_UNKNOWN',				# Not Checked
  		1 => 'DRIVE_NO_ROOT_DIR',			# Not Checked
  		2 => 'DRIVE_REMOVABLE',
  		3 => 'DRIVE_FIXED',
  		4 => 'DRIVE_REMOTE',
  		5 => 'DRIVE_CDROM',
  		6 => 'DRIVE_RAMDISK'
	);

	my ($drives, $DriveType, $letter);
	my (@rtnDrives, @drives) = ();

	@drives = getLogicalDrives();

#	foreach (@drives) {
#		print "drive = $_\n";
#	}
#	foreach my $letter ( @drives ) {
#		$DriveType = GetDriveType($letter);
#		print "Drive $letter is $Types{$DriveType}\n";
#	}

	if ( $option =~ /all/i ) {
		@rtnDrives = @drives;
	}
	elsif ( $option =~ /rem/i ) {
		foreach $letter ( @drives ) {
			$DriveType = GetDriveType($letter);
			if ( $DriveType == 2) {
				push (@rtnDrives, $letter);
			}
		}
	}
	elsif ( $option =~ /fix/i ) {
		foreach $letter ( @drives ) {
			$DriveType = GetDriveType($letter);
			if ( $DriveType == 3) {
				push (@rtnDrives, $letter);
			}
		}
	}
	elsif ( $option =~ /rmt/i ) {
		foreach $letter ( @drives ) {
			$DriveType = GetDriveType($letter);
			if ( $DriveType == 4) {
				push (@rtnDrives, $letter);
			}
		}
	}
	elsif ( $option =~ /cdr/i ) {
		foreach $letter ( @drives ) {
			$DriveType = GetDriveType($letter);
			if ( $DriveType == 5) {
				push (@rtnDrives, $letter);
			}
		}
	}
	elsif ( $option =~ /ram/i ) {
		foreach $letter ( @drives ) {
			$DriveType = GetDriveType($letter);
			if ( $DriveType == 6) {
				push (@rtnDrives, $letter);
			}
		}
	}
	return (sort(@rtnDrives));

} 	# End of getDrives

#------------------------------------------------------------------------------
# Purpose:	Get the names of all the databases in a SQL Server 
#
#	Input:		Server name
#	Output:		Return an array with all the name(s) of the databases in 
#				in the given server.
#				In case of an error return $T38ERROR
#
#------------------------------------------------------------------------------
sub getDBNames($) {
	my ($serverName) = shift;

	my ($cmd,$rtnCode); 
	my (@dbNames) = (); 

	my ($logFileName, $base, $logFilePath, $type);
	my (@inc) = ();
	my (@exc) = ();

	my ($sqlFileName) = "dbnames.sql";
	my ($outFileName) = "dbnames.out";

	$logFileName = &T38lib::Common::getLogFileName($0);
	fileparse_set_fstype("MSWin32");
	($base, $logFilePath, $type) = fileparse($logFileName, '\.[^\.]*');

# Open a temp file to write the sql, in case of an error return $T38ERROR. 
	$sqlFileName = $logFilePath . $sqlFileName;

	unless (open(SQL,"> $sqlFileName")) {			
		push (@dbNames, $T38ERROR);
		return (@dbNames);
	}

# Write the SQL to get the dbnames
#	print SQL "use master\n";
#	print SQL "go\n";
	print SQL "set nocount on\n";
	print SQL "go\n";
	print SQL "select name from sysdatabases\n";
	print SQL "go\n";

	close(SQL);

	# get the log file name which will give us the directory 
	# where log file is and use that directory to create
	# any temp files

	$rtnCode  = &runSQLChk4Err($sqlFileName, $serverName, "", $outFileName, "", "", "", "");
	if ( $rtnCode == 1)  {
		push (@dbNames, $T38ERROR);
		return (@dbNames);
	}

	# Set the output file name using -o option
	#
	$outFileName = $logFilePath . "$outFileName";
	
# Open the output file to read, in case of error return $T38ERROR
	unless (open(TMP,"< $outFileName"))  {
		push (@dbNames, $T38ERROR);
		return (@dbNames);
	}

# Read the output file created by SQL command and look for 
# databases names.
# In case of an error terminate the loop and return $T38ERROR
	while (<TMP>) {
		chomp;
		if ( (/\w+/) ) {
			$_ = &T38lib::Common::stripWhitespace($_);
			push (@dbNames,$_);			
		}
	}
	close(TMP);

# Delete temp files
	unlink($sqlFileName);
	unlink($outFileName);

# Sort and return the database names
	return (sort (@dbNames) );

}	# End of getDbNames

#------------------------------------------------------------------------------
# 	Purpose: Read the path information from the registry.  This is used to 
#          	 initlized the environment once the SQL server is installed.
#			 This is done so isql command does not failed.
#
#	Input	 None
#	Output:	 Return the full path read from registry
#			 In case of an error return $T38ERROR="__T38ERROR__"
#			 
#
#------------------------------------------------------------------------------
sub getEnvPathVar() {
	my $p='';
	my ($handle, $j);
	my (%valueList);
	my ($envPath, $userPath, $fullPath);
	my $ERR=-1;

	$p="SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment";
  	$main::HKEY_LOCAL_MACHINE->Open($p, $handle ) or return $ERR;
	$handle->GetValues(\%valueList);
  	croak "[T38lib::Common::getEnvPathVar]: curVer->GetValues failed\n" unless defined(%valueList);

	$handle->Close();

  	foreach $j ( sort (keys( %valueList))) {
    	if ( $j =~ /^Path$/i ) {
			$envPath = $valueList{$j}[2];
      		last;
    	}
  	}											
	
	%valueList=();
	$j="";
	$p="Environment";

	$main::HKEY_CURRENT_USER->Open($p, $handle ) or return $ERR;
	$handle->GetValues(\%valueList);
  	croak "[T38lib::Common::getEnvPathVar]: curVer->GetValues failed\n" unless defined(%valueList);

	$handle->Close();

	foreach $j ( sort (keys( %valueList))) {
  		if ( $j =~ /^Path$/i ) {
			$userPath = $valueList{$j}[2];
      		last;
  		}
  	}

	if ( (defined($userPath)) and (defined($envPath)) ) {
		$fullPath=`cmd /D /C echo $envPath;$userPath`;
	}
  	elsif (defined($envPath)) {	
		$fullPath=`cmd /D /C echo $envPath`;
	}
	else {
		$fullPath = $T38ERROR;
	}
	chomp($fullPath);

	return $fullPath;

}	# End of getEnvPathVar

#------------------------------------------------------------------------------
#	Purpose: Get a program name and return a log file name
#			 Log file name is ProgramName.log
#
#	Input: 	Program Name
#	Output: Return a string with the log file name
#			Example:
#				program name  = c:\\winnt\\temp\\T38abcd.pl
#				log file name = T38abcd.log
#
#------------------------------------------------------------------------------
sub getLogFileName($) {
	my ($progName)	= shift;					# Get the input parameter
	my $logFileName	= '';

	if ($gLogFileDir) {
		$progName = &stripPath($progName);
		$progName = stripFileExt($progName);
		$logFileName = $gLogFileDir . $progName . ".log";
	} else {
		$progName		= stripFileExt($progName);
		$logFileName	= $progName . ".log";
	}

	return $logFileName;

}	# End of getLogfileName
	
#------------------------------------------------------------------------------
# Purpose: Start a given service.
#		Input:	Service Name
#				Machine Name (Optional)
#		Output:	Return an array
#				[0] = notfound or found or zero in case of an error
#		If Found then
#				[1] = Running or Stopped or Pause
#------------------------------------------------------------------------------
sub getServiceStatus($;$) {
	my $service_name	= shift;						# Get the status of this service name
	my $Machine			= shift;

	my (%serviceList, %serStatus);
	my $found = my $cnt = my $status = my $state = 0;
	my (@rtnStatus) = "zero";

	my ($key, $value);

	$Machine = Win32::NodeName() unless ($Machine); 				# Get the machine name

	if (! Win32::Service::GetServices($Machine, \%serviceList) ) {
		carp "** ERROR **  [T38list::Common::getServiceStatus]: Win32::Services::GetServices failed.";
		return (@rtnStatus);
	}

	while (($key,$value) = each(%serviceList)) {
		if ( (lc($value)) eq (lc($service_name)) ){
			$found = 1;								# Found the service;
			last;									# Terminate the While loop (No need to search any more).
		}
	}

	if ( $found == 0 ) {
		return ($rtnStatus[0]="notfound");
	}
	else {
		$rtnStatus[0]="found";
	}
		
# Get the Service status
# serStatus{'CurrentState'} = 1 Stopped
# serStatus{'CurrentState'} = 4 Running
# serStatus{'CurrentState'} = 7 Pause

	if ( ! Win32::Service::GetStatus($Machine, $service_name, \%serStatus) ) {
		carp "** ERROR **  [T38list::Common::startService]: Win32::Services::GetStatus failed.";
		return ($rtnStatus[0]="zero");
	}

	if ( $serStatus{'CurrentState'} == 1 ) {
		$rtnStatus[1]="stopped";
	}
	elsif ( $serStatus{'CurrentState'} == 4 ) {
		$rtnStatus[1]="running";
	}
	elsif ( $serStatus{'CurrentState'} == 7 ) {
		$rtnStatus[1]="paused";
	}
	else {
		return ($rtnStatus[0]="zero");
	}

	return( @rtnStatus );

}	# End of getServiceStatus

#------------------------------------------------------------------------------
#	Purpose: Get MSSQLServer version number
#
#	Input: 	Instance Name used in SQL 2000 and up
#			Optional Machine name for connecting to remote registry
#	Output: Return a string with the following format
#			SQLMajorVersion.SQLMinorVersion.SQLServicepackVersion
#			or 0 in case of an error.
#
#------------------------------------------------------------------------------
sub getSqlCurVer(;$$) {
	my $instanceName = shift;
	my $Machine	= shift;

	my $p='';
	my ($curVer, $j);
	my (%valueList);
	my $sqlVer=0;
	my @serviceStatus = my @isqlOut =  ();
	my ($serverName, $serviceName )="";
	my ($regResult, $rtnCode)	= 0;

	my ($outFileName) = "sqlver.out";
	my ($logFileName, $base, $logFilePath, $type);

	$Machine = Win32::NodeName() unless ($Machine); 			# Get the machine name

	# If the SQL Server is running then connect to the server and use @@version
	# to get the version number
	#
	$serverName  = ($instanceName) ? "$Machine\\$instanceName" : "$Machine";
	$serviceName=($instanceName) ? "MSSQL\$$instanceName" : "MSSQLSERVER";

	@serviceStatus = &T38lib::Common::getServiceStatus($serviceName, $Machine);

	if ( ($serviceStatus[0] eq "found") and ($serviceStatus[1] eq "running") ) {
		$rtnCode = &runSQLChk4Err("select \@\@version", $serverName, "", $outFileName, "", "", "", "");

		# get the log file name which will give us the directory 
		# where log file is and use that directory to create
		# any temp files

		$logFileName = &T38lib::Common::getLogFileName($0);
		fileparse_set_fstype("MSWin32");
		($base, $logFilePath, $type) = fileparse($logFileName, '\.[^\.]*');
	
		# Set the output file name using -o option
		#
		$outFileName = $logFilePath . "$outFileName";
# 		Open the output file to read, in case of error return 0
		unless (open(TMP,"< $outFileName"))  {
			return (0);
		}
    	while (<TMP>) {
    	    if (/.*(\d\.\d{2}\.\d{3,4}).*/ ) {
				  close(TMP);
				  unlink($outFileName);
    	        return ($1);
    	    }
    	}
	}
	close(TMP);
	unlink($outFileName);

	# If we can not get the version from SQL server then read the registry entry to
	# get the server version
	#
	$p=($instanceName) ?
		"SOFTWARE\\Microsoft\\Microsoft SQL Server\\$instanceName\\MSSQLServer\\CurrentVersion" :
		"SOFTWARE\\Microsoft\\MSSQLServer\\MSSQLServer\\CurrentVersion";

	if (uc($Machine) eq uc(Win32::NodeName())) {
		$regResult = $main::HKEY_LOCAL_MACHINE->Open($p, $curVer );
	} else {
		$regResult = 
				$main::HKEY_LOCAL_MACHINE->Connect($Machine, $curVer ) &&
				$curVer->Open($p, $curVer);
	}
	return ($sqlVer) unless($regResult);

	$curVer->GetValues(\%valueList);		# Get sub keys and values -hash ref
	croak "[T38lib::Common::getSqlCurVer]: curVer->GetValues failed\n" unless defined(%valueList);
	$curVer->Close();

	foreach $j ( sort (keys( %valueList))) {
		if ( $j =~ /^CurrentVersion$/i ) {
		   	$sqlVer = $valueList{$j}[2];
			last;
		}
	}	
	
	return $sqlVer;

}	# End of getSqlCurver

#------------------------------------------------------------------------------
#	Purpose: Get MSSQLServer CSD version number
#
#	Input: 	Instance Name used in SQL 2000 and up
#			Machine Name (Optional)
#	Output: Return a string with the following format
#			SQLMajorVersion.SQLMinorVersion.SQLServicepackVersion
#			or 0 in case of an error.
#
#------------------------------------------------------------------------------
sub getSqlCSDVer(;$$) {
	my $instanceName = shift;
	my $Machine		= shift;
	
	my $p='';
	my ($curVer, $j);
	my (%valueList);
	my $sqlVer=0;
	my @serviceStatus = my @isqlOut =  ();
	my ($serverName, $serviceName )="";
	my ($regResult, $rtnCode)	= 0;

	my ($outFileName) = "sqlver.out";
	my ($logFileName, $base, $logFilePath, $type);
	
	$Machine = Win32::NodeName() unless ($Machine); 			# Get the machine name

	# If the SQL Server is running then connect to the server and use @@version
	# to get the version number
	#
	$serverName  = ($instanceName) ? "$Machine\\$instanceName" : "$Machine";
	$serviceName=($instanceName) ? "MSSQL\$$instanceName" : "MSSQLSERVER";

	@serviceStatus = &T38lib::Common::getServiceStatus($serviceName, $Machine);

	if ( ($serviceStatus[0] eq "found") and ($serviceStatus[1] eq "running") ) {
		$rtnCode = &runSQLChk4Err("select \@\@version", $serverName, "", $outFileName, "", "", "", "");
	
		# get the log file name which will give us the directory 
		# where log file is and use that directory to create
		# any temp files

		$logFileName = &T38lib::Common::getLogFileName($0);
		fileparse_set_fstype("MSWin32");
		($base, $logFilePath, $type) = fileparse($logFileName, '\.[^\.]*');
	
		# Set the output file name using -o option
		#
		$outFileName = $logFilePath . "$outFileName";
		#	Open the output file to read, in case of error return 0
		unless (open(TMP,"< $outFileName"))  {
			return (0);
		}
    	while (<TMP>) {
    	    if (/.*(\d\.\d{2}\.\d{3,4}).*/ ) {
				  close(TMP);
				  unlink($outFileName);
    	        return ($1);
    	    }
    	}
	}
	close(TMP);
	unlink($outFileName);

	# If we can not get the version from SQL server then read the registry entry to
	# get the server version
	#
	$p=($instanceName) ? 
		"SOFTWARE\\Microsoft\\Microsoft SQL Server\\$instanceName\\MSSQLServer\\CurrentVersion" :
		"SOFTWARE\\Microsoft\\MSSQLServer\\MSSQLServer\\CurrentVersion";

	#$main::HKEY_LOCAL_MACHINE->Open($p, $curVer )
	#		or croak "[T38lib::Common::getSqlCSDVer]: Can not open\n";

	#$main::HKEY_LOCAL_MACHINE->Open($p, $curVer )
	#		or return $sqlVer;

	if (uc($Machine) eq uc(Win32::NodeName())) {
		$regResult = $main::HKEY_LOCAL_MACHINE->Open($p, $curVer );
	} else {
		$regResult = 
				$main::HKEY_LOCAL_MACHINE->Connect($Machine, $curVer ) &&
				$curVer->Open($p, $curVer);
	}
	return ($sqlVer) unless($regResult);

	$curVer->GetValues(\%valueList);		# Get sub keys and values -hash ref
	croak "[T38lib::Common::GetSqlCSDVer]: curVer->GetValues failed\n" 
		unless defined(%valueList);

	$curVer->Close();

	foreach $j ( sort (keys( %valueList))) {
		if ( $j =~ /^CSDVersion$/i ) {
		   	$sqlVer = $valueList{$j}[2];
			last;
		}
	}	
	
	return $sqlVer;

}	# End of getSqlCSDVer
																					
# ----------------------------------------------------------------------
#	getSqlInstLst	Get list of SQL Server instances on a server
# ----------------------------------------------------------------------
#	arguments:
#		rInstLst	reference to list of SQL Server instances
#		srvrName	server Machine Name (Optional)
#	return:
#		1	Success
# ----------------------------------------------------------------------
# Return list of installed SQL  instances on a server. List is returned
# in rInstLst hash. Key of the hash is instance name. Value in a hash is
# corresponding SQL Server version id.
# ----------------------------------------------------------------------

sub getSQLInstLst ($;$) {
	my $rInstLst	= shift;
	my $srvrName	= shift;
	my @instLst		= ();
	my $keyName		= '';
	my $regValue	= '';
	my $instName	= '';
	my $dbmsVer		= '';
	my $hKey		= 0;
	my $x64flg		= 0;
	my $x64process =  0;
	my $status		= 1;
	my $regSrvrRoot		= (!$srvrName || (uc($srvrName) eq uc(Win32::NodeName()))) ? "": "//$srvrName/";

	SUB:
	{
		$srvrName = Win32::NodeName()	if (!$srvrName || ($srvrName eq	'.') );

		# First get Processor Architecture (see http://support.microsoft.com/kb/888731):
		$keyName	= "${regSrvrRoot}LMachine/System/CurrentControlSet/Control/Session Manager/Environment/PROCESSOR_ARCHITECTURE";
		$x64flg = (defined($Registry->{$keyName}) && (uc($Registry->{$keyName}) eq 'AMD64') ) ? 1 : 0;
		$x64process = isX64Process();
		if (!$x64process && $x64flg && (uc($srvrName) eq uc(Win32::NodeName())) ) {
			# On x64 machine we cannot access Microsoft SQL Server InstalledInstances value from 32-bit process.
			# Have to use x64 bit version of the reg.exe command line utilitiy.
			$regValue = &regReadValExe("HKLM\\Software\\Microsoft\\Microsoft SQL Server", "InstalledInstances", $srvrName);
			if ($regValue) {
				@instLst = split('\\\\0', $regValue);
			}
		} elsif ( ($keyName = "${regSrvrRoot}LMachine/Software/Microsoft/Microsoft SQL Server/InstalledInstances") && defined($Registry->{$keyName})) {
			@instLst = split('\0', $Registry->{$keyName});
		} else {
			# It is probably pre SQL 2000 server. If we can get
			# SQL Server version id, there is only one default instance.
			# Otherwise we have to asume SQL Server is not installed.
	
			$instName = DEFAULT_MSINST_NM;
			if ($dbmsVer = &getSqlVerReg($srvrName, $instName)) {
				$$rInstLst{$instName}	= $dbmsVer;
				last SUB;
			}
		}
	
		foreach $instName (@instLst) {
			if ($instName)  {
				$dbmsVer = &getSqlVerReg($srvrName, $instName);
				$$rInstLst{$instName} = ($dbmsVer) ? $dbmsVer:$T38ERROR;
			}
		}
		last SUB;
	}

	return ($status);

}	# getSqlInstLst

# ----------------------------------------------------------------------
#	getSQLInst4VirtualSrvr	Get SQL Instance name for virtual server
# ----------------------------------------------------------------------
#	arguments:
#		vSrvrName		virtual SQL server name
#	return:
#		InstanceName	Success
#		0				Instance Name is not available
#	NOTE:
#		This version is working only with named instances. 
#		Default name is not supported at BBTG with Virtual SQL Server
#		at this time.
# ----------------------------------------------------------------------
sub getSQLInst4VirtualSrvr ($) {
	my $srvrName		= shift;
	my $regSrvrRoot		= "//$srvrName/";
	my @instLst			= ();
	my $instName		= 0;
	my $instProxy		= '';
	my $returnInstName	= 0;
	my $keyName			= "";
	my $sqlVer			= "";
	my $x64flg			= 0;
	my $regValue = "";

	$x64flg = &chkx64($srvrName);
	my $x64process = isX64Process();
	if ($x64process || $x64flg != 1) {
		$keyName	= "${regSrvrRoot}LMachine/Software/Microsoft/Microsoft SQL Server/InstalledInstances";
		if (defined($Registry->{$keyName})) {
			@instLst = split('\0', $Registry->{$keyName});
			foreach $instName (@instLst) {
				$sqlVer = &getSqlVerReg($srvrName, $instName);
	
				if ($sqlVer =~ '^8\.') {
					# Check SQL 2000 version.
					$keyName = "${regSrvrRoot}LMachine/Software/Microsoft/Microsoft SQL Server/$instName/Cluster/ClusterName";
					if ($instName && defined($Registry->{$keyName}) && uc($Registry->{$keyName}) eq uc($srvrName) )  {
						$returnInstName = $instName;
						last;
					}
				} elsif ($sqlVer =~ /^(9|10)\./) {
					# Check SQL 2005 version.
					$keyName	= "${regSrvrRoot}LMachine/Software/Microsoft/Microsoft SQL Server/Instance Names/SQL/$instName";
					if (defined($Registry->{$keyName}) ) {
						$instProxy = $Registry->{$keyName};
						$keyName = "${regSrvrRoot}LMachine/Software/Microsoft/Microsoft SQL Server/$instProxy/Cluster/ClusterName";
						if ($instName && defined($Registry->{$keyName}) && uc($Registry->{$keyName}) eq uc($srvrName) )  {
							$returnInstName = $instName;
							last;
						}
					} # if defined instProxy
					# sqlVer 9x.
				} else {
					# Invalid SQL Server Version for cluster.
					$returnInstName = 0;
					last;
				} # switch $sqlVer
			} # foreach $instName
		} else {
			$returnInstName = 0;
		} # if defined LMachine/Software/Microsoft/Microsoft SQL Server/InstalledInstances
	}
	else {

		$keyName	= "HKLM\\Software\\Microsoft\\Microsoft SQL Server";
		$regValue = &T38lib::Common::regReadValExe("$keyName", "InstalledInstances", $srvrName);

		if ($regValue) {
			@instLst = split('\\\\0', $regValue);
		}

		foreach $instName (@instLst) {
			$sqlVer = &getSqlVerReg($srvrName, $instName);
			if ($sqlVer =~ /^(9|10)\./) {
				$keyName= "HKLM\\Software\\Microsoft\\Microsoft SQL Server\\Instance Names\\SQL";
				$instProxy = &regReadValExe("$keyName", "$instName", $srvrName);
	
				if ($instProxy) {
					$keyName= "HKLM\\Software\\Microsoft\\Microsoft SQL Server\\$instProxy\\Cluster";
					$regValue = &regReadValExe("$keyName", "ClusterName", $srvrName);
					if ($instName && uc($regValue) eq uc($srvrName)) {
						$returnInstName = $instName;
						last;
					}
				}
				else {
					$returnInstName = 0;
				}
			}
			else {
				$returnInstName = 0;
			}
		}
	}
	
	return ($returnInstName);

}	# getSQLInst4VirtualSrvr

#------------------------------------------------------------------------------
# 	Purpose: Get the port number form SQL server or an instence from REG
#
#	arguments:
#		srvrName		server machine name (Optional)
#		instanceName	SQL Server instance name. Default instance name
#						is NULL or MSSQLSERVER.
#	return:
#		PortNum		Success
#		0			Failure
# ----------------------------------------------------------------------
sub getSqlPort(;$$) {
	my $srvrName		= shift;
	my $instanceName	= shift;

	my $regSrvrRoot		= (!$srvrName || (uc($srvrName) eq uc(Win32::NodeName()))) ? "": "//$srvrName/";
	my $portNum	= 0;
	my $keyName	= "";

	$srvrName = Win32::NodeName()	if (!$srvrName || ($srvrName eq	'.') );

	$keyName = ($instanceName && uc($instanceName) ne uc(DEFAULT_MSINST_NM)) ?
		"${regSrvrRoot}LMachine/Software/Microsoft/Microsoft SQL Server/$instanceName/MSSQLServer/SuperSocketNetLib/Tcp":
		"${regSrvrRoot}LMachine/Software/Microsoft/MSSQLServer/MSSQLServer/SuperSocketNetLib/Tcp";

	if (defined($Registry->{$keyName}->{TcpPort})) {
		$portNum = $Registry->{$keyName}->{TcpPort};
	} 
	else {
		$portNum = 0;
	}

	return $portNum;
}

# ----------------------------------------------------------------------
#	getSqlVerReg	Get SQL Server Version from registry
# ----------------------------------------------------------------------
#	arguments:
#		srvrName		server machine name (Optional)
#		instanceName	SQL Server instance name. Default instance name
#						is NULL or MSSQLSERVER.
#	return:
#		VersionID	Success
#		0			Failure
# ----------------------------------------------------------------------
sub getSqlVerReg (;$$) {
	my $srvrName		= shift;
	my $instanceName	= shift;
	my $regSrvrRoot		= (!$srvrName || (uc($srvrName) eq uc(Win32::NodeName()))) ? "": "//$srvrName/";
	my $sqlVer	= 0;
	my $keyName	= "";

	SUB:
	{
		$srvrName = Win32::NodeName()	if (!$srvrName || ($srvrName eq	'.') );
		$keyName = ($instanceName && uc($instanceName) ne uc(DEFAULT_MSINST_NM)) ?
			"${regSrvrRoot}LMachine/Software/Microsoft/Microsoft SQL Server/$instanceName/MSSQLServer/CurrentVersion":
			"${regSrvrRoot}LMachine/Software/Microsoft/MSSQLServer/MSSQLServer/CurrentVersion";

		if (defined($Registry->{$keyName}->{CSDVersion})) {
			$sqlVer = $Registry->{$keyName}->{CSDVersion};
		} 
		elsif (defined($Registry->{$keyName}->{CurrentVersion})) {
			$sqlVer = $Registry->{$keyName}->{CurrentVersion};
		} 
		else {
			$sqlVer = 0;
			last SUB;
		}
		last SUB;
	}

	return ($sqlVer);
}	# getSqlVerReg

# ----------------------------------------------------------------------
#	getWinClusterName	Get Windows Cluster name from Registry
# ----------------------------------------------------------------------
#	arguments:
#		vSrvrName		virtual server machine name (Optional)
#	return:
#		ClusterName	Success
#		0			Not a cluster
# ----------------------------------------------------------------------
sub getWinClusterName (;$) {
	my $srvrName		= shift;
	my $regSrvrRoot		= (!$srvrName || (uc($srvrName) eq uc(Win32::NodeName()))) ? "": "//$srvrName/";
	my $clusterName		= 0;
	my $keyName			= "";

	$keyName = "${regSrvrRoot}LMachine/Cluster";
	$clusterName = $Registry->{$keyName}->{ClusterName}	if (defined($Registry->{$keyName}->{ClusterName}));

	return ($clusterName);
}	# getWinClusterName


# ----------------------------------------------------------------------
#	getWinClusterNodes		get node names for windows cluster
# ----------------------------------------------------------------------
#	arguments:
#		$clusterName	windows cluster name
#		\@clusNodes		list of cluster node names
#	return:
#		1			Success
#		0			Failure
# ----------------------------------------------------------------------
#	get node names for windows cluster
# ----------------------------------------------------------------------

sub getWinClusterNodes ($$) {
	my ($clusterName, $rClusNodes) = @_;
	my @clusOut	= ();
	my $machine	= '';
	my $i;
	my $status	= 1;
SUB:
{
	&notifyWSub("Started. Cluster Name: $clusterName");

	# Get list of physical nodes for target machines.
	
	@clusOut = `cmd.exe /C CLUSTER $clusterName node`;


	# Output for preferred nodes is:
	#
	# C:/.../InstallLinks>cluster dv02db node      
	# Listing status for all available nodes:      
	#                                              
	# Node           Node ID Status                
	# -------------- ------- --------------------- 
	# DS02DB02             2 Up                    
	# DS02DB01             1 Up                    
	# DS02DB04             4 Up                    
	# DS02DB03             3 Up                    

	# Remove blank lines from @clusOut.

	for ($i = 0; $i < scalar @clusOut;) {
		( $clusOut[$i] =~ /^\s*$/) ? splice (@clusOut, $i, 1) : $i++;
	}

	&notifyMe ("\n" . join('', @clusOut));
	unless (
		$clusOut[0] =~ /^Listing status for all available nodes:/i &&
		$clusOut[1] =~ /^Node\s+Node ID\s+Status/i &&
		$clusOut[2] =~ /^\-+/i
	) {
		&errme("There is problem with parsing output of the cluster command to get list of nodes for virtual server $clusterName.");
		$status = 0; last SUB;
	}
	for $i (3..$#clusOut) {
		$clusOut[$i] =~ /^\s*(\S+)\s+/;
		$machine = $1;
		if ($machine =~/^\S+$/) {
			push (@{$rClusNodes}, $machine);
		} else {
			&errme("Problem with parsing machine name for line $i: $clusOut[$i].");
		}
	}
	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# getWinClusterNodes


# ----------------------------------------------------------------------
#	getWinClusterRes		get list of resources in windows cluster group
# ----------------------------------------------------------------------
#	arguments:
#		$vsName			cluster virtual server name
#		\@resNames		list of resource names in cluster group
#		$clusterName	optional
#	return:
#		$clusterName		Success
#		0				Failure
# ----------------------------------------------------------------------
#	get list of resources in windows cluster group
# ----------------------------------------------------------------------

sub getWinClusterRes ($$;$) {
	my $vsName	= shift;
	my $rResNames = shift;
	my $clusterName	= shift;
	my @clusOut	= ();
	my $resName	= '';
	my $i;
	my $status	= 1;
SUB:
{
	&notifyWSub("Started. Cluster Name: $clusterName");

	$clusterName = &getWinClusterName($vsName)	if (!$clusterName);
	unless( $clusterName ) {
		&errme("Cannot get Cluster Name for virtual server $vsName.");
		$status = 0; last SUB;
	}

	# Get list of resources for a cluster
	
	@clusOut = `cmd.exe /C CLUSTER $clusterName resource`;


	# Output for resource is:
	#
	# C:/.../InstallLinks>cluster dv02db node      
	#
	# Listing status for all available resources:                            #
	#                                                                        #
	# Resource             Group                Node            Status       #
	# -------------------- -------------------- --------------- ------       #
	# Cluster IP Address   RVT1DB               RST1DB2         Online       #
	# Cluster Name         RVT1DB               RST1DB2         Online       #
	# RVT1DB Quorum        RVT1DB               RST1DB2         Online       #
	# MSDTC                RVT1DB               RST1DB2         Online       #
	# RVT1DB1 Disk         RVT1DB1              RST1DB2         Online       #
	# SQL Network Name (RVT1DB1) RVT1DB1              RST1DB2         Online #
	# SQL IP Address 1 (RVT1DB1) RVT1DB1              RST1DB2         Online #
	# SQL Server (TSQ9)    RVT1DB1              RST1DB2         Online       #
	# SQL Server Agent (TSQ9) RVT1DB1              RST1DB2         Online    #
	# SQL Server Fulltext (TSQ9) RVT1DB1              RST1DB2         Online #
	# t38bkp.RVT1DB1       RVT1DB1              RST1DB2         Online       #
	# t38mdf.RVT1DB1       RVT1DB1              RST1DB2         Online       #
	# t38ndf.RVT1DB1       RVT1DB1              RST1DB2         Online       #
	# t38ldf.RVT1DB1       RVT1DB1              RST1DB2         Online       #
	# t38trc.RVT1DB1       RVT1DB1              RST1DB2         Online       #
	# t38tmp.RVT1DB1       RVT1DB1              RST1DB2         Online       #
	# t38sys.RVT1DB1       RVT1DB1              RST1DB2         Online       #
	# t38app80.RVT1DB1     RVT1DB1              RST1DB2         Online       #

	# Remove blank lines from @clusOut.

	for ($i = 0; $i < scalar @clusOut;) {
		( $clusOut[$i] =~ /^\s*$/) ? splice (@clusOut, $i, 1) : $i++;
	}

	&notifyMe ("\n" . join('', @clusOut));
	unless (
		$clusOut[0] =~ /^Listing status for all available resources:/i &&
		$clusOut[1] =~ /^Resource\s+Group\s+Node\s+Status/i &&
		$clusOut[2] =~ /^\-+/i
	) {
		&errme("There is problem with parsing output of the cluster command to get list of nodes for virtual server $clusterName.");
		$status = 0; last SUB;
	}
	for $i (3..$#clusOut) {
		if ($clusOut[$i] =~ /^\s*(\S.*\S)\s+$vsName\s+\S+\s+\S+\s*\n/i) {
			$resName = $1;
			push (@{$rResNames}, $resName);
		}
	}
	$status = $clusterName;
	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# getWinClusterRes



#------------------------------------------------------------------------------
#	Purpose: Expand command line arguments
#
#	Input: 	Command line argument as an array
#	Output: Expand command line argument and an array of the expanded 
#			command line arguments
#			If globbing expand to nothing then return $T38ERROR="__T38ERROR__"
#			
#------------------------------------------------------------------------------
sub globbing(\@) {
	my @cmdLine = @_;				# Get the input parameters

	my @argv= ();					# Variable to hold all the globbing results

	foreach (@cmdLine) {
    	if (/^['"](.*)["']$/) {
        	push @argv, $1;
    	} elsif (!/[*?]/) {
        	push @argv, $_;
    	} else {
        	push @argv, glob $_;
    	}
	}
	
	if ( defined (@argv) ) {		# if globbing produce any result then
		return @argv;				# the result
	}
	else {
		$argv[0]=$T38ERROR;			# No result from globbing
		return @argv;				# Return $T38ERROR
	}

}	# End of globbing

# ----------------------------------------------------------------------
# logEvent -- log an event in Windows NT Event Log.
# ----------------------------------------------------------------------
#	arguments:
#		$errtype	Info, Warn or Error.
#		$errmsg		Error message text.
#		$eventcode	Optional parameter: started or done.
#	return:
#		1		Success
#		0		Failure
# ----------------------------------------------------------------------
sub logEvent ($$;$) {
use Win32::EventLog;
	my ($errtype, $errmsg, $eventcode) = @_;
	my $logEventStat	= 0;
	my $eventLog;
	my $appname	= &stripPath($0);
	my $data	= "";

	my $eventype 	=
			($errtype =~ m/Info/i) ? EVENTLOG_INFORMATION_TYPE :
			($errtype =~ m/Warn/i) ? EVENTLOG_WARNING_TYPE :
			EVENTLOG_ERROR_TYPE;
	my $eventId	=
			($eventcode eq 'started') ? 9001 :
			($eventcode eq 'done') ? 9002 :
			9000;
no strict 'subs';
	my %event=(
		'Category',  NULL,
		'Source', $appname,
		'Computer', '',
		'Length', length($data),
		'RecordNumber', NULL,
		'TimeGenerated', NULL,
		'Timewritten', NULL,
		'EventID', $eventId,
		'EventType', $eventype,
		'ClosingRecordNumber',NULL,
		'Strings',$errmsg,
		'Data',$data,
	);
use strict 'subs';
SUB:
{
	&notifyMe ("($appname:$errtype): $errmsg");
	unless ($eventLog = Win32::EventLog->new("Application")) {
		warn("Cannot open Event Log. $!"); carp("Called");
		$logEventStat = 0;
		last SUB;
	}
	unless ($eventLog->Report(\%event)) {
		warn("Cannot write to Application Event Log. $!"); carp("Called");
		$logEventStat = 0;
		last SUB;
	}
	$logEventStat = 1;
	last SUB;
}	# SUB
# ExitPoint:

	$eventLog->Close();
	return($logEventStat);

}	 # End of logEvent

#------------------------------------------------------------------------------
# Purpose: 	Log messages to a log file.  Log file name is the name of the 
#			program with an extension of log.
#			Example:
#					Program Name: 	T38instl.pl
#					Log File Name:	T38instl.log
#
#		Input Parameter: Message
#		Output Parameter: None
#------------------------------------------------------------------------------
sub notifyMe($) {
	my ($msg) = shift;			# Get the input parameter
   	my ($log);
	my ($logFileName);

	# open the log file

	$logFileName = &T38lib::Common::getLogFileName($0);
	 
	croak "[notifyMe]: Cannot open file $logFileName" 
		unless (open(LOG,">>$logFileName"));

	my($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) 
		= localtime(time);

	print "$msg\n";
	$log = sprintf ("%02d/%02d/%04d %02d:%02d - %s\n", 
		$mon+1, $mday, $year+1900, $hour, $min, $msg);
	print LOG $log;

  	close(LOG);

}	# End  of notifyMe

###	notifyWSub -- calls packaged notifyMe with callers suproutine name.
#
# ----------------------------------------------------------------------
#	arguments:
#		$msg		Message text.
#		$eventcode	Optional parameter: started or done.
#	return:
#		none
# ----------------------------------------------------------------------
sub notifyWSub ($;$){
	my $txt	= shift;
	my $lvl	= shift;

	unless ($lvl) { $lvl = 1;}
	my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask)
			 = caller($lvl);
	$subroutine =~ s/^${package}:://;
	&notifyMe("[$subroutine]: $txt");

} 	# End of notifyWSub


###	logme -- issue an informative message
# ----------------------------------------------------------------------
#	arguments:
#		$msg		Message text.
#		$eventcode	Optional parameter: started or done.
#	return:
#		none
# ----------------------------------------------------------------------
sub logme ($;$){
	my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask)
			 = caller(1);
	$subroutine =~ s/^${package}:://;
	logEvent("Info", "[$subroutine]: $_[0]", $_[1]);

}	# End of logme


###	warnme -- issue a warning message
# ----------------------------------------------------------------------
#	arguments:
#		$msg		Message text.
#		$eventcode	Optional parameter: started or done.
#	return:
#		none
# ----------------------------------------------------------------------
sub warnme ($;$){
	my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask)
			 = caller(1);
	$subroutine =~ s/^${package}:://;
	logEvent("Warn", "[$subroutine]: $_[0]", $_[1]);

} 	# End of warnme

###	errme -- issue an error message
# ----------------------------------------------------------------------
#	arguments:
#		$msg		Message text.
#		$eventcode	Optional parameter: started or done.
#	return:
#		none
# ----------------------------------------------------------------------
sub errme ($;$){
	my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask)
			 = caller(1);
	$subroutine =~ s/^${package}:://;
	logEvent("Error", "[$subroutine]: $_[0]", $_[1]);

} 	# End of errme

#------------------------------------------------------------------------------
# 	Purpose:	
#
# 	Input:	Server Name
# 	Output: 	0 ping successful
# 				1 ping failed
# 				$T38ERROR = __T38ERROR__ Ping utility not found 
# 				or any other unexpected error
#
#------------------------------------------------------------------------------
sub pingServer($) {
	my $serverName = shift;

	my ($pingUtil);
	my ($ping) = "ping.exe";
	my	$pingResult;
	my ($rtnStatus) = 0;

	BLOCK: {	# Start of BLOCK

		if ( ($serverName eq "") or (! defined($serverName)) ) {
			$rtnStatus = $T38ERROR;			
			last BLOCK;
		}

		$pingUtil	= &T38lib::Common::whence($ping);
		unless ($pingUtil) {
			$rtnStatus = $T38ERROR;			
			last BLOCK;
		}
		
		$pingResult = qx(ping -n 2 $serverName);

		if ($pingResult =~ /Request Timed Out/i) {
			$rtnStatus = 1;
			last BLOCK;
		}

		if ($pingResult =~ /TTL Expired in Transit/i) {
			$rtnStatus = 1;
			last BLOCK;
		}

		if ($pingResult =~ /Destination Host Unreachable/i) {
			$rtnStatus = 1;
			last BLOCK;
		}

		if ($pingResult =~ /Ping request could not find host/i) {
			$rtnStatus = 1;
			last BLOCK;
		}

	} # End of BLOCK

	return ($rtnStatus);

}	# End of pingServer

###	parseProgramName --  Parse program name.
# ----------------------------------------------------------------------
#	arguments:
#		None
#	return:
#		programPath		program directory path
#		programName		base name of the program, without extension
#		programSuffix	program suffix
#
#	Example 1: command line perl tester.pl, executed in 
#	C:/DBMS/t38app80, returns 
#		('C:\DBMS\t38app80\', 'tester', '.pl')
#	Example 2: command line tester.exe, executed in 
#	C:/DBMS/t38app80, returns 
#		('C:\DBMS\t38app80\', 'tester', '.exe')
#	Example 3: command line perl ../t38app80/tester.pl
#	executed in C:/DBMS/t38app80, returns
#		('..\t38app80\', 'tester', '.pl')
#	Example 4: command line perl //$computername/t38app80/tester.pl
#	executed on LAP-TSMRRL-NTW computer, returns
#		 ('\\LAP-TSMRRL-NTW\t38app80\', 'tester', '.pl')
# ----------------------------------------------------------------------
sub parseProgramName() {
	my $execFullName;
	my @suffixList	= ('.pl', '.exe');
	my $currentDir	= ".";			# Current program directory.
	my $programName	= "";			# Base name of the current script.
	my $programPath	= ".\\";		# Directory path to current script.
	my $programSuffix	= ".pl";		# Script suffix.

	$currentDir = Cwd::getcwd();
	$execFullName = $0;
	if ($execFullName !~ /^\\|\/|.:/) { $execFullName = "$currentDir" . "\\" . "$execFullName"; }
	$execFullName =~ s|\\|/|g;	# since fileparse does not understand WinNT OS, it assumes UNIX.
	($programName, $programPath, $programSuffix) = fileparse($execFullName, @suffixList);
	$programPath =~ s/\//\\/g;		# Convert UNIX path delimiters back to DOS
	$programPath =~ s/\\.\\/\\/g;	# Remove redundant directories.
	return ($programPath, $programName, $programSuffix);

} 	# End of parseProgramName

#------------------------------------------------------------------------------
#	Purpose: Read values from a section of an ini file
# 
#	Input: 	ini file name, section name, key
#
#	Output:	Return Value of the key if no ERROR				
#	In case of an ERROR
#			Return section name if section name is not found in the ini file
#			Return key if the key is not found in the ini file
#			Return key if the key is there but there no value assign to the key
#
#------------------------------------------------------------------------------
sub readINI($$$) {
	my ($iniFileName, $secName, $key) = @_;			# Get the input parameter
	my $secNameWithBracket;
	my $secFound=0;
	my $a=undef;
	my $b=undef;
	my $keyValue=undef;

	# Add brrackets to section name 
	# Section are define using brackets in ini file.
	#
	$secNameWithBracket = "[" . $secName . "]";

	# Open the ini file for reading.
	#
  	unless	(open(INI, "<$iniFileName")) {
		&notifyWSub("Can not open file: $iniFileName in T38lib::Common::readINI");
		&notifyWSub("Continue to wait for the file created by setupsql.exe ....");
		return;
	}

	SUB:
	{
		while (<INI>) {
			chomp;		# Get rid off new line character
			$_ = stripWhitespace($_);
			if ( ($_ eq $secNameWithBracket) && ( $secFound == 0) ) {
				$secFound = 1;
				next;
			}
			if ( $secFound == 1 ) {
				if ( /\[\w+\]/ ) {
					$keyValue=$key;
					last SUB;
				}
				else {
					$a=$_;
					$a=~s/=.*$//;
					if ( $a eq $key ) {
						$b = $_;
						$b=~s/\w+=//;
						$keyValue = $b;	
						last SUB;
					}
					else {
						next;
					}
				}
			}
		} # end of while 
	} # end SUB

# Close the ini file
#
	close(INI);	

# if Section name is not found return section name
# if key not found return key
# if found return the value of the key. 
#
	if ( defined ($keyValue) ) {
		return $keyValue;
	}
	else {
		( $secFound == 0 ) ? return $secName : return $key;
	}

}	# End of readINI

#------------------------------------------------------------------------------
# 	Purpose: 	Reboot the local machine. Countdown 10 sec.
#
# 	Input		None
# 	Output:		None
#
#------------------------------------------------------------------------------
sub rebootLocalMachine() {
	Win32::InitiateSystemShutdown(undef,                 		# local machine
                              	"Rebooting...",					# message
                              	10,                     		# 10 seconds
                              	1,                     			# force apps
                              	1)                     			# reboot
					or carp "[T38lib::Common::rebootLocalMachine] InitiateSystemShutdown failed.";
#sleep 3;
#Win32::AbortSystemShutdown(undef)
#        or carp "[T38lib::rebootLocalMachine] AbortSystemShutdown failed.";

}	# End of rebootLocalMachine


# ----------------------------------------------------------------------
#	regReadValExe		read value from the registry on x64 machine
# ----------------------------------------------------------------------
#	arguments:
#		$regTree
#		$regValueName
#		$machine		Optional machine name
#	return:
#		$regValue	
#			string	Success
#			0		Fail
# ----------------------------------------------------------------------
#	read value from the registry on x64 machine
# ----------------------------------------------------------------------

sub regReadValExe ($$;$) {
	my $regTree			= shift;
	my $regValueName	= shift;
	my $machine			= shift;
	my $keyName			= '';
	my $procArch		= '';
	my $sysRoot			= '';
	my $oscmd			= '';
	my $osout			= '';
	my $regValue	= 0;
SUB:
{
	$machine = Win32::NodeName()	if (!$machine || ($machine eq	'.') );
	&notifyWSub("Started. Read registry value \\\\$machine\\$regTree\\$regValueName");

	# First, verify that remote server and current machine have same processor architecture.
	$keyName	= "LMachine/System/CurrentControlSet/Control/Session Manager/Environment/PROCESSOR_ARCHITECTURE";
	$procArch = (defined($Registry->{$keyName})) ? $Registry->{$keyName} : '';

	$keyName	= "//$machine/LMachine/System/CurrentControlSet/Control/Session Manager/Environment/PROCESSOR_ARCHITECTURE";
	unless ( $procArch && ( uc($procArch) eq uc($Registry->{$keyName}) ) ) {
		&errme("Processor architecture $procArch for local machine does not match $machine. Cannot run reg.exe from remote server.");
		$regValue = 0; last SUB;
	}

	$keyName	= "//${machine}/LMachine/Software/Microsoft/Windows NT/CurrentVersion/SystemRoot";
	if (defined($Registry->{$keyName})) {
		$sysRoot = $Registry->{$keyName};
	} else {
		&errme("Registry value $keyName is unaccessible.");
		$regValue = 0;
		last SUB;
	}

	$sysRoot =~ s/^([A-Z]):/$1\$/i;
	$sysRoot =~ s/[\\\/]$//;
	$oscmd = "\\\\$machine\\$sysRoot\\system32\\reg.exe";

	$oscmd .= " query \"\\\\$machine\\$regTree\" /v $regValueName";
	$osout = `$oscmd`;
	if ($osout =~ /$regValueName\s+REG_\S+\s+(\S.*)\s*\n/i) {
		$regValue = $1;
		$regValue = &stripWhitespace($regValue);
	} else {
		&errme("Failed to run $oscmd.\n$osout");
		$regValue = 0; last SUB;
	}

	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Result: $regValue.");
	return($regValue);
}	# regReadValExe


# ----------------------------------------------------------------------
#	runOSCmd		Run OS Command
# ----------------------------------------------------------------------
#	arguments:
#		$oscmd	operating system command to execute
#		$osout	(optional) reference for output file name
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	Run OS Command and stores results in file name provided by osout.
#	If $osout is not provided, local variable is used and file name is
#	created based on log file directory name.
#	If reference to $osout is specified, but value is 0, file name is
#	created based on log file directory name and stored in $$osout so
#	calling subroutine can use it.
# ----------------------------------------------------------------------

sub runOSCmd ($;$) {
	my $oscmd	= shift;
	my $osout	= shift;
	my $myosout	= '';
	my $status	= 1;
	my $result	= 0;
	my ($logFileName, $lfbase, $logFilePath, $lftype);


SUB:
{
	&notifyWSub("Running OS Command: $oscmd");

	$osout = \$myosout	unless ($osout);	# If osout is not provided as argument, set it to local variable. 
	unless ($$osout) {
		$logFileName = &T38lib::Common::getLogFileName($0);
		fileparse_set_fstype("MSWin32");
		($lfbase, $logFilePath, $lftype) = fileparse($logFileName, '\.[^\.]*');
		$$osout	= $logFilePath . "$lfbase\.osout";
	}

	$result = system("cmd /E:on /C \"$oscmd\" > $$osout 2>\&1");
	if ( $result != 0 ) {
		$status = 0;
		&errme("Problem running OS Command. Result code is $result.");
		unless (open OSOUT, "<$$osout") {
			&errme("Cannot open $$osout for reading.");
			last SUB;
		}
		&notifyWSub("Output is:");
		while (<OSOUT>) { &notifyWSub($_); };
		close(OSOUT);

		last SUB;
	}
	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# runOSCmd


#------------------------------------------------------------------------------
#	Purpose: To run sql from a given file or command line sql, once the 
#			 sql is run successfully check for sql error(s). If no error
#			 return 0, in case of an error return 1.
#
#	Input Argument: 
#		A file name that have the SQL to run. Example: getDevices.sql
# 		or the one line SQL, Example: "select @@version"
#
# 	Optional parameters: 
# 		Server Name (SQL Server name, default local machine)
#
# 		Database Name
#
# 		Output file Name Default is inputfilename.out 
#		In case of a command line query use a unique temp file name.
#
# 		User name (example, sa)
# 		Password  (example, XXXXXX);
#			if user and password is not provided then use
#			trusted connection option -E
#
#		Severity level, default 11
#
# 		More command (example, -b)
#		Verify that the command line options are valid
#
#		Add More error code to the Include Err list
#		pass an ref to an array 
#
#		Add More error code to the Exclude Err list
#		pass a ref to an array
#
#		Force Headers on
#
#	Output:
#		Return Status, 0 no error, 1 error(s).
#
#	Examples:
#		1) Run SQL commands from $sql variable on $gSrvrName server in $dbname database.
#		   Store results in $outtmp file. Path references to empty arrays for include and
#		   Exclude errors. Force printing of the headers.
#		$subresult = &runSQLChk4Err($sql, $gSrvrName, $dbname, $outtmp, "", "", "", "", [], [], 1);
#		
#		2) Run SQL commands from $sql variable on $gSrvrName server in $dbname database.
#		   Store results in $outtmp file. Path reference to array with include error 5000,
#		   and empty array for exclude errors. Force printing of the headers.
#		$subresult = &runSQLChk4Err($sql, $gSrvrName, $dbname, $outtmp, "", "", "", "", [5000], [], 1);
#
#------------------------------------------------------------------------------
sub runSQLChk4Err($;$$$$$$$\@\@$) {
	my ($sqlscript, $srvr, $dbname, $sqlout, $usr, $pw, $lowersev, $morecmd, $Inc, $Exc, $headersOnFlg) = @_;

	my ($status, $systemStatus, $processID) = 0;
	my ($outfile, $isql, $err, $sev, $tmpFN, $errFN, $opt)  = "";
	my (@morecmdArray) = ();	
	my (%xErr, %iErr) = ();	
	my ($nodeName);
	my %sqlOptions = ();
	my ($logFileName, $base, $logFilePath, $type, $i, $nvals);

	# Hash of osql valid options. This hash is used to validate 
	# osql option(s) given by the user.
	#

	if ( $gisqlBin == 2 ) {
		$isql = "sqlcmd -h-1 -w2048";
	
	}
	else {
		if ( $gisqlBin == 0 ) {
			$isql = "isql -h-1 -n -w2048";
		#
		# SQL 6.5 isql options
		#
			%sqlOptions=("-U" => "loginid",
						 "-e" => "echoinput",
						 "-p" => "printstatistics",
						 "-n" => "removenumbering",
						 "-c" => "cmdend",
						 "-w" => "columnwidth",
						 "-s" => "colseparator",
						 "-m" => "errorlevel",
						 "-t" => "querytimeout",
						 "-l" => "logintimeout",
						 "-L" => "listservers",
						 "-a" => "packetsize",
						 "-H" => "hostname",
						 "-P" => "password",
						 "-q" => "cmdlinequery",
						 "-Q" => "cmdlinequeryandexit",
						 "-S" => "server",
						 "-d" => "usedatabasename",
						 "-r" => "msgstostderr",
						 "-E" => "trustedconnection",
						 "-o" => "outputfile",
						 "-b" => "onerrorbatchabort" );
		}
		# SQL 7.0 and above osql options
		else {
			$isql = "osql -h-1 -n -w2048";
				%sqlOptions=("-U" => "loginid",
							"-P" => "password",
							"-S" => "server",
							"-H" => "hostname",
							"-E" => "trustedconnection",
							"-d" => "usedatabasename",
							"-l" => "logintimeout",
							"-t" => "querytimeout",
							"-h" => "headers",
							"-s" => "colseparator",
							"-w" => "columnwidth",
							"-a" => "packetsize",
							"-e" => "echoinput",
							"-I" => "enablequotedidentifiers",
							"-L" => "listservers",
							"-c" => "cmdend",
							"-D" => "odbcdsnname",
							"-q" => "cmdlinequery",
							"-Q" => "cmdlinequeryandexit",
							"-n" => "removenumbering",
							"-m" => "errorlevel",
							"-r" => "msgstostderr",
							"-V" => "severitylevel",
							"-i" => "inputfile",
							"-o" => "outputfile",
							"-p" => "printstatistics",
							"-b" => "onerrorbatchabort" );
		}
	}

	# Check if headers should be turned on.

	if ($headersOnFlg) {
		$isql .= " -h+1";
	}

	# Use server name if provided. if the server is . (period) 
	# then replace the period with local machine.
	#
	if ($srvr) {
		$nodeName = Win32::NodeName();
		$srvr =~ s/^\./$nodeName/;
		$srvr =~ s|/|\\|g;
		$isql .= " -S$srvr";
		delete $sqlOptions{"-S"};
		delete $sqlOptions{"-h"};
		delete $sqlOptions{"-n"};
		delete $sqlOptions{"-w"};
	}
	else {
		delete $sqlOptions{"-h"};
		delete $sqlOptions{"-n"};
		delete $sqlOptions{"-w"};
	}

	# If database name is given then add that to isql command
	#
	if ($dbname) {
		$isql .= " -d$dbname";
		delete $sqlOptions{"-d"};
	}

	# if user and password is provided add these 
	# to osql command else use -E option for trusted
	# connection
	#
	if ( ($usr) and  ($pw) ) {							
		$isql .= " -U$usr -P$pw";
		delete $sqlOptions{"-U"};
		delete $sqlOptions{"-P"};
	} 
	else {
		$isql .= " -E"; 
		delete $sqlOptions{"-E"};
	}

	# get the log file name which will give us the directory 
	# where log file is and use that directory to create
	# any temp files

	$logFileName = &T38lib::Common::getLogFileName($0);
	fileparse_set_fstype("MSWin32");
	($base, $logFilePath, $type) = fileparse($logFileName, '\.[^\.]*');

	# Set the error out file name.

	$processID = $$;
	$errFN = $logFilePath . "err$processID.out";
	while ( -s $errFN ) {
		$processID += 1;
		$errFN = $logFilePath . "err$processID.out";
	}

	# Check if the input file is provided or a command line query by
	# checking the existing of the file.
	# If file found set the osql string with the -i input file option
	# else -Q command line query
	#
	if (-s "$sqlscript" ) {
		$isql .= " -i \"$sqlscript\"";
		delete $sqlOptions{"-i"};
		($tmpFN = $sqlscript) =~s/\.\w*$/\.out/;				
		$outfile = ($sqlout) ? $sqlout : $tmpFN;
		$outfile = $outfile . ".out" if ( $sqlscript eq $outfile);
	}
	else {
		$isql .= " -Q \"$sqlscript\"";
		$processID = $$;
		$tmpFN = $logFilePath . "tmp$processID.out";

		while ( -s $tmpFN ) {
			$processID += 1;
			$tmpFN = $logFilePath . "tmp$processID.out";
			$tmpFN = "tmp$processID.out";
		}
		$outfile = ($sqlout) ? $sqlout : $tmpFN;
		delete $sqlOptions{"-Q"};
		delete $sqlOptions{"-q"};
	}

	if ($outfile !~ /^\\|.:/) { 
	
		# Set the output file name using -o option
		#
		$outfile = $logFilePath . "$outfile";
	}

	$isql .= " -o \"$outfile\"";
	delete $sqlOptions{"-o"};

	# Validate the additional isql options provided
	# by the user and add them to isql/osql command line.
	# Do not duplicate command line arguments
	#
	if ($morecmd) {
		@morecmdArray = split /\-/, $morecmd;
		foreach $opt (@morecmdArray) {
			$opt = &stripWhitespace($opt);
			$opt = '-' . $opt;
			if ($sqlOptions{substr($opt,0,2)}) {
				$isql .= " $opt";
				delete $sqlOptions{substr($opt,0,2)};
			}
		}
	}

# For debugging 
#	print "$isql \n";

	unlink($errFN);
	unlink ($outfile);
	$systemStatus = (system("$isql > $errFN 2>&1") == 0);

	# possible severity values are
	#	 0 - 10 are informational
	#	11 - 16 are user generated
	#	17 - 19 are hardware issues
	#	20 - +  are system fatal errors

	BLOCK: {	# Start of BLOCK

		# if some thing went wrong with the system command
		# then set the status to 1 and exit the block
		#
		if (!$systemStatus) {
			&notifyWSub("System commad failed: $isql");
			&notifyWSub("Review the $errFN for errrors.");
			$status = 1;
			last BLOCK;
		}

		# Lowest severity level that we will report on.
		# if provided as an input parameter, default is 11
		#
		$lowersev = ($lowersev) ? $lowersev : 11;		

		# For debugging 
		# print "Checking for error in $outfile with lowest severity level $lowersev\n";

		# errors we're not interested in
		%xErr = (219 => 219, 1104 => 1104, 2540 => 2540, 
		         15023 => 15023, 15024 => 15024, 15025 => 15025, 
					15026 => 15026, 15027 => 15027, 15028 => 15028, 
					15029 => 15029, 15030 => 15030, 15031 => 15031, 
					15032 => 15032, 15034 => 15034);	

		# Error we always want to include regardless of sev. level.
		%iErr = ();		

		# Add any include error provided as a parameter to the sub
		#
		if (defined ($Inc) ) {
			$nvals = scalar @{$Inc};
			if ( $nvals > 0 ) {
				for $i (0..$nvals-1) {
					if (! (defined ($iErr{$$Inc[$i]})) ) {
						$iErr{$$Inc[$i]} = $$Inc[$i];
					}
				}
			}
		}

		# Add any exclud3 error provided as a parameter to the sub
		#
		if (defined ($Exc) ) {
			$nvals = scalar @{$Exc};
			if ( $nvals > 0 ) {
				for $i (0..$nvals-1) {
					if (! (defined ($xErr{$$Exc[$i]})) ) {
						$xErr{$$Exc[$i]} = $$Exc[$i];
					}
				}
			}
		}

		# Open the output file to check for errors
		#
		unless (open(ERRFILE, $outfile)) { 
			&notifyWSub("Can not open file : $outfile");
			$status = 1;
			last BLOCK;	
		}
			# Parse the file to see for any sql generated errors.
			#
			foreach (<ERRFILE>)	{
				chomp();
				if ( /^$/) {
					next;
				}
				
				# Check for deadlocked condition
				#
				if (/deadlocked/i) {
					$status = 1;
					last BLOCK;
				}
	
				# Check for Msg messages and evaluate with exclude
				# and include error list. 
				# Set status accordingly.
				#	
				if (m/Msg\s* (\d+),\s* Level\s*(\d+),/i) {
					($err, $sev) = ($1, $2);
					if ( (($sev >= $lowersev) || (defined ($iErr{$err}))) and (!defined ($xErr{$err})) ) {
						&notifyWSub("Msg $err, Level $sev found");
						$status = 1;
						last BLOCK;	
					} 
				}
			}

		} # End of BLOCK

	close(ERRFILE);
		
	# In case of a command line sql program creates a tmp file
	# delete this tmp file
	#
	if ( ($outfile =~ /tmp$processID\.out/) and ($status==0) ) {
		unlink($outfile);
	}
	if ($status == 0) {
		unlink($errFN);
	}
	
	return ($status);

}	# End of runSQLChk4Err

#------------------------------------------------------------------------------
# Purpose:		Send messages to SQL Monitor tool.
#
#	Input:		Error Level, Application Name, Actual Message to log 
#	Output:		Status 0 OK, 1 Fail	
#
#------------------------------------------------------------------------------
sub sendMsg2Monitor ($$$) {
	my($errLevel, $appName, $msg) = @_;

	my ($errType, $itoSeverity, $dateStr, $cmd);
	my ($rtnStatus, $fileFound, $cmdStatus) = (0,0,0);
	my $cur_time=time();
	my($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($cur_time);
	my ($monitorName) = "opcmsg.exe";

	BLOCK: {

	# Validate Parametes
	#
		if ( ($appName eq "") or ($msg eq "") ) {
			$rtnStatus = 1;			# Status Fail
			last BLOCK;
		}

		$year += 1900;
		$mon += 1;
		$dateStr = sprintf("%02d/%02d/%04d %02d:%02d:%02d", $mon, $mday, $year, $hour, $min, $sec);

	# If the error level is out of range set it to 2, which
	# is the default error level
	#
		if ( ($errLevel > 3) or ($errLevel < 0)  or ($errLevel eq "") ) {
			$errLevel = 2;
		}

	# Set errType, depending upon errLevel
	#
		SWITCH: {

			if ($errLevel == 0) { $errType = "abort";	last SWITCH; }
			if ($errLevel == 1) { $errType = "error";	last SWITCH; }
			if ($errLevel == 2) { $errType = "warn"; 	last SWITCH; }
			if ($errLevel == 3) { $errType = "note"; 	last SWITCH; }
	
		} # End SWITCH

	# Set itoSeverity, depending upon errLevel
	#
	SWITCH: {

		if ($errLevel == 0) { $itoSeverity = "critical";	last SWITCH; }
		if ($errLevel == 1) { $itoSeverity = "major";		last SWITCH; }
		if ($errLevel == 2) { $itoSeverity = "minor"; 		last SWITCH; }
		if ($errLevel == 3) { $itoSeverity = "normal"; 		last SWITCH; }

	} # End SWITCH

		$msg = $dateStr . " " . $errType . " (" . $appName . ") " . $msg;

		$fileFound	= &T38lib::Common::whence($monitorName);
		unless ($fileFound) {
			&T38lib::Common::warnme("Can not find $monitorName file.");
			$rtnStatus = 1;			# Status Fail
			last BLOCK;
		}

		$cmd = "$monitorName application=T38ALERT msg_grp=BBY_T38 object=sendMsg2Monitor severity='$itoSeverity' msg_text='$msg'";
	
		$cmdStatus = system($cmd);
		if ($cmdStatus != 0 ) {
			&T38lib::Common::warnme("$cmd\nfailed using system call");
			$rtnStatus = 1;			# Status Fail
			last BLOCK;
		}
	} # End of BLOCK

	return $rtnStatus;

} # End of sendMsg2Monitor

#------------------------------------------------------------------------------
# Purpose: Set isql Binary, either use OSQL or ISQL so we can ran this on 
# 			  SQL 6.5, On SQL 6.5 server the perl program using this module should
# 			  call this function to set it to isql.
# 			  Since osql does not work on 6.5 servers.  Default is Osql.
#
# Input:	  Isql Binary name, either OSQL or ISQL or SQLCMD
# Output:  Return the status: 
#				   1 = Successfully start the service
#				   0  = Failed to start the service
#------------------------------------------------------------------------------
sub setIsqlBin($) {
	my $isqlBinaryName = shift;					# OSQL or ISQL

	my $rtnStatus = 1;

	$isqlBinaryName = &stripWhitespace($isqlBinaryName);
	$isqlBinaryName = lc($isqlBinaryName);

	BLOCK: {
		if ( ($isqlBinaryName ne "osql") and ($isqlBinaryName ne "isql") and ($isqlBinaryName ne "sqlcmd") ) {
			$rtnStatus = 0;
			last BLOCK;
		}

		if ( $isqlBinaryName eq "isql" ) {
			$gisqlBin=0; 					# gisqlBin=1 means use osql, 0 means use isql
			last BLOCK;
		}
		if ( $isqlBinaryName eq "sqlcmd" ) {
			$gisqlBin=2; 					# gisqlBin=1 means use osql, 0 means use isql , 2 means sqlcmd
			last BLOCK;
		}

	} # End of BLOCK
	&notifyWSub("SQL Command Set is (1 =osql, 0 = isql , 2 = sqlcmd) : $gisqlBin");
	return($rtnStatus);

} # End of setIsqlBin

#------------------------------------------------------------------------------
# Purpose: Start a given service.
#		Input:	Service Name, Server Name (Optional)
#		Output:	Return the status: 
#				1 = Successfully start the service
#				0 = Failed to start the service
#------------------------------------------------------------------------------
sub startService($;$) {
	my ($service_name, $Machine) = @_;					# Service name to start

	my (%serviceList, %serStatus);
	my $found = my $cnt = my $status = my $state = 0;

	my ($key, $value);
	my $SERVICE_TIMEOUT = 1000;					# Time out value for starting/stopping services

	if ($Machine eq "") {
		$Machine = Win32::NodeName(); 				# Get the machine name
	}

	&notifyWSub("Starting Service Name: $service_name");

	if (! Win32::Service::GetServices($Machine, \%serviceList) ) {
		carp "** ERROR **  [T38list::Common::startService]: Win32::Services::GetServices failed.";
		return ($status=0);
	}

	while (($key,$value) = each(%serviceList)) {
		if ( (lc($value)) eq (lc($service_name)) ){
			$found = 1;		# Found the service;
			last;			# Terminate the While loop (No need to search any more).
		}
	}

	if ( $found == 0 ) {
		carp "** ERROR **  [T38lib::Common::startService] $service_name is not a valid service on $Machine.";
		return ($status=0);
	}

# Get the Service status
# serStatus{'CurrentState'} = 1 Stopped
# serStatus{'CurrentState'} = 4 Running
# serStatus{'CurrentState'} = 7 Pause

	if ( ! Win32::Service::GetStatus($Machine, $service_name, \%serStatus) ) {
		carp "** ERROR **  [T38lib::Common::startService]: Win32::Service::GetStatus failed.";
		return ($status=0);
	}

	if ( $serStatus{'CurrentState'} == 1 ) {
		if ( ! Win32::Service::StartService($Machine, $service_name) ) {
			carp "** ERROR ** [T38lib::Common::startService]: Win32::Service::StartService failed.";
			return ($status=0);
		}
		else {
			while ( $state != 4 ) {
				if ($cnt > $SERVICE_TIMEOUT) {
					carp "** ERROR ** [T38lib::Common::startService]: $service_name service startup timed out.";
					$status = 0;
					last;
				}
				sleep 10;
				$cnt=$cnt+10;

				if ( ! Win32::Service::GetStatus($Machine, $service_name, \%serStatus) ) {
					carp "** ERROR **  [T38lib::Common::stopService]: Win32::Service::GetStatus failed.";
				}
				$state = $serStatus{'CurrentState'};
			}
			if ( $state == 4) {
				$status = 1;
			}
			else {
				carp "** ERROR **  [T38lib::Common::startService] $service_name failed to start.";
				$status = 0;
			}
		}
	}
	elsif ( $serStatus{'CurrentState'} == 7 ) {
		if ( ! Win32::Service::ResumeService($Machine, $service_name) ) {
			carp "** ERROR ** [T38lib::Common::startService]: Win32::Service::ResumeService failed";
			return ($status=0);
		}
		else {
			while ( $state != 4 ) {
				if ($cnt > $SERVICE_TIMEOUT) {
					carp "** ERROR ** [T38lib::Common::startService]: $service_name service startup timed out";
					$status = 0;
					last;
				}
				sleep 10;
				$cnt=$cnt+10;

				if ( ! Win32::Service::GetStatus($Machine, $service_name, \%serStatus) ) {
					carp "** ERROR **  [T38lib::Common::startService]: Win32::Service::GetStatus failed";
				}
				$state = $serStatus{'CurrentState'};
			}
			if ( $state == 4) {
				$status = 1;
			}
			else {
				carp "** ERROR **  [T38lib::Common::startService] $service_name failed to resume.";
				$status = 0;
			}
		}
	}
	else {
		$status = 1;
	}

	return $status;

}	# End of startService

#------------------------------------------------------------------------------
# Purpose: Stop a given service.
#		Input:	Service Name, Server Name (Optional)
#		Output:	Return the status: 
#				1 = Successfully stop the service
#				0 = Failed to stop the service
#------------------------------------------------------------------------------
sub stopService($;$) {
	my ($service_name, $Machine) = @_;		# Service name to stop

	my (%serviceList, %serStatus);
	my $found = my $cnt = my $status = my $state = 0;
	my ($key, $value);
	my $SERVICE_TIMEOUT = 1000;		# Time out value for starting/stopping services

	if ($Machine eq "") {
		$Machine = Win32::NodeName(); 			# Get the machine name
	}
	
	&notifyWSub("Stopping Service Name: $service_name");

	if (! Win32::Service::GetServices($Machine, \%serviceList) ) {
		carp "** ERROR ** [T38lib::Common::stopService]: Win32::Services::GetServices failed.";
		return ($status=0);
	}

	while (($key,$value) = each(%serviceList)) {
		if ( (lc($value)) eq (lc($service_name)) ){
			$found = 1;		# Found the service;
			last;			# Terminate the While loop (No need to search any more).
		}
	}

	if ( $found == 0 ) {
		carp "** ERROR **  [T38lib::Common::stopService] $service_name is not a valid service on $Machine.";
		return ($status=0);
	}

# Get the Service status
# serStatus{'CurrentState'} = 1 Stopped
# serStatus{'CurrentState'} = 4 Running
# serStatus{'CurrentState'} = 7 Pause

	if ( ! Win32::Service::GetStatus($Machine, $service_name, \%serStatus) ) {
		carp "** ERROR **  [T38lib::Common::stopService]: Win32::Service::GetStatus failed.";
		return ($status=0);
	}
	
	if ( ($serStatus{'CurrentState'} == 4) || ($serStatus{'CurrentState'} == 7) ) {
		if ( ! Win32::Service::StopService($Machine, $service_name) ) {
			carp "** ERROR **  [T38lib::Common::stopService]: Win32::Service::StopService failed.";
			return ($status=0);
		}
		else {
			while ( $state != 1 ) {
				if ($cnt > $SERVICE_TIMEOUT) {
					carp "** ERROR ** [T38lib::Common::stopService]: $service_name service shutdown timed out.";
					$status = 0;
					last;
				}
				sleep 10;
				$cnt=$cnt+10;

				if ( ! Win32::Service::GetStatus($Machine, $service_name, \%serStatus) ) {
					carp "** ERROR **  [T38lib::Common::stopService]: Win32::Service::GetStatus failed.";
				}
				$state = $serStatus{'CurrentState'};
			}

			if ( $state == 1) {
				$status = 1;
			}
			else {
				carp "** ERROR **  [T38lib::Common::stopService] $service_name failed to stopped.";
				$status = 0;
			}
		}
	}
	else {
		$status=1;
	}

	return $status;

}	# End of stopService

#------------------------------------------------------------------------------
# Purpose: Stop all the dependent services before stoping the given service.
#		Input:	Service Name, Server Name (Optional)
#		Output:	Return the status: 
#				1 = Successfully stop all the services
#				0 = Failed to stop the service
#------------------------------------------------------------------------------
sub stopServiceWithDepend($;$) {
	my ($serviceName, $Machine) = @_;		# Service name to stop
	
	my (%serviceList, %serStatus);
	my ($key, $value, $found);
	my @depServiceNames=0;
	my ($depService, $rtnCode);
	my $status=1;

	if ($Machine eq "") {
		$Machine = Win32::NodeName(); 			# Get the machine name
	}

	if (! Win32::Service::GetServices($Machine, \%serviceList) ) {
		carp "** ERROR ** [T38lib::Common::stopServiceWithDepend]: Win32::Services::GetServices failed.";
		return ($status=0);
	}

	while (($key,$value) = each(%serviceList)) {
		if ( (lc($value)) eq (lc($serviceName)) ) {
			$found = 1;		# Found the service;
			last;			# Terminate the While loop (No need to search any more).
		}
	}

	if ( $found == 0 ) {
		carp "** ERROR **  [T38lib::Common::stopService] $serviceName is not a valid service on $Machine.";
		return ($status=0);
	}

	# Get names of all the dependent services
	@depServiceNames = findDependentService($serviceName, $Machine); 

	if ( $depServiceNames[0] ne $T38ERROR ) {
		# Stop all the dependent services if any
		foreach $depService (@depServiceNames) {
			last if ( $depService =~ /\bZero\b/i );		# No dependent services found
			$rtnCode = stopService($depService, $Machine);
			if ( $rtnCode == 0 ) {
#				carp "[T38lib::Common::stopServiceWithDepend] Can not stop dependent service: $depService"; 
				$status =  0;
			}
		}

		# Stop the service
		$rtnCode = stopService( $serviceName, $Machine );
		if ( $rtnCode == 0 ) {
#			carp "[T38lib::Common::stopServiceWithDepend] Can not stop service: $serviceName"; 
			$status =  0;
		}
	}
	else {
		carp "** ERROR **  [T38lib::Common::stopService] call to T38lib::Common::findDependentService failed for service $serviceName.";
		return ($status=0);
	}

	return $status;	

}	# End of stopServiceWithDepend

#------------------------------------------------------------------------------
#	setLogFileDir -- set default directory for log file.
#------------------------------------------------------------------------------
#	Purpose: sets directory for a log file.
#
#	Input: 	Directory name for program logs.
#	Output: Return 1 if successfull, 0 if directory does not exists or cannot
#			be created.
#
#------------------------------------------------------------------------------
sub setLogFileDir($) {
	my $dirName		= shift;					# Get the input parameter
	my $subroutine	= "T38lib::Common::setLogFileDir";
	my $cmd			= '';

	unless ($dirName) {
		croak("[$subroutine]: Empty directory name is not allowed.");
		return(0);
	}
	$dirName =~ s/[\\\/]\s*$//;
	unless (-d $dirName) {
		$cmd = "cmd /E:on  /C \"mkdir \"$dirName\"\"";
		unless (system($cmd) == 0) {
			croak("Cannot create directory $dirName. Problem with $cmd");
			return(0);
		}
	}

	$gLogFileDir = $dirName . "\\";
	return(1);

}	# End of setLogFileDir
	
#------------------------------------------------------------------------------
#	Purpose: Remove the file extension.
#
#	Input: 	A string containg the file name with path and extension
#	Output: Return the string after removing the file extension
#------------------------------------------------------------------------------
sub stripFileExt($) {
	my $str = shift;			# Get the input parameter

	$str =~ s/\.\w*$//;			# Search for word boundry and delete the rest.
	return $str;				# Return the string

}	# End of stripFileExt

#------------------------------------------------------------------------------
#	Purpose: Remove the path information
#
#	Input:  A string containg the file name with path and extension
#	Output: Retrun the string after removing the path
#------------------------------------------------------------------------------
sub stripPath($) {
	my $str = shift;					# Get the input parameter

	$str =~ s|^.*[\\/]([^\\/]+)$|$1|;	# Remove the path information
	return $str;						# Return the string

}	# End of stripPath

#------------------------------------------------------------------------------
#	Purpose: Stripe leading and trailing white spaces of a given string.
#
#	Input: 	A string with trailing or leading spaces
#	Output: Return the string after removing all the trailing
#			and leading spaces
#
# 	Use of regular expression to search for spaces and remove them
# 	by using the substitute command.
#------------------------------------------------------------------------------
sub stripWhitespace($) {
  my $str = shift;
  
  $str =~ s/^\s+//;		# Remove leading white spaces
  $str =~ s/\s+$//;		# Remove trailing white spaces
  return $str;

}	# End of Stripwhitespace

# ----------------------------------------------------------------------
#	unc2path	return physical path for unc share name 
# ----------------------------------------------------------------------
#	arguments:
#		server	server name
#		share	full share name for specified server
#	return:
#		physical path
# ----------------------------------------------------------------------
#	Example:
#		$path = unc2path('HST6DB', '\\HST6DB\t38app80');
#	Value of $path = d:\dbms\t38app80.
#
# ----------------------------------------------------------------------
sub unc2path($$) {
	my $server	= shift;
	my $share	= shift;

	use Win32::NetResource qw(:DEFAULT GetSharedResources GetError NetShareGetInfo);
	my $href;
	
	# &notifyWSub("Server name: $server, Share: $share");
	$share =~ s/^\\\\$server\\//i;
	unless (NetShareGetInfo($share, $href, $server)) {
		my $err = undef;
		GetError($err);
		&warnme(Win32::FormatMessage($err));
		return(0);
	}

	return($href->{path});

}	# End of unc2path

# ----------------------------------------------------------------------
# whence -- checks if file can be found via PATH variable.
# ----------------------------------------------------------------------
#	arguments:
#		$fname		File name.
#	return:
#		full file name	Success
#		0		Failure
# ----------------------------------------------------------------------

sub whence ($) {
use File::Spec;
	my $fname	= shift;
	my @path	= File::Spec->path();
	my $dir		= '';
	

	# If file name includes volume and directory, check file at specified
	# location
	if ($fname =~ /[\\\/]/) {
		if ( -e $fname) {
			return($fname);
		} else {
			return(0);
		}
	}

	# Base file name is used. First check if it is in current directory.
	
	if ( -e "./$fname") { return("./$fname"); }
	
	# On Windows NT, check $SystemRoot\system32 directory.
	
	if ( $^O == "MSWin32" && -e "$ENV{'SystemRoot'}/system32/$fname") { 
		return("$ENV{'SystemRoot'}/system32/$fname");
	}

	# Check if file can be found on $PATH.
	
	foreach $dir (@path) {
		$dir =~ s/[\\\/]\s*$//;	# Remove trailing directory separator.
		 if ( -e "$dir/$fname" ) { return("$dir/$fname"); }
	}
	return(0);

}	# End of whence

1;

__END__

=pod

=head1 NAME

T38lib::Common - Perl extension DBA Common Tasks.

=head1 SYNOPSIS

=over

=item *

use T38lib::Common;

=back

=head1 FUNCTION LISTING

 sub adActName2samid ($);
 sub adGrpName2samid ($);
 sub adUsrName2samid ($);
 sub archiveFile($$);
 sub archiveLogFile($);
 sub chkPerlVer();
 sub clusGrpSrvcsStop ($);
 sub clusResStart ($$$);
 sub clusResStop ($$$);
 sub errorTrap();
 sub findDependentService($;$);
 sub getDBNames($);
 sub getDrives(;$);
 sub getEnvPathVar();
 sub getLogFileName($);
 sub getServiceStatus($;$);
 sub getSqlCSDVer(;$$);
 sub getSqlCurVer(;$$);
 sub getSQLInstLst ($;$);
 sub getSQLInst4VirtualSrvr($);
 sub getSqlVerReg(;$$);
 sub getWinClusterName(;$);
 sub getWinClusterNodes($$);
 sub globbing(\@);
 sub logEvent ($$;$); 
 sub notifyMe($);
 sub notifyWSub ($;$);
 sub logme ($;$);
 sub warnme ($;$);
 sub errme ($;$);
 sub parseProgramName();
 sub readINI($$$);
 sub rebootLocalMachine();
 sub runOSCmd ($;$);
 sub runSQLChk4Err($,$$$$$$\@\@$);
 sub sendMsg2Monitor($$$);
 sub setLogFileDir($);
 sub startService($;$);
 sub stopService($;$);
 sub stopServiceWithDepend($;$);
 sub stripFileExt($);
 sub stripPath($);
 sub stripWhitespace($);
 sub unc2path($$);
 sub whence ($);

=head2 DESCRIPTION

 Active directory Account Name to samid
 Sub Call	&T38lib::Common::adActName2samid($adUsrName, $adActType);
 Input Parameters:
 	$adUsrName => active directory account name
 	$adActType => active directory account type (1 = Group, 2 = User)
 return: samid = Success, 0 = Failure

 Active directory Group Name to samid
 Sub Call	&T38lib::Common::adGrpName2samid($adGrpName);
 Input Parameters:
 	$adGrpName => active directory group name
 return: samid = Success, 0 = Failure

 Active directory User Name to samid
 Sub Call	&T38lib::Common::adUsrName2samid($adUsrName);
 Input Parameters:
 	$adUsrName => active directory user name
 return: samid = Success, 0 = Failure

 Archive log file
 Sub Call	&T38lib::Common::archiveFile($archiveFileName, $numArchive);
 Input Parameter: 
 	$archiveFileName => Archive file name 
	$numArchive => number of archive files

 Archive log file
 Sub Call	&T38lib::Common::archiveLogFile($numberOfCopies);
 Input Parameter: Number of copies to keep for log file

 Take offline all service resources in a cluster group
 Sub Call	&T38lib::Common::clusGrpSrvcsStop($vsName)
 return: 1 = Success, 0 = Failure

 Bring online clustered resource
 Sub Call	&T38lib::Common::clusResStart($clusName, $vsName, $resName)
 return: 1 = Success, 0 = Failure

 Take offline clustered resource
 Sub Call	&T38lib::Common::clusResStop($clusName, $vsName, $resName)
 return: 1 = Success, 0 = Failure


 Display error messages and die.
 Sub Call	&T38lib::Common::errorTrap();
 Display an error message and die.

 Find dependent services of a given service.
 Sub Call	&T38lib::Common::findDependentService($Service_name, $machine);
 Input Parameter: Service Name, Server Name (Optional)
 return all other services that the are dependent on the given service in an array. 
 If no dependent service found return a array[0]="zero" 
 In case of an error return $T38ERROR="__T38ERROR__"

 Get the database names from a give SQL Server
 Sub Call	&T38lib::Common:getDBNames($SQLServerName);
 Return the database names in an array 
 In case of an error return $T38ERROR="__T38ERROR__"

 Get the full path info from Registry.
 Sub Call	&T38lib::Common::getEnvPathVar();
 Return the full path from registry
 In case of an error return $T38ERROR="__T38ERROR__"
 
 Construct a log file name from the program name.
 Get the log file name
 Sub Call	&T38lib::Common::getLogFileName($programName);
 Input Parameter: programName
 Get the input file name and replace the extension with .log
 Return the file name i.e. Name of the program name .log

 Get current version of SQL Server.
 Sub Call	&T38lib::Common::getSqlCurVer($InstanceName);
 Input Parameter: Instance Name used in SQL 2000 and up
 Retrun a string with the following format
 	SQLMajorVersion.SQLMinorVersion.SQLServicepackVersion
 	or 0 in case of an error.

 Get CSD version of SQL Server
 Sub Call	&T38lib::Common::getSqlCSDVer($InstanceName);
 Input Parameter: Instance Name used in SQL 2000 and up
 Retrun a string with the following format
 	SQLMajorVersion.SQLMinorVersion.SQLServicepackVersion
 	or 0 in case of an error.
 
 Get list of SQL Server instances on a server
 Sub Call	&T38lib::Common::getSqlInstLst(\%instLst, $srvrName);
 Input Parameter: 
	rInstLst	reference to list of SQL Server instances
	srvrName	server Machine Name (Optional)
 Return status is
	1		Success
 
 Get SQL Instance name for virtual server
 Sub Call	&T38lib::Common::getSQLInst4VirtualSrvr($virtualSrvrName);
	vSrvrName		virtual server machine name
 Retruns SQL Server instance name for virtual SQL server name or 0 if
 instance name is not available.
 
 
 Get SQL Server Version from registry
 Sub Call	&T38lib::Common::getSqlVerReg($srvrName, $instanceName);
	srvrName		server machine name (Optional)
	instanceName	SQL Server instance name. Default instance name
					is NULL or MSSQLSERVER.
 Retrun a string with the following format
 	SQLMajorVersion.SQLMinorVersion.SQLServicepackVersion
 	or 0 in case of an error.
 
 Get Windows Cluster name from Registry
 Sub Call	&T38lib::Common::getWinClusterName($virtualSrvrName);
	vSrvrName		virtual server machine name (Optional)
 Retruns virtual server name for the whole cluster or 0 if
 server is not clustered.

 Get node names for windows cluster
 Sub Call	&T38lib::Common::getWinClusterNodes($clusterName, \@clusNodes);
	$clusterName	windows cluster name
	\@clusNodes		list of cluster node names
 List of nodes in a cluster are added to @clusNodes array.

 Get list of resources in windows cluster group
 Sub Call	$clusterName = &T38lib::Common::getWinClusterRes($vsName, \@resNames, $clusterName);
	$vsName			cluster virtual server name
	\@resNames		list of resource names in cluster group
	$clusterName	optional cluster name
 List of nodes in a cluster are added to @resNames array.
 Status $clusterName = success, 0 = fail.

 
 Expand wild characters in the command line argument.
 Sub Call	&T38lib::Common::globbing(\@);
 Input: 	Command line argument as an array
 Return Expand command line argument and return an array of the expanded 
 command line arguments
 If globbing expand to nothing then return $T38ERROR="__T38ERROR__"

 Check perl version on the local machine
 Sub Call	&T38lib::Common::chkPerlVer();
 Return 1 or Perl version on the box
 	1 mean version is 5.005 or higher
 	Perl version mean older version

 Display the message on the screen and log the message into the log file.
 Sub Call	&T38lib::Common::notifyMe($);
 Input: Message string
 Display the message on the screen and log the message into
 the log file.

 Log an event in Windows NT Event Log.
 Sub Call	&T38lib::Common::logEvent($errtype, $errmsg, $eventcode);
 Input: 
 	$errtype	Info, Warn or Error.
	$errmsg		Error message text.
	$eventcode	Optional parameter: started or done.
 Return status is
	1		Successfully logged an event.
	0		Failed to log an event.
 
 Parse program name.
 Sub Call	&T38lib::Common::parseProgramName();
 Input:	None
 Return Values: List, consisting of
	programPath		program directory path
	programName		base name of the program, without extension
	programSuffix	program suffix
 Example 1: command line perl tester.pl, executed in 
	C:/DBMS/t38app80, returns 
		('C:\DBMS\t38app80\', 'tester', '.pl')
 Example 2: command line tester.exe, executed in 
	C:/DBMS/t38app80, returns 
		('C:\DBMS\t38app80\', 'tester', '.exe')
 Example 3: command line perl ../t38app80/tester.pl
	executed in C:/DBMS/t38app80, returns
		('..\t38app80\', 'tester', '.pl')
 Example 4: command line perl //$computername/t38app80/tester.pl
	executed on LAP-TSMRRL-NTW computer, returns
		 ('\\LAP-TSMRRL-NTW\t38app80\', 'tester', '.pl')

 Read values from INI file.
 Sub Call	&T38lib::Common::readINI($iniFileName $secName, $key);
 Input: 	ini file name, section name, key
 Return Value of the key if no ERROR				
 In case of an ERROR
	Return section name if section name is not found in the ini file
	Return key if the key is not found in the ini file
 	Return key if the key is there but there no value assign to the key
  
 Reboot the local machine
 Sub Call  &T38lib::Common::rebootLocalMachine();

 Run OS Command
 Sub Call  &T38lib::Common::runOSCmd($oscmd, $osout)
    arguments:
        $oscmd	operating system command to execute
        $osout	(optional) reference for output file name
    return:
        1	Success
        0	Failure
 Run OS Command and stores results in file name provided by osout.
 If $osout is not provided, local variable is used and file name is
 created based on log file directory name.
 If reference to $osout is specified, but value is 0, file name is
 created based on log file directory name and stored in $$osout so
 calling subroutine can use it.

 To run sql from a given file or command line sql, once the 
 sql is run successfully check for sql error(s). If no error
 return 0, in case of an error return 1.
 Sub Call	&T38lib::Common::runSQLChk4Err(inputFileName, severName, databaseName
                                           outputFileName, userName, Password, LowerSeverity
														  MoreCmds, \@IncErr, \@ExcErr, headersOnFlg);

 Input Argument: 
 	A file name that have the SQL to run. Example: getDevices.sql
 	or the one line SQL, Example: "select @@version"

	Optional parameters: 
		Server Name (SQL Server name, default local machine)

		Database Name

		Output file Name Default is inputfilename.out 
		In case of a command line query use a unique temp file name.

		User name (example, sa)
		Password  (example, XXXXXX);
			if user and password is not provided then use
			trusted connection option -E

		Severity level, default 11

		More command (example, -b)
		Verify that the command line options are valid

	Output:
	Return Status, 0 no error, 1 error(s).

 Send message to SQL Monitor tool
 Sub Call  &sendMsg2Monitor ("T38bkp.pl", "This is a test message...");

 Input:		Error Level, Application Name, Actual Message to log 
 Output:		Status 0 OK, 1 Fail	

 Set isql Binary to either ISQL or OSQL default is OSQL
 Sub Call	&T38lib::Common::setIsqlBin($isqlBinaryName)
 Input:	Isql binary name, either isql or osql
 Return the status: 
 	1 = Successfully start the service
 	0 = Failed to start the service

 Start any given service.
 Sub Call	&T38lib::Common::startService($serviceName, $machine)
 Input:	Service Name, Server Name (Optional)
 Return the status: 
 	1 = Successfully start the service
 	0 = Failed to start the service

 Stop any given service.
 Sub Call	&T38lib::Common::stopService($serviceName, $machine)
 Input:	Service Name, Server Name (Optional)
 Return the status: 
 	1 = Successfully start the service
 	0 = Failed to start the service

 Stop all the dependent services before stoping the given service.
 Sub Call	&T38lib::Common::stopServiceWithDepend($serviceName, $machine);
 Input:	Service Name, Server Name (Optional)
 Return the status: 
 	1 = Successfully stop all the services
 	0 = Failed to stop the service

 Remove the file extension from a given file name.
 Sub Call	T38lib::Common::stripFileExt($fileName);
 Input: 	A string containg the file name with path and extension
 Retrun the string after removing the file extension

 Remove the path information from a given file name.
 Sub Call	&T38lib::Common::stripPath($fileName);
 Input: 	A string containg the file name with path and extension
 Retrun the string after removing the path info

 Remove any leading and trailing spaces from a given string
 Sub Call	&T38lib::Common::stripWhitespace($string);
 Input:	string
 Return the same string after removing any leading and trailing spaces.

 Return physical path for unc share name.
 Sub Call	&T38lib::Common::unc2path($server, $share);
 Input:
		server	server name
		share	full share name for specified server
 Return:
		physical path
 Example:
		$path = unc2path('HST6DB', '\\HST6DB\t38app80');
	Value of $path = d:\dbms\t38app80.

 Checks if file can be found via PATH variable.
 Sub Call	&T38lib::Common::whence($fileName)
 Input: 	A string containing the File name.
 Return the full file name with the path, if successful,
 0, if file is not found on $PATH

=head1 BUGS

I<Common.pm> has no known bugs.

=head1 REVISION

$Revision: 1.1 $

=head1 AUTHOR

Asif Kaleem

=head1 SEE ALSO

Registry, Service, Win32 and Carp

=head1 COPYRIGHT and LICENSE

This program is copyright by BestBuy Inc.

=cut
