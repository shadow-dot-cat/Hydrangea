package Hydrangea::Loop;

use strictures 2;
use IO::Async::Loop;
use Exporter 'import';

our @EXPORT = qw(*Loop $_loop_add $_loop_remove loop_add loop_remove);
our @EXPORT_OK = qw(set_loop with_loop);

our $Loop = IO::Async::Loop->new;

sub set_loop {
  $Loop = $_[0];
}

sub with_loop (&$) {
  local $Loop = $_[1];
  $_[0]->();
}

my $_loop_add = sub { $Loop->add($_[0]); $_[0] };

my $_loop_remove = sub { $Loop->remove($_[0]); $_[0] };

sub loop_add { $Loop->add($_[0]); $_[0] }

sub loop_remove { $Loop->remove($_[0]); $_[0] }

1;
