package Hydrangea::HP::Role::FarObject;

use Hydrangea::HP::Types;
use Hydrangea::Role;

ro 'connection';
ro 'node';

requires '_type';
requires '_far_type';

lazy type_meta => sub { Hydrangea::HP::Types->meta };

sub __lookup_type ($self, $end, $raw_name) {
  my $name = join '_', map ucfirst, $self->$end, split '_', $raw_name;
  $self->type_meta->get_type($name);
}

sub _lookup_type ($self, $name) { $self->__lookup_type('_type', $name) }
sub _lookup_far_type ($self, $name) { $self->__lookup_type('_far_type', $name) }

sub _send ($self, $message_name, @args) {
  my @msg = ($message_name, @args);
  unless ($self->_lookup_type($message_name)->check(\@msg)) {
    log error => 'Invalid message';
    return;
  }
  $self->connection->send({ json => \@msg });
  return;
}

sub handle ($self, $msg) {
  my ($message_name, @args) = @$msg;
  unless ($self->_lookup_far_type($message_name)->check($msg)) {
    log error => 'Invalid message';
    return;
  }
  $self->${\"_handle_${message_name}"}(@args);
}

1;
