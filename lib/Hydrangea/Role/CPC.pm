package Hydrangea::Role::CPC;

use JSON::Dumper::Compact 'jdc';
use List::Util qw(uniq);
use Hydrangea::HCL;
use Hydrangea::Role;

ro 'stream';

with 'Role::EventEmitter';

sub hcl_commands { qw(say) }

lazy tx => sub { +{ changes => [], requires => {} } },
  predicate => 1, clearer => 1;

lazy hcl => sub ($self) {
  Hydrangea::HCL->new(
    commands => {
      map +($_ => $self->$curry::weak("cmd_$_")),
        $self->hcl_commands
    },
  )
};

sub BUILD ($self, $) {
  my $stream = $self->stream;
  log debug => 'Control port connection start';
  $stream->configure(
    on_read_line => sub {
      my ($stream, $line) = @_;
      log debug => 'Control port exec line: '.$line;
      unless (eval { $self->exec_line($line); 1 }) {
        log error => $@;
      }
    },
  );
  loop_add $stream;
}

sub exec_line ($self, $line) {
  $self->hcl->exec_line($line);
}

sub cmd_say { shift->say(@_) }

sub say ($self, $to_say) {
  $self->stream->write($to_say."\n");
}

1;
