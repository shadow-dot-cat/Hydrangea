package Hydrangea::Root::ControlPort::Connection;

use JSON::Dumper::Compact 'jdc';
use List::Util qw(uniq);
use Hydrangea::Class;

with 'Hydrangea::Role::CPC';

ro 'node';

lazy tx => sub { +{ changes => [], requires => {} } },
  predicate => 1, clearer => 1;

around hcl_commands => sub ($orig, $self, @) {
  ($self->$orig, qw(config subscribe unsubscribe service send))
};

sub cmd_service ($self, $service, @cmd) {
  unless ($self->node->has_service($service)) {
    $self->say("Invalid service name ${service}");
    return;
  }
  my ($cmd, @args) = @cmd;
  unless ($cmd =~ /^(?:supervise|once|stop|restart)$/) {
    $self->say("Invalid command ${cmd} for service ${service}");
    return;
  }
  $cmd = 'start_once' if $cmd eq 'once';
  $self->node->supervisors->{$service}->$cmd(@args);
}

rw _sub_ids => (default => sub { {} });

sub DEMOLISH ($self, $gd) {
  return if $gd;
  $self->node->unsubscribe($_) for values %{$self->_sub_ids};
}

sub cmd_subscribe ($self, $event) {
  $self->_sub_ids->{$event} = $self->node->on(
    $event => sub { shift; $self->say(jdc(\@_)) },
  );
  return;
}

sub cmd_unsubscribe ($self, $event) {
  $self->node->unsubscribe(delete $self->_sub_ids->{$event});
}

sub cmd_config ($self, @config) {
  unless (@config) {
    $self->say("config [service] ([name] [value]?)?");
    return;
  }
  if (my $meth = $self->can("_cmd_config_$config[0]")) {
    shift @config;
    return $self->$meth(@config);
  }
  my ($svc, $name, @rest) = @config;
  my $existing = $self->node->config->{$svc};
  my $service = $self->node->service($svc);
  my $svc_cfg = $service->config_spec;
  unless ($name) {
    $self->say("${svc} $_ ".$service->$_) for sort keys %{$svc_cfg};
    return;
  }
  my $cfg_spec = $svc_cfg->{$name};
  unless ($cfg_spec) {
    $self->say("Config name ${svc}.${name} invalid");
    return;
  }
  unless (@rest) {
    $self->say("${svc} ${name} ".$service->$name);
    return;
  }
  unless ($self->has_tx) {
    $self->say("Config is read only outside a transaction");
    return;
  }
  my ($value) = @rest;
  if (defined(my $err = $cfg_spec->{type}->validate($value))) {
    $self->say("Config value ${svc}.${name} invalid: ${err}");
    return;
  }
  my $prev = $service->$name;
  push(
    @{$self->tx->{changes}},
    [ $svc, $name, $prev, $value, $cfg_spec ],
  );
  return;
}

sub _cmd_config_save ($self) {
  $self->node->save_config;
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
  return unless $cb{apply};
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
        unless $self->node->service($svc)->$prop eq $old;
    }
  );
  $self->_traverse_tx(
    change => sub ($svc, $prop, $old, $new) {
      $self->node->service($svc)->$prop($new);
      $self->node->config->{$svc}{$prop} = $new;
    },
    apply => sub ($svc, @sync) {
      $self->node->service($svc)->apply(@sync);
    },
  );
  $self->clear_tx;
  return;
}

sub say ($self, $to_say) {
  ($to_say = $to_say."\n") =~ s/\n\n\Z/\n/;
  $self->stream->write($to_say);
}

sub cmd_send ($self, $to, $msg) {
  $self->node->send_message($to, $msg);
}

1;
