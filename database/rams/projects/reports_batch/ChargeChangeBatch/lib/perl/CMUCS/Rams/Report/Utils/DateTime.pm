#!/usr/local/bin/perl58 -w
# $Header: c:\\Repository/database/rams/projects/reports_batch/ChargeChangeBatch/lib/perl/CMUCS/Rams/Report/Utils/DateTime.pm,v 1.3 2006/04/19 18:25:00 yangl Exp $

package DateTime;
use Carp;
use Time::ParseDate;
require Exporter;
@ISA = qw(Exporter);

=pod

=head1 NAME

DateTime.pm      - Common Utility functions

=head1 SYNOPSIS

use 

=head1 DESCRIPTION

Some Common Useful functions.

=head1 FUNCTIONS

=cut

# function name        return type    args
# -------------        -----------    ----
# str2ts		

@EXPORT = qw(
str2ts
str2ts_neat
);

@EXPORT_OK = qw();

=over

=item str2ts()           - 

=back

=cut

sub str2ts
{
	my $ts_string = shift;
	
	croak "Time string is not defined." unless $ts_string;

	my $epoch = parsedate($ts_string);
	
	if (!defined($epoch))
	{
		print STDERR "\nUn-recognized time string $ts_string. Use current time\n";
		$epoch = parsedate("now");
	}
	my @ts = localtime($epoch);

	#my @ts = localtime(parsedate($ts_string));
	[@ts];
}

=over

=item str2ts_neat()           - 

=back

=cut

sub str2ts_neat
{
	my $ts_string = shift;
	#my $ts_outformat = shift || "%02s-%3s-%s %02s.%02s.%02s\n";
	my $ts_outformat = shift || "%02s-%3s-%s %02s.%02s.%02s";
	
	croak "Time string is not valid." unless $ts_string;
	#print "\nts_string=$ts_string\nts_outformat=$ts_outformat\n" if $CmdOptions{'VERBOSE'};
	
	my %ts_map = (
			second  => 0,
			minute  => 1,
			hour    => 2,
			mday    => 3,
			month   => 4,
			year    => 5,
			wday    => 6,
			yday    => 7,
			isdst   => 8,
		);
	
	my @mons = qw/JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC/;

	my $epoch = parsedate($ts_string);
	
	if (!defined($epoch))
	{
		print STDERR "\nUn-recognized time string $ts_string. Use current time\n";
		$epoch = parsedate("now");
	}
	my @ts = localtime($epoch);
	#my @ts = localtime(parsedate($ts_string));
	
	#sprintf("%02s-%3s-%s %02s.%02s.%02s\n", $ts[$ts_map{mday}]
	sprintf($ts_outformat, $ts[$ts_map{mday}]
				,$mons[$ts[$ts_map{month}]]
				,$ts[$ts_map{year}]+1900
				,$ts[$ts_map{hour}]
				,$ts[$ts_map{minute}]
				,$ts[$ts_map{second}]
			);
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

		#print str2ts_neat("now", "%02s-%3s-%s %02s.%02s.%02s : ");
