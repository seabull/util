#!/usr/local/bin/perl58 -w

#use lib '/afs/cs/user/yangl/.sys/sun4x_59/lib/perl5';
#use MIME::Lite;

#use lib '.';
use lib '/afs/cs/user/yangl/.sys/common/lib/perl5';
use mailer qw(mail_user $mail_suppress $mail_log_fd %default_mailconf);
use Carp;
use Text::Template;

my $content = q!

Net Increase for users : $ 8.15

!;

sub main
{
	my (@args) = @_;
	#my $ora_conn = shift @args || "/\@facqa.crescent";

	##my $dbh = CMUCS::Rams::Report::Utils::Oracle::ora_connect("$ora_conn");
	#my $dbh = Oracle::ora_connect("$ora_conn");

	#my $rows = HashByCol(fetchData($dbh));
	##print Dumper($rows);

	#my $rpt_content = stringifyRows($rows->{'mpa'});

	my $mailtmpl = { TYPE => 'FILE', SOURCE => './mail.tmpl' };

	my $template = Text::Template->new( %$mailtmpl )
               or croak "Couldn't construct template: $Text::Template::ERROR";

	my $mailcontent = $template->fill_in(HASH => {
					starttime	=> 'Jun-20-2006 12AM',
					endtime		=> 'Jun-22-2006 12AM'
				}
			);

	my $subject = 'PTAs charged in FY06 without Report Managers';
	#print $mailcontent;

	#mailer::mail_user(
	#		To              => 'yangl+@cs.cmu.edu',
	#		From            => 'help+costing@cs.cmu.edu',
	#		'Reply-To'      => 'help+costing@cs.cmu.edu',
	#		Cc              => 'ylj@andrew.cmu.edu',
	#		Bcc             => 'ylj@andrew.cmu.edu',
	#		Type            => 'TEXT',
	#		Subject         => "Test - Machine Primary User",
	#		Data            => "$mailcontent",
	#		);
	mailer::mail_attachments(
		{
			'Return-Path'	=> 'longjiang.yang@cs.cmu.edu',
			To		=> 'yangl@cs.cmu.edu',
			To		=> 'kelly.mullins@cs.cmu.edu, ed0u@cs.cmu.edu, ed0u@andrew.cmu.edu',
			To		=> 'ed0u@cs.cmu.edu, ed0u@andrew.cmu.edu',
			From		=> 'longjiang.yang@cs.cmu.edu',
			Sender		=> 'longjiang.yang@cs.cmu.edu',
			Cc		=> 'michael.nikithser@cs.cmu.edu',
			Cc		=> 'ed0u+@cs.cmu.edu',
			Bcc		=> 'yangl@cs.cmu.edu',
			'Reply-To'	=> 'longjiang.yang@cs.cmu.edu',
			'Return-Path'	=> 'longjiang.yang@cs.cmu.edu',
			###
			#To		=> 'yangl@cs.cmu.edu',
			#From		=> 'longjiang.yang@cs.cmu.edu',
			#Sender          => 'longjiang.yang@cs.cmu.edu',
			#Cc              => 'longjiang.yang@cs.cmu.edu',
			#Bcc             => 'yangl@cs.cmu.edu',
			#'Reply-To'      => 'longjiang.yang@cs.cmu.edu',
			#'Return-Path'   => 'longjiang.yang@cs.cmu.edu',
			###
			'X-Rams-Mode'   => 'beta',
			Type		=> 'Text',
			Subject         => "$subject",
			Data            => "$mailcontent",
		},
		{
			Type		=> 'Text/csv',
			Disposition	=> 'attachment',
			Path		=> './Charged_NotIn_RM2.csv',
			Filename	=> 'Charged_NotIn_RM.csv'
		}
                );


	#$dbh && $dbh->disconnect();
}

use Cwd 'abs_path';
if (abs_path($0) eq abs_path(__FILE__))
{
    no strict 'refs';
    exit &main(@ARGV);
}

1;
