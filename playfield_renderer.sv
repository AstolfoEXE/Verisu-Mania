module playfield_renderer #(
    parameter int FIELD_X   = pulse4_pkg::FIELD_X,
    parameter int LANE_W    = pulse4_pkg::LANE_W,
    parameter int HIT_Y     = pulse4_pkg::HIT_Y,
    parameter int HIT_H     = pulse4_pkg::HIT_H,
    parameter int RECEP_Y   = 412,
    parameter int RECEP_H   = 48,
    parameter int RECEP_PAD = 6,
    parameter int SEP_W     = 2
) (
    input  logic       de,
    input  logic [9:0] sx,
    input  logic [9:0] sy,
    input  logic [3:0] lane_down,

    output logic [3:0] red,
    output logic [3:0] green,
    output logic [3:0] blue
);
    localparam int FIELD_END = FIELD_X + 4*LANE_W;

    logic       in_field, on_sep, on_hit, on_recep;
    logic [1:0] lane;
    logic [9:0] lane_x;       // x offset inside the current lane
    logic [11:0] lane_color;  // {R,G,B}, 4 bits each
    logic [11:0] rgb;

    // Which lane, and where inside it
    always_comb begin
        in_field = (sx >= FIELD_X) && (sx < FIELD_END);

        lane = 2'd0;
        if      (sx >= FIELD_X + 3*LANE_W) lane = 2'd3;
        else if (sx >= FIELD_X + 2*LANE_W) lane = 2'd2;
        else if (sx >= FIELD_X +   LANE_W) lane = 2'd1;

        lane_x = sx - (FIELD_X + lane*LANE_W);
    end

    // Shape tests
    always_comb begin
        on_sep   = in_field && ((lane_x < SEP_W) || (sx >= FIELD_END - SEP_W)); //late separator
        on_hit   = in_field && (sy >= HIT_Y)   && (sy < HIT_Y + HIT_H); //white horizontal bar thingy
        on_recep = in_field && (sy >= RECEP_Y) && (sy < RECEP_Y + RECEP_H)
                   && (lane_x >= RECEP_PAD) && (lane_x < LANE_W - RECEP_PAD); //color recyangles
    end

    // Receptor color: bright when held, dim otherwise
    always_comb begin
        case (lane)
            2'd0: lane_color = lane_down[0] ? 12'h5DF : 12'h267;  // cyan
            2'd1: lane_color = lane_down[1] ? 12'hB8F : 12'h548;  // purple
            2'd2: lane_color = lane_down[2] ? 12'hF96 : 12'h853;  // orange
            2'd3: lane_color = lane_down[3] ? 12'h7EA : 12'h375;  // green
        endcase
    end

    // Priority: hit line > receptor > separator > field > background
    always_comb begin
        if      (!de)      rgb = 12'h000;
        else if (on_hit)   rgb = 12'hFFF;
        else if (on_recep) rgb = lane_color;
        else if (on_sep)   rgb = 12'h667;
        else if (in_field) rgb = 12'h012;
        else               rgb = 12'h123;
    end

    assign {red, green, blue} = rgb;
endmodule