#!/usr/local/bin/perl5 -w

use strict;
use Getopt::Long;
use Pod::Usage;
use IO::File;
use IO::Handle;
#use File::Copy;

my %CmdOptions = (
	'CONN'		=> undef,
	'FILE'		=> undef,
	'USER'		=> undef,
	'VERBOSE'	=> undef,
	'HELP'		=> undef,
);
my $verbose = 0;

my $DEFAULT_ORAHOME = ( $ENV{'ORACLE_HOME'} || "/usr1/app/oracle/product/9.2") ;
my $SQLPLUS = "$DEFAULT_ORAHOME/bin/sqlplus";
my $SQLOPTS = "-s";
my $MAILER = "/usr/costing/bin/metasend";

my @pi_list = ();
my $ora_conn = "/\@fac_03.apogee";

my $DEFAULT_PIFILE = "pilist.txt";
my $PIFILE = $DEFAULT_PIFILE;
my $report_sql = "report.sql";

=pod

=head1 NAME

gen_report.pl	- Generate report for PIs

=head1 SYNOPSIS

gen_report.pl [options] 

The following options are supported.
	--oraconn | -c ARG	Oracle connection string.
	--verbose | -v		print verbose information
	--help | -h		this help

=head1 DESCRIPTION

Script to generate expiring account report and email to users.

=head1 FUNCTIONS

=cut

=over 

=item parse_opts()	- Parse the command line options

=back

=cut

sub parse_opts() {
	GetOptions(
		'oraconn|c=s'	=>	\$CmdOptions{'CONN'},
		'file|f=s'	=>	\$CmdOptions{'FILE'},
		'verbose|v'	=>	\$CmdOptions{'VERBOSE'},
		'help|h'	=>	\$CmdOptions{'HELP'}
		) 
	or pod2usage( {
			-message	=> 'Option is not supported',
			-exitval	=> 1,
			-verbose	=> 0,
			}
	);

	usage('Usage:')	if ($CmdOptions{'HELP'}) ;

	$ora_conn	= $CmdOptions{'CONN'}		if $CmdOptions{'CONN'};
	$PIFILE		= $CmdOptions{'FILE'}		if $CmdOptions{'FILE'};
	$verbose	= $CmdOptions{'VERBOSE'}	if $CmdOptions{'VERBOSE'};
}

=over 

=item usage()		- Usage information

=back

=cut

sub usage(;$) {
	my ($msg) = @_;
	
	$msg = "" unless $msg;

	print $msg."\n";
	pod2usage( {
			-message	=> $msg,
			-exitval	=> 0,
			-verbose	=> 3,
			}
	);
}

sub init_ora() {

	$ENV{'ORACLE_HOME'} = $DEFAULT_ORAHOME unless defined($ENV{'ORACLE_HOME'});
	print "ORACLE_HOME=$ENV{'ORACLE_HOME'}\n" if $verbose;
	$SQLPLUS = "$ENV{'ORACLE_HOME'}/bin/sqlplus";
}

# @arg	: file name that contains the list of users'd scs id
sub getUsers($) {
	my ($fname) = @_;

	die "File name of user list has to be specified. filename=$fname \n" unless $fname;

	die "File $fname is not readable. \n" unless ( -r $fname );

	my $fh = new IO::File;
	unless ($fh->open("< $fname")) {
		die "Error opening file $fname. $! \n";
	}
	
	while (<$fh>){
		chomp;
		push @pi_list, $_;
	}
	undef $fh;
}

sub genSQL($) {
	my ($fname) = @_;

	die "File name of user list has to be specified. filename=$fname \n" unless $fname;

	die "File $fname is not readable. \n" unless ( -r $fname );

	my $R = new IO::File;
	my $W = new IO::File;

	unless ($R->open("< $fname") && $W->open("> $fname.sql")) {
		die "Error opening file $fname or $fname.sql. $!\n";
	}

	while (<$R>) {
		chomp;
		if(/\w+/) {
			print $W "\@$report_sql $_ \n";
			print $W "host cp template.xls results/$_.xls \n";
			print $W "host sed -e '/^\$/d' < results/$_.lst > results/$_.csv \n";
		}
	}
	print $W "quit \n";
	$R->close();
	$W->close();
}

#
# not used
#
sub generate($) {
	my ($ulist) = @_;

	my($sqlcode, $SQL);

	$sqlcode = join( "\n", map {"\@$report_sql $_";} @$ulist);

	#print $sqlcode;
	#system($SQLPLUS, " -s $ora_conn");

	#$SQL = new IO::File;

	open(SQL, " | $SQLPLUS -s $ora_conn") or die "Error opening $SQLPLUS $ora_conn pipe. $@ - $!";
	#eval { $SQL->open(" | $SQLPLUS -SILENT $ora_conn") };
	#if($@) {
		#die "Error piping to $SQLPLUS. $@\n";
	#}
	print SQL "spool foo\n";
	print SQL "select user from dual; \n";
	print SQL "spool off \n";
	print SQL "exit \n";
	close SQL;
}

parse_opts;
init_ora;

#getUsers($DEFAULT_PIFILE);
#generate(\@pi_list);

unlink("$PIFILE.sql");

if ( ! -d "results" ) {
	mkdir "results";
} else {
	unlink glob("results/*.csv");
}

genSQL($PIFILE);

print "$SQLPLUS -s $ora_conn \@$PIFILE.sql \n";

system("$SQLPLUS -s $ora_conn \@$PIFILE.sql") and die "error executing $SQLPLUS $!\n";

#copy("template.xls", "results/template.xls");

unlink glob("results/*.lst");

my $today = `whenis -f "%year-%Month-%02day"`;
chomp $today;

rename 'results',"$today";

#system("cd results; gtar zcvf all.tar.gz *") and die "error TARing the files in results $! \n";
system("gtar zcvf $today.all.tar.gz $today") and die "error TARing the files in results $! \n";

rename "$today",'results';

unlink glob("results/*.xls");

system("cp $today.all.tar.gz /afs/cs/user/yangl/deleteme/all.$today.tar.gz") and die "error Copying the tgz file to afs $! \n";

#email();

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
