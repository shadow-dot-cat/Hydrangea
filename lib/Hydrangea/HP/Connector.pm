package Hydrange::HP::Connector;

use Mojo::URL;
use List::Util qw(reduce);
#use Hydrangea::Utils qw(match_pw);
sub match_pw { die "unimplemented" }
use Hydrangea::HP;
use Hydrangea::HP::Far::Trunk;
use Hydrangea::Class;

lazy ua_settings => sub { {} };
lazy ua_class => sub { 'Mojo::UserAgent' };
lazy ua => sub ($self) {
  use_module($self->ua_class)->new($self->ua_settings)
};

ro 'my_nodename';
ro 'my_pw';

ro 'node';

ro 'trunk_url';
ro 'trunk_pw_hash';

lazy _trunk_url => sub ($self) {
  Mojo::URL->new($self->trunk_url)->tap(sub ($u) {
    $u->path('/ws/trunk') unless $u->path and $u->path ne '/';
  });
};

sub connect ($self) {
  # Sequence: connect websocket, negotiate protocol, authenticate, setup
  reduce { $a->then($b) }
    $self->ua->$_do(websocket => $self->_trunk_url),
      map { my $m = $_; sub { $self->$m(@_) } } qw(negotiate auth setup)
}

sub negotiate ($self, $conn) {
  $conn->send({ json => [ protocol_offer => hydrangea => $HP_VERSION ] })
       ->$_once('json')
       ->then(sub ($msg) {
           if (
             is_Trunk_Protocol_Accept($msg)
             and $msg->[-1] eq '0.2019073000'
           ) {
             return Future->done($conn);
           }
           return Future->fail("Protocol negotiation error");
         })
}

sub auth ($self, $conn) {
  $conn->send({ json => [
    ident_assert => $self->my_nodename, $self->my_pw
  ] });
  $conn->$_once('json')
       ->then(sub ($msg) {
           if (
             is_Trunk_Ident_Confirm($msg)
             and match_pw($self->trunk_pw_hash, $msg->[-1])
           ) {
             return Future->done($conn);
           }
           return Future->fail("Authentication error");
         })
}

sub setup ($self, $conn) {
  my $far = Hydrangea::HP::Far::Trunk->new(
    connection => $conn,
    node => $self->node
  );
  return Future->done($far);
}

1;
