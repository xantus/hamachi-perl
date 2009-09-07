package Hamachi::Network;

use strict;
use warnings;

use base 'Mojo::Base';

__PACKAGE__->attr( [ qw/ status name dest / ] );
__PACKAGE__->attr( hosts => sub { [] } );

sub add_host {
    my $self = shift;
    my $hosts = $self->hosts;
    push( @$hosts, shift ) if @_;
#    return wantarray ? @$hosts : $hosts;
}

1;

