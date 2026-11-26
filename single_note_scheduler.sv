module single_note_scheduler
    import pulse4_pkg::*;
#(
    parameter int NOTE_TIME_MS = 3000,
    parameter int NOTE_LANE    = 0,
    parameter int APPROACH_MS  = 2000,
    parameter int TAIL_MS      = 300     // keep drawing after the target time
) (
    input  logic               clk,
    input  logic signed [31:0] song_time_ms,

    output logic               note_visible,
    output logic [1:0]         note_lane,
    output logic signed [10:0] note_y      // note center, can be negative
);
    localparam int TRAVEL = HIT_C + NOTE_H/2;                 // spawn center = -NOTE_H/2
    localparam int SPEED  = (TRAVEL*65536 + APPROACH_MS/2) / APPROACH_MS;  // Q16 px/ms

    logic signed [31:0] dt_full;
    logic signed [12:0] dt;
    logic signed [31:0] prod;
    logic               in_window;

    always_comb begin
        dt_full   = NOTE_TIME_MS - song_time_ms;
        in_window = (dt_full <= APPROACH_MS) && (dt_full >= -TAIL_MS);
        dt        = dt_full[12:0];            // only used when in_window
        prod      = dt * SPEED;
    end

    always_ff @(posedge clk) begin
        note_visible <= in_window;
        note_lane    <= NOTE_LANE[1:0];
        note_y       <= 11'(HIT_C - (prod >>> 16));
    end
endmodule