use strictures 2;
use Test::More;
use Test::Mojo;
use Hydrangea::Utils qw(hash_pw);
use Hydrangea::HP;

BEGIN {
  package StreamRole;

  use Role::Tiny;
  use experimental 'signatures';

  use overload
    '<<' => '_stream_in',
    '>>' => '_stream_out',
    fallback => 1;

  sub _stream_out ($self, $other, @) {
    die "WTAF" unless ref($other) eq 'ARRAY';
    $self->send_ok({ json => $other });
  }

  sub _stream_in ($self, $other, @) {
    die "WTAF" unless ref($other) eq 'ARRAY';
    $self->message_ok
         ->json_message_is($other);
  }
}

my $my_hash = hash_pw(my $my_pw = 'scatterbrain');

my $far_hash = hash_pw(my $far_pw = 'plebiscite');

my $t = Test::Mojo->new(
  'Hydrangea::Trunk::Server',
  { known_nodes => {
    (my $node_name = '01server_echo')
      => { far_hash => $my_hash, my_pw => $far_pw }
  } },
)->with_roles('StreamRole');

$t->app->log->level('debug');

no warnings 'void';

$t->websocket_ok('/api/echo')
  >> [ protocol_offer => hydrangea => $HP_VERSION ]
  << [ protocol_accept => hydrangea => $HP_VERSION ]
  >> [ ident_assert => $node_name, $my_pw ]
  << [ ident_confirm => $far_pw ]
  >> [ message_from => { nick => 'mst' },
       { raw_text => 'argh', text => 'argh', is_to_me => \1 } ]
  << [ message_to => { nick => 'mst' }, { text => 'argh', is_address => 1 } ];

done_testing;
