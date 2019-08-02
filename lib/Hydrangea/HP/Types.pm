package Hydrange::HP::Types;

use Hydrangea::Package;
use Type::Library -base, -declare => 'JBool';
use Types::Standard -types;
use Type::Utils -all;

BEGIN {
  no warnings 'redefine';
  my $tuple = __PACKAGE__->can('Tuple');
  *Tuple = sub :prototype(;$) {
    $tuple->([ map +(ref($_) ? $_ : Enum[$_]), @$_ ]);
  }
}

declare JBool, as (InstanceOf['JSON::PP::Boolean'] | ScalarRef[Bool]);

declare Client_Protocol_Offer => as Tuple[
  protocol_offer => hydrangea => Num
];

declare Trunk_Protocol_Accept => as Tuple[
  protocol_accept => hydrangea => Num
];

declare Client_Ident_Assert => as Tuple[
  ident_assert => Str, Str
];

declare Trunk_Ident_Confirm => as Tuple[
  ident_confirm => Str
];

declare Client_Message_From => as Tuple[
  message_from
    => Dict[ venue => Optional[Str], nick => Str, user => Optional[Str] ]
    => Dict[ raw_text => Str, text => Str, is_to_me => JBool ]
];

declare Trunk_Message_To => as Tuple[
  message_to
    => Dict[ venue => Optional[Str], nick => Str ]
    => Str
];

declare Client_Command_Register => as Tuple[ command_register => Str ];

declare Trunk_Command_Start => as Tuple[
  command_start => Str, Str, Dict[ raw => Str, args => ArrayRef ]
];

declare Trunk_Command_Send => as Tuple[
  command_send => Str, Str
];

declare Trunk_Command_Cancel => as Tuple[
  command_cancel => Str
];

declare Client_Command_Sent => as Tuple[
  command_sent => Str, Str
];

declare Client_Command_Done => as Tuple[
  command_done => Str, Optional[Str]
];

declare Client_Command_Failed => as Tuple[
  command_failed => Str, Str
];

1;
