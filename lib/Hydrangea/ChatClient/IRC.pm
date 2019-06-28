package Hydrangea::ChatClient::IRC;

use Net::Async::IRC;
use Types::Standard qw(Dict Str Int ArrayRef Optional);

use Type::Utils qw(subtype as coerce from via);

my $_channels = (ArrayRef[Str])->plus_coercions(
                  Str, sub { [ split(/[, ]+/, $_[0]) ] }
                );

use Hydrangea::Class;

sub config_spec {
  +{
    nick => { type => Str, requires => 'sync' },
    server => { type => Str, requires => 'restart' },
    port => { type => Int, requires => 'restart' },
    channels => { type => $_channels, requires => 'sync' },
  }
}

with 'Role::EventEmitter';

rw nick => (isa => Str);
rw server => (isa => Str);
rw port => (isa => Int, default => 6667);
rw channels => (
  isa => $_channels,
  coerce => 1,
  default => sub { [] },
);

sub apply ($self, @things) {
  my %things = map +($_ => 1), @things;
  if ($things{restart}) {
    return $self->stop->then(sub { $self->start })
  }
  if ($things{sync}) {
    $self->sync;
  }
}

lazy irc => sub ($self) {
  loop_add(
    Net::Async::IRC->new(
      nick => $self->nick,
      on_message_text => $self->curry::weak::receive_message,
      on_closed => $self->curry::weak::closed,
    )
  );
}, (clearer => 1);

sub DEMOLISH ($self, $gd) {
  return if $gd;
  loop_remove($self->irc)
}

sub closed ($self, @) { $self->clear_run_f->fail("closed") }

lazy run_f => sub { Future->new }, clearer => 1;

sub start ($self) {
  my $run_f = $self->run_f;
  log info => "Starting IRC root";
  $self->irc
       ->login(host => $self->server, service => $self->port)
       ->on_done($self->curry::weak::sync)
       ->then(sub {
           log info => "IRC root up";
           Future->done($run_f);
         }, sub ($error) {
           log error => "IRC root start failed: $error";
           Future->fail($error);
         });
}

sub stop ($self) {
  $self->clear_irc->$_loop_remove->close;
  $self->clear_run_f->done;
  Future->done;
}

sub sync ($self, @) {
  # if not on preferred nick, attempt to change nick
  # send join messages for all configured channels
}

sub receive_message ($self, $, $message, $hints) {
  return if $hints->{is_notice}; # for the moment
  my @msg = (
    {
       venue => $hints->{target_name},
       nick => $hints->{prefix_nick},
       user => $self->infer_user_from($hints),
    },
    {
    }
  );
  $self->emit(receive_message => @msg);
}

1;
