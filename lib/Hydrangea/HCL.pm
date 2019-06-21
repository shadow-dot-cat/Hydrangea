package Hydrangea::HCL;

use Hydrangea::Class;

ro 'commands';

sub exec_line ($self, $line) {
  my ($cmd, @args) = map $_->[1], $self->parse($line);
  $self->commands->{$cmd}(@args);
}

sub parse ($self, $line) {
  my @split = split ' ', $line;
  my @parsed = map [ do {
    if (/^[a-zA-Z_]\w+$/) { 'word' }
    elsif (/^[0-9]+$/) { 'int' }
    elsif (/^(?:\d*\.\d+|\d+\.)(?:e-?\d+)?|-?\d+e-?\d+$/) { 'float' }
    elsif (/^[^ '"\{\[\(]\s+$/) { 'symbol' }
    else { die "WHUT" }
  }, $_ ], @split;
}

1;
