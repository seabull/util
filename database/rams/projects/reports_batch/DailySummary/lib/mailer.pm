package mailer;

require Exporter;
use lib 'lib/perl5';
#use lib '/afs/cs/user/yangl/.sys/sun4x_59/lib/perl5';
use MIME::Lite;
@ISA = qw(Exporter);

@EXPORT = qw(
mail_user
mail_attachments
);

@EXPORT_OK = qw(%default_mailconf $mail_suppress $mail_log_fd);

# No mails sent if set
our $mail_suppress 	= 0;
our $mail_log_fd	= \*STDERR;

our %default_mailconf	= (
	'X-Rams-Mode'		=> 'Test',
	'Return-Path'		=> 'help+costing@cs.cmu.edu',
	Sender			=> 'help+costing@cs.cmu.edu',
	From			=> 'help+costing@cs.cmu.edu',
	To			=> 'yangl+test@cs.cmu.edu',
	'Reply-To'		=> 'help+costing@cs.cmu.edu',
	Subject			=> 'Test Message',
	Cc			=> 'ramscya+@cs.cmu.edu',
	Bcc			=> 'ramscya+@cs.cmu.edu',
	Type			=> 'TEXT',
	Data			=> 'This is a test message. Please ignore.',
	AdminTo			=> 'yangl+test@cs.cmu.edu',
	AdminCc			=> '',
	AdminBcc		=> 'ramscya+@cs.cmu.edu',
	'Admin-ReplyTo'		=> 'help+costing@cs.cmu.edu',
	AdminSubject		=> 'Summary Message',
	'X-Rams-From'		=> 'help+costing@cs.cmu.edu',
	'X-Rams-To'		=> 'yangl+test@cs.cmu.edu',
	'X-Rams-Reply-To'	=> 'help+costing@cs.cmu.edu',
	'X-Rams-Subject'	=> 'Test Message',
	'X-Rams-Cc'		=> 'ramscya+@cs.cmu.edu',
	'X-Rams-Bcc'		=> 'ramscya+@cs.cmu.edu',
	'X-Rams-Type'		=> 'TEXT',
	Linesep			=> "\r",
);

sub mail_attachments
{
	my $init_part = shift;
	my @attachments = @_;

	die 'mail_with_attachment : First argument should be ref to hash, got '.ref($init_part) 
		unless(ref($init_part) eq 'HASH');
	my %mail_conf = (
			%default_mailconf,
			%$init_part
			);
	my $msg ;

	map { 
		defined($mail_conf{$_}) or $mail_conf{$_} = ''; 
	} keys %mail_conf;

	if(	( uc($mail_conf{'X-Rams-Mode'}) eq 'PRODUCTION' )
	     or	( uc($mail_conf{'X-Rams-Mode'}) eq 'BETA' ) 
	  )
	{
		my %params = (
			'Return-Path'	=> $mail_conf{'Return-Path'},
			Sender		=> $mail_conf{Sender},
			From		=> $mail_conf{From},
			To		=> $mail_conf{To},
			'Reply-To'	=> $mail_conf{'Reply-To'},
			Subject		=> $mail_conf{Subject},
			Cc		=> $mail_conf{Cc},
			Bcc		=> $mail_conf{Bcc},
			Type		=> $mail_conf{Type},
			'X-Rams-Mode'	=> $mail_conf{'X-Rams-Mode'},
			);
		$params{Data} = $mail_conf{Data} if($mail_conf{Data});
	
		$msg = MIME::Lite->new (
			%params
		);
			#'Return-Path'	=> $mail_conf{'Return-Path'},
			#Sender		=> $mail_conf{Sender},
			#From		=> $mail_conf{From},
			#To		=> $mail_conf{To},
			#'Reply-To'	=> $mail_conf{'Reply-To'},
			#Subject		=> $mail_conf{Subject},
			#Cc		=> $mail_conf{Cc},
			#Bcc		=> $mail_conf{Bcc},
			#Type		=> $mail_conf{Type},
			#'X-Rams-Mode'	=> $mail_conf{'X-Rams-Mode'},
			#Data		=> $mail_conf{Data},	
	} else {
		$msg = MIME::Lite->new (
			'Return-Path'	=> $mail_conf{'Return-Path'},
			Sender		=> $mail_conf{Sender},
			From		=> $mail_conf{'X-Rams-From'},
			To		=> $mail_conf{'X-Rams-To'},
			'Reply-To'	=> $mail_conf{'X-Rams-Reply-To'},
			Subject		=> $mail_conf{'X-Rams-Subject'}.'-'.$mail_conf{'Subject'},
			Cc		=> $mail_conf{'X-Rams-Cc'},
			Bcc		=> $mail_conf{'X-Rams-Bcc'},
			Type		=> $mail_conf{'X-Rams-Type'},
			'X-Rams-Mode'	=> $mail_conf{'X-Rams-Mode'},
			Data		=> [	
						"From     :".$mail_conf{From}."\r",
						"To       :".$mail_conf{To}."\r",
						"Reply-To :".$mail_conf{'Reply-To'}."\r",
						"Cc       :".$mail_conf{Cc}."\r",
						"Bcc      :".$mail_conf{Bcc}."\r\n",
						$mail_conf{Data},	
					],
		);
	}
	
	foreach my $p (@attachments)
	{
		if (ref($p) && (ref($p) eq 'HASH'))
		{
			my %params = (
					Disposition	=> 'attachment',
					%$p
				);
			$msg->attach(
				%params
				);
		} else {
			print 'mail_attachments : Should be logged. hash ref expected as attachment argument.';
		}
	}

	$msg->print($mail_log_fd);

	my $r = 0;
	#$r = $msg->send unless $CmdOptions{'MAILSUPPRESS'};
	unless($mail_suppress)
	{
		#$r = $msg->send ;
		my $mprog_name = 'sendmail';
		my $mprog = '/usr/lib/sendmail';
		
		$r = $msg->send('sendmail', "/usr/lib/sendmail -t -oi -oem -f $mail_conf{'Return-Path'}");
		$r || print $mail_log_fd "Error sending mail: $? -- $!";
	}
	$r;
}

sub mail_user
{
	my %mail_conf = ( 
			%default_mailconf,
			@_ 
		);
	my $msg ;

	#print $mail_log_fd "Before sending emails - 0\n";
	# To get rid of undef concat warnings.
	map { 
		defined($mail_conf{$_}) or $mail_conf{$_} = ''; 
	} keys %mail_conf;

	#print $mail_log_fd "Before sending emails - 1\n";
	if(	( uc($mail_conf{'X-Rams-Mode'}) eq 'PRODUCTION' )
	     or	( uc($mail_conf{'X-Rams-Mode'}) eq 'BETA' ) 
	  )
	{
		$msg = MIME::Lite->new (
			'Return-Path'	=> $mail_conf{'Return-Path'},
			Sender		=> $mail_conf{Sender},
			From		=> $mail_conf{From},
			To		=> $mail_conf{To},
			'Reply-To'	=> $mail_conf{'Reply-To'},
			Subject		=> $mail_conf{Subject},
			Cc		=> $mail_conf{Cc},
			Bcc		=> $mail_conf{Bcc},
			Type		=> $mail_conf{Type},
			'X-Rams-Mode'	=> $mail_conf{'X-Rams-Mode'},
			Data		=> $mail_conf{Data},	
		);
	} else {
		$msg = MIME::Lite->new (
			'Return-Path'	=> $mail_conf{'Return-Path'},
			Sender		=> $mail_conf{Sender},
			From		=> $mail_conf{'X-Rams-From'},
			To		=> $mail_conf{'X-Rams-To'},
			'Reply-To'	=> $mail_conf{'X-Rams-Reply-To'},
			Subject		=> $mail_conf{'X-Rams-Subject'}.'-'.$mail_conf{'Subject'},
			Cc		=> $mail_conf{'X-Rams-Cc'},
			Bcc		=> $mail_conf{'X-Rams-Bcc'},
			Type		=> $mail_conf{'X-Rams-Type'},
			'X-Rams-Mode'	=> $mail_conf{'X-Rams-Mode'},
			Data		=> [	
						"From     :".$mail_conf{From}."\r",
						"To       :".$mail_conf{To}."\r",
						"Reply-To :".$mail_conf{'Reply-To'}."\r",
						"Cc       :".$mail_conf{Cc}."\r",
						"Bcc      :".$mail_conf{Bcc}."\r\n",
						$mail_conf{Data},	
					],
		);
	}

	#print $mail_log_fd "Before sending emails\n";
	#$msg->print(\*STDERR);
	$msg->print($mail_log_fd);

	#print $mail_log_fd "Before sending emails - 2\n";
	my $r = 0;
	#$r = $msg->send unless $CmdOptions{'MAILSUPPRESS'};
	unless($mail_suppress)
	{
		#$r = $msg->send ;
		my $mprog_name = 'sendmail';
		my $mprog = '/usr/lib/sendmail';
		
		$r = $msg->send('sendmail', "/usr/lib/sendmail -t -oi -oem -f $mail_conf{'Return-Path'}");
		$r || print $mail_log_fd "Error sending mail: $? -- $!";
	}
	$r;
}

1;
