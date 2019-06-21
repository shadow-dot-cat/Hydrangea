package Hydrangea::Log;

use Hydrangea::Package;
use Exporter 'import';

our @EXPORT = qw(log);

sub log ($level, @log) {
  warn "[${level}] @{log}\n";
}

1;
