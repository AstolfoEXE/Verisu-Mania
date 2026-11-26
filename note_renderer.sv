module note_renderer
    import pulse4_pkg::*;
(
    input  logic               de,
    input  logic [9:0]         sx,
    input  logic [9:0]         sy,
    input  logic               note_visible,
    input  logic [1:0]         note_lane,
    input  logic signed [10:0] note_y,

    output logic               note_on,
    output logic [11:0]        note_rgb
);
    logic signed [11:0] y_c, y_top, y_bot, sy_s;
    logic [9:0]         x_start, x_end;
    logic               in_x, in_y;

    always_comb begin
        y_c   = note_y;                       // sign-extends
        y_top = y_c - NOTE_H/2;
        y_bot = y_top + NOTE_H;
        sy_s  = {2'b00, sy};

        x_start = FIELD_X + note_lane*LANE_W + NOTE_PAD;
        x_end   = x_start + LANE_W - 2*NOTE_PAD;

        in_x = (sx >= x_start) && (sx < x_end);
        in_y = (sy_s >= y_top) && (sy_s < y_bot);

        note_on = de && note_visible && in_x && in_y;

        case (note_lane)
            2'd0:    note_rgb = 12'h5DF;
            2'd1:    note_rgb = 12'hB8F;
            2'd2:    note_rgb = 12'hF96;
            default: note_rgb = 12'h7EA;
        endcase
    end
endmodule