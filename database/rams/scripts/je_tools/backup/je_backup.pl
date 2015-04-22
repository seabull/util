#!/usr/local/bin/perl5 -w
# $Id: je_backup.pl,v 1.1 2005/08/29 18:41:47 yangl Exp $

use strict;
use IO::File;
use Getopt::Long;
use File::Copy;
use Pod::Usage;
use POSIX qw(strftime);

=pod

=head1 NAME

je_backup.pl	- Call regular cold backup script to do cold backup 
                  and save a copy in the appropriate place.

=head1 SYNOPSIS

B<je_backup.pl> [options] [E<lt>directoryE<gt>]

        The following options allowed.
        --orasid | -c <arg>	Oracle sid of the Oracle database being backed up.
                                The script uses dbhome script to determine ORACLE_HOME.
				if dbhome is not available or sid can not be determined
                                the default (/usr1/app/oracle/product/9.2) is used.

	--script <arg>		The cold backup script to be used.
	--nobkup | -n		Skip cold backup
        --verbose | -v		print verbose information
        --help | -h		this help

=head1 DESCRIPTION

Script to do cold backup before or after monthly JE.

=head1 FUNCTIONS

=cut

#The SRC_DIR should be the same as in cold bakcup script
#The DEST_DIR can be changed at command line.
my $SRC_DIR		= '/usr11/orabkup';
my $DEST_DIR		= '/usr11/orabkup';

#
# Will be overridden by oratab or environment.
# We check for the ORACLE_HOME based on SID
# This default is used *only* when we can not figure out
# ORACLE_HOME based on SID and environment.
#
my $DEFAULT_ORAHOME	= "/usr1/app/oracle/product/9.2";

#
# This is the default location for Solaris.
#
my $ORATAB		= "/var/opt/oracle/oratab";

#
# These can be overridden by command line options
#
my $OraSid		= $ENV{ORACLE_SID};
my $Script		= '/usr/oracle/bin.qa/coldbackup_start.sh';
my $verbose		= undef;

my %CmdOptions = (
	'SID'			=> undef,
	'COLDBKUPSCRIPT'	=> undef,
	'NOCOLDBKUP'		=> undef,
	'LOG'			=> undef,
	'VERBOSE'		=> undef,
	'HELP'			=> undef,
	);

=over

=item usage()           - Usage information

=back

=cut

sub usage(;$) {
        my ($msg) = @_;

        $msg = "" unless $msg;

        print $msg."\n";
        pod2usage( {
                        -message        => $msg,
                        -exitval        => 0,
                        -verbose        => 3,
                        }
        );
}

=over

=item parse_opts()      - Parse the command line options

=back

=cut

sub parse_opts() {
	GetOptions(
		'sid|c=s'	=>	\$CmdOptions{'SID'},
		'script=s'	=>	\$CmdOptions{'COLDBKUPSCRIPT'},
		'nobkup|n'	=>	\$CmdOptions{'NOCOLDBKUP'},
		'verbose|v'	=>	\$CmdOptions{'VERBOSE'},
		'help|h'	=>	\$CmdOptions{'HELP'}
		)
	or pod2usage( {
			-message        => 'Option is not supported',
			-exitval        => 1,
			-verbose        => 0,
			}
	);
	
	usage('Usage:') if ($CmdOptions{'HELP'}) ;
	$OraSid = $CmdOptions{'SID'} if $CmdOptions{'SID'};
	$Script = $CmdOptions{'COLDBKUPSCRIPT'} if $CmdOptions{'COLDBKUPSCRIPT'};
	$verbose = $CmdOptions{'VERBOSE'} if $CmdOptions{'VERBOSE'};
	print "SID=$OraSid\n" if $verbose;
	print "COLDBKUPSCRIPT=$Script\n" if $verbose;
	print "NOCOLDBKUP=",defined($CmdOptions{'NOCOLDBKUP'})? 'TRUE' : 'FALSE' , "\n" if $verbose;
}

=over

=item init_env($)      - initialize oracle environment. 

		Oracle Home is determined by
		1. oratab file based on SID
		2. environment ORACLE_HOME
		3. default

=back

=cut

#
# Oracle Home is determined by
# 1. oratab file based on SID
# 2. environment ORACLE_HOME
# 3. default
#
sub init_env($) {
	my ($orasid) = @_;
	my ($orahome, $pid, $orahome_tab) = ($ENV{ORACLE_HOME}, undef, "");
	
	usage("ORACLE_SID is not set or invalid (oracle_sid=$orasid)") 
		unless (defined($orasid) && $orasid =~ /[a-zA-Z0-9_]+/); 

	chomp($orasid);
	chomp($orahome) if defined($orahome);

	if ( -r "$ORATAB" ) {
        	$orahome_tab = `awk -F: "/^$orasid:/ {print \\\$2; exit;}" $ORATAB 2>/dev/null`;
		chomp($orahome_tab);
		print "Find Oracle_Home=$orahome_tab for $orasid in $ORATAB\n" if $verbose;
	}
 
	if ($orahome_tab) {
		die "Oracle Home in $ORATAB does not match environment. $orasid-$orahome_tab : $orahome" 
			unless (defined($orahome) && ($orahome_tab eq $orahome));
		print "Use Oracle Home from $ORATAB\n";
		$orahome = $orahome_tab;
	} 

	$orahome = defined($orahome) ? $orahome : $DEFAULT_ORAHOME;

	print "set environment ORACLE_HOME to $orahome \n" if $verbose;
	$ENV{ORACLE_HOME} = $orahome;
	print "set environment ORACLE_SID to $OraSid \n" if $verbose;
	$ENV{ORACLE_SID} = $orasid;

	#
	# This is a safer way to do `dbhome $orasid`
	#
#	die "Cannot fork:$!" unless defined($pid = open(DBHOME, "-|"));
#	if ($pid) {     
#		# parent
#		while (<DBHOME>) {
#			# do something interesting
#			$orahome .= $_;
#		}
#		unless (close(DBHOME)) {
#			my $rtn = $?;
#			$orahome = $DEFAULT_ORAHOME;
#			print "Use default oracle home - $orahome. - $rtn\n";
#		}
#	
#	} else {      # child
#		# we may not be able to find dbhome
#		exec("dbhome", $orasid);
#			#or die "can't exec program: $!";
#	}

	print "-------------------------------\n";
	print "Oracle_SID=$OraSid\n";
	print "Oracle_Home=$orahome\n";
	print "COLDBKUPSCRIPT=$Script\n";
	print "-------------------------------\n";
}

sub do_coldbkup($) {
	my ($bkup_cmd) = @_;

	print "Executing $bkup_cmd\n" if $verbose;
	system("$bkup_cmd") and die "Error executing backup script $bkup_cmd - $! \n"; 
	print "Cold backup completed\n" if $verbose;
}

sub save_bkup($$;$) {
	my ($src_dir, $dest_dir, $subdir) = @_;

	my ($pre, $post) = ("pre", "post");

	chomp($dest_dir);

	#mkdir $dest_dir unless ( -d $dest_dir );
	unless (-d $dest_dir) {
		print "Creating directory $dest_dir\n" if $verbose;
		system("mkdir -p $dest_dir") and die "Error creating $dest_dir - $!\n";
	}

	chomp($subdir) if defined($subdir);
	if (!defined($subdir) || ! $subdir ) {
		if ( -d "$dest_dir/$pre" ) {
			die "Both pre and post already exist in $dest_dir. No cold backup is saved.\n" 
				unless ( ! -d "$dest_dir/$post" );
			# Pre JE directory exists
			$subdir = $post;
			print "save cold backup to $dest_dir/$post \n" if $verbose;
		} else {
			print "save cold backup to $dest_dir/$pre \n" if $verbose;
			$subdir = $pre;
		}
	} 
	print "do the save from $src_dir to $dest_dir/$subdir \n" if $verbose;
	move("$src_dir", "$dest_dir/$subdir") 
		or die "Error moving cold backup to $dest_dir/$subdir - $!\n";
	print "Cold Backup saved \n" if $verbose;
}

$OraSid = $ENV{ORACLE_SID};
parse_opts();
init_env($OraSid);

do_coldbkup("$Script $OraSid") unless $CmdOptions{'NOCOLDBKUP'};

my $src_dir = "$SRC_DIR/$OraSid/cold";

die "Cold backup directory $src_dir does not exist! \n" unless ( -d $src_dir);

#my $date = strftime("%d-%b-%Y\n", localtime);
my $date = strftime("%Y-%b\n", localtime);

print "Saving cold backup from $src_dir to $DEST_DIR/$OraSid/$date\n";
save_bkup("$src_dir","$DEST_DIR/$OraSid/$date");

print "-- JE Cold Backup Completed -- \n";

1;

__END__

=pod

=head1 EXAMPLES

je_backup.pl -c 'fac_03' -v 

=head1 AUTHOR

Longjiang Yang, E<lt>yangl+@cs.cmu.eduE<gt>

=head1 COPYRIGHT

        School of Computer Science
        Carnegie Mellon University

=head1 SEE ALSO

L<Perl>

=cut
 
