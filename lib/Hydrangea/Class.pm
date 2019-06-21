package Hydrangea::Class;

use Import::Into;
use curry ();

sub import {
  Mu->import::into(1);
  Hydrangea::Loop->import::into(1);
  Object::Tap->import::into(1);
  Safe::Isa->import::into(1);
  Scalar::Util->import::into(1, 'weaken');
  Module::Runtime->import::into(1, 'use_module');
  experimental->import::into(1, 'signatures');
}

1;
