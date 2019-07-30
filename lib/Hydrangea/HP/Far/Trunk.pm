package Hydrangea::HP::Far::Trunk;

use Hydrangea::Class;

ro 'connection';
ro 'root';
ro commands => (default => sub { {} });
ro ci => (default => sub { {} });

with 'Hydrangea::HP::Role::FarObject';

sub message_from ($self, @args) { $self->_send(message_from => @args) }

sub command_register ($self, @args) { $self->_send(command_register => @args) }
sub command_sent ($self, @args) { $self->_send(command_sent => @args) }
sub command_done ($self, @args) { $self->_send(command_done => @args) }
sub command_failed ($self, @args) { $self->_send(command_failed => @args) }

sub _type { 'client' }
sub _rtype { 'trunk' }

sub _handle_message_to ($self, @msg) {
  $self->root->send_message(@msg);
}

sub _handle_command_start ($self, $tx_id, $name, @args) {
  $self->ci->{$tx_id} = $self->commands->{$name}->start($tx_id, @args);
}

sub _handle_command_send ($self, $tx_id, $send) {
  $self->ci->{$tx_id}->send($send);
}

sub _handle_command_cancel ($self, $tx_id) {
  $self->ci->{$tx_id}->cancel;
}

1;
