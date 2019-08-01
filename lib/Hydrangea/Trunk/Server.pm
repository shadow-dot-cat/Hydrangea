package Hydrangea::Trunk::Server;

use Mojo::Base 'Mojolicious';
use Hydrangea::Package;

has trunk => sub { use_module('Hydrangea::Trunk')->new };

has echo => sub { use_module('Hydrangea::EchoTrunk')->new };

has known_nodes => sub { {} };

sub startup ($self) {
  my $known = $self->known_nodes;
  $self->helper(known_nodes => sub { $known });
  $self->helper(node => sub ($c) { $c->app->${\$c->stash->{node_type}} });
  {
    my $r = $self->routes;
    $r->get('/api/trunk')
      ->to("Hydrangea::HP::TrunkController#start", node_type => 'trunk');
    $r->get('/api/echo')
      ->to("Hydrangea::HP::TrunkController#start", node_type => 'echo');
  }
}

1;
