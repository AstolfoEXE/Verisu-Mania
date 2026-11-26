module keyboard_input (
    input  logic       clk,        // 100 MHz
    input  logic       rst,
    input  logic       ps2_clk,
    input  logic       ps2_data,

    output logic [3:0] lane_down,
    output logic [3:0] lane_press,
    output logic       enter_down,
    output logic       enter_press,
    output logic       rx_error
);
    logic [7:0] rx_data;
    logic       rx_valid;
    logic       ev_valid, ev_ext, ev_break;
    logic [7:0] ev_code;

    ps2_receiver rx (
        .clk(clk), .rst(rst),
        .ps2_clk(ps2_clk), .ps2_data(ps2_data),
        .data(rx_data), .valid(rx_valid), .error(rx_error)
    );

    scan_decoder dec (
        .clk(clk), .rst(rst),
        .data(rx_data), .valid(rx_valid),
        .ev_valid(ev_valid), .ev_code(ev_code),
        .ev_ext(ev_ext), .ev_break(ev_break)
    );

    key_tracker trk (
        .clk(clk), .rst(rst | rx_error),   // clear held keys on a bad frame
        .ev_valid(ev_valid), .ev_code(ev_code),
        .ev_ext(ev_ext), .ev_break(ev_break),
        .lane_down(lane_down), .lane_press(lane_press),
        .enter_down(enter_down), .enter_press(enter_press)
    );
endmodule