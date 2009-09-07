package Hamachi::IPC;

use strict;
use warnings;

use base 'Mojo::Base';

use Socket;
use Fcntl ':flock';
use bytes;

use constant
    IPC_SHUTDOWN    => 1,
	IPC_LOGIN		=> 2,
	IPC_LOGOUT		=> 3,
	IPC_CREATE		=> 4,
	IPC_DELETE		=> 5,
	IPC_JOIN		=> 6,
	IPC_STATUS	 	=> 7,
	IPC_GET_LIST 	=> 8,
	IPC_LEAVE		=> 9,
	IPC_GET_NICK	=> 10,
	IPC_EVICT 		=> 11;

__PACKAGE__->attr( [qw/ agent online nick pid /] );
__PACKAGE__->attr( ipc_sock => '.hamachi/ipc_sock' );
__PACKAGE__->attr( debug => 1 );
__PACKAGE__->attr( sock => sub {
    my $self = shift;

    die $self->ipc_sock.' is not a unix socket'
        unless -S $self->ipc_sock;
    
    socket( my $sock, PF_UNIX, SOCK_STREAM, 0 )
        or die "socket: $!";
    connect( $sock, sockaddr_un( $self->ipc_sock ) )
        or die "connect: $!";

    return $sock;
});

sub get_status {
    my $self = shift;

    my $sock = $self->sock;

    $self->sock_lock;

    # read the status length
    sysread( $sock, my $size, 4, 0 );
    $size = unpack( 'N', $size );

    my $data;
    # read until done
    while( $size > 0 ) {
        my $len = sysread( $sock, $data, $size, 0 );
        unless ( $len ) {
            $size = -1;
            last;
        }
        $size -= $len;
    }

    $self->sock_unlock;

    if ( $size == -1 ) {
        warn "error reading status";
        return;
    }

    my $code = unpack( 'c', substr( $data, 0, 1, '' ) );
    if ( $code != -128 ) {
        warn "incorrect start code";
        return;
    }

    $self->agent( substr( $data, 0, unpack( 'c', substr( $data, 0, 1, '' ) ), '' ) );
    $self->pid( unpack( 'N', substr( $data, 0, 4, '' ) ) ); # 4 len of gint

    substr( $data, 0, 5, '' ); # ignore?
    
    $self->online( unpack( 'b', substr( $data, 0, 1, '' ) ) );
    $self->nick( substr( $data, 0, unpack( 'c', substr( $data, 0, 1, '' ) ), '' ) );
    
    $self->debug && warn "pid:   ".$self->pid."\n";
    $self->debug && warn "agent: ".$self->agent."\n";
    $self->debug && warn "online:".( $self->online ? 'yes' : 'no' )."\n";
    $self->debug && warn "nick:  ".$self->nick."\n";
    
    return 1;
}

sub sock_lock {
    flock( shift->sock, LOCK_EX );
}

sub sock_unlock {
    flock( shift->sock, LOCK_UN );
}


1;
