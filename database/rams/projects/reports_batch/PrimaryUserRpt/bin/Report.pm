#!/usr/local/bin/perl58 -w
#
#   $Author: yangl $
#   $Date: 2006/11/27 19:10:32 $
#   $RCSfile: Report.pm,v $
#   $Revision: 1.1 $
#
#   $Id: Report.pm,v 1.1 2006/11/27 19:10:32 yangl Exp $
#

use strict;

#package PrimaryUserRpt::Report;
package Report;

use DBI;
use Carp;
use Pod::Usage;
use DBD::Oracle qw(:ora_types);

#use lib 'lib/perl';
#use MIME::Lite;

#use lib '/afs/cs.cmu.edu/user/yangl/rams/ProdOps/AdhocReports/AllDetails/database/rams/projects/reports_batch/ChargeChangeBatch/lib/perl';

#use CMUCS::Rams::Report::Utils::Utils;
#use CMUCS::Rams::Report::Utils::DateTime;
#use CMUCS::Rams::Report::Utils::Oracle;
#use CMUCS::Rams::Report::Utils::mailer qw(mail_user $mail_suppress $mail_log_fd %default_mailconf);

use Data::Dumper;

sub fetchData
{
	my $dbh = shift ;

	my $sql = qq{
			select
				ASSETNO
				,HOSTNAME
				,PRI
				,OS
				,OSVERS
				,CPUTYPE
				,CPUMODEL
				,CPUMODELEXT
				,HOSTID
				,PROJECT
				,HWADDR
				,USRPRINC
				,PrimaryUserName
				,PRJPRINC
				,PrjContactName
				,USAGE
				,IROWID
				,DIST
				,CHARGE_BY
				,OPROJECT
				,OUSAGE
				,SUBPROJECT
				,DIST_SRC
				,MR_CLASS
				,FILTER_CODE
				,DESCRIPTION
				,IPADDRESS
				,PROTOCOL
				,TTL
				,PCT_USE
				,OPRI
				,CONN
			  from hostdb.mach_primaryuser_v
			order by assetno, pri
		};

	my $rows;
	my $sth = $dbh->prepare($sql);

	eval {
		#$sth->bind_param();
		$sth->execute();

		#my $colnames = $sth->{NAME};
		#my $colwidths = $sth->{PRECISION};

		$rows = $sth->fetchall_arrayref();
		$sth->finish();
	};
	if($@) {
		my $e;
		$e = $@;
		$dbh && $dbh->disconnect();
		croak "fetchData - Error while fetching data from DB. $e";
	}

	$rows;
}

sub HashByCol
{
	my $rows = shift;
	my $col_idx = shift || 11;

	#should check col_idx to make sure it's numeric here
	die "non-digit exists in column index $col_idx\n" if($col_idx =~ /\D/);

	my %result = ();

	foreach my $r (@$rows)
	{
		my $k = $r->[$col_idx] || 'UNKNOWN';
		push @{$result{$k}}, $r;
	}

	\%result;
}

sub stringifyRows
{
	my $rows = shift;

	#my $tmpl = shift || '';

	my @field_width = (10, 24, 6, 10, 10, 20);
	my @field_title = (
			 'Assetno'
			, 'Hostname'
			, 'HostID'
			, 'OS'
			, 'CPUType'
			, 'HwAddress'
		);

	#my $rowformat = "%10s %24s %6s %10s %10s %20s\n";
	my $rowformat = join(' ', map('%' . $_ . 's', @field_width)) . "\n";

	my $str = sprintf("$rowformat"
			, 'Assetno'
			, 'Hostname'
			, 'HostID'
			, 'OS'
			, 'CPUType'
			, 'HwAddress'
			);
	$str .= join(' ', map('-' x $_, @field_width)) . "\n";

	foreach my $r (@$rows)
	{
		$str .= sprintf(
				"$rowformat"
				, $r->[0]
				, $r->[1] || ' '
				, $r->[2] || '0'
				, $r->[3] || ' '
				, $r->[5] || ' '
				, $r->[10] || ' '
			);
				#HWADDR
	}
	$str;
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
use lib '../util-lib';
use CMUCS::Rams::Report::Utils::Oracle;
use CMUCS::Rams::Report::Utils::mailer;
use Text::Template;

sub main
{
	my (@args) = @_;
	my $ora_conn = shift @args || "/\@facqa.crescent";

	#my $dbh = CMUCS::Rams::Report::Utils::Oracle::ora_connect("$ora_conn");
	my $dbh = Oracle::ora_connect("$ora_conn");

	my $rows = HashByCol(fetchData($dbh));
	#print Dumper($rows);

	my $rpt_content = stringifyRows($rows->{'mpa'});

	my $mailtmpl = { TYPE => 'FILE', SOURCE => './email.tmpl' };
	my $template = Text::Template->new( %$mailtmpl )
               or croak "Couldn't construct template: $Text::Template::ERROR";

	my $mailcontent = $template->fill_in(HASH => {
					princ		=> 'mpa',
					fullname	=> $rows->{'mpa'}->[0]->[12],
					report          => \$rpt_content,
				}
			);

	print $mailcontent;

	mailer::mail_user(
			To              => 'yangl+@cs.cmu.edu',
			From            => 'help+costing@cs.cmu.edu',
			'Reply-To'      => 'help+costing@cs.cmu.edu',
			Cc              => 'ylj@andrew.cmu.edu',
			Bcc             => 'ylj@andrew.cmu.edu',
			Type            => 'TEXT',
			Subject         => "Test - Machine Primary User",
			Data            => "$mailcontent",
			);


	$dbh && $dbh->disconnect();
}

use Cwd 'abs_path';

if (abs_path($0) eq abs_path(__FILE__))
{
    no strict 'refs';
    exit &{__PACKAGE__ . '::main'}(@ARGV);
}

1;

__END__

=pod

=head1 EXAMPLES

=head1 AUTHOR

Longjiang Yang, E<lt>yangl+@cs.cmu.eduE<gt>

=head1 COPYRIGHT
	
	School of Computer Science
	Carnegie Mellon University

=head1 SEE ALSO

L<Perl>

=cut
