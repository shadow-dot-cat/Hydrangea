package Hydrangea::Class;

use Import::Into;

sub import {
  Mu->import::into(1);
  Hydrangea::Package->import::into(1);
}

1;
