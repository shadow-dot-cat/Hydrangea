package Hydrangea::Root;

use JSON::Dumper::Compact;
use Mojo::File qw(path);
use Hydrangea::Class;

with 'Role::EventEmitter';
with 'Hydrangea::Role::ServiceManager';

ro 'name';

ro 'chat_client_type';

ro base_dir => builder => sub {
  require FindBin;
  require Cwd;
  require File::Spec;
  my $dir = File::Spec->updir(Cwd::abs_path($FindBin::Bin));
};

lazy chat_service_name => sub ($self) { lc($self->chat_client_type) };

lazy chat_client_class => sub ($self) { 
  use_module('Hydrangea::ChatClient::'.$self->chat_client_type)
};

sub chat_service ($self) { $self->service($self->chat_service_name) }

lazy service_spec => sub ($self) {
  return +{
    $self->chat_service_name => $self->chat_client_class,
  };
};

sub _build_services ($self) {
  return +{
    map +($_ => $self->_construct_service($_)), keys %{$self->service_spec}
  };
}

sub _construct_service ($self, $name) {
  my $service_spec = $self->service_spec->{$name};
  my $config_spec = use_module($service_spec)->config_spec;
  my $this_config = $self->config->{$name};
  $self->validate_config($this_config, $config_spec);
  return $service_spec->new($this_config||());
}

sub validate_config {
  # I keep getting writer's block on this bit
  return 1;
}

lazy config_spec => sub ($self) {
  my $cc_class = $self->chat_client_class;
  return +{
    lc($self->chat_client_type) => $cc_class->config_spec,
  };
};

sub has_service ($self, $name) {
  exists $self->config_spec->{$name};
}

lazy file_base => sub ($self) {
  "root.${\$self->chat_service_name}.${\$self->name}";
};

lazy config_file => sub ($self) {
  path($self->base_dir)->child('etc')->child($self->file_base.'.conf');
};

lazy config => sub ($self) {
  my $file = $self->config_file;
  unless (-f $file) {
    log warn => "Config file ${file} does not exist";
    return {};
  }
  my $conf = do { local (@ARGV, $/) = ($file); <> };
  JSON::Dumper::Compact->decode($conf);
};

lazy control_socket => sub ($self) {
  path($self->base_dir)->child('var', 'run')->mkpath
    ->file($self->file_base.'.sock');
};

lazy control_port_class => sub { 'Hydrangea::ControlPort' };

lazy control_port => sub ($self) {
  use_module($self->control_port_class)->new(node => $self);
};

sub BUILD ($self, $) {
  my $cc = $self->chat_service;
  $cc->on(receive_message => $self->curry::weak::receive_message);
  $self->on(send_message => $cc->curry::weak::send_message);
}

sub receive_message ($self, $from, $msg) {
  $self->emit('message_to_me', $from, $msg) if $msg->{is_to_me};
  $self->emit('message_seen', $from, $msg);
}

sub send_message ($self, $to, $msg) {
  $self->emit('send_message', $to, $msg);
}

sub start ($self) {
  $self->control_port->start;
  $self->start_supervisors;
}

1;
