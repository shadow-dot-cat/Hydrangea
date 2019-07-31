package Hydrangea::MojoFutureDo;

use strictures 2;
use experimental 'signatures';
use Future;
use Mojo::Promise::Role::Futurify;
use Exporter 'import';

our @EXPORT = qw($_do);

our $_do = sub ($self, $method, @args) {
  if (my $p = $self->can("${method}_p")) {
    return $p->Mojo::Promise::Role::Futurify::futurify;
  }
  my $f = Future::Mojo->new;
  $self->$method(@args, sub {
    my (undef, $err, @result) = @_;
    unless ($err) {
      $f->done(@result);
    } else {
      $f->fail($err);
    }
    return
  });
  return $f;
};

1;
