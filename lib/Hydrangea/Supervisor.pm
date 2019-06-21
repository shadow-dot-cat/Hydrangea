package Hydrangea::Supervisor;

use Hydrangea::Class;
use Future::Utils qw(repeat);
use List::Utils qw(min);

ro backoff_plan => (default => sub { [ 30, 60, 300, 600, 1800, 3600 ] });

rwp backoff_index => (
  lazy => 1, default => 0, clearer => 'reset_backoff_index'
);

sub next_backoff_index ($self) {
  min(
    $self->backoff_index, $#{$self->backoff_plan}
  )->$_tap($self->curry::_set_backoff_index);
}

sub next_backoff_value ($self) {
  $self->backoff_plan->[$self->next_backoff_index];
}

ro 'service';

sub desired_state ($self) {
  return $self->supervising_f ? 'up' : 'down'
}

sub current_state ($self) {
  return 'starting' if $self->starting_f;
  return 'stopping' if $self->stopping_f;
  return 'up' if $self->running_f;
  return 'down';
}

rwp last_error => (default => '');

rwp [ qw(starting_f running_f stopping_f) ] => (
  default => undef,
  clearer => 1,
  trigger => 1,
);

lazy 'supervising_f' => (clearer => 1);

sub _trigger_starting_f ($self, $f) {
  $f->on_ready($self->curry::weak::clear_starting_f);
  $f->on_done($self->curry::weak::_set_running_f);
}

sub wrap ($class, $service, @rest) {
  $class->new(service => $service, @rest);
}

sub once ($self) {
  return Future->done($self->running_f) if $self->running_f;
  $self->starting_f || $self->_set_starting_f($self->service->start);
}

sub stop ($self) {
  return Future->done unless $self->running_f;
  $self->stopping_f || $self->_set_stopping_f($self->service->stop);
}

sub up ($self) {
  $self->supervising_f;
  return;
}

sub cancel_supervising_f ($self) {
  $_->cancel for grep defined(), $self->clear_supervising_f;
  return;
}

sub down ($self) {
  $self->cancel_supervising_f;
  return unless $self->running_f; # starting_f, unsure atm, must revisit XXX
  $self->stop;
  return;
}

sub _build_supervising_f ($self) {
  weaken($self);
  my $repeat = repeat {
    my $f = (
      $self->running_f
      || $self->start
              ->then(sub ($run) {
                  $self->reset_backoff_value;
                  $run;
                })
    );
    $f->else(
      Future->new->$_tap(sub ($wait_f) {
        $Loop->watch_time(
          after => $self->next_backoff_value,
          code => $wait_f->curry::done;
        );
      })
    );
  } while => sub { 1 }; # it's 2019, we never admit failure, we get cancelled
  return $repeat;
}

1;
