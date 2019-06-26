package Hydrangea::Root::ControlPort::Connection;

use JSON::Dumper::Compact 'jdc';
use List::Util qw(uniq);
use Hydrangea::Class;

with 'Hydrangea::Role::CPC';

ro 'node';

lazy tx => sub { +{ changes => [], requires => {} } },
  predicate => 1, clearer => 1;

around hcl_commands => sub ($orig, $self, @) {
  ($self->$orig, qw(config subscribe unsubscribe service))
}

sub cmd_service ($self, $service, @cmd) {
  die "No such service ${service}" unless $self->node->has_service($service);
  my ($cmd, @args) = @cmd;
  $self->node->$service->$cmd(@args);
}

rw _sub_ids => (default => sub { {} });

sub DEMOLISH ($self, $gd) {
  return if $gd;
  $self->node->unsubscribe($_) for values %{$self->_sub_ids};
}

sub cmd_subscribe ($self, $event) {
  $self->_sub_ids->{$event} = $self->node->on(
    $event => sub { $self->stream->write(sub { jdc $_[0] }) }.
  );
}

sub cmd_unsubscribe ($self, $event) {
  $self->node->unsubscribe(delete $self->_sub_ids->{$event});
}

sub cmd_config ($self, @config) {
  if (my $meth = $self->can("${\"_cmd_config_$config[0]"}")) {
    shift @config;
    return $self->$meth(@config);
  }
  my ($svc, $name, $value) = @config;
  my $existing = $self->config;
  my $cfg_spec = $self->config_spec;
  my $this_spec = $cfg_spec->{$svc}{$name};
  die "No such attribute ${svc}.${name}\n" unless $this_config;
  if (defined(my $err = $this_spec->{isa}->validate($value))) {
    die "Config value ${svc}.${name} invalid: ${err}";
  }
  my $node = $self->root;
  my $prev = $node->$svc->$name;
  push(
    @{$self->tx->{changes}},
    [ $svc, $name, $prev, $value, $this_spec ],
  );
  return;
}

sub _cmd_config_tx ($self, $cmd = 'status', @args) {
  $self->${\"_cmd_config_tx_${cmd}"}(@args);
}

sub _cmd_config_tx_begin ($self) {
  die "Sir, we already began once, to begin twice would be to beg strife\n"
    if $self->has_tx;
  $self->tx;
  return;
}

sub _cmd_config_tx_rollback ($self) {
  $self->clear_tx;
  return;
}

sub _traverse_tx ($self, %cb) {
  die "There ain't no tx, son\n" unless my $tx = $self->has_tx;
  my @changes = @{$self->tx->{changes}};
  my %sync;
  foreach my $c (@changes) {
    my ($svc, $prop, $old, $new, $spec) = @$c;
    $cb{change}($svc, $prop, $old, $new);
    $sync{$svc}{$spec->{requires}} = 1;
  }
  foreach my $set (sort keys %sync) {
    $cb{apply}($set => [ sort keys %{$sync{$set}||{}} ]);
  }
}

sub _cmd_config_tx_diff ($self) {
  return '' unless $self->has_tx;
  $self->_traverse_tx(
    change => sub ($svc, $prop, $old, $new) {
      $self->say("-${svc}.${prop} = $old");
      $self->say("+${svc}.${prop} = $new");
    },
  );
}

sub _cmd_config_tx_actions ($self) {
  return '' unless $self->has_tx;
  $self->_traverse_tx(
    change => sub ($svc, $prop, $old, $new) {
      $self->say("${svc}.${prop} = change(${old} => ${new})");
    },
    apply => sub ($svc, @sync) {
      $self->say("apply $svc ".join(' ', sort uniq @sync));
    },
  );
}

sub _cmd_config_tx_commit ($self) {
  $self->_traverse_tx(
    change => sub ($svc, $prop, $old, $new) {
      die "Concurrency error; bailing out\n"
        unless $self->node->$svc->$prop eq $old;
    }
  );
  $self->_traverse_tx(
    change => sub ($svc, $prop, $old, $new) {
      $self->node->$svc->$prop($new);
    },
    apply => sub ($svc, @sync) {
      $svc->apply(@sync);
    },
  );
  $self->clear_tx;
  return;
}

sub say ($self, $to_say) {
  $self->stream->write($to_say."\n");
}

1;
