package Hydrangea::Package;

use Import::Into;
use curry ();

sub import {
  Hydrangea::Loop->import::into(1);
  Hydrangea::Log->import::into(1);
  Object::Tap->import::into(1);
  Safe::Isa->import::into(1);
  Scalar::Util->import::into(1, 'weaken');
  Module::Runtime->import::into(1, 'use_module');
  strictures->import(1, { version => 2 });
  experimental->import::into(1, 'signatures');
}

1;
