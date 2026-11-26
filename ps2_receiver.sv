module ps2_receiver #(
    parameter int TIMEOUT_CLKS = 100_000   // 1 ms at 100 MHz
) (
    input  logic       clk,
    input  logic       rst,
    input  logic       ps2_clk,
    input  logic       ps2_data,
    output logic [7:0] data,
    output logic       valid,   // one-clock pulse per good byte
    output logic       error    // one-clock pulse on bad frame
);
    logic [2:0]  c_sync;
    logic [1:0]  d_sync;
    logic [10:0] sh, nsh;
    logic [3:0]  bitcnt;
    logic [16:0] idle_cnt;

    always_ff @(posedge clk) begin
        c_sync <= {c_sync[1:0], ps2_clk};
        d_sync <= {d_sync[0],  ps2_data};
    end

    wire fall = c_sync[2] && !c_sync[1];

    always_comb nsh = {d_sync[1], sh[10:1]};   // new bit enters at the top

    always_ff @(posedge clk) begin
        valid <= 1'b0;
        error <= 1'b0;

        if (rst) begin
            bitcnt   <= 4'd0;
            idle_cnt <= '0;
        end else if (fall) begin
            idle_cnt <= '0;
            sh       <= nsh;
            if (bitcnt == 4'd10) begin
                bitcnt <= 4'd0;
                // nsh[0]=start, nsh[8:1]=data, nsh[9]=parity, nsh[10]=stop
                if (!nsh[0] && nsh[10] && (^nsh[9:1])) begin
                    data  <= nsh[8:1];
                    valid <= 1'b1;
                end else begin
                    error <= 1'b1;
                end
            end else begin
                bitcnt <= bitcnt + 4'd1;
            end
        end else if (bitcnt != 0) begin
            if (idle_cnt == TIMEOUT_CLKS) begin   // abandoned frame
                bitcnt   <= 4'd0;
                idle_cnt <= '0;
                error    <= 1'b1;
            end else begin
                idle_cnt <= idle_cnt + 17'd1;
            end
        end
    end
endmodule