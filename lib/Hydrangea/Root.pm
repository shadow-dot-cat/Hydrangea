package Hydrangea::Root;

use Hydrangea::Class;

with 'Role::EventEmitter';

ro 'chat_client_type';

lazy chat_client_class => sub ($self) { 
  use_module('Hydrangea::ChatClient::'.$self->chat_client_type)
};

lazy config_spec => sub ($self) {
  my $cc_class = $self->chat_client_class;
  return +{
    lc($self->chat_client_type) => $cc_class->config_spec,
  };
};

sub has_service ($self, $name) {
  exists $self->config_spec->{$name};
}

lazy config => sub { {} };

lazy chat_client => sub ($self) {
  my $cc = $self->chat_client_class->new;
  $cc->on(receive_message => $self->curry::weak::receive_message);
  $self->on(send_message => $cc->curry::weak::send_message);
});

rw control_socket => (required => 0);

sub run ($self) {
  $self->chat_client(Hydrange::Supervisor->wrap(use_module(
    'Hydrangea::ChatClient::'.ucfirst($client_type)
  )->from_config($self->config)));
  $self->control_socket(Hydrangea::ControlSocket->new(...));
  ...
}

sub receive_message ($self, $from, $msg) {
  $self->emit('message_to_me', $from, $msg) if $msg->{is_to_me};
  $self->emit('message_seen', $from, $msg);
}

sub send_message ($self, $to, $msg) {
  $self->emit('send_message', $to, $msg);
}

## These are probably ::Node methods or ::Role::Node methods or something

1;
