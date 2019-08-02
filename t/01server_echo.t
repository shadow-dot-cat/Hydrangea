use strictures 2;
use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('Hydrangea::Trunk::Server');


$t->app->start('routes', '-v');

$t->app->log->level('debug');

$t->websocket_ok('/api/echo');

done_testing;
