module song_timer #(
    parameter int CLK_HZ       = 100_000_000,
    parameter int CLKS_PER_MS  = CLK_HZ / 1000,   // override in simulation
    parameter int PREROLL_MS   = 3000
) (
    input  logic               clk,
    input  logic               reset,      // synchronous, clears everything
    input  logic               start,      // one-clock pulse: restart timeline
    input  logic               running,    // level: counts only while high

    output logic               tick_ms,    // one-clock pulse per millisecond
    output logic               song_zero,  // one-clock pulse when time reaches 0
    output logic signed [31:0] song_time_ms
);
    localparam int DIV_W = (CLKS_PER_MS > 1) ? $clog2(CLKS_PER_MS) : 1;
    localparam logic signed [31:0] T0 = -PREROLL_MS;

    logic [DIV_W-1:0] div_cnt;

    always_ff @(posedge clk) begin
        tick_ms   <= 1'b0;
        song_zero <= 1'b0;

        if (reset) begin
            div_cnt      <= '0;
            song_time_ms <= T0;
        end else if (start) begin
            div_cnt      <= '0;
            song_time_ms <= T0;
            song_zero    <= (PREROLL_MS == 0);
        end else if (running) begin
            if (div_cnt == DIV_W'(CLKS_PER_MS - 1)) begin
                div_cnt      <= '0;
                tick_ms      <= 1'b1;
                song_time_ms <= song_time_ms + 32'sd1;
                song_zero    <= (song_time_ms == -32'sd1);   // next value is 0
            end else begin
                div_cnt <= div_cnt + 1'b1;
            end
        end
    end
endmodule