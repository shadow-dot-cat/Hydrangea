package Hydrangea::Trunk::Server;

use Mojo::Base 'Mojolicious';
use Hydrangea::Package;
use namespace::clean;

has trunk => sub { use_module('Hydrangea::Trunk')->new };

has echo => sub { use_module('Hydrangea::EchoTrunk')->new };

has known_nodes => sub { {} };

sub startup ($self) {
  my $known = $self->known_nodes;
  $self->helper(known_nodes => sub { $known });
  $self->helper(node => sub ($c) { $c->app->${\$c->stash->{node_type}} });
  {
    my $r = $self->routes;
    my %tc = (
      namespace => 'Hydrangea::HP',
      controller => 'TrunkController',
      action => 'start'
    );
    $r->websocket('/api/trunk')
      ->to(%tc, node_type => 'trunk');
    $r->websocket('/api/echo')
      ->to(%tc, node_type => 'echo');
  }
  return $self;
}

1;
