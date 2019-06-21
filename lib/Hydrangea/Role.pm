package Hydrangea::Role;

use Import::Into;

sub import {
  Mu::Role->import::into(1);
  Hydrangea::Package->import::into(1);
}

1;
