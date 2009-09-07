package Hamachi::Host;

use strict;
use warnings;

use Scalar::Util qw( weaken );

use base 'Mojo::Base';

__PACKAGE__->attr( [ qw/ status ip name dest / ] );

our $host_cache = {};

sub new {
    my $self = shift->SUPER::new( @_ );
    my $ip = $self->ip;

    my $cached = $host_cache->{ $ip } || $self;
    $host_cache->{ $ip } = $cached;

    weaken( $host_cache->{ $ip } );
    
    return $cached;
}

1;
