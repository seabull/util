#!/usr/local/bin/perl58 -w

#use lib '/afs/cs/user/yangl/.sys/sun4x_59/lib/perl5';
#use MIME::Lite;

use Carp;
use Text::Template;
use Pod::Usage;
use Getopt::Long;
use Data::Dumper;

use lib './lib';
use mailer qw(mail_user $mail_suppress $mail_log_fd %default_mailconf);

=pod

=head1 NAME

dailysummary.pl      - Main script for Daily Summary Internal Report

=head1 SYNOPSIS

B<dailysummary.pl> [options] 

The following common options are supported for all commands.

=head1 DESCRIPTION

Script to generate daily change summary report and email to users.

=head1 FUNCTIONS

=cut


my $defaultsumfile = 'dailysummary.csv';

my $ORAHOME = $ENV{'ORACLE_HOME'} || '/usr1/app/oracle/product/9.2';
my $ora_conn = '/@facqa.crescent.fac.cs.cmu.edu';
my $SqlCmd = 'sql/summary.sql';
my $sumfile = "$defaultsumfile";

	#'TS_SINCE'      =>      undef,
	#'TS_UNTIL'      =>      undef,
my %CmdOptions = (
	'CONN'		=>      $ora_conn,
	'TMPL_DIR'      =>      'etc',
	'RPT_FILE'	=>      $sumfile,
	'MAILCONF'      =>      undef,
	'VERBOSE'       =>      0,
	'HELP'          =>      0
);
        #'TS_SINCE'      =>      \$CmdOptions{'TS_SINCE'},
        #'TS_UNTIL'      =>      \$CmdOptions{'TS_UNTIL'},
my %CmdOptionVars = (
        'CONN'          =>      \$CmdOptions{'CONN'},
        'TMPL_DIR'      =>      \$CmdOptions{'TMPL_DIR'},
        'RPT_FILE'	=>      \$CmdOptions{'RPT_FILE'},
        'MAILCONF'      =>      \$CmdOptions{'MAILCONF'},
        'VERBOSE'       =>      \$CmdOptions{'VERBOSE'},
        'HELP'          =>      \$CmdOptions{'HELP'},
);
        #'TS_SINCE'      =>      'ts_since|1=s',
        #'TS_UNTIL'      =>      'ts_until|2=s',
my %CmdOptionStrs = (
        'CONN'          =>      'oraconn|c=s',
        'TMPL_DIR'      =>      'tmpl_dir|d=s',
        'RPT_FILE'	=>      'rpt|r=s',
        'MAILCONF'      =>      'mailconf|m=s',
        'VERBOSE'       =>      'verbose|v+',
        'HELP'          =>      'help|h!',
);


sub usage(;$) {
	my ($msg) = @_;
	
	$msg = "" unless $msg;
	
	print '***:'.$msg.":***\n";
	pod2usage( {
	                -message        => $msg,
	                -exitval        => 1,
	                -verbose        => 3,
	                }
	);
}

sub parse_opts() {

	my %opts;
	map     { $opts{$CmdOptionStrs{$_}} = \$CmdOptions{$_} }
	        (keys %CmdOptions);
	
	GetOptions(%opts)
	        or pod2usage( {
	                -message        => 'Option is not supported',
	                -exitval        => 1,
	                -verbose        => 0,
	                }
	        );
	
	#$CmdOptions{'TS_SINCE'} = DateTime::str2ts_neat($CmdOptions{'TS_SINCE'}) if $CmdOptions{'TS_SINCE'};
	#$CmdOptions{'TS_UNTIL'} = DateTime::str2ts_neat($CmdOptions{'TS_UNTIL'}) if $CmdOptions{'TS_UNTIL'};
	
	usage('Usage:') if $CmdOptions{'HELP'};

	$ora_conn       = $CmdOptions{'CONN'}           if $CmdOptions{'CONN'};
	$sumfile	= $CmdOptions{'RPT_FILE'}	if $CmdOptions{'RPT_FILE'};
	
	if($CmdOptions{'VERBOSE'})
	{
	        #$Utils::VERBOSE = $CmdOptions{'VERBOSE'};
	        print "\n",
	                '-'x40, "\n",
	                join("\n", map(
	                                {"\t" . $_ . '=' . ($CmdOptions{$_}||'undef')}
	                                sort keys %CmdOptions
	                        )),
	                "\n",
	                '-'x40, "\n";
	}
	
	#Utils::mylog(1, undef, "TS_SINCE=",$CmdOptions{'TS_SINCE'}) if $CmdOptions{'TS_SINCE'};
	#Utils::mylog(1, undef, "TS_UNTIL=",$CmdOptions{'TS_UNTIL'}) if $CmdOptions{'TS_UNTIL'};
	
	#print join("\n", map $_ . "=" . $CmdOptions{$_}  sort keys %CmdOptions) if $CmdOptions{'VERBOSE'};
}

=over

=item load_configfile           - Load config hash from file.

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
		chomp;                  # remove newline
		s/^\s*#.*//;            # remove comments, allow # in the config var and value
		s/^\s+//;               # remove leading white
		s/\s+$//;               # remove trailing white
		next unless length;     # anything left?
		
		my ($var, $value) = split(/\s*=\s*/, $_, 2);
		$user_conf{$var} = $value;
	}
	# or treat it a full perl code
	# { package MySettings; do "$fname"; }
	%user_conf;
}


sub summary_gen
{
	my $filename = shift || $defaultsumfile;

	system("$ORAHOME/bin/sqlplus", "$ora_conn", "\@$SqlCmd", "$filename")
		&& die "Error executing $ORAHOME/bin/sqlplus $ora_conn \@$SqlCmd $filename - $? $!";
}

sub main
{
	#my (@args) = @_;

	my $rpt_content = '';
	my $linesep = "";

	parse_opts;

	my $max_try = 3;
	while ($max_try > 0)
	{
		summary_gen($sumfile);
		my $num_of_lines ;
		$num_of_lines = `wc -l $sumfile`;

		last if $num_of_lines < 8100;
		$max_try--;
	}

	print STDERR "Max_Try=$max_try";

	open(RPT, "< $sumfile") or croak "Error Opening file $sumfile - $!\n";

	my ($starttime, $endtime); 
	while(<RPT>)
	{
		$rpt_content .= $_ . $linesep;

		if (/Start-Time,\s*(\S+\s*\S+)\s*$/)
		{
			$starttime = $1;
			chomp($starttime);
		}
		if (/End-Time,\s*(\S+\s*\S+)\s*$/)
		{
			$endtime = $1;
			chomp($endtime);
		}
		#last if($starttime && $endtime);
	}
	close(RPT);

	my $mailtmpl = { TYPE => 'FILE'
			, SOURCE => "$CmdOptions{'TMPL_DIR'}/mail.tmpl"
			};

	my $template = Text::Template->new( %$mailtmpl )
               or croak "Couldn't construct template: $Text::Template::ERROR";

	my $mailcontent = $template->fill_in(HASH => {
					starttime	=> \$starttime,
					endtime		=> \$endtime,
					content		=> \$rpt_content,
				}
			);

	my $subject = 'Daily Change Summary Report';

	print STDERR $mailcontent if $CmdOptions{'VERBOSE'};

	if ( -f $sumfile ) 
	{
		my %mailconf;

		if($CmdOptions{'MAILCONF'}) {
			%mailconf = load_configfile($CmdOptions{'MAILCONF'});
		}

		%mailconf = (	TO	=> 'yangl@cs.cmu.edu',
				Cc	=> 'yangl@cs.cmu.edu',
			) unless %mailconf;

		$subject = uc($mailconf{'X-Rams-Mode'}) . " - $subject" if $mailconf{'X-Rams-Mode'};
		#print Dumper(\%mailconf);

		my $rtn = mailer::mail_attachments(
			{
				'Return-Path'	=> 'yangl+costing@cs.cmu.edu',
				To		=> 'yangl@cs.cmu.edu',
				#To		=> 'michael.nikithser@cs.cmu.edu',
				From		=> 'fac-costing-staff@cs.cmu.edu',
				Sender		=> 'fac-costing-staff@cs.cmu.edu',
				Cc		=> 'yangl@cs.cmu.edu',
				Bcc		=> 'yangl@cs.cmu.edu',
				'Reply-To'	=> 'yangl+costing@cs.cmu.edu',
				#'Return-Path'	=> 'fac-costing-staff@cs.cmu.edu',
				'X-Rams-Mode'	=> 'beta',
				Type		=> 'Text',
				Subject		=> "$subject",
				Data		=> "$mailcontent",
				%mailconf
			},
			{
				Type		=> 'Text/csv',
				Disposition	=> 'attachment',
				Path		=> "$sumfile",
				Filename	=> 'DailySummary.csv'
			}
	                );
	
	
		$rtn || print "Error sending email.";
	}
}

use Cwd 'abs_path';
if (abs_path($0) eq abs_path(__FILE__))
{
    no strict 'refs';
    exit &main(@ARGV);
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

