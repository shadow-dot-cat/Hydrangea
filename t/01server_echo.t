use strictures 2;
use Test::More;
use Test::Mojo;
use Hydrangea::HP;

my $t = Test::Mojo->new('Hydrangea::Trunk::Server');

$t->app->log->level('debug');

$t->websocket_ok('/api/echo')
  ->send_ok({ json => [ protocol_offer => hydrangea => $HP_VERSION ] })
  ->message_ok
  ->json_message_is([ protocol_accept => hydrangea => $HP_VERSION ]);

done_testing;
