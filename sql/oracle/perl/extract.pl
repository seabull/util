#!/usr/local/bin/perl5
# $Id: extract.pl,v 1.2 2005/07/14 18:11:59 yangl Exp $
#----------------------------------------------------------

use Getopt::Long;
use IO::File;
use IO::Pipe;

$SQL_prog = "$ENV{ORACLE_HOME}/bin/sqlplus";
$SQL_db   = "/\@hostdb.fac.cs.cmu.edu";
$User     = "HOSTDB";

%CmdOptions = (
	'CONN'		=> undef,
	'PROG'		=> undef,
	'SCHEMA'	=> undef,
	'TYPE'		=> undef,
	'LOG'		=> undef,
	'VERBOSE'	=> undef,
	'HELP'		=> undef,
	);
%Types = (
	'func'	=> 'FUNCTION',
 	'java'	=> 'JAVA SOURCE',
	'spec'	=> 'PACKAGE',
	'body'	=> 'PACKAGE BODY',
	'proc'	=> 'PROCEDURE',
	'trig'	=> 'TRIGGER',
 	'type'	=> 'TYPE',
 	'typeb'	=> 'TYPE BODY',
);

sub usage (;$) {
	my ($msg)=@_ ;
	
	$msg="" unless ($msg);
	pod2usage( {
			-message        => $msg,
			-exitval        => 0,
			-verbose        => 3,
			-noperldoc      => 1,
		} );
	exit 0;
}

sub parse_opts () {
	GetOptions(
		'Conn|c=s'	=> \$CmdOptions('CONN'),
		'Prog=s'	=> \$CmdOptions('PROG'),
		'Schema|u=s'	=> \$CmdOptions('SCHEMA'),
		'Type|t=s'	=> \$CmdOptions('TYPE'),
		'log|l=s'	=> \$CmdOptions{'LOG'},
		'verbose|v'	=> \$CmdOptions{'VERBOSE'},
		'help|h'	=> \$CmdOptions{'HELP'},
	) or pod2usage( {
	                -message        => 'Option not supported',
	                -exitval        => 1,
	                -verbose        => 0,
	                }
	                );
	
	if ( defined($CmdOptions{'HELP'}) ) {
	        &usage();
	}
	
}

sub do_extract_trig ($$$$) {
	my($owner, $name, $type, $file) = @_;
	my($CMD);
	
	print "Extracting $type $owner.$name...";
	$CMD = new IO::File('extract.sql', O_RDWR|O_CREAT|O_TRUNC, 0644)
		or die "extract.sql: $!\n";

	print $CMD <<"EOF";
set linesize 4000
set newpage none
set echo off
set feedback off
set heading off
set termout off
set trimspool on
set long 2000000000
set recsep off

spool $file
select 'CREATE OR REPLACE TRIGGER' from dual;
select description from all_triggers
 where owner = '$owner' and trigger_name = '$name'
;
select trigger_body from all_triggers
 where owner = '$owner' and trigger_name = '$name'
;
select '.' from dual;
select 'RUN' from dual;
select 'SHOW ERRORS' from dual;
spool off
exit
EOF

	$CMD->close();
	system($SQL_prog, '-SILENT', $SQL_db, '@extract.sql');
	unlink('extract.sql');
	print " Done!\n";
}

sub do_extract ($$$$) {
	my($owner, $name, $type, $file) = @_;
	my($CMD);
	
	if ($type eq 'TRIGGER') {
		do_extract_trig($owner, $name, $type, $file);
		return;
	}
	print "Extracting $type $owner.$name...";
	$CMD = new IO::File('extract.sql', O_RDWR|O_CREAT|O_TRUNC, 0644)
		or die "extract.sql: $!\n";

	print $CMD <<"EOF";
set linesize 4000
set newpage none
set echo off
set feedback off
set heading off
set termout off
set trimspool on

spool $file
select 'CREATE OR REPLACE' from dual;
select text from all_source
 where owner = '$owner' and name = '$name' and type = '$type'
 order by line
;
select '.' from dual;
select 'RUN' from dual;
select 'SHOW ERRORS' from dual;
spool off
exit
EOF

	$CMD->close();
	system($SQL_prog, '-SILENT', $SQL_db, '@extract.sql');
	unlink('extract.sql');
	print " Done!\n";
}

sub do_extract_all ($$$) {
	my($owner, $type, $ext) = @_;
	my($CMD, $RESULT, @names, $name, $fname);
	
	print "Extracting list of $type objects...";
	$CMD = new IO::File('extract.sql', O_RDWR|O_CREAT|O_TRUNC, 0644)
		or die "extract.sql: $!\n";
	
	print $CMD <<"EOF";
set linesize 4000
set newpage none
set echo off
set feedback off
set heading off
set trimout on
set trimspool on
EOF
	if ($type eq 'TRIGGER') {
		print $CMD <<"EOF";
select distinct trigger_name from all_triggers where owner = '$owner';
EOF
	} else {
		print $CMD <<"EOF";
select distinct name from all_source where owner = '$owner' and type = '$type';
EOF
	}

	print $CMD "exit\n";
	$CMD->close();
	$RESULT = new IO::Pipe;
	$RESULT->reader($SQL_prog, '-SILENT', $SQL_db, '@extract.sql');
	@names = $RESULT->getlines();
	$RESULT->close;
	unlink('extract.sql');
	print " Done!\n";
	
	foreach $name (@names) {
		chomp($name);
		($fname = $name) =~ tr/A-Z/a-z/;
		do_extract($owner, $name, $type, "$fname.$ext");
	}
}

$| = 1;

&parse_opts;
#getopts('D:U:') or die;

$SQL_db = $opt_D if defined $opt_D;
$User   = $opt_U if defined $opt_U;

foreach (@ARGV) {
	$file = $_;
	($name, $ext) = split(/\./);
	if ($name =~ /\./) { ($user, $name) = ($`, $') }
	else               { $user = $User             }
	$user =~ tr/a-z/A-Z/;
	$name =~ tr/a-z/A-Z/;
	$type = $Types{$ext};
	if ($name eq '*') {
		do_extract_all($user, $type, $ext);
	} else {
		do_extract($user, $name, $type, $file);
	}
}

1;

## Everything after the __END__ token is considered documentation,
## and is read through the DATA filehandle.
__END__

=pod

=head1 NAME

extract.pl - perl script to extract sources from Oracle database.

=head1 SYNOPSIS

 extract.pl [OPTIONS] 

  --verbose		turn up verbosity of output for debugging
  --conn | -c <ARG> 	Database name to connect to
  --schema | -u		schema user of the object 
  --help | -h		this help

=head1 DESCRIPTION

 This is the perl script to extract Oracle database sources.

=head1 AUTHOR

        Longjiang Yang (yangl@cs.cmu.edu)

=head1 COPYRIGHT
        School of Computer Science
        Carnegie Mellon University

=head1 SEE ALSO

=cut
