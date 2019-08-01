package Hydrangea::EchoTrunk;

use Hydrangea::Class;

ro 'connected_nodes' => (default => sub { {} });

sub register_command {}

sub receive_message ($self, $node, $from, $msg) {
  $self->connected_nodes->{$node}->message_to(
    { %{$from}{grep exists $from->{$_}, qw(venue user)} },
    { %{$msg}{qw(text)}, is_address => \1 },
  );
}

1;
