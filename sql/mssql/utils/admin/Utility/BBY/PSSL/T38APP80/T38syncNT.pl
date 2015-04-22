#! perl
#
# PVCS header information
# $Archive:   //cs01pvcs/pvcs/cm/Database/archives/Applications/DBINST/SQL65/T38syncNT.pv_  $
# $Author: A645276 $
# $Date: 2011/02/09 22:52:00 $
# $Revision: 1.1 $
#*
#*
#*
#* Purpose:  T38syncNT.pl incorporates local NT groups into SQL Server then checks the log file for errors.  If it finds an error it exit with status code 1.
#* Program must be executed from within the directory it is located.
#*
#* SYNOPSIS
#*
#*	t38SyncNT.pl -h | -S server name
#*
#*	Command line:
#*
#*	-S	optional server name
#*
#*
#*	Example: 
#*	1. Not specifying the server
#*		perl t38SyncNT.pl
#*
#*		
#*	2. Specifying a server
#*       perl t38SyncNT.pl -S ServerName
#*	
#*	
#*
#***

#use strict;

# Modules used.
use Win32::EventLog;
use Getopt::Std;


my ($gscript, $gserverName, $glogFile, $ghistoryFile, $gsqlVer, $gstat);

# check the command line arguments
getopts('hS:');

if ($opt_h) {	 # exit if h option exists
	&showHelp;
    exit 0;	}

if($Getopt::Std::opt_S){
  $gserverName = $Getopt::Std::opt_S;
  $gisql = "osql -E -S$gserverName -dmaster -n -w300"; 
  # $gisql = "isql -E -S$gserverName -dmaster -n -w300"; 
}else{
  $gisql = "osql -E -dmaster -n -w300"; 
  # $gisql = "isql -E -dmaster -n -w300"; 
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

# Run program to calculate database size
&syncNT;

# Close files
close(RunLog);
close(AppendLog);

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
# Gathers information on SQL 6.5, 7.0, or 2000 Servers
#
#
#----------------------------------------------------------------------

sub syncNT {

my ($syncNT);

$syncNT = `$gisql -Q "exec sp_T38SYNCNT2SQL "`;
&notifyme ("Start syncNT \n");
&notifyme ("---------------- \n");
&notifyme ("$syncNT \n");
&notifyme ("Finish syncNT \n");
}

#----------------------------------------------------------------------
#
# Check for errors in logfile#
#
#----------------------------------------------------------------------

sub chk4errs {

################### Variables of errors to include/exclude ##########################
my $lowersev = 17;	# Lowest severity level that we will report on.
					# possible serverity values are
					#	 0 - 10 are informational
					#	11 - 16 are user generated
					#	17 - 19 are hardware issues
					#	20 - +  are system fatal errors

my @XErr = (219, 1104, 2540, 15023, 15024, 15025, 15026, 15027, 15028, 15029, 
	15029, 15030, 15031, 15032, 15034);	# errors we're not interested in

my @IErr = ();		# Error we always want to include
							# regardless of sev. level.

my ($err, $sev);  

#########################  Optional Variable Conditions  ##########################

##############################  Program Variables  ##############################

$gstat = 0;
my $noterr = join("|",@XErr);
my $iserr  = join("|",@IErr);

unless (open(OUTFILE,"$glogFile")) {
	print ("** ERROR ** [errorcheck]: Cannot open file $glogFile: $!");
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
( $gstat == 0 ) ?
	&logme("Finished with status $gstat") :
	&warnme("Finished with status $gstat") ;
print("\nFinished with status $gstat \n");
exit($gstat);
}

###	logme -- issue an informative message
#
###

sub
logme {
	&logEvent("Info", $_[0]);
} #	logme

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
	my $perlv;
    my @perlv;

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
  if($perlflag == 0){
    print "This does not fit our standard for perl \n";
	$badwrite =`$gisql "Exec sp_T38LOGERROR 2, \'t38size\', \'Error can't write to Event Log because it can't interpret perl version, check problem\'"`;
  }
} #	logEvent
