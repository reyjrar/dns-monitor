package POE::Component::dns::monitor::sniffer::plugin::packet::logger;

use strict;
use warnings;
use POE;
use DateTime;
use YAML;
use Try::Tiny;

sub spawn {
	my $self = shift;
	my %args = @_;

	die "Bad Config" if ref $args{Config} ne 'HASH';
	die "Bad Model" unless ref $args{DBICSchema};
	die "No Alias" unless length $args{Alias};

	my $sess = POE::Session->create( inline_states => {
		_start	=> sub { $poe_kernel->yield( 'packet_logger_start', \%args ); },
		_stop 	=> sub { },
		packet_logger_start => \&packet_logger_start,
		process => \&process,
		maintenance => \&packet_logger_maintenance,
		packet_logger_query_response => \&packet_logger_query_response,
		packet_logger_client_is_server => \&packet_logger_client_is_server,
	});

	return $sess->ID;
}

sub packet_logger_start {
	my($kernel,$heap,$args) = @_[KERNEL,HEAP,ARG0];

	$kernel->alias_set( $args->{Alias} );
	
	# Store stuff in the heap
	$heap->{log} = $args->{LogSID};
	$heap->{model} = $args->{DBICSchema};

	# Caching
	my %_qcache = ();
	$heap->{qcache} = CHI->new( driver => 'Memory', datastore => \%_qcache, expires_in => 90 );
	$heap->{__qcache} = \%_qcache;

	# Trigger Maintenance
	$kernel->delay_add( 'maintenance', 30 );
}

sub process {
	my ( $kernel,$heap,$dnsp,$ip,$srv,$cli ) = @_[KERNEL,HEAP,ARG0,ARG1,ARG2,ARG3];

	# Packet ID
	my $packet_id = join(';', $srv->id, $cli->id, $dnsp->header->id );

	# Handle Conversation
	my $role_server_id = $cli->role_server_id || 0;
	my $conversation = $heap->{model}->resultset('packet::meta::conversation')->find_or_create({
		server_id => $srv->id,
		client_id => $cli->id,
	});
	$conversation->client_is_server( defined $cli->role_server_id ? 1 : 0 );
	$conversation->update;
	my $answers = $conversation->answers || 0;
	my $questions = $conversation->questions || 0;

	# Check for query/response
	if( $dnsp->header->qr ) {
		$answers++;
		# Grab Queriy id from cache:
		my $query_id = $heap->{qcache}->get( $packet_id );
		# Answer
		my $resp = $heap->{model}->resultset('packet::response')->create({
			client_id => $cli->id,
			server_id => $srv->id,
			conversation_id => $conversation->id,
			client_port => $ip->{client_port},
			server_port => $ip->{server_port},
			query_serial => $dnsp->header->id,
			opcode => $dnsp->header->opcode,
			status => $dnsp->header->rcode,
			size_answer => $dnsp->answersize,
			count_answer => $dnsp->header->ancount,
			count_additional => $dnsp->header->arcount,
			count_authority => $dnsp->header->nscount,
			count_question => $dnsp->header->qdcount,
			flag_authoritative => $dnsp->header->aa,
			flag_authenticated => $dnsp->header->ad,
			flag_truncated => $dnsp->header->tc,
			flag_checking_desired => $dnsp->header->cd,
			flag_recursion_desired => $dnsp->header->rd,
			flag_recursion_available => $dnsp->header->ra,
		});
		$resp->update;
		# Link Query / Response
		if( defined $query_id ) {
			$resp->query_id( $query_id );
			my $qobj = $heap->{model}->resultset('packet::query')->find( $query_id );
			if( defined $qobj ) {
				$qobj->response_id( $resp->id );
			}
			$qobj->update;
			$resp->update;
		}

		my @sets = (
			{ name => 'answer', rr => [ $dnsp->answer ], },
			{ name => 'additional', rr => [ $dnsp->additional ], },
			{ name => 'authority', rr => [ $dnsp->authority ], },
		);
		foreach my $set ( @sets ) {
			foreach my $pa ( @{ $set->{rr} } ) {
				my %data = _get_rr_data( $pa );
				
				next unless defined $data{value} && length $data{value};
				
				my $aobj = $heap->{model}->resultset('packet::record::answer')->find_or_create({
					name	=> $pa->name,
					type	=> $pa->type,
					class	=> $pa->class,
					opts	=> $data{opts},
					value	=> $data{value},
				});
	
				try {	
					my $meta = $heap->{model}->resultset('packet::meta::answer')->create({
						ttl		=> $pa->ttl,
						response_id => $resp->id,
						answer_id	=> $aobj->id,
						section => $set->{name},
					});
					$meta->update;
					my $ref_count = $aobj->reference_count || 0;
					$aobj->reference_count( $ref_count + 1 );
					$aobj->update;
				} catch {
					$kernel->post( $heap->{log}, "Meta-Record Duplication in Response: $_" );
				};

			}
		}
	}
	else {
		# Query
		$questions++;
		my $query = $heap->{model}->resultset('packet::query')->create({
			client_id => $cli->id,
			server_id => $srv->id,
			conversation_id => $conversation->id,
			client_port => $ip->{client_port},
			server_port => $ip->{server_port},
			query_serial => $dnsp->header->id,
			opcode => $dnsp->header->opcode,
			count_questions => $dnsp->header->qdcount,
			flag_recursive => $dnsp->header->rd,
			flag_truncated => $dnsp->header->tc,
			flag_checking => $dnsp->header->cd,
				
		});
		$query->update;
		# Set Cache:
		$heap->{qcache}->set( $packet_id, $query->id );
		foreach my $pq ( $dnsp->question ) {
			my $qobj = $heap->{model}->resultset('packet::record::question')->find_or_create({
				name => $pq->qname,
				type => $pq->qtype,
				class => $pq->qclass,
			});
			my $ref_count = $qobj->reference_count() || 0;
			$qobj->reference_count( $ref_count + 1 );
			$qobj->update;
			my $record = $heap->{model}->resultset('packet::meta::question')->create({
				query_id => $query->id,
				question_id => $qobj->id,
			});
			$record->update;
		}
	}

	# Update Conversations:
	$conversation->answers( $answers );
	$conversation->questions( $questions );
	$conversation->update;
}

sub packet_logger_maintenance {
	my ($kernel,$heap) = @_[KERNEL,HEAP];

	# Purge the Query Cache
	$heap->{qcache}->purge();

	$kernel->yield('packet_logger_query_response');
	$kernel->yield('packet_logger_client_is_server');

	# Reschedule
	$kernel->delay_add( 'maintenance', 600 );
}

sub packet_logger_query_response {
	my ($kernel,$heap) = @_[KERNEL,HEAP];

	# Select Null response_id
	my $check_ts = DateTime->now()->subtract( days => 2 );
	my $unanswered = $heap->{model}->resultset('packet::query')->search(
		{ response_id => undef },
		{
			order_by => 'query_ts',
		},
	);

	my $updates = 0;
	while( my $q = $unanswered->next ) {
		my $answer = $heap->{model}->resultset('packet::response')->find(
			{
				conversation_id => $q->conversation_id,
				query_serial => $q->query_serial,
				response_ts => { -between => [ $q->query_ts->clone->subtract( seconds => 1), $q->query_ts->clone()->add( seconds => 10 )] },
			},
		);	
		if( defined $answer ) {
			$q->response_id( $answer->id );
			$q->update;
			$updates++;
		}
	}
	$kernel->post( $heap->{log} => debug => "packet::logger::query_response linked $updates stray queries" );
}

sub packet_logger_client_is_server {
	my ($kernel,$heap) = @_[KERNEL,HEAP];

	my $clients = $heap->{model}->resultset('client')->search(
		{ role_server_id => { '!=' => undef } },
	);
	
	my $updates = 0;
	while( my $cli = $clients->next ) {
		my $conversations = $heap->model('packet::meta::conversation')->search(
			{ 
				client_id => $cli->id,
				client_is_server => 0
			}
		);

		while ( my $conv = $conversations->next ) {
			$conv->client_is_server( 1 );
			$conv->update;
			$updates++;
		}
	}

	$kernel->post( $heap->{log} => debug => "packet::logger::client_is_server updated $updates conversations" );
}

sub _get_rr_data {
	my ($pa) = shift;

	my %data = ( value => undef, opts => undef );

	if( $pa->type eq 'A' || $pa->type eq 'AAAA' ) {
		$data{value} = $pa->address;
	}
	elsif( $pa->type eq 'CNAME' ) {
		$data{value} = $pa->cname;
	}
	elsif( $pa->type eq 'DNAME' ) {
		$data{value} = $pa->dname;
	}
	elsif( $pa->type eq 'MX' ) {
		$data{value} = $pa->exchange;
		$data{opts} = $pa->preference;
	}
	elsif( $pa->type eq 'NS' ) {
		$data{value} = $pa->nsdname;
	}
	elsif( $pa->type eq 'PTR' ) {
		$data{value} = $pa->ptrdname;
	}
	elsif( $pa->type eq 'SRV' ) {
		$data{value} = $pa->target;
		$data{value} .= ':' . $pa->port if $pa->port;
		$data{opts} = $pa->priority;
		$data{opts} .= ';' . $pa->priority if defined $pa->weight;
	}
	elsif( $pa->type eq 'SPF' || $pa->type eq 'TXT' ) {
		$data{value} = $pa->txtdata;
	}
	
	return %data;
}

1;


