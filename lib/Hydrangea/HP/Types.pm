package Hydrange::HP::Types;

use Hydrangea::Package;
use Type::Library -base;
use Types::Standard -types;
use Type::Utils -all;

declare JBool => InstanceOf['JSON::PP::Boolean'] | ScalarRef[Bool];

declare Client_Protocol_Offer => Tuple[
  protocol_offer => hydrangea => Num
];

declare Trunk_Protocol_Accept => Tuple[
  protocol_accept => hydrangea => Num
];

declare Client_Message_From => Tuple[
  message_from
    => Dict[ venue => Optional[Str], nick => Str, user => Optional[Str] ]
    => Dict[ raw_text => Str, text => Str, is_to_me => JBool ]
];

declare Trunk_Message_To => Tuple[
  message_to
    => Dict[ venue => Optional[Str], nick => Str ]
    => Str

;

declare Client_Command_Register => Tuple[ command_register => Str ];

declare Trunk_Command_Start => Tuple[
  command_start => Str, Str, Dict[ raw => Str, args => ArrayRef ]
];

declare Trunk_Command_Send => Tuple[
  command_send => Str, Str
];

declare Trunk_Command_Cancel => Tuple[
  command_cancel => Str
];

declare Client_Command_Sent => Tuple[
  command_sent => Str, Str
];

declare Client_Command_Done => Tuple[
  command_done => Str, Optional[Str]
];

declare Client_Command_Failed => Tuple[
  command_failed => Str, Str
];

1;
