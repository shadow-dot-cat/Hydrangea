package Hydrangea::HP::Role::FarObject;

use Hydrangea::Role;
use Hydrangea::HP::Types;

requires '_type';
requires '_rtype';

lazy type_meta => sub { Hydrangea::HP::Types->meta };

sub __lookup_type ($self, $end, $name) {
  my $name = join '_', map ucfirst, $self->$end, split '_', $name;
  $self->type_meta->get_type($name);
}

sub _lookup_type ($self, $name) { $self->__lookup_type('_type', $name) }
sub _lookup_rtype ($self, $name) { $self->__lookup_type('_rtype', $name) }

sub _send ($self, $message_name, @args) {
  my @msg = ($message_name, @args);
  unless ($self->_lookup_type($message_name)->check(\@msg)) {
    log error => 'Invalid message';
    return;
  }
  $self->connection->send(\@msg);
  return;
}

sub handle ($self, $message_name, @args) {
  my @msg = ($message_name, @args);
  unless ($self->_lookup_rtype($message_name)->check(\@msg)) {
    log error => 'Invalid message';
    return;
  }
  $self->${\"_handle_${message_name}"}(@args);
}

1;
