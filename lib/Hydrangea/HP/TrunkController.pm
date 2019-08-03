package Hydrangea::HP::TrunkController;

use Mojo::Base 'Mojolicious::Controller';
use Hydrangea::Utils qw(match_pw);
use Hydrangea::HP;
use Hydrangea::HP::Types qw(:all);
use Hydrangea::HP::Far::Client;
use Hydrangea::Package;
use namespace::clean;

has state => sub { 'negotiate' };

has sub_id => sub ($self) {
  $self->on(json => sub ($, $data) { $self->on_message($data) });
};

has 'far';

sub start ($self) {
  $self->sub_id;
  return;
}

sub on_message ($self, $data) {
  $self->${\"on_${\$self->state}"}($data);
}

sub on_negotiate ($self, $msg) {
  # Remember to make jberger help you with websocket subprotocol support as an
  # alternative option for people who know websockets and aren't trying to adapt
  # code that speaks the unix socket protocol
  if (is_Client_Protocol_Offer($msg)) {
    if ($msg->[-1] eq $HP_VERSION) {
      $self->send({ json => [
        protocol_accept => hydrangea => $HP_VERSION
      ] });
      $self->state('authenticate');
      return;
    } else {
      log error => "Unknown version ${\($msg->[-1])}";
    }
  } else {
    log error =>
      "Invalid negotiation packet: "
        .join("\n", @{Client_Protocol_Offer->validate_explain($msg)})
    ;
  }
  $self->send({ json => [ 'protocol_fail' ] });
  $self->finish;
}

sub on_authenticate ($self, $msg) {
  if (is_Client_Ident_Assert($msg)) {
    my ($name, $pw) = @{$msg}[1,2];
    if (my $node = $self->known_nodes->{$name}) {
      if (match_pw($node->{far_hash}, $pw)) {
        $self->send({ json => [
          ident_confirm => $node->{my_pw}
        ] });
        $self->node->connected_nodes->{$name} = $self->setup_for($name);
        $self->state('far');
        return;
      }
    }
  }
  $self->send({ json => [ 'ident_fail' ] });
  $self->finish;
}

sub setup_for ($self, $name) {
  $self->far(my $far = Hydrangea::HP::Far::Client->new(
    connection => $self->tx,
    node => $self->node,
    far_nodename => $name,
  ));
  return $far;
}

sub on_far ($self, $msg) {
#::Dwarn($msg);
  $self->far->handle($msg);
}

1;
