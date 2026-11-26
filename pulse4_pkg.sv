package pulse4_pkg;
    localparam int FIELD_X  = 160;
    localparam int LANE_W   = 80;
    localparam int HIT_Y    = 400;
    localparam int HIT_H    = 4;
    localparam int HIT_C    = HIT_Y + HIT_H/2;   // 402: note center at target time
    localparam int NOTE_H   = 16;
    localparam int NOTE_PAD = 6;                 // horizontal inset inside a lane
endpackage