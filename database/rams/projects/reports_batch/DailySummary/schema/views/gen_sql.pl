#!/usr/local/bin/perl58 -w

use Text::Template;
use Getopt::Long;
use Carp;
use Pod::Usage;

use strict;

=pod

=head1 NAME

gen_sql.pl      - script to generate DDL from template 

=head1 SYNOPSIS

gen_sql.pl [OPTIONS]

The following options are supported:

	-h		This help page.
	-v		Verbose
	-l <filename>	file contains table name list
	-t <filename>	Template file name

=head1 DESCRIPTION

 script to generate DDL from template 

=head1 FUNCTIONS

=cut

my %CmdOptions = (
		'TEMPLATE'	=> './touched_v.tmpl',
		'TBLLIST'	=> undef,
		'VERBOSE'	=> 0,
		'HELP'		=> 0,
		);

my %opts = (
	'template|t=s'	=> \$CmdOptions{'TEMPLATE'},
	'list|l=s'	=> \$CmdOptions{'TBLLIST'},
	'verbose|v+'	=> \$CmdOptions{'VERBOSE'},
	'help|h!'	=> \$CmdOptions{'HELP'},
	);

=over

=item usage()           - Usage information

=back

=cut

sub usage {
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

=over

=item parse_opts()      - Parse the command line options

=back

=cut

sub parse_opts {

        GetOptions(%opts)
                or pod2usage( {
                        -message        => 'Option is not supported',
                        -exitval        => 1,
                        -verbose        => 0,
                        }
                );

        if($CmdOptions{'VERBOSE'})
        {
                print "\n", '-'x40, "\n";
                print join("\n", map(
                                        {"\t" . $_ . '=' . ($CmdOptions{$_}||'undef')}
                                        sort keys %CmdOptions
                                ));
                print "\n", '-'x40, "\n";
        }

}

sub load_data
{
	my $fname = shift ;
	my $content = undef;
	
	$fname || return undef;

	(-r $fname) || croak "load_data : $fname is not readable.\n";
	
	open (RPT, "< $fname") or croak "Error: open file $fname: $!";
	{
		local $/ = undef;       #read in file all at once
		$content = <RPT>;
	}
	
	close RPT;
	
	my @rtn = split(/\s+/, $content);
	\@rtn;
}

sub main
{

	parse_opts;

	if($CmdOptions{'HELP'})
	{
		usage('Usage:');
	}

	my $tmpl_file	= $CmdOptions{'TEMPLATE'} || die "Error - Undefined Template file.\n";;
	
	my $template = Text::Template->new(	TYPE	=> 'FILE',
						SOURCE	=> $tmpl_file,
					) 
				or die "Could not construct template : $tmpl_file: $Text::Template::ERROR ";
	

	my $tbls = load_data($CmdOptions{'TBLLIST'}) ;

	$tbls or $tbls = [qw/aud_hostdb.who aud_hostdb.name aud_hostdb.principal 
				aud_hostdb.hoststab aud_hostdb.machtab aud_hostdb.capequip/] ;
	
	foreach my $t (@$tbls)
	{
		$t =~ /^\s*(.+)\.(.+)\s*$/;

		my ($owner, $tbl) = ($1, $2);
		my $sql_string = $template->fill_in( HASH	=> {
								ViewOwner	=> 'CCREPORT',
								BaseTableOwner	=> $owner,
								BaseTableName	=> $tbl,
								ParamTableOwner	=> 'UTILITY',
								ParamTableName	=> 'ASOFV_PARAM',
								ParamFlagValueSince	=> '1',
								ParamFlagValueUntil	=> '2',
								}
						);
		print $sql_string;
	}
}

main;

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

