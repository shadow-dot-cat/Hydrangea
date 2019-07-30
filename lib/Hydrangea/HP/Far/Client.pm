package Hydrangea::HP::Far::Client;

use Hydrangea::Class;
use Hydrangea::HP::Far::CommandInvocation;

ro 'connection';
ro 'node';
ro rci => (default => sub { {} });

ro curr_tx_id => (default => 'A000');

sub next_tx_id ($self) { ++$self->{curr_tx_id} }

sub _type { 'client' }
sub _rtype { 'trunk' }

with 'Hydrangea::HP::Role::FarObject';

sub message_to ($self, @args) { $self->_send(message_to => @args) }

sub command_start ($self, @args) {
  my $tx_id = $self->next_tx_id;
  $self->_send(command_start => $tx_id, @args);
  return $self->rci->{$tx_id} = Hydrangea::HP::Far::CommandInvocation->new(
    tx_id => $tx_id,
    parent => $self,
  );
}

sub _command_send ($self, @args) { $self->_send(command_send => @args) }
sub _command_cancel ($self, @args) { $self->_send(command_cancel => @args) }

sub _handle_message_from ($self, @msg) {
  $self->node->receive_message(@msg);
}

sub _handle_command_register ($self, $cmd) {
  $self->node->register_command($self->connection->nodename, $cmd);
}

sub _handle_command_sent ($self, $tx_id, $sent) {
  $self->rci->{$tx_id}->_sent($sent);
}

sub _handle_command_done ($self, $tx_id, $done = undef) {
  (delete $self->rci->{$tx_id})->_done($done);
}

sub _handle_command_failed ($self, $tx_id, $failure) {
  (delete $self->rci->{$tx_id})->_fail($failure);
}

1;
