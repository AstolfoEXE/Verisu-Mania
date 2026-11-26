module scan_decoder (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] data,
    input  logic       valid,

    output logic       ev_valid,   // one-clock pulse
    output logic [7:0] ev_code,
    output logic       ev_ext,     // preceded by E0
    output logic       ev_break    // key release
);
    logic ext, brk;

    always_ff @(posedge clk) begin
        ev_valid <= 1'b0;
        if (rst) begin
            ext <= 1'b0;
            brk <= 1'b0;
        end else if (valid) begin
            case (data)
                8'hE0:   ext <= 1'b1;
                8'hF0:   brk <= 1'b1;
                default: begin
                    ev_valid <= 1'b1;
                    ev_code  <= data;
                    ev_ext   <= ext;
                    ev_break <= brk;
                    ext <= 1'b0;
                    brk <= 1'b0;
                end
            endcase
        end
    end
endmodule