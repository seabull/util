#!/usr/local/bin/perl58 -w
# $Header: c:\\Repository/database/rams/projects/reports_batch/ChargeChangeBatch/bin/rptProc.pl,v 1.32 2007/11/02 14:50:55 costing Exp $
#

use strict;

use DBI;
use Getopt::Long;
use Carp;
use Pod::Usage;
#use Time::ParseDate;
use Text::Template;
use DBD::Oracle qw(:ora_types);

#use lib 'lib/perl5';
use lib 'lib/perl';
#use lib '/afs/cs/user/yangl/.sys/sun4x_59/lib/perl5';
use MIME::Lite;

#use lib '/afs/cs.cmu.edu/user/yangl/rams/ProdOps/AdhocReports/AllDetails/database/rams/projects/reports_batch/ChargeChangeBatch/lib/perl';

use CMUCS::Rams::Report::Utils::Utils;
use CMUCS::Rams::Report::Utils::DateTime;
use CMUCS::Rams::Report::Utils::Oracle;
use CMUCS::Rams::Report::Utils::mailer qw(mail_user $mail_suppress $mail_log_fd %default_mailconf);

use CMUCS::Rams::Report::ChargeChange::Users;
use CMUCS::Rams::Report::ChargeChange::Machines;
use CMUCS::Rams::Report::ChargeChange::ChargeChange;

use Data::Dumper;

BEGIN {
	$ENV{ORACLE_HOME} = '/usr1/app/oracle/product/9.2' unless $ENV{ORACLE_HOME};
	#$ENV{ORACLE_SID} = 'fac_03' unless $ENV{ORACLE_SID};
	$ENV{TWO_TASK} = 'fac_03.apogee' unless $ENV{TWO_TASK};
}

=pod

=head1 NAME

rptProc.pl	- Main script for Charge Change Reports 

=head1 SYNOPSIS

B<rptProc.pl> <command> [command-options] <command arguments>

The following common options are supported for all commands.

	--oraconn | -c <arg>	Oracle connection string to connect to Oracle
				database. You need to set ORACLE_HOME in your
				environment or the default
				(/usr1/app/oracle/product/9.2) is used.

	--verbose | -v		print verbose information
	--help | -h		this help 

The following commands are supported.

	* list [options] [<number>]
			List the last <number> of report IDs.

	* notify [options] <batch id>
			Notify (email) the related customers for
			a report batch ID <batch id>.

	* process [options] 
			record and notify (using the newly recorded batch id).
			options:
				same options as command "record" below

	* record [options]
			Record a new report batch.
			options:

			--type | -t [1|2|3]
				Type of report to record.
				1	- Regular weekly (used for pre-JE and weekly)
				2	- Regular labor (used for post-JE)
				3	- Adhoc
			--ts_since | -1 <time string>
			--ts_until | -2 <time string>
				start time and end time of the report being
				recorded.  
				They are required for type 3 (Adhoc).

				<time string> supports fuzzy parsing. You can
				use "timetest" command to test whether a string
				can be parsed correctly.

	* report [options] <batch id>

	* timetest <time string>
			Test whether a time string can be parsed correctly.
			e.g.
			rptProc.pl timetest '2005/12/20'
			rptProc.pl timetest 'yesterday'
			rptProc.pl timetest 'last friday'

	* help 	-	This help.

=head1 DESCRIPTION

Script to generate expiring account report and email to users.

=head1 FUNCTIONS

=cut

my $dbh;
my $DEFAULT_ORAHOME = defined($ENV{'ORACLE_HOME'}) ? "$ENV{'ORACLE_HOME'}" : "/usr1/app/oracle/product/9.2";
my $DEFAULT_DUMPFILE = "./.ccrpt_object.perldata";

#Things that can be overriden by command line options
#my $ora_conn = "/\@hostdb.fac.cs.cmu.edu";
my $ora_conn = "ccreport/ccreport\@fac_03.apogee";
#my $verbose = 0;
#my %DEFAULT_MAILCONF = (
#	From		=> 'help+costing@cs.cmu.edu',
#	To		=> 'yangl+test@cs.cmu.edu',
#	'Reply-To'	=> 'help+costing@cs.cmu.edu',
#	Subject		=> 'Test Message',
#	Cc		=> '',
#	Bcc		=> 'ramscya+@cs.cmu.edu',
#	Type		=> 'TEXT',
#	'X-Rams-Mode'	=> 'Test',
#	Data		=> 'This is a test message. Please ignore.',
#	AdminTo		=> 'yangl+test@cs.cmu.edu',
#	AdminCc		=> '',
#	AdminBcc	=> 'ramscya+@cs.cmu.edu',
#	'Admin-ReplyTo'	=> 'help+costing@cs.cmu.edu',
#	AdminSubject		=> 'Summary Message',
#	'X-Rams-From'		=> 'help+costing@cs.cmu.edu',
#	'X-Rams-To'		=> 'yangl+test@cs.cmu.edu',
#	'X-Rams-Reply-To'	=> 'help+costing@cs.cmu.edu',
#	'X-Rams-Subject'	=> 'Test Message',
#	'X-Rams-Cc'		=> '',
#	'X-Rams-Bcc'		=> 'ramscya+@cs.cmu.edu',
#	'X-Rams-Type'		=> 'TEXT',
#	Linesep		=> "\r",
#);
my %custom_mailconf = (%mailer::default_mailconf);

#TODO: Make log file configurable.
my $LOG_FD = \*STDERR;

my %TmplNames = (
		'Envelope'	=> 'ccrpt_envelop.tmpl',
		'URptBody'	=> 'ccrpt_ureport.tmpl',
		'URptSection'	=> 'ccrpt_usection.tmpl',
		'MRptBody'	=> 'ccrpt_mreport.tmpl',
		'MRptSection'	=> 'ccrpt_msection.tmpl',
		'MailBody'	=> 'ccrpt_mail.tmpl',
		);

my @command_common = ('HELP','VERBOSE');
my %commands = (
		'record'	=> ['TS_SINCE','TS_UNTIL','RPT_TYPE','CONN','HELP','VERBOSE'],
		'notify'	=> ['MAILSUPPRESS','TMPL_DIR','EXCLUDE','INCLUDE','MAILCONF','CONN','HELP','VERBOSE'],
		'process'	=> ['MAILSUPPRESS','TMPL_DIR','MAILCONF','TS_SINCE','TS_UNTIL','RPT_TYPE','CONN','HELP','VERBOSE'],
		'report'	=> ['TMPL_DIR','RPT_ID','CONN','HELP','VERBOSE'],
		'list'		=> ['CONN','HELP','VERBOSE'],
		'timetest'	=> ['HELP','VERBOSE'],
	);
my %CmdOptions = (
	'CONN'		=>	$ora_conn,
	'TS_SINCE'	=>	undef,
	'TS_UNTIL'	=>	undef,
	'RPT_TYPE'	=>	1,
	'RPT_ID'	=>	0,
	'TMPL_DIR'	=>	'etc',
	'EXCLUDE'	=>	undef,
	'INCLUDE'	=>	undef,
	'RPTOBJ_FILE'	=>	undef,
	'MAILCONF'	=>	undef,
	'MAILSUPPRESS'	=>	undef,
	'VERBOSE'	=>	0,
	'HELP'		=>	0
);
	#'REPORT'	=>	0,
	#'RECORD'	=>	0,
	#'NOTIFY'	=>	1,
	#'LIST'		=>	undef,
	#'REPORT'	=>	'report|s!',
	#'RECORD'	=>	'record|r',
	#'NOTIFY'	=>	'notify|n!',
	#'LIST'		=>	'list|l:5',
my %CmdOptionVars = (
	'CONN'		=>	\$CmdOptions{'CONN'},
	'TS_SINCE'	=>	\$CmdOptions{'TS_SINCE'},
	'TS_UNTIL'	=>	\$CmdOptions{'TS_UNTIL'},
	'RPT_TYPE'	=>	\$CmdOptions{'RPT_TYPE'},
	'RPT_ID'	=>	\$CmdOptions{'RPT_ID'},
	'TMPL_DIR'	=>	\$CmdOptions{'TMPL_DIR'},
	'EXCLUDE'	=>	\$CmdOptions{'EXCLUDE'},
	'INCLUDE'	=>	\$CmdOptions{'INCLUDE'},
	'RPTOBJ_FILE'	=>	\$CmdOptions{'RPTOBJ_FILE'},
	'MAILCONF'	=>	\$CmdOptions{'MAILCONF'},
	'MAILSUPPRESS'	=>	\$CmdOptions{'MAILSUPPRESS'},
	'VERBOSE'	=>	\$CmdOptions{'VERBOSE'},
	'HELP'		=>	\$CmdOptions{'HELP'},
);
my %CmdOptionStrs = (
	'CONN'		=>	'oraconn|c=s',
	'RPT_TYPE'	=>	'type|t:1',
	'RPT_ID'	=>	'id=i',
	'TS_SINCE'	=>	'ts_since|1=s',
	'TS_UNTIL'	=>	'ts_until|2=s',
	'TMPL_DIR'	=>	'tmpl_dir|d=s',
	'EXCLUDE'	=>	'exclude|x=s',
	'INCLUDE'	=>	'only|o=s',
	'RPTOBJ_FILE'	=>	'rptobj|r=s',
	'MAILCONF'	=>	'mailconf|m=s',
	'MAILSUPPRESS'	=>	'mailsuppress|q!',
	'VERBOSE'	=>	'verbose|v+',
	'HELP'		=>	'help|h!',
);

my %rpt_types = (
		1	=>	{'RPTTYPE'	=> 'R', 'RPTSUBTYPE'	=> 'W'},
		2	=>	{'RPTTYPE'	=> 'R', 'RPTSUBTYPE'	=> 'L'},
		3	=>	{'RPTTYPE'	=> 'A', 'RPTSUBTYPE'	=> 'N'},
	);

=over 

=item usage()		- Usage information

=back

=cut

sub usage(;$) {
	my ($msg) = @_;
	
	$msg = "" unless $msg;

	print '***:'.$msg.":***\n";
	pod2usage( {
			-message	=> $msg,
			-exitval	=> 1,
			-verbose	=> 3,
			}
	);
}

=over 

=item parse_opts()	- Parse the command line options

=back

=cut

sub parse_opts() {

	my $cmd = lc(shift @ARGV);

	usage('Usage:') if($cmd eq '-h' ||$cmd eq 'help');
	usage('Unknown commands') unless($cmd && exists($commands{$cmd}));

	my %opts;
	map	{ $opts{$CmdOptionStrs{$_}} = \$CmdOptions{$_} }
		@{$commands{$cmd}};

	GetOptions(%opts) 
		or pod2usage( {
			-message	=> 'Option is not supported',
			-exitval	=> 1,
			-verbose	=> 0,
			}
		);

	$CmdOptions{'TS_SINCE'} = DateTime::str2ts_neat($CmdOptions{'TS_SINCE'}) if $CmdOptions{'TS_SINCE'};
	$CmdOptions{'TS_UNTIL'} = DateTime::str2ts_neat($CmdOptions{'TS_UNTIL'}) if $CmdOptions{'TS_UNTIL'};
	$ora_conn	= $CmdOptions{'CONN'}		if $CmdOptions{'CONN'};

	if($CmdOptions{'VERBOSE'})
	{
		$Utils::VERBOSE = $CmdOptions{'VERBOSE'};
		print "\n", '-'x40, "\n";
		print join("\n", map(
					{"\t" . $_ . '=' . ($CmdOptions{$_}||'undef')}
					sort keys %CmdOptions
				));
		print "\n", '-'x40, "\n";
	}

	usage("Unknown type option.")
		if(	defined($CmdOptions{'RPT_TYPE'})
			&& !exists($rpt_types{$CmdOptions{'RPT_TYPE'}})
		);

	#print "TS_SINCE=",$CmdOptions{'TS_SINCE'} if $CmdOptions{'TS_SINCE'};
	#print "TS_UNTIL=",$CmdOptions{'TS_UNTIL'} if $CmdOptions{'TS_UNTIL'};
	Utils::mylog(1, undef, "TS_SINCE=".$CmdOptions{'TS_SINCE'}) if $CmdOptions{'TS_SINCE'};
	Utils::mylog(1, undef, "TS_UNTIL=".$CmdOptions{'TS_UNTIL'}) if $CmdOptions{'TS_UNTIL'};

	$mailer::mail_suppress = 1 if $CmdOptions{'MAILSUPPRESS'};
	
	$cmd;

	#GetOptions(
	#	'oraconn|c=s'	=>	\$CmdOptions{'CONN'},
	#	'type|t:1'	=>	\$CmdOptions{'RPT_TYPE'},
	#	'id=i'		=>	\$CmdOptions{'RPT_ID'},
	#	'ts_since|1=s'	=>	\$CmdOptions{'TS_SINCE'},
	#	'ts_until|2=s'	=>	\$CmdOptions{'TS_UNTIL'},
	#	'report|s!'	=>	\$CmdOptions{'REPORT'},
	#	'record|r'	=>	\$CmdOptions{'RECORD'},
	#	'notify|n!'	=>	\$CmdOptions{'NOTIFY'},
	#	'list|l:5'	=>	\$CmdOptions{'LIST'},
	#	'verbose|v+'	=>	\$CmdOptions{'VERBOSE'},
	#	'help|h!'	=>	\$CmdOptions{'HELP'}
	#	) 
	#or pod2usage( {
	#		-message	=> 'Option is not supported',
	#		-exitval	=> 1,
	#		-verbose	=> 0,
	#		}
	#);

	#usage('Usage:') 	if ($CmdOptions{'HELP'}) ;

	#$ora_conn	= $CmdOptions{'CONN'}		if $CmdOptions{'CONN'};
	#$verbose	= $CmdOptions{'VERBOSE'}	if $CmdOptions{'VERBOSE'};


	#print "TS_SINCE=",DateTime::str2ts_neat($CmdOptions{'TS_SINCE'});
	#print "TS_UNTIL=",DateTime::str2ts_neat($CmdOptions{'TS_UNTIL'});
}

=over

=item acct_fmt_check()		

=back

=cut

sub acct_fmt_check ($;$) {
	my ($accts, $acct_sep) = @_;

	my $acct_seperator = '-';
	$acct_seperator = $acct_sep if $acct_sep;

	my $GM_FMT = qr/^\s*(\d{3,5})$acct_seperator([0-9a-zA-z\.]{1,4})$acct_seperator(\d){6,8}\s*$/;
	my $GL_FMT = qr/^\s*(\d{6,7})$acct_seperator(\d{3})$acct_seperator(\d{3})$acct_seperator(\d){6}$acct_seperator(\d{2})\s*$/;

	foreach $a (@$accts) {
		usage("Account $a does not seem to be in general GMS account format. \n") unless ($a =~ $GM_FMT);
	}
}

sub record_rpt
{
	my $dbh = shift;
	my $rpt_obj = shift;
	my $rpt_type = shift;
	my ($ts_since, $ts_until, $ts_format) = @_;

	my $rpt_id;

	croak "record_rpt - Database handle not defined." unless $dbh;
	die_close("record_rpt - Report Object not defined.", $dbh) unless $rpt_obj;
	die_close("Unknown or undefined report type", $dbh) unless($rpt_type && defined($rpt_types{$rpt_type}));

	if($rpt_types{$rpt_type}->{'RPTTYPE'} eq 'R')
	{
		die_close("record_rpt - unknown RPTSUBTYPE=$rpt_types{$rpt_type}->{'RPTSUBTYPE'} for type=$rpt_type.", $dbh)
			unless(
				$rpt_types{$rpt_type}->{'RPTSUBTYPE'} eq 'W' 
				||$rpt_types{$rpt_type}->{'RPTSUBTYPE'} eq 'L'
				);

		Utils::mylog(2, undef, "rpt_obj->dbRecordRegularRpt(dbh"
					,defined($ts_since)?",ts_since=>$ts_since":"undef"
					,defined($ts_until)?",ts_until=>$ts_until":"undef"
					,defined($rpt_types{$rpt_type}->{'RPTSUBTYPE'})?",$rpt_types{$rpt_type}->{'RPTSUBTYPE'}":"undef"
					,",ts_format);\n");

		$rpt_id = $rpt_obj->dbRecordRegularRpt(
					  $dbh
					, $ts_since
					, $ts_until
					, $rpt_types{$rpt_type}->{'RPTSUBTYPE'}
					, $ts_format
				);

	} elsif($rpt_types{$rpt_type}->{'RPTTYPE'} eq 'A') {
		die_close("No ts_since provided, please use option -1 to specify it.", $dbh) unless($ts_since);

		$ts_until or $ts_until = DateTime::str2ts_neat("`date`");

		Utils::mylog(2, undef, "rpt_obj->dbRecordAdhocRpt(dbh,ts_since=>$ts_since,ts_until=>$ts_until, ts_format);\n");

		$rpt_id = $rpt_obj->dbRecordAdhocRpt(
					  $dbh
					, $ts_since
					, $ts_until
					, $ts_format
				);

	} else {
		die_close("record_rpt - unknown RPTTYPE=$rpt_types{$rpt_type}->{'RPTTYPE'} for type=$rpt_type.", $dbh);
	}
	$rpt_id;
}

sub fetchEmails
{
	my $dbh = shift;
	my $rpt_obj = shift;
	my $rpt_id = shift;
	my $acct_list = shift;

	croak "fetchEmails - Database handle not defined." unless $dbh;
	die_close("fetchEmails - Report Object not defined.", $dbh) unless $rpt_obj;
	die_close("fetchEmails - report ID requested does not seem to match the report fetched.", $dbh)
			unless(!defined($rpt_id) || $rpt_id == ($rpt_obj->reportid || $rpt_id));

	$rpt_obj->fetchEmails($dbh);
}

sub send_notifications
{
	my $dbh = shift;
	my $rpt_obj = shift;
	my $rpt_id = shift;
	my $emailrows = shift;
	my $acct_list = shift;
	my $acct_list_ex_hash = shift;

	my @succeeded = ();
	my @failed = ();

	croak "send_notifications - Database handle not defined." unless $dbh;
	die_close("send_notifications - Report Object not defined.", $dbh) unless $rpt_obj;
	die_close("send_notifications - report ID requested does not seem to match the report fetched.", $dbh)
				unless(!defined($rpt_id) || $rpt_id == ($rpt_obj->reportid || $rpt_id));

        my $tmpl;
	
	if ($CmdOptions{'TMPL_DIR'})
	{
		$tmpl = { TYPE		=> 'FILE',
			  SOURCE	=> "$CmdOptions{'TMPL_DIR'}/$TmplNames{'MailBody'}", 
			};

		$rpt_obj->rpt_template({
					TYPE	=> 'FILE', 
					SOURCE	=> "$CmdOptions{'TMPL_DIR'}/$TmplNames{'Envelope'}",
					});

		$rpt_obj->users->rpt_template({	
					TYPE	=> 'FILE',
					SOURCE	=> "$CmdOptions{'TMPL_DIR'}/$TmplNames{'URptBody'}",
						});

		$rpt_obj->users->rpt_section_tmpl({	
					TYPE	=> 'FILE',
					SOURCE	=> "$CmdOptions{'TMPL_DIR'}/$TmplNames{'URptSection'}",
						});

		$rpt_obj->machines->rpt_template({	
					TYPE	=> 'FILE',
					SOURCE	=> "$CmdOptions{'TMPL_DIR'}/$TmplNames{'MRptBody'}",
						});

		$rpt_obj->machines->rpt_section_tmpl({	
					TYPE	=> 'FILE',
					SOURCE	=> "$CmdOptions{'TMPL_DIR'}/$TmplNames{'MRptSection'}",
						});
	} else {
		$tmpl = $rpt_obj->mail_template;
	}

	if (defined($acct_list))
	{
		$emailrows or $emailrows = $rpt_obj->email;
		die_close("Email information is not available.\n".Dumper($emailrows), $dbh) unless($emailrows);
		
		# To be cautious
		# should compare whether the two lists are the same.
		#my $acct_list = $rpt_obj->acctstring || $rpt_obj->fetchAcctList($dbh);

		Utils::mylog(5, undef, "Get the following email info \n".Data::Dumper->Dump([$emailrows],['emailinfo']));

		foreach my $acct (@$acct_list)
		{
			#chomp($acct);
			if($acct_list_ex_hash)
			{
				next if exists($acct_list_ex_hash->{$acct});
			}

			if(mail_acctrpt($rpt_obj, $acct, $tmpl, $emailrows, 1))
			{
				push @succeeded, $acct;
			} else {
				push @failed, $acct;
			}
			#last;
		}

		my $rpt_cnt = scalar(@$acct_list);
		
		Utils::mylog(1, undef, "Total $rpt_cnt email notifications sent.\n");
		
		my $mailbody = "\n\nThere are $rpt_cnt notifications sent in this batch.\n";

		if(scalar(@failed)>0)
		{
			$mailbody .= "Number of Notification sent successfully   : ".scalar(@succeeded)."\n"
				   . "Number of Notification not sent or failed  : ".scalar(@failed)."\n"
				   . "List of Accounts without notification sent :\n".join("\n",@failed)."\n";
		} else {
			$mailbody .= "All $rpt_cnt notifications were sent out successfully. ";
		}

		my $mail_rtn = mail_admin("Summary - Service Charge Changes report completed",
				$mailbody
			);
				#"\n\nThere are $rpt_cnt notifications sent in this batch.\n"
		Utils::mylog(3, undef, "Admin email notifications sent.\n", "mail_rtn=$mail_rtn");

	} else {
		Utils::mylog(1, undef, 'fetchReport returned undef account list.');
		mail_admin("Summary - Service Charge Changes report completed",
				"fetchReport returned undef account list."
			);
		Utils::mylog(3, undef, "Admin email notifications sent.\n");
	}

}

# report object will be populated
# return account list in report object.
# if $rpt_obj_fname is defined and not empty, 
# the report object will not be populated from DB (since it is loaded from dump file.).
sub fetch_rpt
{
	my $dbh = shift;
	my $rpt_obj = shift;
	my $rpt_id = shift;
	my $rpt_obj_fname = shift;
	# no caller uses them at this moment.
	my ($adhoc, $asof) = @_;

	my $acct_list;

	croak "fetch_rpt - Database handle not defined." unless $dbh;
	die_close( "fetch_rpt - Report Object not defined.", $dbh) unless $rpt_obj;

	if($rpt_obj_fname)
	{
		#The object should be loaded already by dispatcher.
		#$rpt_obj = load_reportobj($CmdOptions{'RPTOBJ_FILE'});
		$acct_list = $rpt_obj->acctstring;
	} else {
		die_close( "fetch_rpt - undefined report ID", $dbh) unless($rpt_id);
	
		Utils::mylog(2, undef, "Fetch Report ID=$rpt_id\n");
		$acct_list = $rpt_obj->fetchReport($dbh, $rpt_id, $adhoc, $asof);
	}
	
	Utils::mylog(4, undef, "Report $rpt_id account list\n".join("\n", @$acct_list));

	$acct_list;
}

sub mail_admin
{
	my $subject = shift || 'Error in Service Charge Changes report';
	my $body = shift || 'Error in Charge Change Report.';

	my $to = $custom_mailconf{'AdminTo'} || "yangl+\@cs.cmu.edu";
	#my $from = $mailconf{} || 'help+costing@cs.cmu.edu';
	my $replyto = $custom_mailconf{'Admin-ReplyTo'} 
			|| $custom_mailconf{'ReplyTo'} 
			|| 'help+costing@cs.cmu.edu';
	my $cc = $custom_mailconf{'AdminCc'} || "yangl";
	my $bcc = $custom_mailconf{'AdminBcc'} || "ramscya";
	#my $format = 'TEXT';

			#$from,
	mailer::mail_user(	
			%custom_mailconf,
			To		=> $to,
			'Reply-To'	=> $replyto,
			Cc		=> $cc,
			Bcc		=> $bcc,
			Subject		=> $subject,
			Data		=> $body,
		);

}

#sub get_acctrpt_content
#{
#	my ($report, $acct) = @_;
#
#	my $rpt_id = $report->reportid;
#
#	Utils::mylog(4, undef, "Generating notification content for $acct ...\n");
#	my $content = $report->rptPrint([$acct]);
#	Utils::mylog(4, undef, "Completed generating notification content for $acct ...\n");
#
#	$content;
#}

sub get_acctrpt_mailbody
{
	my ($report, $acct, $mailtmpl) = @_;

	$report->rptMailBody($acct, $mailtmpl);

	#my $content = get_acctrpt_content($report, $acct);

	#unless($content) 
	#{
	#	print STDERR "Report is empty. No email notification for $acct ...\n";
	#	Utils::mylog(1, undef, "Report is empty. No email notification for $acct ...\n");
	#	return undef;
	#}

	#my $rpt_id = $report->reportid;
	#my ($t_since, $t_until) = $report->getRptTimeRange;
	#$t_since or $t_since = 'Unknown';
	#$t_until or $t_until = 'Unknown';

	#my $t_1 = substr($t_since, 0, 9);
	#my $t_2 = substr($t_until, 0, 9);

	#my $template = Text::Template->new( %$mailtmpl )
	#	or croak "Couldn't construct template: $Text::Template::ERROR";

	#my $amt_u = $report->users->rows->{$acct}->{'_SUMMARY_'}->{'CHARGE'} || 0;
	#my $amt_m = $report->machines->rows->{$acct}->{'_SUMMARY_'}->{'CHARGE'} || 0;
	#my $a = $amt_u + $amt_m;
	#my $amt = Utils::commify(sprintf("%.02f",$a));

	#my $r = $template->fill_in(HASH => {
	#					reportid	=> \$rpt_id,
	#					account		=> \$acct,
	#					amount		=> \$amt,
	#					report		=> \$content,
	#					timesince	=> \$t_1,
	#					timeuntil	=> \$t_2,
	#					}
	#		);
	#unless($r)
	#{
	#	Utils::mylog(1, undef, "$acct - Couldn't fill in template: $Text::Template::ERROR.\n".Data::Dumper->Dump([$report],['report'])."\n");
	#}
	#$r;
}

sub mail_acctrpt
{
	#my ($report, $acct, $mailtmpl, $mailrows, $mailtestflag) = @_;
	my ($report, $acct, $mailtmpl, $mailrows) = @_;
	my $rtn;

	my $mailbody = get_acctrpt_mailbody($report, $acct, $mailtmpl);
	my $rpt_id = $report->reportid;

	chomp($acct);
	if($mailbody)
	{
		Utils::mylog(1, undef, "email notification for $acct ...\n");

		#should check for $mailrows
		if( defined($mailrows)
			&& defined($mailrows->{$acct})
			&& exists($mailrows->{$acct}->{'MAILTO'})
			&& exists($mailrows->{$acct}->{'MAILFROM'})
			&& exists($mailrows->{$acct}->{'MAILREPLYTO'})
			&& exists($mailrows->{$acct}->{'MAILCC'})
			&& exists($mailrows->{$acct}->{'MAILBCC'})
			)
		{
			my $mailcc = $mailrows->{$acct}->{'MAILCC'};

			if (defined($mailrows->{$acct}->{'MSG'}))
			{

				#No report manager found. Send to remedy help+costing@cs.cmu.edu queue.
				$mailcc =~ s/help\+ramsnotify\@cs\.cmu\.edu/help\+costing\@cs\.cmu\.edu/ if(defined($mailcc));
			} else {
				#report manager found. Do not Send to remedy (help+...) queue.
				$mailcc =~ s/,? ?help\+ramsnotify\@cs\.cmu\.edu// if(defined($mailcc));
			}
			$rtn = mailer::mail_user(
					%custom_mailconf,
					To		=> $mailrows->{$acct}->{'MAILTO'},
					From		=> $mailrows->{$acct}->{'MAILFROM'},
					'Reply-To'	=> $mailrows->{$acct}->{'MAILREPLYTO'},
					Cc		=> $mailcc,
					Bcc		=> $mailrows->{$acct}->{'MAILBCC'},
					Type		=> 'TEXT',
					Subject		=> "Notification of Service Charge Changes to $acct ($rpt_id)",
					Data		=> "$mailbody",
					#'X-Rams-Mode'	=> $testflag,
				);
					#Cc		=> $mailrows->{$acct}->{'MAILCC'},
	
		} else {
			#Utils::mylog(1, undef, "mailbody=$mailbody\n");
			Utils::mylog(1, undef, "mail_acctrpt - email info for $acct not found.\n".Data::Dumper->Dump([$mailrows],['mailrows']));
			$rtn = undef;
		}
	
	} else {
		Utils::mylog(1, undef, "Empty email for $acct . No email sent. \n");
		$rtn = $mailbody;
	}
	$rtn;
}

sub list_rpts
{
	my $dbh = shift;
	my $rpt_obj = shift;
	my $count = shift || 5;

	croak "list_rpt - Database handle not defined." unless $dbh;
	croak "list_rpt - Report Object not defined." unless $rpt_obj;

	#my $report = new CMUCS::Rams::Report::ChargeChange::Users;

	my $rptid_list;
	if($rpt_obj)
	{
		$rptid_list = $rpt_obj->dbListRpt_str($dbh, $count);
	} else {
		$rptid_list = dbListRpt_str CMUCS::Rams::Report::ChargeChange::ChargeChange::($dbh, $count);
	}

	print "\n".$rptid_list;
}

sub cmd_record
{
	my $dbh = shift;
	my $rpt_obj = shift;

	($dbh && $rpt_obj) || die_close("cmd_notify - Wrong arguments.", $dbh);
	#unless($dbh && $rpt_obj) { 
	#	$dbh->disconnect if($dbh);
	#	croak "cmd_record - Wrong arguments.";
	#};
	
	$CmdOptions{'RPT_TYPE'} = 1 unless defined($CmdOptions{'RPT_TYPE'});
	if($CmdOptions{'RPT_TYPE'} == 3)
	{
		unless($CmdOptions{'TS_SINCE'} && $CmdOptions{'TS_UNTIL'})
		{
			$dbh->disconnect() if $dbh;
			usage('Both ts_since and ts_until are required for Type 3 reports.');
		}
	}
	my $rpt_id = record_rpt(	
					$dbh
					, $rpt_obj
					, $CmdOptions{'RPT_TYPE'}
					, $CmdOptions{'TS_SINCE'}
					, $CmdOptions{'TS_UNTIL'}
				);
	unless($rpt_id) {
		$dbh->disconnect();
		croak "Error recording report $rpt_id.";
	};
	print STDERR "report id=$rpt_id recorded successfully.\n";
	$rpt_id;
}

sub cmd_notify
{
	my $dbh = shift;
	my $rpt_obj = shift;
	my $rpt_id = shift;
	my $rpt_obj_fname = shift;

	($dbh && $rpt_obj && $rpt_id)
		|| die_close("cmd_notify - Wrong arguments."
			. Data::Dumper->Dump([$rpt_obj], ['report'])."\n"
			,$dbh
			);

	#unless($dbh && $rpt_obj && $rpt_id) {
	#	$dbh->disconnect() if $dbh;
	#	croak "cmd_notify - Wrong arguments.";
	#};
	
	my $acct_list;
	my $emailrows;
	#
	my $exclude_fname = $CmdOptions{'EXCLUDE'};
	my $include_fname = $CmdOptions{'INCLUDE'};
	my $acct_list_ex = undef;
	my $acct_list_ex_hash = undef;
	my $acct_list_in = undef;

	if ($exclude_fname)
	{
		Utils::mylog(1, undef, "Exclude accounts in file $exclude_fname.\n");
		$acct_list_ex = Utils::get_acctlist_fromfile($exclude_fname) 
			or die_close("exclude account list is empty.", $dbh);
		map { $acct_list_ex_hash->{$_} = 1 } @$acct_list_ex;
	} 
	if ($include_fname)
	{
		Utils::mylog(1, undef, "Notify only accounts in file $include_fname.\n");
		$acct_list_in = Utils::get_acctlist_fromfile($include_fname)
				or die_close("include account list is empty.", $dbh);
	}

	$acct_list = fetch_rpt($dbh, $rpt_obj, $rpt_id, $rpt_obj_fname);
	#Utils::mylog(5, undef, "Account list returned from DB.\n".join("\n", @$acct_list));

	$emailrows = fetchEmails($dbh, $rpt_obj, $rpt_id, $acct_list) unless $rpt_obj_fname;

	$acct_list = $acct_list_in if $acct_list_in;

	Utils::dump_reportobj($rpt_obj) unless $rpt_obj_fname;

	send_notifications($dbh, $rpt_obj, $rpt_id, $emailrows, $acct_list, $acct_list_ex_hash);

	Utils::mylog(1, undef, "report id=$rpt_id notification completed.\n");

	#send_rpt($dbh, $rpt_obj, $rpt_id);
	#print STDERR "report id=$rpt_id notification completed.\n";
	1;
}

#--------------------
# Command dispatcher
#--------------------
sub dispatcher
{
	my $cmd = shift;

	if($cmd eq 'timetest')
	{
		my $timestr = shift @ARGV;

		print STDERR DateTime::str2ts_neat($timestr), "\n";
		return 1;
	}

	print "Using connection string $ora_conn \n";
	#my $dbh = shift || Oracle::ora_connect('ccreport/ccreport');
	my $dbh = shift || Oracle::ora_connect("$ora_conn");
	my $rpt_obj = shift || CMUCS::Rams::Report::ChargeChange::ChargeChange->new;

	usage('Unknown commands in cmd_dispatch') unless($cmd && exists($commands{$cmd}));

	my %mailconf_extra;

	if($CmdOptions{'MAILCONF'}) {
		if(-r "$CmdOptions{'MAILCONF'}") {
			#%mailconf_extra = Utils::load_configfile("./.mailconf");
			%mailconf_extra = Utils::load_configfile("$CmdOptions{'MAILCONF'}");
			%custom_mailconf = ( %mailer::default_mailconf, %mailconf_extra );
		} else {
			die_close("File $CmdOptions{'MAILCONF'} not readable. $!", $dbh);
		}
	}

	Utils::mylog(2, undef, map { "$_\t\t=$custom_mailconf{$_}" } sort keys %custom_mailconf);
	
	if($cmd eq 'list') {

		my $cnt = shift @ARGV;
		list_rpts($dbh, $rpt_obj, $cnt);

	} elsif($cmd eq	'process') {

		my $rpt_id = cmd_record($dbh, $rpt_obj);
		die_close("Error recording report.", $dbh) unless $rpt_id;
		cmd_notify($dbh, $rpt_obj, $rpt_id);
		
	} elsif($cmd eq	'notify') {

		my $rpt_id = shift @ARGV;

		if($CmdOptions{'RPTOBJ_FILE'})
		{
			Utils::mylog(2, undef, "Load report object from file $CmdOptions{'RPTOBJ_FILE'}.\n");
			$rpt_obj = Utils::load_reportobj($CmdOptions{'RPTOBJ_FILE'});
		} else {
			unless($rpt_id) {
				$dbh->disconnect();
				usage("command $cmd requires <report_id> specified.");
			};
		}

		cmd_notify($dbh, $rpt_obj, $rpt_id, $CmdOptions{'RPTOBJ_FILE'});
		
	} elsif($cmd eq	'record') {

		my $rpt_id = cmd_record($dbh, $rpt_obj);

	} elsif($cmd eq	'report') {
		$dbh->disconnect() if $dbh;
		croak "Command $cmd does not have actions defined yet.";
	} else {
		$dbh->disconnect() if $dbh;
		croak "Command $cmd does not have actions defined.";
	}

	$dbh->disconnect() if $dbh;
}

sub die_close
{
	my ($msg, $dbh) = @_;

	$dbh->disconnect() if $dbh;
	croak "Error : $msg";
}

#--------------------------------
# Main
#--------------------------------
#

my $CMD = parse_opts;

#my $debug = $CmdOptions{'VERBOSE'} || 0;
#if ($debug > 0)
#{
#	DBI->trace($debug);
#}
#print "Execute command <$CMD>\n" if $CmdOptions{'VERBOSE'};

Utils::mylog(1, undef, "Execute command <$CMD>\n");
dispatcher($CMD, $dbh, undef);

#$dbh->disconnect() if $dbh;

1;

__END__

sub init_ora() {

	$ENV{'ORACLE_HOME'} = $DEFAULT_ORAHOME unless defined($ENV{'ORACLE_HOME'});
	print "ORACLE_HOME=$ENV{'ORACLE_HOME'}\n" if $verbose;
	$SQLPLUS = "$ENV{'ORACLE_HOME'}/bin/sqlplus";
}

=pod

=head1 EXAMPLES

	rptProc.pl help 
	rptProc.pl timetest '2005/12/11'
	rptProc.pl list 
	rptProc.pl list 20

	rptProc.pl process 
	rptProc.pl process -t 1
	rptProc.pl process -t 2
	rptProc.pl process -t 3 -1 '2006/01/12' -2 '2006/01/19'
	rptProc.pl notify 10

=head1 AUTHOR

Longjiang Yang, E<lt>yangl+@cs.cmu.eduE<gt>

=head1 COPYRIGHT
	
	School of Computer Science
	Carnegie Mellon University

=head1 SEE ALSO

L<Perl>

=cut
