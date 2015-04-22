#!perl

#------------------------------------------------------------------------------
# PVCS info
#
# $Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/Utilities/T38lib/t38cfgfile.pv_  $
# $Author: A645276 $
# $Date: 2011/02/08 17:23:18 $ 
# $Revision: 1.1 $
#------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# $Workfile:   t38cfgfile.pm  $
#
# $Log: t38cfgfile.pm,v $
# Revision 1.1  2011/02/08 17:23:18  A645276
# init check in
#
# 
#    Rev 1.8   Aug 26 2005 15:16:46   tsmmxr
# Added delConfigValues subroutine to clear gConfigValues hash.
# 
#    Rev 1.7   Aug 24 2005 17:22:44   tsmmxr
# 1) Changed readConfigFile subroutine to be able to process values with keys that start with T38LIST:. Values for these keys,  will be stored as list of vaules in a hash for the corresponding key.
# 
# 2) Added subroutine printConfigValues to print configuration values, read from the file.
# 
# 3) Changed default for SQLSourceBox parameter to DS02ADBI.
# 
#    Rev 1.6   Mar 08 2005 08:55:06   tsmask
# SQLMemory has been taken out, since AWE used other memory variable from cfg file.
# 
#    Rev 1.5   Jan 09 2004 18:04:06   TSMMXR
# Updated, based on t38instl80.pl release 1.13.
# 
#    Rev 1.4   Aug 28 2002 12:29:26   tsmmxr
# Added updateCfgFile function.
# 
#    Rev 1.2   14 Aug 2002 17:26:28   TSMMXR
# Changed starting and finishing notifications.
# 
#    Rev 1.1   13 Aug 2002 17:59:52   TSMMXR
# Removed debug code for exporter.
# 
#    Rev 1.0   13 Aug 2002 17:56:58   TSMMXR
# Initial revision.
# 
#
# Script Name:  t38cfgfile.pm 
#
#-------------------------------------------------------------------------------

# Setting the default package to 
package T38lib::t38cfgfile;

use T38lib::Common qw(notifyMe notifyWSub warnme errme logme);
use Carp qw(croak carp);

# Use the Perl library's Exporter module.
require Exporter;

# Turn on strict
use strict;

# Declaration of package variables.
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS
			%gUserDb %gSystemDb %gConfigValues
);

# Subclass Exporter and AutoLoader
@ISA = qw(Exporter AutoLoader);

# Add the names of functions and other package variables that we want to
# export by default.
# Item to export into caller namespace by default.
#@EXPORT = qw(delConfigValues printConfigValues readConfigFile updateCfgFile %gUserDb %gSystemDb %gConfigValues);

# Add the names of functions and other package variables that we want to 
# exported on request.
@EXPORT_OK = qw(delConfigValues printConfigValues readConfigFile updateCfgFile
				%gUserDb %gSystemDb %gConfigValues
				);

# All names of EXPORT and EXPORT_OK in EXPORT_TAGS{tag} anonymous list
# Define names for sets of symbols

%EXPORT_TAGS = (CFGFILE_SUBS => [qw(readConfigFile updateCfgFile delConfigValues printConfigValues)],
			    CFGFILE_VARS => [qw(%gUserDb %gSystemDb %gConfigValues)]);
			    
# A version number that you should increment every time you generate a new
# release of the module.
$VERSION	= do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf '%d'.'.%02d'x$#r,@r};

#-- constants

#-- variables

# Global hash that hold all the parameter read from cfg files.
#
%T38Lib::t38cfgfile::gConfigValues	= ();

# Initilize the global array
#
$gConfigValues{EnvironmentType}		= "";

$gConfigValues{SQLSourceBox} 		= "ds02adbi";
$gConfigValues{SQLShare} 	 		= "dbaiutil";


$gConfigValues{DumpDevicesDrive}		= "";
$gConfigValues{MdfDrive} 				= "";
$gConfigValues{NdfDrive} 				= ""; 
$gConfigValues{LdfDrive} 				= "";
$gConfigValues{TrcDrive} 				= "";
$gConfigValues{TmpDrive} 				= "";
$gConfigValues{SQLDataRootDrive}		= "";
$gConfigValues{DBAUtilsDrive} 			= "";
$gConfigValues{SQLAppDrive} 			= ""; 
$gConfigValues{DumpDevicesSrvr}			= "";

$gConfigValues{SQLSrvrEdition}			= "enterprise";					# Server edition
$gConfigValues{SQLInstanceName}			= "";							# SQL instance Name

$gConfigValues{SortOrder} 				= "dictionary";					# Sort order
$gConfigValues{CharSet} 				= "ISO";						# Character set
$gConfigValues{CaseSensitive}			= "N";							# Case sensitive
$gConfigValues{RebootFlag} 				= "N";							# Y reboot the box / N, do NOT reboot the box (default)

$gConfigValues{DumpDevicesPath}			= "\\DBMS\\t38bkp";
$gConfigValues{MdfPath}					= "\\DBMS\\t38mdf";
$gConfigValues{NdfPath}					= "\\DBMS\\t38ndf";
$gConfigValues{LdfPath}					= "\\DBMS\\t38ldf";
$gConfigValues{TrcPath}					= "\\DBMS\\t38trc";
$gConfigValues{TmpPath}					= "\\DBMS\\t38tmp";
$gConfigValues{SQLDataRootPath}			= "\\DBMS\\t38sys";
$gConfigValues{DBAUtilsPath}			= "\\DBMS\\T38app80";
$gConfigValues{SQLAppPath}				= "\\APPS\\SQL2000";

$gConfigValues{__SharePointDumpDevicesPath}		= "t38bkp";
$gConfigValues{__SharePointMdfPath}				= "t38mdf";
$gConfigValues{__SharePointNdfPath}				= "t38ndf";
$gConfigValues{__SharePointLdfPath}				= "t38ldf";
$gConfigValues{__SharePointLdfPath}				= "t38ldf";
$gConfigValues{__SharePointTrcPath}				= "t38trc";
$gConfigValues{__SharePointSQLDataRootPath}		= "t38sys";
$gConfigValues{__SharePointDBAUtilsPath}		= "t38app80";
$gConfigValues{__SharePointSQLAppPath}		= "t38sql80";

$gConfigValues{SQLInstallPath}			= "";
$gConfigValues{ServicesDown}			= "";

$gConfigValues{SQLServiceName}			= "";
$gConfigValues{SQLServiceVersion}		= "";
$gConfigValues{SQLAgentName}			= "";

$gConfigValues{SPVersion}				= "";
$gConfigValues{SPDirectory}				= "";
$gConfigValues{SPIssFile}				= "";


$gConfigValues{gIssCollationName}   	= "";
$gConfigValues{gIssInstanceName} 		= "";
$gConfigValues{gIssTCPPort}	     		= 0;
$gConfigValues{gIssPipeName}			= "";
$gConfigValues{gSQLConnectName}	 		= ".";

# Databases information 
#
%gSystemDb	= ();
%gUserDb	= ();


# Function declaration in alphabetical order in t38cfgfile.pm

sub delConfigValues();					# Delete all values in %gConfigValues hash
sub printConfigValues();				# Print configuration values with notifyMe
sub readConfigFile($);					# Read the CFG files initial values
sub updateCfgFile($$);					# update parameters in CFG file

# ----------------------------------------------------------------------
#	delConfigValues		delete all values from %gConfigValues hash
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
#	delete all values from %gConfigValues hash
# ----------------------------------------------------------------------

sub delConfigValues () {
	my $status	= 1;
SUB:
{
	&notifyWSub("Started.");

	undef(%gConfigValues);
	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# delConfigValues


# ----------------------------------------------------------------------
#	printConfigValues		print configuration values
# ----------------------------------------------------------------------
#	arguments:
#		none
#	return:
#		none
# ----------------------------------------------------------------------
#	print configuration values
# ----------------------------------------------------------------------

sub printConfigValues () {
	my $status	= 1;
	my $key		= 0;
	my $i		= 0;
SUB:
{
	&notifyWSub("Started.");

	foreach $key (sort keys (%gConfigValues)) {
		if (ref $gConfigValues {$key} && ref $gConfigValues {$key} == 'ARRAY' ) {
			for ($i = 0; $i < scalar( @ { $gConfigValues {$key} }); $i++) {
				&notifyMe ("\$gConfigValues{$key}[$i] = " . $ {$gConfigValues{$key} }[$i] );
			}
		} elsif (ref $gConfigValues {$key} && ref $gConfigValues {$key} != 'ARRAY' ) {
			&notifyMe ("\$gConfigValues{$key} is reference to unsupported data type [". ref $gConfigValues {$key} . "]");
		} else {
			&notifyMe ("\$gConfigValues{$key} = $gConfigValues{$key}");
		}
	}

	last SUB;
}	# SUB
# ExitPoint:
	&notifyWSub("Done. Status: $status.");
	return($status);
}	# printConfigValues


# ----------------------------------------------------------------------
# readConfigFile
# ----------------------------------------------------------------------
#	arguments:
#		cfgFile	configuration file to parse
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	Purpose: Read the provided configuration file .
#            Set up global variables with the values read from CFG file.
#	This subroutine reads configuration file parameters, created in
#	the following form:
#	key = value
#	and stores them in hash %gConfigValues. If key starts with T38LIST:,
#	for example T38LIST:TblName, more then one value can be defined with
#	same key. All values will be collected and stored as list of values
#	for the hash key T38LIST:TblName. Individual values in a list,  can
#	be referenced using following syntax:  $ {$gConfigValues{$key} }[$i]
# ----------------------------------------------------------------------

sub readConfigFile($) {
	my $cfgFile		= shift;
	my $cfgFileHdl	= 0;
	my $status;							# test condition variable for creating dbms\db_apps\install directory
	my ($sysDatabases, $userDatabases );
	my ($dbname, $dataName, $dataSize, $logName, $logSize, $dataBackup, $logBackup, 
	    $truncLog, $selectInto, $expandData);
	my $status	= 1;
SUB:
{
	&notifyWSub("START - Reading cfg file $cfgFile.");

	unless ($cfgFile  and open(CFGFILE, $cfgFile)) {
		&warnme("Cannot read configuration file $cfgFile!");
		$status	= 0; last SUB; 
	}

	while  (<CFGFILE>) {				# read the input file line by line
		chomp();						# Get rid of new line character
		if ( /^\#/ or /^$/ ) {		# Skip comment and blank lines
			next;
		}

		$_ =~ s/\#.*$//g;				# Remove comments
	    $_ =~ s/^\s*//g;				# Remove all leading white spaces
	    $_ =~ s/\s*$//g;				# Remove all trailing white spaces

		# cfg variable has a list value defined and it is assigned to global hash
		#
		if (/^(T38LIST:\S+)\s*=\s*(\S+.*)$/) {
			$gConfigValues{$1} = []	if ( !defined($gConfigValues{$1}) );
			push @{ $gConfigValues{$1} }, $2;
		}
		# cfg variable has NO list values defined so global hash is initilized
		#
		elsif (/^(T38LIST:\S+)\s*=$/) {
			$gConfigValues{$1} = []	if ( !defined($gConfigValues{$1}) );
		}
		# cfg variable has a scalar value defined and it is assigned to global hash
		#
		elsif (/^(\S+)\s*=\s*(\S+.*)$/) {
			$gConfigValues{$1}=$2;
		}
		# cfg variable has NO values defined so global hash is initilized
		#
		elsif (/^(\S+)\s*=$/){
			$gConfigValues{$1}="";
		}

		# determine if we have read the <system database> header	
		#
		if (/<system databases>/) { 
			$sysDatabases = 1; 
			next;
		}
     	$sysDatabases = 0 if (/<end system databases>/i);
     	if (($sysDatabases) && 
     		!(/Name\s*DataName\s*DataSize\s*LogName\s*LogSize\s*DataBackup\s*LogBackup\s*TruncLog\s*SelectInto\s*ExpandData/i) &&
			!(/^\s*$/) ) {
			chop;
			s/^[\s]+//g;
			($dbname, $dataName, $dataSize, $logName, $logSize, $dataBackup, $logBackup, $truncLog, $selectInto, $expandData) = 
			split("[\t ]+");
		      
			# create a hash of hashes for system database options
	
			$gSystemDb{$dbname}{'DataName'}		= $dataName;		# logical name of the database data device
			$gSystemDb{$dbname}{'DataSize'}		= $dataSize;		# size of the the logical data device
			$gSystemDb{$dbname}{'LogName'}		= $logName;			# logical name of the database log device
			$gSystemDb{$dbname}{'LogSize'}		= $logSize;			# size of the logical log device
			$gSystemDb{$dbname}{'DataBackup'}	= $dataBackup;		# logical name of the database backup device
			$gSystemDb{$dbname}{'LogBackup'}	= $logBackup;		# logical name of the database log backup device
			$gSystemDb{$dbname}{'TruncLog'}		= $truncLog;		# "truncate log" option set on / off for this database
			$gSystemDb{$dbname}{'SelectInto'}	= $selectInto;		# "select into" option set on / off for this database
			$gSystemDb{$dbname}{'ExpandData'} 	= $expandData;		# Should Data device be automatically expandable 

	    } # end of the if for building hash for system databases 
	
		# determine if we have read the <user database> header
		if (/<user databases>/) { 
			$userDatabases = 1; 
			next;
		}
     	$userDatabases = 0 if (/<end user databases>/i);
     	
     	if ( ($userDatabases) && 
     		!(/Name\s*DataName\s*DataSize\s*LogName\s*LogSize\s*DataBackup\s*LogBackup\s*TruncLog\s*SelectInto\s*ExpandData/i) &&
			!(/^\s*$/)) {
			chop;
			s/^[\s]+//g;
			($dbname, $dataName, $dataSize, $logName, $logSize, $dataBackup, $logBackup, $truncLog, $selectInto, $expandData)
			 = split("[\t ]+");

			# create a hash of hashes for user database options	
			$gUserDb{$dbname}{"DataName"}		= $dataName;		# logical name of the database data device
			$gUserDb{$dbname}{"DataSize"}		= $dataSize;		# size of the the logical data device
			$gUserDb{$dbname}{"LogName"}		= $logName;			# logical name of the database log device
			$gUserDb{$dbname}{"LogSize"}		= $logSize;			# size of the logical log device
			$gUserDb{$dbname}{"DataBackup"}		= $dataBackup;		# logical name of the database backup device
			$gUserDb{$dbname}{"LogBackup"}		= $logBackup;		# logical name of the database log backup device
			$gUserDb{$dbname}{"TruncLog"}		= $truncLog;		# "truncate log" option set on / off for this database
			$gUserDb{$dbname}{"SelectInto"}		= $selectInto;		# "select into" option set on / off for this database
			$gUserDb{$dbname}{"ExpandData"} 	= $expandData;		# Should Data device be automatically expandable
		} # end of the if for building hash for user databases 
	}	  
	# Set dba installation path.
	
	$status	= 1;
	last SUB;
}
	close(CFGFILE)	if ($cfgFile);
	&notifyWSub("DONE - Reading cfg file.");
	return($status);	
} # end sub readconfigfile

# ----------------------------------------------------------------------
# updateCfgFile	update existing configuration file
# ----------------------------------------------------------------------
#	arguments:
#		$cfgFileName	configuration file name
#		$reftodo		reference to hash with keys to replace
#	return:
#		1	Success
#		0	Failure
# ----------------------------------------------------------------------
#	Update configuration file with provided key, value hash. 
#	For example to update LogShipEnabledFlg and LogShipDatabases 
#	parameters in t38ls.cfg file, use the following code.
#
#	%cfgtodo	= (
#		LogShipEnabledFlg 	=> 'N', 
#		LogShipDatabases	=> 'ADMDB004 MXRDB001',
#		);
#
#	&T38lib::t38cfgfile::updateCfgFile('t38ls.cfg', \%cfgtodo);
# ----------------------------------------------------------------------
sub updateCfgFile($$) {
	my $cfgFileName	= shift;
	my $reftodo		= shift;
	my %todo		= %{$reftodo};
	my $status		= 1;
	my $hkey;
	my @done		= ();	# List of processed values.
SUB:
{
	&notifyWSub("Updating $cfgFileName configuration file.");

	# With this version we cannot update list of values in configuration file.
	# This functinality should be implemented when requirements are available.
	# At this point just exist with error message.

	foreach $hkey (keys %todo) {
		if ($hkey =~ /^T38LIST:/) {
			&warnme("** ERROR** ($hkey): Updates to list values (T38LIST:*) are not implemented at this time.");
			$status = 0;
			last SUB;
		}
	}

	unless (open(T38DBACFG,"<$cfgFileName")) { 
		&warnme("** ERROR** Cannot open file $cfgFileName for reading. $!");
		$status = 0;
		last SUB;
	}

	unless (open(T38DBACFGNEW,">$cfgFileName.new")) { 
		&warnme("** ERROR** Cannot open file $cfgFileName.new for writing. $!");
		$status = 0;
		last SUB;
	}

	while (<T38DBACFG>) {
		# Check if we already have required key in configuration file.
		foreach $hkey (keys %todo) {
			if (/^\s*$hkey\s*=/) {
				$_ = "$hkey\t= $todo{$hkey}\n";

				# We cannot delete the key yet, because same value can show up
				# in configuration file again. We should replace all of these
				# values.
				push(@done, $hkey);
			}
		}
		print T38DBACFGNEW;
	}

	# Delete all processed keys from %todo hash and add remaining values to
	# configuration file.

	foreach $hkey (@done) { delete $todo{$hkey}; }
	foreach $hkey (keys %todo) {
		print T38DBACFGNEW "$hkey\t= $todo{$hkey}\n";
	}
	
	close(T38DBACFG);
	close(T38DBACFGNEW);

	if (
		system("cmd /C move $cfgFileName $cfgFileName.old") == 0 &&
		system("cmd /C move $cfgFileName.new $cfgFileName") == 0) {
		$status = 1;
	} else {
		&warnme("Problems renaming $cfgFileName, $cfgFileName.old or $cfgFileName.new.");
		$status = 0;
	}

	last SUB;
}	# SUB
# ExitPoint:
	close(T38DBACFG);
	return($status);
}	# updateCfgFile


# To display exporter diagnostic information, uncomment the following line.
# BEGIN { $Exporter::Verbose=1 }

1;

__END__

=pod

=head1 NAME

T38lib::t38cfgfile - Perl extension DBA Common Tasks.

=head1 SYNOPSIS

=over

=item *

use T38lib::t38cfgfile;

=back

=head1 FUNCTION LISTING

 sub delConfigValues();
 sub printConfigValues();
 sub readConfigFile($);
 sub updateCfgFile($$);

=head2 DESCRIPTION

=over 4

=item delConfigValues()

 delete all values from %gConfigValues hash
 Sub Call	&T38lib::t38cfgfile::delConfigValues();
 Input Parameter: None

=item printConfigValues()

 Print configuration values
 Sub Call	&T38lib::t38cfgfile::printConfigValues();
 Input Parameter: None

=item readConfigFile()

 read t38 configuration file
 Sub Call	&T38lib::t38cfgfile::readConfigFile($cfgFile);
 Input Parameter: Configuration file to parse

=item updateCfgFile()

 update existing configuration file
 Sub Call	&T38lib::t38cfgfile::updateCfgFile($cfgFile, \%todo);
 arguments:
		$cfgFileName	configuration file name
		$reftodo		reference to hash with keys to replace
 return:
		1	Success
		0	Failure

 Update configuration file with provided key, value hash. 
 For example to update LogShipEnabledFlg and LogShipDatabases 
 parameters in t38ls.cfg file, use the following code.

=back

=head1 BUGS

I<t38cfgfile.pm> has no known bugs.

=head1 REVISION

$Revision: 1.1 $

=head1 AUTHOR

Michael Royzman

=head1 SEE ALSO


=head1 COPYRIGHT and LICENSE

This program is copyright by BestBuy Inc.

=cut
