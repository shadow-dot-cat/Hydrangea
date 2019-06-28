package Hydrangea::Role::ServiceManager;

use Types::Standard qw(Bool);
use Hydrangea::Supervisor;
use Hydrangea::Role;

# has services => (is => 'ro', default => sub { {} });
# ->
# ro services => (default => sub { {} });
# ->
lazy services => sub { {} };

sub has_service ($self, $name) { exists $self->services->{$name} }

sub service ($self, $name, @rest) {
  my $s = $self->services;
  return $s->{$name} unless @rest;
  my ($service) = $rest[0];
  if (defined $service) {
    my $x = exists $s->{$name};
    $s->{$name} = $service;
    $self->add_supervisor($name) unless $x;
  } else {
    if (delete $s->{$name}) {
      $self->remove_supervisor($name);
    }
  }
  return $self;
}

lazy supervisors => sub { {} };

sub add_supervisor ($self, $name) {
  my $service = $self->services->{$name};
  my $sup = Hydrangea::Supervisor->wrap($service);
  $self->supervisors->{$name} = $sup;
  return $self;
}

sub remove_supervisor ($self, $name) {
  delete $self->supervisors->{$name};
  return $self;
}

sub start_supervisors ($self) {
  my $svc_conf = $self->config->{service};
  foreach my $name (sort keys %{$self->services}) {
    if ($svc_conf->{$name}{enabled}) {
      $self->services->{$name}->up;
    }
  }
}

sub check_supervisor_config ($self) {
  my $config_spec = map +($_ => +{
    enabled => Bool,
  });
  $self->validate_config($config_spec, $self->config->{service});
}

1;
