package Hydrangea::STDIOControlPort;

use IO::Async::Stream;
use IO::Async::Protocol::LineStream;
use Hydrangea::Root::ControlPort::Connection;
use Hydrangea::Class;

ro 'node';

lazy conn => sub ($self) {
  Hydrangea::Root::ControlPort::Connection->new(
    node => $self->node,
    stream => IO::Async::Protocol::LineStream->new(
      transport => IO::Async::Stream->new_for_stdio
    )
  )
};

sub start ($self) {
  $self->conn;
}

1;
