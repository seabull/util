#! perl
#
# PVCS header information
# $Archive:   //cs01pvcs/pvcs/cm/Database/archives/SERVERS/STORE/MLGSTORE/DBINST/MR01/T38BBYdbsize.pv_  $
# $Author: A645276 $
# $Date: 2011/02/09 22:54:03 $
# $Revision: 1.1 $
#*
#*
#*
#* Purpose:  T38BBYdbsize.pl This program increases BBYDB001 to 150MB from 50MB because 
#*           EJRestore process populates several tables in BBY.
#*           If it finds an error it exit with status code 1.
#* Program must be executed from within the directory it is located.  Default is trusted connection.
#*
#* SYNOPSIS
#*
#*	t38BBYdbsize.pl -h | -S server name | -U user name | -P password
#*
#*	Command line:
#*
#*	-S	optional server name | -U optional user name | -P optional password
#*
#*
#*	Example: 
#*	1. Not specifying the server
#*		perl T38BBYdbsize.pl
#*
#*		
#*	2. Specifying a server, user name, and password
#*       perl T38BBYdbsize.pl -S ServerName -U UserName -P Password
#*	
#*	
#*
#***

#use strict;

# Modules used.
use Win32::EventLog;
use Getopt::Std;

my ($gscript, $gserverName, $glogFile, $ghistoryFile, $gsqlVer, $gstat, $guser, $gpwd, $gconnection);

# check the command line arguments
getopts('hS:U:P:');

if ($opt_h) {	 # exit if h option exists
	&showHelp;
    exit 0;	}

if($Getopt::Std::opt_U){
  $guser = $Getopt::Std::opt_U;
  $gpwd = $Getopt::Std::opt_P;
  $gconnection = "-U$guser -P$gpwd"; 
}else{
  $gconnection = "-E"; 
}

if($Getopt::Std::opt_S){
  $gserverName = $Getopt::Std::opt_S;
  $gisql = "isql $gconnection -S$gserverName -dmaster -n -w2048"; 
}else{
  $gisql = "isql $gconnection -dmaster -n -w2048"; 
}

# Get the name of the program for log file
# Log file name is equal to name of the program.log
#
($gscript = $0)  =~ s/\.\w*$//;
$glogFile = "$gscript.log";
$ghistoryFile = "$gscript.out";

# Open log file 
unless (open(RunLog,">$glogFile")) {
	print ("** ERROR ** [main]: Cannot open file $glogFile: $!");
	exit 1;
}

&notifyme ("Start T38BBYdbsize \n");
&BBYdbsize;
&notifyme ("Finish T38BBYdbsize \n");

# Clean-up: Delete temp work files
unlink("$gscript.sql");

close(OUT);


#  Check for error(s), if it finds error(s) return status of 1 so Maestro abends
&chk4errs;
     


###   Subroutines  #######################################################################

#--------------------------------------------------
#
#     notifyme -- log a message
#
#-------------------------------------------------

sub
notifyme {
	my($msg)  = @_;
	my($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);

	($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
	print "$msg\n";
	printf RunLog ("%02d/%02d/%02d %02d:%02d \n %s\n", $mon+1, $mday, $year, $hour, $min, $msg);
} # END sub notifyme

###	showHelp -- show help information from the current perl script.
###

sub
showHelp {
	local($inhelp) = 0;

unless (open(PLFILE, $0)) { errme("Cannot open $0: $!\n"); die "Died"; } 

	while (<PLFILE>) {
		$inhelp = 1 if (!$inhelp && /^#\*\s/);
		if ($inhelp) {
			if (/^#\*\s/) {
				s/^#\*//;
				print;
			} else {
				last;
			}
		}
	}
	close(PLFILE);
} #	showHelp

#----------------------------------------------------------------------
#
# Consistency checker on SQL 6.5 Servers
#
#
#----------------------------------------------------------------------

sub BBYdbsize {

my ($cmd, $status);
my (@dbnames);

# Open a temp file 
	unless (open(SQL,">$gscript.sql")) {
		print ("** ERROR ** [main]: Cannot open file $gscript.sql: $!");
		&notifyme ("** ERROR ** [main]: Cannot open file $gscript.sql: $!");
		exit 1;
	}

# Write the SQL to get the dbnames
	print SQL "use master\n";
	print SQL "go\n";
	print SQL "set nocount on\n";
	print SQL "go\n";
	print SQL "EXEC sp_T38LOGERROR 3, 'T38BBYdbsize', 'Started.'\n";
    print SQL "ALTER DATABASE BBYDB001 MODIFY FILE (NAME = BBYDB001_ndf, SIZE = 150MB) \n";
    print SQL "EXEC sp_T38LOGERROR 3, 'T38BBYdbsize', 'Finished.' \n";
    close(SQL);

$cmd="$gisql -i $gscript.sql -o $gscript.out";

# Run the SQL
	$status = system($cmd);
#	print "status = $status\n";

	unless (open(OUT,"<$gscript.out")) {
		print ("** ERROR ** [getdbnames]: Cannot open file $gscript.out: $!");
		exit 1;
	}

# Read the output file created by SQL command and look for 
# databases names.
	while (<OUT>) {
		chomp;
		if ( (/\w+/) ) {
				$_ = StripWhitespace($_);

				if ( /Unable to Connect/i ) {
					@dbnames = (); 
					push (@dbnames,"Error");
					last;
				}
				push (@dbnames,$_) if (! /name/ );
			
		}
	}
	close(OUT);

# Sort and return the database names.
	return (sort (@dbnames) );

}

#------------------------------------------------------------------------------
#	Purpose: Stripe leading and trailing white spaces of a given string.
#
#	Input: A string with trailing or leading spaces
#	Output: Retrun the string after removing all the trailing
#			and leading spaces
#
# Use of regular expresion to search for spaces and remove them
# by using the subsitute command.
#------------------------------------------------------------------------------
sub StripWhitespace {
  my $str = shift;
  $str =~ s/^\s+//;
  $str =~ s/\s+$//;
  return $str;
}

#----------------------------------------------------------------------
#
# Check for errors in logfile#
#
#----------------------------------------------------------------------

sub chk4errs {

################### Variables of errors to include/exclude ##########################
my $lowersev = 17;			# Lowest severity level that we will report on.
					# possible serverity values are
					#	 0 - 10 are informational
					#	11 - 16 are user generated
					#	17 - 19 are hardware issues
					#	20 - +  are system fatal errors

my @XErr = (219, 1104, 2540, 15023, 15024, 15025, 15026, 15027, 15028, 15029, 
	15029, 15030, 15031, 15032, 15034);	# errors we're not interested in

my @IErr = (911, 5039, 5041, 18456);		# Error we always want to include
							# regardless of sev. level.
my ($err, $sev);



#########################  Optional Variable Conditions  ##########################

##############################  Program Variables  ##############################

$gstat = 0;
my $noterr = join("|",@XErr);
my $iserr  = join("|",@IErr);

unless (open(OUTFILE,"$gscript.out")) {
	print ("** ERROR ** [errorcheck]: Cannot open file $gscript.out: $!");
	exit 1;
}
foreach (<OUTFILE>)	{
	if (m/Msg\s* (\d+),\s* Level\s*(\d+),/i) {
		($err, $sev) = ($1, $2);
		if (($sev >= $lowersev) || ($err =~ m/$iserr/))	{
			$gstat = 1 unless ($err =~ m/$noterr/);
			} 
		}

	}

close(OUTFILE);
ExitPoint:
( $gstat == 0) ?
   &logme("Finished with status $gstat") :
   &warnme("Finished with status $gstat");
print("\nFinished with status $gstat \n");
exit($gstat);

}

###logme -- issue an informative message
#
###

sub logme {

   &logEvent("Info", $_[0]);

} #logme


###	warnme -- issue a warning message
#
###

sub
warnme {
	&logEvent("Warn", $_[0]);
} #	warnme

###	errme -- issue a warning message
#
###

sub
errme {
	&logEvent("Error", $_[0]);
} #	errme


###	logEvent -- log an event in Windows NT Event Log.
#
###

sub
logEvent {
	my ($errtype, $errmsg) = @_;
	my $eventype;
	my $EventLog;
	my $appname = $gscript;
	my $data	= "";
    my $perlflag = 0;
	my $badwrite;

	$eventype = 	($errtype =~ m/Info/i) ? EVENTLOG_INFORMATION_TYPE :
			($errtype =~ m/Warn/i) ? EVENTLOG_WARNING_TYPE :
			EVENTLOG_ERROR_TYPE;

	my %event=(
		'Category',  NULL,
		'Source', $appname,
		'Computer', '',
		'Length', length($data),
		'RecordNumber', NULL,
		'TimeGenerated', NULL,
		'Timewritten', NULL,
		'EventID', 9000,
		'EventType', $eventype,
		'ClosingRecordNumber',NULL,
		'Strings',$errmsg,
		'Data',$data,
	);
    

@perlv = `perl -v`;
	foreach $perlv(@perlv) {
	  if($perlv =~ /110/){
            Open Win32::EventLog($EventLog, '', "Application") || die "$! ";
 	    if( ! $EventLog->Report(\%event) ){
		   print "Warning *** Fail to write to Event Log\n";
	    }
		    $perlflag = 1;
            last;
			$perlflag = 1;
	  }elsif (($perlv =~ /613/) || ($perlv =~ /522/)){
	       Win32::EventLog::Open($EventLog, $appnam, '') || die "$! ";

	    if ( ! $EventLog->Report(\%event) ){
           print "Warning *** Fail to write to Event Log\n";
	    }             
		$perlflag = 1;
		last;
	  }
    }
  if($perlflag ==0){
    print "This does not fit our standard for perl \n";
	$badwrite =`$gisql -Q "Exec sp_T38LOGERROR 2, \'t38BBYdbsize\', \'Error can't write to Event Log because it can't interpret perl version, check problem\'"`;
  }
} #	logEvent