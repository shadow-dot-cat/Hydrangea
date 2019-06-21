package Hydrangea::Root::ControlPort;

use Hydrangea::Class;

ro 'path';

ro 'root';

ro _streams => (default => sub { {} });

lazy listener => sub ($self) {
  my $socket = IO::Socket::UNIX->new(
   Local => $self->path,
   Listen => 1,
  ) or die "Cannot make UNIX socket - $!\n";
  use_module('IO::Async::Listener')->new(
    handle => $socket,
    on_stream => $self->curry::weak::incoming_stream,
  )->$_tap(sub { $Loop->add($_[0]) });
};

sub incoming_stream ($self, $stream) {
  my $conn = use_module('Hydrangea::Root::ControlPort::Connection')->new(
    root => $self->root,
    stream => $stream,
  );
  $self->_streams->{$stream} = $stream;
  $stream->configure(
    on_closed => sub { delete $self->_streams->{$stream} },
  );
  return;
}

1;
