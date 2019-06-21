package Hyndrangea::Log;

use Exporter 'import';
use Hydrangea::Package;

our @EXPORT = qw(log);

sub log ($level, @log) {
  warn "[${level}] @{log}\n";
}

1;
