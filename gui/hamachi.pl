#!/usr/bin/env perl

# A single file http server and web gui to Hamachi
# Using: Extjs, Mojolicious, and Perl
# Copyright (c) 2009 - David Davis, <xantus@xantus.org>
#
# quickstart:
# ./hamachi.pl daemon
# visit http://localhost:3000/

use lib qw( lib ../lib );

BEGIN {
    eval('use Mojolicious::Lite');
    die "Mojo Required! (sudo cpan Mojo)\n" if ( $@ );
}

use Hamachi;
use JSON;

our $ham = Hamachi->new();

my $hdata = sub {
    my $self = shift;

    my $data = [];

    my $node = $self->req->param( 'node' );

    if ( !$node || $node eq 'root' ) {
        my $networks = $ham->get_networks;
        foreach ( @$networks ) {
            push( @$data, {
                cls    => 'network-'.$_->status,
                text   => $_->name.' ('.$_->status.')',
                name   => $_->name,
                status => $_->status,
                id     => 'network-'.$_->name,
            });
        }
    } elsif ( $node =~ s/^network-// ) {
        warn "network: $node";
        my $networks = $ham->get_networks;
        my ( $network ) = grep { $_->name eq $node } $ham->get_networks;
        my $hosts = $network->hosts;
        if ( $hosts ) {
            foreach ( sort { $b->status cmp $a->status } @$hosts ) {
                my $qtip = 'ip: '.$_->ip.'<br>status: '.$_->status;
                if ( my $dest = $_->dest ) {
                    $qtip .= '<br>tunnel: '.$dest;
                }
                if ( my $name = $_->name ) {
                    $qtip = 'name: '.$name.'<br>'.$qtip;
                }
                push( @$data, {
                    cls    => 'host-'.$_->status,
                    qtip   => $qtip,
                    text   => ( $_->name || $_->ip ).' ('.$_->ip.')',
                    name   => $_->name,
                    ip     => $_->ip,
                    dest   => $_->dest,
                    status => $_->status,
                    leaf   => JSON::true,
                });
            }
        }
    }

    $self->render(
        'hamachi-data',
        format => 'json',
        json => $data
    );
};

get '/' => sub {
    my $self = shift;
    $self->stash( hamachi => $ham );
    $self->render( 'index' );
};
get '/hamachi-data' => $hdata;
post '/hamachi-data' => $hdata;

app->types->type( json => 'text/plain' );
#app->types->type( json => 'application/javascript' );

app->start;

exit;

__DATA__

@@ index.html.epl
% my $c = shift;
% my $ham = $c->stash( 'hamachi' );
% $c->stash( layout => 'normal-local', title => 'Hamachi' );
        
<style type="text/css">
    .x-panel-mc {
        background-color: #fff;
    }
    .host-online .x-tree-node-icon {
        background-image:url(lib/ext-3.0.0/resources/images/default/tree/drop-yes.gif);
    }
    .host-offline .x-tree-node-icon {
        background-image:url(lib/ext-3.0.0/resources/images/default/tree/drop-no.gif);
    }
</style>

<script type="text/javascript">

Ext.onReady(function() {
    Ext.QuickTips.init();
    var tree = new Ext.tree.TreePanel({
        id: 'hamachi-tree',
        title: 'Ext Hamachi - <%== $ham->name || '' %> (<%== $ham->ip %>)',
        height: '100%',
        width: '100%',
        useArrows: true,
        autoScroll: true,
        animate: true,
        enableDD: true,
        containerScroll: true,
        rootVisible: false,
        frame: true,
        root: {
            id: 'root',
            nodeType: 'async'
        },
        dataUrl: '/hamachi-data',
        listeners: {
            'beforeappend': function( tree, nodeParent, node ) {
                // auto expand online networks
                if ( node.attributes.status == 'online' ) {
                    node.expand.defer( 100, node );
                }
            },
            'checkchange': function( node, checked ) {
                if ( !checked )
                    return;
                // uncheck the other checkboxes
                var selNodes = tree.getChecked();
                Ext.each( selNodes, function( n ) {
                    if ( n !== node )
                        n.ui.toggleCheck();
                });
            }
        }
    });
    new Ext.Viewport({
        id:'hamachi-viewport',
        layout:'fit',
        border: false,
        items: tree
    });
});

</script>

@@ hamachi-data.json.epl
% my $c = shift;
% use JSON;
<%= to_json( $c->stash( 'json' ) ) %>

@@ layouts/normal.html.epl
% my $c = shift;
<!doctype html>
<html>
    <head>
        <title><%= $c->stash('title') || 'No Title' %></title>
        <link rel="stylesheet" href="http://xant.us/lib/ext-3.0.0/resources/css/ext-all.css" type="text/css" media="screen" />
        <script type="text/javascript" src="http://xant.us/lib/ext-3.0.0/adapter/ext/ext-base.js"></script>
        <script type="text/javascript" src="http://xant.us/lib/ext-3.0.0/ext-all.js"></script>
        <script type="text/javascript">Ext.BLANK_IMAGE_URL = 'http://xant.us/lib/ext-3.0.0/resources/images/default/s.gif';</script>
    </head>
    <body><%= $c->render_inner %></body>
</html>

@@ layouts/normal-local.html.epl
% my $c = shift;
<!doctype html>
<html>
    <head>
        <title><%= $c->stash('title') || 'No Title' %></title>
        <link rel="stylesheet" href="lib/ext-3.0.0/resources/css/ext-all.css" type="text/css" media="screen" />
        <script type="text/javascript" src="lib/ext-3.0.0/adapter/ext/ext-base.js"></script>
        <script type="text/javascript" src="lib/ext-3.0.0/ext-all.js"></script>
        <script type="text/javascript">Ext.BLANK_IMAGE_URL = 'lib/ext-3.0.0/resources/images/default/s.gif';</script>
    </head>
    <body><%= $c->render_inner %></body>
</html>

@@ exception.html.epl
% use Data::Dumper ();
% my $self = shift;
% my $e = $self->stash('exception');
% my $s = $self->stash;
% delete $s->{inner_template};
<!html>
<head><title>Exception</title></head>
    <body>
        <pre><%= $e->message %></pre>
        <pre>
% for my $line (@{$e->lines_before}) {
<%= $line->[0] %>: <%== $line->[1] %>
% }
% if ($e->line->[0]) {
<b><%= $e->line->[0] %>: <%== $e->line->[1] %></b>
% }
% for my $line (@{$e->lines_after}) {
<%= $line->[0] %>: <%== $line->[1] %>
% }
        </pre>
        <pre>
% for my $frame (@{$e->stack}) {
<%== $frame->[1] %>: <%= $frame->[2] %>
% }
        </pre>
        <pre>
% delete $s->{exception};
%== Data::Dumper->new([$s])->Maxdepth(2)->Indent(1)->Terse(1)->Dump
% $s->{exception} = $e;
        </pre>
    </body>
</html>
