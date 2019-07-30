package Hydrange::HP::Far::CommandInvocation;

use Hydrangea::Class;

ro 'tx_id';
ro parent => (weak_ref => 1);

with 'Role::EventEmitter';

sub _parent_call ($self, $call, @args) {
  $self->parent->${\"_command_${call}"}($self->tx_id, @args);
}

sub send ($self, $send) { $self->_parent_call(send => $send) }
sub cancel ($self) { $self->_parent_call('cancel') }

sub _sent { shift->emit(sent => @_) }
sub _done { shift->emit(done => @_) }
sub _fail { shift->emit(fail => @_) }

1;
