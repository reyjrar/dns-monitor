package dns::monitor::plugin::sniffer::log;

use Digest::SHA qw( sha1_hex );
use MooseX::POE;

extends qw(dns::monitor::core::plugin);

has cache => ( isa => 'HashRef', is => 'rw', default => sub { {} } );

event process => sub {
	my ($self,$kernel,$dnsp,$info) = @_[OBJECT,KERNEL,ARG0,ARG1];

	# Establish UUID
	my $uuid = sha1_hex join(';', 
							$info->{server}, $info->{server_port},
							$info->{client}, $info->{client_port},
							$dnsp->header->id
	); 

	# Check for query/response
	if( $dnsp->header->qr ) {

		# Grab entry from cache:
		my $entry = delete $self->cache->{$uuid};
		# If there isn't an entry, create one and set the the flushed flag
		$entry ||= { uuid => $uuid, flushed => 1 };

		# Answer Header
		$entry->{a} = {
			'time'	=> $info->{time},
			cli		=> join(':', $info->{client}, $info->{client_port} ),
			srv		=> join(':', $info->{server}, $info->{server_port} ),
			id		=> $dnsp->header->id,
			op		=> $dnsp->header->opcode,
			qcnt	=> $dnsp->header->qdcount,
			cd		=> $dnsp->header->cd,
			rd		=> $dnsp->header->rd,
			status	=> $dnsp->header->rcode,
			size	=> $dnsp->answersize,
			anscnt	=> $dnsp->header->ancount,
			addcnt	=> $dnsp->header->arcount,
			authcnt	=> $dnsp->header->nscount,
			authr	=> $dnsp->header->aa,
			authn	=> $dnsp->header->ad,
			ra		=> $dnsp->header->ra,
		};

		my @sets = ();
		
		foreach my $section (qw(answer additional authority)) {
			my @records = ();
			try {
				no strict;
				@records = $dnsp->$section();
			};
			if( @records ) {
				push @sets, { name => $_SECTION_CODE{$section}, rr => \@records };
			}
		}
		foreach my $set ( @sets ) {
			foreach my $pa ( @{ $set->{rr} } ) {
				my %data = $self->get_rr_data( $pa );
				
				next unless defined $data{value} && length $data{value};
				
				push @{ $entry->{ar} }, {
					sect	=> $set->{name},
					class	=> $pa->class,
					rtype	=> $pa->type,
					name	=> $pa->name,
					value	=> $data{value},
					opts	=> $data{opts},
					ttl		=> $pa->ttl,
				};
			}
		}

		$kernel->yield( 'flush_entry' => $entry );
	}
	else {
		# Query
		my %entry = (
			proc_time => time,
			uuid => $uuid,
		);
		$entry{q} = {
			'time'	=> $info->{time},
			cli		=> join(':', $info->{client}, $info->{client_port} ),
			srv		=> join(':', $info->{server}, $info->{server_port} ),
			id		=> $dnsp->header->id,
			op		=> $dnsp->header->opcode,
			qcnt	=> $dnsp->header->qdcount,
			rd		=> $dnsp->header->rd,
			cd		=> $dnsp->header->cd,
		};

		# Set Cache:
		foreach my $pq ( $dnsp->question ) {
			push @{ $entry{qr} }, {
				class	=> $pq->qclass,
				rtype	=> $pq->qtype,
				name	=> $pq->qname,
			};
		}

		# Store it in the cache
		$self->cache->{$uuid} = \%entry;
	}
};

event flush_entry => sub {
	my ($self,$entry) = @_[OBJECT,ARG0];

	my $line = '';
	$self->write( $line );
};

before maintenance => sub {
	my $self = $_[OBJECT];
};


# Add Roles
with qw(
	dns::monitor::core::util
	dns::monitor::plugin::sniffer
);

no MooseX::POE;
__PACKAGE__->meta->make_immutable;
1;
