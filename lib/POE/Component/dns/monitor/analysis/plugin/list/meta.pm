package POE::Component::dns::monitor::analysis::plugin::list::meta;

use strict;
use warnings;
use POE;
use DateTime;
use YAML;
use Try::Tiny;
use WWW::Mechanize;

sub spawn {
	my $self = shift;
	my %args = @_;

	die "Bad Config" if ref $args{Config} ne 'HASH';
	die "Bad DBH" unless ref $args{DBH};
	die "No Alias" unless length $args{Alias};

	my $sess = POE::Session->create( inline_states => {
		_start	=> sub { $poe_kernel->yield( 'list_meta_start', \%args ); },
		_stop 	=> sub { },
		list_meta_start => \&list_meta_start,
		analyze => \&analyze,
		notify => \&notify,
		refresh => \&refresh,
	});

	return $sess->ID;
}

sub list_meta_start {
	my($kernel,$heap,$args) = @_[KERNEL,HEAP,ARG0];

	$kernel->alias_set( $args->{Alias} );
	
	# Store stuff in the heap
	$heap->{log} = $args->{LogSID};
	$heap->{dbh} = $args->{DBH};
	$heap->{interval} = $args->{Config}{interval} || 3600;

	# Schedule the Analysis
	$kernel->yield('analyze');
}

# Discover Questions and Answers in Lists
sub analyze {
	my ( $kernel,$heap ) = @_[KERNEL,HEAP];

	$kernel->call( $heap->{log} => debug => "list::meta running analysis" );

	my $check_ts = DateTime->now()->subtract( seconds => $heap->{interval} );
	my %SQL = ( 
		'check' => q{select z.id as zone_id, l.id as list_entry_id, l.list_id as list_id
						from list_entry l
							inner join zone z on z.path <@ l.path
		},
		'check_answer' => q{select answer_id from zone_answer where zone_id = ?},
		'check_question' => q{select question_id from zone_question where zone_id = ?},
		'insert_answer'		=> q{insert into list_meta_answer ( answer_id, list_entry_id, list_id ) values ( ?, ?, ? )},
		'insert_question'	=> q{insert into list_meta_question ( question_id, list_entry_id, list_id ) values ( ?, ?, ? )},
		'refresh_check' => q{select id from list
								where can_refresh = true
									and NOW() - refresh_last_ts > refresh_every
		},
	);
	my %STH = ();
	foreach my $s ( keys %SQL ) {
		$STH{$s} = $heap->{dbh}->run( fixup => sub {
			my $sth = $_->prepare( $SQL{$s} );
			$sth;
		});
	}

	$STH{check}->execute();

	my $updates = 0;
	while( my $ent = $STH{check}->fetchrow_hashref ) {
		foreach my $type (qw(question answer)) {
			$STH{"check_$type"}->execute( $ent->{zone_id} );
			while ( my ($id) = $STH{"check_$type"}->fetchrow_array ) {
				$updates++;
				try {
					$STH{"insert_$type"}->execute( $id, $ent->{list_entry_id}, $ent->{list_id} );
				} catch {
					# update not necessary
					$updates--;
				};
			}
		}
	}
	$kernel->post( $heap->{log} => debug => "list::meta posted $updates updates");

	$STH{refresh_check}->execute();
	while( my ($id) = $STH{refresh_check}->fetchrow_array ) {
		$kernel->yield( refresh => $id );
	}
	

	# Schedule the Analysis
	$kernel->delay_add( analyze => $heap->{interval} );
}

# Do URL Refreshes
sub refresh {
	my ( $kernel, $heap, $list_id ) = @_[KERNEL,HEAP,ARG0];
	$kernel->call( $heap->{log} => debug => "list::meta refreshing list_id:$list_id");
}

# Notification of Unauthorized Servers
sub notify {
	my ($kernel,$heap,$cli) = @_[KERNEL,HEAP,ARG0];
}

# Return True
1;
