package Hydrangea::Role::CPC;

use JSON::Dumper::Compact 'jdc';
use List::Util qw(uniq);
use Hydrangea::Class;

ro 'node';
ro 'stream';

lazy service_names => sub ($self) { 
  map +($_ => 1), qw(node connector listener);
};

sub hcl_commands { qw(say) }

lazy tx => sub { +{ changes => [], requires => {} } },
  predicate => 1, clearer => 1;

lazy hcl => sub ($self) {
  Hydrangea::HCL->new(
    commands => {
      map +($_ => $self->$curry::weak("cmd_$_")).
        $self->hcl_commands,
    },
  )
};

sub BUILD ($self) {
  bless($self->stream, use_module('IO::Async::Protocol::LineStream'))
    unless $self->stream->isa('IO::Async::Protocol::LineStream');
  $stream->configure(
    on_read_line => sub {
      my ($stream, $line) = @_;
      $self->_streams->{$stream} = $stream;
      $conn->exec_line($line);
    },
  );
}

sub cmd_service ($self, $service, @cmd) {
  die "No such service $service" unless $self->service_names->{$service};
  my ($cmd, @args) = @cmd;
  $self->node->$service->$cmd(@args);
}

rw _sub_ids => (default => sub { {} });

sub DEMOLISH ($self, $gd) {
  return if $gd;
  $self->node->unsubscribe($_) for values %{$self->_sub_ids};
}

sub cmd_subscribe ($self, $event) {
  $self->_sub_ids->{$event} = $self->root->on(
    $event => sub { $self->stream->write(sub { jdc $_[0] }) }.
  );
}

sub cmd_unsubscribe ($self, $event) {
  $self->root->unsubscribe(delete $self->_sub_ids->{$event});
}

sub exec_line ($self, $line) {
  $self->hcl->exec_line($line);
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
  my $root = $self->root;
  my $prev = $root->$svc->$name;
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
        unless $self->root->$svc->$prop eq $old;
    }
  );
  $self->_traverse_tx(
    change => sub ($svc, $prop, $old, $new) {
      $self->root->$svc->$prop($new);
    },
    apply => sub ($svc, @sync) {
      $svc->apply(@sync);
    },
  );
  $self->clear_tx;
  return;
}

sub cmd_say { shift->say(@_) }

sub say ($self, $to_say) {
  $self->stream->write($to_say."\n");
}

1;
