# $Header: c:\\Repository/database/rams/projects/reports_batch/ChargeChangeBatch/lib/perl/CMUCS/Rams/Report/Utils/Utils.pm,v 1.3 2006/04/28 16:18:50 yangl Exp $

package Utils;

use Carp;
require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(
dump_reportobj
load_reportobj
load_configfile
get_acctlist_fromfile
mylog
$VERBOSE
commify
);

@EXPORT_OK = qw();

=pod

=head1 NAME

CMUCS::Rams::Report::Utils.pm	- Utility script for Rams Reports 

=head1 SYNOPSIS

TO be filled in.

=head1 DESCRIPTION

Common Script 

=head1 FUNCTIONS

=cut

our $VERBOSE = 0;

=over 

=item dump_reportobj		- Dump report object to file (to be used to load).

=back

=cut

sub dump_reportobj
{
	my $rpt_obj = shift ;
	my $rpt_obj_name = shift || 'report';
	my $fname = shift || './.reportobj.perldata';

	#(-w `dirname $fname`) || croak "Report object file $fname is not writable.\n";

	open (RPT, "> $fname")
		or croak "Error: open file $fname: $!";
	#print RPT Data::Dumper->Dump([$rpt_obj],['rpt_obj']);
	print RPT Data::Dumper->Dump([$rpt_obj],[$rpt_obj_name]);
	close(RPT);
}

=over 

=item load_reportobj		- Load report object from file.

=back

=cut

sub load_reportobj
{
	my $fname = shift ;

	my $myreport_str;

	$fname || croak "Report object file name is not defined.";
	(-r $fname) || croak "Report object file $fname is not readable.\n";

	open (RPT, "< $fname") or croak "Error: open file $fname: $!";
	{
		local $/ = undef; 	#read in file all at once
		#eval <RPT>;
		$myreport_str = <RPT>;
	}

	close RPT;
	#mylog(5, undef, "Report Object loaded:\n"
	#		.Data::Dumper->Dump([$rpt_obj],['rpt_obj'])
	#	);

	eval $myreport_str;
}

=over 

=item load_configfile		- Load config hash from file.

=back

=cut

sub load_configfile
{
	my $fname = shift ;

	my %user_conf;

	$fname || croak "Report object file name is not defined.";
	(-r $fname) || croak "Report object file $fname is not readable.\n";

	open (CONFIG, "< $fname") or croak "Error: open file $fname: $!";

	while (<CONFIG>) {
	      	chomp;			# remove newline
	      	s/^\s*#.*//;		# remove comments, allow # in the config var and value
	      	s/^\s+//;		# remove leading white
	      	s/\s+$//;		# remove trailing white
	      	next unless length;	# anything left?

	      	my ($var, $value) = split(/\s*=\s*/, $_, 2);
	      	$user_conf{$var} = $value;
	} 
	# or treat it a full perl code 
	# { package MySettings; do "$fname"; }
	%user_conf;
}

=over 

=item get_acctlist_fromfile		- Load account list from file.

=back

=cut

sub get_acctlist_fromfile
{
	my $fname = shift;

	my $acctlist = [];

	unless (-r $fname) 
	{
		#mylog(1, undef, "File $fname is not readable.\n");
		return undef;
	}

	if( open(ACCTFILE, " < $fname") )
	{
		while (<ACCTFILE>)
		{
			chomp;
			s/^\s*//;
			s/\s*$//;
			#s/[^0-9a-zA-Z-\.]*$//;
			#should probably do validation here
			next unless length;
			push @$acctlist, $_;
		}
		close(ACCTFILE);
		mylog(3, undef, "Read account list from file $fname:\n".join(" ", @$acctlist)."\n");
	} else {
		mylog(1, undef, "Error open file $fname \n");
		$acctlist = undef ;
	}
	$acctlist;
}

=over 

=item mylog		- log messages to STDERR or file.

=back

=cut

sub mylog
{
	my $level = shift;
	my $FD = shift || \*STDERR;
	my @msg = @_;

	$level	or $level = 0;

	$VERBOSE or $VERBOSE = 0;

	#$| = 1;
	#if($level <= $CmdOptions{'VERBOSE'} + 1)
	if($level <= $VERBOSE + 1)
	{
		my $timestr = DateTime::str2ts_neat("now", "%02s-%3s-%s %02s.%02s.%02s : ");

		print $FD "\n$timestr".join("\n$timestr", @msg);
	}
}

=over 

=item commify		- Commify number, steal from Perl Cookbook.

=back

=cut

sub commify
{
	my $text = reverse $_[0];
	$text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
	return scalar reverse $text;
}

1;

=pod

=head1 EXAMPLES

	To be filled in.

=head1 AUTHOR

Longjiang Yang, E<lt>yangl+@cs.cmu.eduE<gt>

=head1 COPYRIGHT
	
	School of Computer Science
	Carnegie Mellon University

=head1 SEE ALSO

L<Perl>

=cut
