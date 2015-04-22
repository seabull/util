#!/usr/local/bin/perl58 -w
# $Header: c:\\Repository/database/rams/projects/reports_batch/ChargeChangeBatch/lib/perl/CMUCS/Rams/Report/Utils/Oracle.pm,v 1.2 2006/04/19 18:59:29 yangl Exp $

package Oracle;
use DBI;
require Exporter;
@ISA = qw(Exporter);

=pod

=head1 NAME

Oracle.pm      - Common Utility functions

=head1 SYNOPSIS

use CMUCS::Rams::Report::Utils::Oracle;

=head1 DESCRIPTION

Common Oracle related functions.

=head1 FUNCTIONS

=cut

@EXPORT = qw(
ora_connect
);

@EXPORT_OK = qw();

local $default_conn = '/@fac_03.apogee';

=over

=item B<ora_connect(conn_str, attr)>

	Description: Get DB handle for Oracle.

	Params: conn_str - Oracle Connection String, e.g. '/@hostdb'
		attr     - (Hash Reference) Attribute passed to DBI connect.
			e.g. $dbh = ora_connect('/@hostdb', {RaiseError => 1});

=back

=cut

sub ora_connect($)
{
	#my ($conn,$attr) = @_;
	my $conn = shift || $default_conn;
	my $attr = shift || {};
	
	die "Oracle::ora_connect hash reference expected for attr." 
			unless(ref($attr) && ref($attr) eq 'HASH');

	my %ora_attr = (
			AutoCommit      => 0,
			PrintError      => 0,
			RaiseError      => 0,
			%$attr
			);
	                #$attr
	my $data_source = 'DBI:Oracle:';
	
	my $dbh = DBI->connect($data_source, $conn, "", \%ora_attr)
		or die "Unable to connect to DB $data_source and $conn \n", $DBI::errstr, "\n";

	# turn on either one.
	$dbh->{RaiseError} = 1;
	#$dbh->{PrintError} = 1;
	
	$dbh;
}


1;

__END__

=pod

=head1 EXAMPLES

	I will fill in when I have time.

=head1 AUTHOR

Longjiang Yang, E<lt>yangl+@cs.cmu.eduE<gt>

=head1 COPYRIGHT

        School of Computer Science
        Carnegie Mellon University

=head1 SEE ALSO

L<Perl>

=cut

