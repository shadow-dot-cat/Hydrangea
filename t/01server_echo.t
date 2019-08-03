use strictures 2;
use Test::More;
use Test::Mojo;
use Hydrangea::Utils qw(hash_pw);
use Hydrangea::HP;

my $my_hash = hash_pw(my $my_pw = 'scatterbrain');

my $far_hash = hash_pw(my $far_pw = 'plebiscite');

my $t = Test::Mojo->new(
  'Hydrangea::Trunk::Server',
  { known_nodes => {
    (my $node_name = '01server_echo')
      => { far_hash => $my_hash, my_pw => $far_pw }
  } },
);

$t->app->log->level('debug');

$t->websocket_ok('/api/echo')
  ->send_ok({ json => [ protocol_offer => hydrangea => $HP_VERSION ] })
  ->message_ok
  ->json_message_is([ protocol_accept => hydrangea => $HP_VERSION ])
  ->send_ok({ json => [ ident_assert => $node_name, $my_pw ] })
  ->message_ok
  ->json_message_is([ ident_confirm => $far_pw ])
  ->send_ok({ json => [
      message_from => { nick => 'mst' },
      { raw_text => 'argh', text => 'argh', is_to_me => \1 }
    ] })
  ->message_ok
  ->json_message_is([
      message_to => { nick => 'mst' }, { text => 'argh', is_address => 1 }
    ]);

done_testing;
