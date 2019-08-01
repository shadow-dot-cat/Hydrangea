package Hydrangea::HP::TrunkController;

use Mojo::Base 'Mojolicious::Controller';
use Hydrangea::HP;
use Hydrangea::HP::Far::Client;
use Hydrangea::Package;

has 'start_f';

has 'far_object';

sub start ($self) {
  $self->start_f(
    reduce { $a->then($b) } Future::Mojo->done,
      map { my $m = $_; sub { $self->$m } } qw(negotiate auth setup)
  )->on_ready(sub { $self->start_f(undef) });
}

sub negotiate ($self) {
  $self->$_once('json')
       ->then(sub ($msg) {
           if (
             is_Client_Protocol_Offer($msg)
             and $msg->[-1] eq $HP_VERSION
           ) {
             $self->send({ json => [
               protocol_accept => hydrangea => '0.2019073000'
             ] });
             return Future->done;
           }
           return Future->fail("Protocol negotiation error");
         })
}

sub auth ($self) {
  $self->$_once('json')
       ->then(sub ($msg) {
           if (is_Client_Ident_Assert($msg)) {
             my ($name, $pw) = @{$msg}[1,2];
             if (my $node = $self->known_nodes->{$name}) {
               if (match_pw($node->{far_hash}, $pw)) {
                 $self->send({ json => [
                   ident_confirm => $node->{my_pw}
                 ] });
                 return Future->done($name);
               }
             }
           }
           return Future->fail("Authentication error");
         })
}

sub setup ($self, $name) {
  Future->done($self->adopt_far_object(Hydrangea::HP::Far::Client->new(
    connection => $self->tx,
    node => $self->node,
    far_nodename => $name,
  )));
}

sub adopt_far_object ($self, $far) {
  my $connected = $self->node->connected_nodes;
  my $name = $far->far_nodename;
  $self->on(finish => sub { delete $connected->{$name} });
  $connected->{$name} = $far;
  $self->far_object($far);
}

1;
