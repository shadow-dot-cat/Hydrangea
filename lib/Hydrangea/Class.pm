package Hydrangea::Class;

use Import::Into;
use curry ();

sub import {
  Mu->import(1);
  Hydrangea::Loop->import(1);
  Object::Tap->import(1);
  Safe::Isa->import(1);
  Scalar::Util->import(1, 'weaken');
  Module::Runtime->import(1, 'use_module');
  experimental->import('signatures');
}

1;
