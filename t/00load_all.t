use strictures 2;
use Test::More;
use IO::All;

foreach my $file (io('lib')->all_files(0)) {
  (my $name = $file->name) =~ s/^lib\///;
  ok(eval { require $name; 1 }, "${file} loaded ok");
  warn $@ if $@;
}

done_testing;
