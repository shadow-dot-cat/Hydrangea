package Hydrangea::Log;

use Hydrangea::Package;
use Exporter 'import';

our @EXPORT = qw(log);

sub log ($level, @log) {
  (my $str = "[${level}] @{log}\n") =~ s/\n\n$/\n/sm;
  warn $str;
}

1;
