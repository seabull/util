#!/usr/local/bin/perl58 -w
# $Header: c:\\Repository/database/rams/projects/reports_batch/AcctExpiringRpt/bin/acctexpProc.pl,v 1.20 2006/08/14 18:05:13 yangl Exp $
#

use strict;

use DBI;
use Getopt::Long;
use Carp;
use Pod::Usage;
use Time::ParseDate;
use Text::Template;
use DBD::Oracle qw(:ora_types);
#use File::Log;

#use lib 'lib/perl5';
use lib 'lib/perl';
#use lib '/afs/cs/user/yangl/.sys/sun4x_59/lib/perl5';
use MIME::Lite;

#use lib '../lib/perl';

use CMUCS::Rams::Report::Utils::Utils;
use CMUCS::Rams::Report::Utils::DateTime;
use CMUCS::Rams::Report::Utils::Oracle;
use CMUCS::Rams::Report::Utils::mailer qw(mail_user $mail_suppress $mail_log_fd %default_mailconf);

use CMUCS::Rams::Report::AcctExp::AcctExpEntity;
use CMUCS::Rams::Report::AcctExp::AcctExpReport;

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

B<acctexpProc.pl> <command> [command-options] <command arguments>

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
				1	- Regular weekly
				2	- Regular labor
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
my $DEFAULT_DUMPFILE = "./.acctexprpt_object.perldata";

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
my ($LOG_LEVELA, $LOG_LEVELB, $LOG_LEVELC, $LOG_LEVELD, $LOG_LEVELE) = (1,2,3,4,5);

my %TmplNames = (
		'Envelope'	=> 'acctexp_envelop.tmpl',
		'RptBody'	=> 'acctexp_report.tmpl',
		'RptSection'	=> 'acctexp_section.tmpl',
		'MailBody'	=> 'acctexp_mail.tmpl',
		);


my %commands = (
		'record'	=> ['TS_SINCE','TS_UNTIL','CONN','HELP','VERBOSE'],
		'notify'	=> ['TMPL_DIR','CONN','EXCLUDE','INCLUDE','RPTOBJ_FILE','MAILCONF','HELP','VERBOSE'],
		'process'	=> ['TMPL_DIR','TS_SINCE','TS_UNTIL','CONN','MAILCONF','HELP','VERBOSE'],
		'report'	=> ['TMPL_DIR','CONN','MAILCONF','HELP','VERBOSE'],
		'list'		=> ['CONN','HELP','VERBOSE'],
		'timetest'	=> ['HELP','VERBOSE'],
	);

my %CmdOptions = (
	'CONN'		=>	$ora_conn,
	'TS_SINCE'	=>	undef,
	'TS_UNTIL'	=>	undef,
	'RPT_TYPE'	=>	1,
	'TMPL_DIR'	=>	'etc',
	'EXCLUDE'	=>	undef,
	'INCLUDE'	=>	undef,
	'RPTOBJ_FILE'	=>	undef,
	'MAILCONF'	=>	undef,
	'VERBOSE'	=>	0,
	'HELP'		=>	0
);
	#'RPT_ID'	=>	0,
	#'REPORT'	=>	0,
	#'RECORD'	=>	0,
	#'NOTIFY'	=>	1,
	#'LIST'		=>	undef,
	#'REPORT'	=>	'report|s!',
	#'RECORD'	=>	'record|r',
	#'NOTIFY'	=>	'notify|n!',
	#'LIST'		=>	'list|l:5',

	#'RPT_ID'	=>	\$CmdOptions{'RPT_ID'},
my %CmdOptionVars = (
	'CONN'		=>	\$CmdOptions{'CONN'},
	'TS_SINCE'	=>	\$CmdOptions{'TS_SINCE'},
	'TS_UNTIL'	=>	\$CmdOptions{'TS_UNTIL'},
	'RPT_TYPE'	=>	\$CmdOptions{'RPT_TYPE'},
	'TMPL_DIR'	=>	\$CmdOptions{'TMPL_DIR'},
	'EXCLUDE'	=>	\$CmdOptions{'EXCLUDE'},
	'INCLUDE'	=>	\$CmdOptions{'INCLUDE'},
	'RPTOBJ_FILE'	=>	\$CmdOptions{'RPTOBJ_FILE'},
	'MAILCONF'	=>	\$CmdOptions{'MAILCONF'},
	'VERBOSE'	=>	\$CmdOptions{'VERBOSE'},
	'HELP'		=>	\$CmdOptions{'HELP'},
);
	#'RPT_ID'	=>	'id=i',
my %CmdOptionStrs = (
	'CONN'		=>	'oraconn|c=s',
	'RPT_TYPE'	=>	'type|t:1',
	'TS_SINCE'	=>	'ts_since|1=s',
	'TS_UNTIL'	=>	'ts_until|2=s',
	'TMPL_DIR'	=>	'tmpl_dir|d=s',
	'EXCLUDE'	=>	'exclude|x=s',
	'INCLUDE'	=>	'only|o=s',
	'RPTOBJ_FILE'	=>	'rptobj|r=s',
	'MAILCONF'	=>	'mailconf|m=s',
	'VERBOSE'	=>	'verbose|v+',
	'HELP'		=>	'help|h!',
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
		print "\n", 
			'-'x40, "\n",
			join("\n", map(
					{"\t" . $_ . '=' . ($CmdOptions{$_}||'undef')}
					sort keys %CmdOptions
				)),
			"\n",
			'-'x40, "\n";
	}

	#usage("Unknown type option.")
	#	if(	defined($CmdOptions{'RPT_TYPE'})
	#		&& !exists($rpt_types{$CmdOptions{'RPT_TYPE'}})
	#	);

	usage("options -x and -X are mutually exclusive.") 
			if (defined($CmdOptions{'EXCLUDE'}) && defined($CmdOptions{'INCLUDE'}));

	Utils::mylog(1, undef, "TS_SINCE=",$CmdOptions{'TS_SINCE'}) if $CmdOptions{'TS_SINCE'};
	Utils::mylog(1, undef, "TS_UNTIL=",$CmdOptions{'TS_UNTIL'}) if $CmdOptions{'TS_UNTIL'};

	#print join("\n", map $_ . "=" . $CmdOptions{$_}  sort keys %CmdOptions) if $CmdOptions{'VERBOSE'};
	
	$cmd;

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
	# 
	# The following parameters are Not used
	#
	my $rpt_type = shift;
	#my ($ts_since, $ts_until, $ts_format) = @_;

	my $rpt_id;

	croak "record_rpt - Database handle not defined." unless $dbh;
	die_close( "record_rpt - Report Object not defined.", $dbh) unless $rpt_obj;
	#croak "Unknown or undefined report type" unless($rpt_type && defined($rpt_types{$rpt_type}));

	#print "rpt_obj->dbRecordRpt(dbh)"
	#		if $CmdOptions{'VERBOSE'};
	Utils::mylog(1, undef, "rpt_obj->dbRecordRpt(dbh)");

	$rpt_id = $rpt_obj->dbRecordRpt($dbh);
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
		#$rpt_obj = Utils::load_reportobj($CmdOptions{'RPTOBJ_FILE'});
		$acct_list = $rpt_obj->acctstring;
	} else {
		die_close( "fetch_rpt - undefined report ID", $dbh) unless($rpt_id);
	
		Utils::mylog(2, undef, "Fetch Report ID=$rpt_id\n");
		#$asof = 0 unless(defined($asof));
		$acct_list = $rpt_obj->fetchReport($dbh, $rpt_id, $adhoc, $asof);
	}
	
	Utils::mylog(4, undef, "Report $rpt_id account list\n".join("\n", @$acct_list));

	$acct_list;
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

	#my $rows = $rpt_obj->fetchEmails($dbh);
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

	#Utils::mylog(2, undef, "Fetch Report ID=$rpt_id\n");
	#my $acct_list = $rpt_obj->fetchReport($dbh, $rpt_id);

	#Utils::mylog(3, undef, "Report $rpt_id account list\n".join("\n", @$acct_list));

	$rpt_obj->rpt_template({	TYPE	=> 'FILE', 
					SOURCE	=> "$CmdOptions{'TMPL_DIR'}/$TmplNames{'Envelope'}",
				});

        $rpt_obj->entities->rpt_template({	TYPE	=> 'FILE',
						SOURCE	=> "$CmdOptions{'TMPL_DIR'}/$TmplNames{'RptBody'}",
					});

        $rpt_obj->entities->rpt_section_tmpl({	TYPE	=> 'FILE',
						SOURCE	=> "$CmdOptions{'TMPL_DIR'}/$TmplNames{'RptSection'}",
					});

        my $tmpl = { TYPE => 'FILE', SOURCE => "$CmdOptions{'TMPL_DIR'}/$TmplNames{'MailBody'}", };

	if (defined($acct_list))
	{
		#my $rows = $rpt_obj->fetchEmails($dbh);

		$emailrows or $emailrows = $rpt_obj->email;
		die_close("Email information is not available.\n".Dumper($emailrows), $dbh) unless($emailrows);
		
		# To be cautious
		# should compare whether the two lists are the same.
		#my $acct_list = $rpt_obj->acctstring || $rpt_obj->fetchAcctList($dbh);

		Utils::mylog(5, undef, "Get the following email info \n".Data::Dumper->Dump([$emailrows],['emailinfo']));

		foreach my $acct (@$acct_list)
		{
			chomp($acct);

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
		
		mail_admin($rpt_obj, $acct_list, \@succeeded, \@failed);

		#my $mailbody = "\n\nThere are $rpt_cnt notifications sent in this batch.\n";

		#if(scalar(@failed)>0)
		#{
		#	$mailbody .= "Number of Notification sent successfully : ".scalar(@succeeded)."\n";
		#	$mailbody .= "Number of Notification failed            : ".scalar(@failed)."\n";
		#	$mailbody .= "Failed Account list :\n".join("\n",@failed)."\n";
		#} else {
		#	$mailbody .= "All $rpt_cnt notifications were sent out successfully. ";
		#}
		#mail_admin("Summary - Oracle String Expiration Notification Batch completed",
		#		$mailbody
		#	);
				#"\n\nThere are $rpt_cnt notifications sent in this batch.\n"

	} else {
		Utils::mylog(1, undef, 'fetchReport returned undef account list.');
		mail_admin2("Summary - Oracle String Expiring Notification Batch completed",
				"No email notifications sent."
			);
	}

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
	my ($report, $acct, $mailtmpl, $mailrows) = @_;

	$report->rptMailBody($acct, $mailtmpl);

	#my $content = get_acctrpt_content($report, $acct);

	#unless($content) 
	#{
	#	print STDERR "Report is empty. No email notification for $acct ...\n";
	#	Utils::mylog(1, undef, "Report is empty. No email notification for $acct ...\n");
	#	return undef;
	#}

	#my $rpt_id = $report->reportid;
	#my $template = Text::Template->new( %$mailtmpl )
	#	or croak "Couldn't construct template: $Text::Template::ERROR".Data::Dumper->Dump([$report], ['rpt_obj']);

	#my $a = 0;
	#my ($reason, $expdate, $daycount) = ('Unknown', 'today', 0);

	##Utils::mylog(3, undef, "*********".Dumper($report->entities->rows->{$acct}));

	#if(defined($report->entities->rows->{$acct})
	#	&& defined($report->entities->rows->{$acct}->{'_SUMMARY_'}))
	#{
	#	$a = $report->entities->rows->{$acct}->{'_SUMMARY_'}->{'CHARGE'} || 0;

	#	$reason = $report->entities->rows->{$acct}->{'_SUMMARY_'}->{'REASON'}
	#		if(defined($report->entities->rows->{$acct}->{'_SUMMARY_'}->{'REASON'}));
	#	$expdate = $report->entities->rows->{$acct}->{'_SUMMARY_'}->{'EXPDATE'} 
	#		if(defined($report->entities->rows->{$acct}->{'_SUMMARY_'}->{'EXPDATE'}));
	#	$daycount = $report->entities->rows->{$acct}->{'_SUMMARY_'}->{'DAYCOUNT'} 
	#		if(defined($report->entities->rows->{$acct}->{'_SUMMARY_'}->{'DAYCOUNT'}));
	#}
	##Utils::mylog(3, undef, "*********".Dumper($report->entities->rows->{$acct}));

	##Utils::mylog(3, undef, "Net Change for $acct is $a");
	#my $amt = Utils::commify(sprintf("%.02f",$a));
	#Utils::mylog(3, undef, "Net Change for $acct is $amt");

	#my $r = $template->fill_in(HASH => {
	#					reportid	=> \$rpt_id,
	#					account		=> \$acct,
	#					amount		=> \$amt,
	#					report		=> \$content,
	#					reason		=> \$reason,
	#					expdate		=> \$expdate,
	#					daycount	=> \$daycount,
	#					#timesince	=> \$t_1,
	#					#timeuntil	=> \$t_2,
	#					}
	#		);
	#
	##$r || croak "$acct - Couldn't fill in template: $Text::Template::ERROR.\n".Data::Dumper->Dump([$report],['rpt_obj']);
	#unless($r)
	#{
	#	Utils::mylog(1, undef, "$acct - Couldn't fill in template: $Text::Template::ERROR.\n".Data::Dumper->Dump([$report],['rpt_obj'])."\n");
	#	#croak "$acct - Couldn't fill in template: $Text::Template::ERROR.\n".Data::Dumper->Dump([$report],['rpt_obj']);
	#}
	#$r;
}

sub list_rpts
{
	my $dbh = shift;
	my $rpt_obj = shift;
	my $count = shift || 5;

	croak "list_rpt - Database handle not defined." unless $dbh;
	die_close("list_rpt - Report Object not defined.", $dbh) unless $rpt_obj;

	#my $report = new CMUCS::Rams::Report::ChargeChange::Users;

	my $rptid_list;
	if($rpt_obj)
	{
		$rptid_list = $rpt_obj->dbListRpt_str($dbh, $count);
	} else {
		$rptid_list = dbListRpt_str CMUCS::Rams::Report::ChargeChange::ChargeChange::($dbh, $count);
	}

	print $rptid_list;
}

sub mail_acctrpt
{
	my ($report, $acct, $mailtmpl, $mailrows, $testflag) = @_;

	my $rtn;

	my $mailbody = get_acctrpt_mailbody($report, $acct, $mailtmpl);
	my $rpt_id = $report->reportid;

	chomp($acct);
	if($mailbody)
	{
		Utils::mylog(1, undef, "email notification for $acct ...\n");

		#should check for $mailrows
		#croak "mail_acctrpt - email info for $acct not found.\n".Data::Dumper->Dump([$mailrows],['mailrows'])
		if( defined($mailrows)
			&& defined($mailrows->{$acct})
			&& exists($mailrows->{$acct}->{'MAILTO'})
			&& exists($mailrows->{$acct}->{'MAILFROM'})
			&& exists($mailrows->{$acct}->{'MAILREPLYTO'})
			&& exists($mailrows->{$acct}->{'MAILCC'})
			&& exists($mailrows->{$acct}->{'MAILBCC'})
			)
		{
			#($to, $from, $replyto, $cc, $bcc, $type, $subject, $message) = @_;
			if($report->entities->hasEntries($acct))
			{
				$rtn = mailer::mail_user(
					%custom_mailconf,
					To		=> $mailrows->{$acct}->{'MAILTO'},
					From		=> $mailrows->{$acct}->{'MAILFROM'},
					'Reply-To'	=> $mailrows->{$acct}->{'MAILREPLYTO'},
					Cc		=> $mailrows->{$acct}->{'MAILCC'},
					Bcc		=> $mailrows->{$acct}->{'MAILBCC'},
					Type		=> 'TEXT',
					Subject		=> "Oracle String Expiration Notification for $acct ($rpt_id)",
					Data		=> "$mailbody",
				) ;
			} else {
				Utils::mylog(1, undef, "Not sending notification for $acct");
				$rtn = $mailbody;
			}
	
		} else {
			#Utils::mylog(1, undef, "mailrows=".defined($mailrows)."\n");
			#Utils::mylog(1, undef, "mailrows keys=".join("...\n",keys %$mailrows)."\n");
			#Utils::mylog(1, undef, "acct=".defined($mailrows->{"'".$acct."'"})."\n");
			#Utils::mylog(1, undef, "acct=$acct"."\n");
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

sub mail_admin
{
	my ($reportobj, $acctlist, $succeededlist, $failedlist) = @_;

	die_close("mail admin - Report Object not defined.", $dbh) unless $reportobj;
	
	my $linesep = "\n";
	my $summarystring = $reportobj->getSummaryStr($failedlist);
	my $rpt_cnt = scalar(@$acctlist);

	my $mailbody = $linesep x 2 . "There are $rpt_cnt notifications recorded in this batch.".$linesep;

       	if(defined($failedlist) && scalar(@$failedlist)>0)
       	{
       		$mailbody .= "Number of Notification sent successfully : ".scalar(@$succeededlist).$linesep;
       		$mailbody .= "Number of Notification failed            : ".scalar(@$failedlist).$linesep;
       	} else {
       		$mailbody .= "All $rpt_cnt notifications were sent out successfully. ".$linesep;
       	}
	$mailbody .= $linesep x 2 . $summarystring;
       	mail_admin2("Summary - Oracle String Expiration Notification Batch completed",
       			$mailbody
       		);
}
sub mail_admin2
{
	my $subject = shift || 'Error in Oracle String Expiration Notification';
	my $body = shift || 'Error in Oracle String Expiration Notification.';

	my $to = $custom_mailconf{'AdminTo'} || 'yangl+@cs.cmu.edu';
	my $from = $custom_mailconf{'AdminFrom'} ||  $custom_mailconf{'From'} || 'help+costing@cs.cmu.edu';
	my $replyto = $custom_mailconf{'Admin-ReplyTo'} || $from;
	my $cc = $custom_mailconf{'AdminCc'} || '';
	my $bcc = $custom_mailconf{'AdminBcc'} || '';
	my $format = 'TEXT';

	mailer::mail_user(	
			%custom_mailconf,
			To		=> $to,
			'Reply-To'	=> $replyto,
			From		=> $from,
			Cc		=> $cc,
			Bcc		=> $bcc,
			Type		=> $format,
			Subject		=> $subject,
			Data		=> $body,
		);
			#'X-Rams-Mode'	=> 'Test',

}

sub log_notifications
{
}

sub cmd_record
{
	my $dbh = shift;
	my $rpt_obj = shift;

	Utils::mylog($LOG_LEVELB, undef, "Recording report in database.");
	($dbh && $rpt_obj) || die_close("cmd_record - Wrong arguments.", $dbh);

	my $rpt_id = record_rpt(	
					$dbh
					, $rpt_obj
				);
					#, $CmdOptions{'RPT_TYPE'}
					#, $CmdOptions{'TS_SINCE'}
					#, $CmdOptions{'TS_UNTIL'}
	unless($rpt_id) {
		#$dbh->disconnect();
		die_close("Error recording report $rpt_id.", $dbh);
	};
	Utils::mylog($LOG_LEVELA, undef, "report id=$rpt_id recorded successfully.\n");
	$rpt_id;
}

sub cmd_notify
{
	my $dbh = shift;
	my $rpt_obj = shift;
	my $rpt_id = shift;
	my $rpt_obj_fname = shift;

	($dbh && $rpt_obj && $rpt_id) 
		|| die_close("cmd_notify - Wrong arguments.".Data::Dumper->Dump([$rpt_obj], ['rpt_obj']), $dbh);

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

	Utils::mylog($LOG_LEVELB, undef, "Fetching Email and sending notifications.");
	if ($exclude_fname)
	{
		Utils::mylog($LOG_LEVELA, undef, "Exclude accounts in file $exclude_fname.\n");
		$acct_list_ex = Utils::get_acctlist_fromfile($exclude_fname) 
			or die_close("exclude account list is empty.", $dbh);
		map { $acct_list_ex_hash->{$_} = 1 } @$acct_list_ex;
	} 
	if ($include_fname)
	{
		Utils::mylog($LOG_LEVELA, undef, "Notify only accounts in file $include_fname.\n");
		$acct_list_in = Utils::get_acctlist_fromfile($include_fname)
				or die_close("include account list is empty.", $dbh);
	}

	Utils::mylog($LOG_LEVELC, undef, "fetching Report data from database.\n");
	$acct_list = fetch_rpt($dbh, $rpt_obj, $rpt_id, $rpt_obj_fname);
	#Utils::mylog(5, undef, "Account list returned from DB.\n".join("\n", @$acct_list));

	Utils::mylog($LOG_LEVELC, undef, "fetching Emails from database.\n");
	$emailrows = fetchEmails($dbh, $rpt_obj, $rpt_id, $acct_list) unless $rpt_obj_fname;

	$acct_list = $acct_list_in if $acct_list_in;

	Utils::dump_reportobj($rpt_obj) unless $rpt_obj_fname;

	Utils::mylog($LOG_LEVELC, undef, "Sending Emails notifications.\n");
	send_notifications($dbh, $rpt_obj, $rpt_id, $emailrows, $acct_list, $acct_list_ex_hash);

	Utils::mylog($LOG_LEVELA, undef, "report id=$rpt_id notification completed.\n");
	1;
}

sub cmd_report
{
	my $dbh = shift;
	my $rpt_obj = shift;
	my $rpt_id = shift;

	($dbh && $rpt_obj && $rpt_id) || die_close("cmd_report - Wrong arguments.", $dbh);

	Utils::mylog($LOG_LEVELB, undef, "fetching Adhoc Report data from database.\n");
	my $acct_list = fetch_rpt($dbh, $rpt_obj, $rpt_id);
	#send_rpt($dbh, $rpt_obj, $rpt_id);

	$rpt_obj->rpt_template({	TYPE	=> 'FILE', 
					SOURCE	=> "$CmdOptions{'TMPL_DIR'}/$TmplNames{'Envelope'}",
				});

        $rpt_obj->entities->rpt_template({	TYPE	=> 'FILE',
						SOURCE	=> "$CmdOptions{'TMPL_DIR'}/$TmplNames{'RptBody'}",
					});

        $rpt_obj->entities->rpt_section_tmpl({	TYPE	=> 'FILE',
						SOURCE	=> "$CmdOptions{'TMPL_DIR'}/$TmplNames{'RptSection'}",
					});


	Utils::mylog($LOG_LEVELA, undef, "report id=$rpt_id notification completed.\n");
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

	my $dbh = shift || Oracle::ora_connect("$ora_conn");
	#my $dbh = shift || Oracle::ora_connect('ccreport/ccreport');
	my $rpt_obj = shift || CMUCS::Rams::Report::AcctExp::AcctExpReport->new;

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
			$rpt_obj->reportid($rpt_id);
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
Utils::mylog(1,undef, "Execute command <$CMD>\n");

dispatcher($CMD, $dbh, undef);

Utils::mylog(1, undef, "command <$CMD> completed\n");

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
