module key_tracker (
    input  logic       clk,
    input  logic       rst,
    input  logic       ev_valid,
    input  logic [7:0] ev_code,
    input  logic       ev_ext,
    input  logic       ev_break,

    output logic [3:0] lane_down,
    output logic [3:0] lane_press,   // one-clock pulse on up -> down
    output logic       enter_down,
    output logic       enter_press
);
    logic [3:0] lane_hit;
    logic       enter_hit;

    always_comb begin
        lane_hit  = 4'b0000;
        enter_hit = 1'b0;
        if (ev_valid && !ev_ext) begin
            case (ev_code)
                8'h23: lane_hit[0] = 1'b1;   // D
                8'h2B: lane_hit[1] = 1'b1;   // F
                8'h3B: lane_hit[2] = 1'b1;   // J
                8'h42: lane_hit[3] = 1'b1;   // K
                8'h5A: enter_hit   = 1'b1;   // Enter (not keypad Enter)
                default: ;
            endcase
        end
    end

    always_ff @(posedge clk) begin
        lane_press  <= 4'b0000;
        enter_press <= 1'b0;
        if (rst) begin
            lane_down  <= 4'b0000;
            enter_down <= 1'b0;
        end else begin
            for (int i = 0; i < 4; i++) begin
                if (lane_hit[i]) begin
                    if (!ev_break) begin
                        if (!lane_down[i]) lane_press[i] <= 1'b1;
                        lane_down[i] <= 1'b1;
                    end else begin
                        lane_down[i] <= 1'b0;
                    end
                end
            end
            if (enter_hit) begin
                if (!ev_break) begin
                    if (!enter_down) enter_press <= 1'b1;
                    enter_down <= 1'b1;
                end else begin
                    enter_down <= 1'b0;
                end
            end
        end
    end
endmodule