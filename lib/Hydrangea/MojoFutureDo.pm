package Hydrangea::MojoFutureDo;

use strictures 2;
use experimental 'signatures';
use Future::Mojo;
use Mojo::Promise::Role::Futurify;
use Exporter 'import';

our @EXPORT = qw($_do $_once);

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

our $_once = sub ($self, $name) {
  (grep $self->once($name => $_->done_cb), Future::Mojo->new)[0]
};

1;
