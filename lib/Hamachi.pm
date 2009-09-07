package Hamachi;

use strict;
use warnings;

our $VERSION = '0.01';

use Time::HiRes;
use Hamachi::IPC;
use Hamachi::Network;
use Hamachi::Host;

use base 'Mojo::Base';

__PACKAGE__->attr( [qw/ ip name /] );
__PACKAGE__->attr( state => '.hamachi/state' );
__PACKAGE__->attr( path => '/usr/bin/hamachi' );
__PACKAGE__->attr( ipc => sub { Hamachi::IPC->new } );
__PACKAGE__->attr( last_check => 0 );
__PACKAGE__->attr( networks => sub { [] } );

sub new {
    my $self = shift->SUPER::new( @_ );
    
    open( FH, $self->state )
        or die "Can't open ".$self->state." : $!";
    foreach ( <FH> ) {
        if ( /Identity\s+(\d+\.\d+\.\d+\.\d+)/ ) {
            $self->ip( $1 );
            last;
        }
    }
    close( FH );
    
    $self->ipc->get_status;

    return $self;
}

# this hack will go away in favor of the IPC interface
sub parse {
    my ( $self, $force ) = @_;

    return if $self->{parsed}++;

#    $self->last_check( time() );

    my $quad = qr/\d+\.\d+\.\d+\.\d+/;
    my $path = $self->path;
    `$path get-nicks`;
    sleep(1);
    my @h = split( /\n/, `$path list` );
    my ( $network, @networks );

    $self->networks( \@networks );

    foreach ( @h ) {
        if ( /\[([^\]]+)\]/ ) {
            
            push( @networks, $network = Hamachi::Network->new( name => $1 ) );
            $network->status( /\*/ ? 'online' : 'offline' );
        
        } elsif ( /($quad)(?:\s+(\S*))?/ ) {
            my ( $ip, $name, $host ) = ( $1, $2 );

            $network->add_host( $host = Hamachi::Host->new( ip => $ip ) );
            $host->status( /\*/ ? 'online' : 'offline' );
            $host->name( $name ) if defined $name;
            
            # when the name is missing, the regexp catches the dest
            if ( /($quad:\d+)/ ) {
                $host->dest( $1 );
                $host->name( undef ) if ( $host->name && $host->name eq $1 );
            }

        }
    }

    require Data::Dumper;
    warn Data::Dumper->Dump([\@networks]);
}

sub get_networks {
    my $self = shift;
    
    $self->parse();

    return wantarray ? @{ $self->networks } : $self->networks;
}

1;

