module keyboard_test (
    input  logic        CLK100MHZ,
    input  logic        PS2_CLK,
    input  logic        PS2_DATA,
    input  logic        BTNC,
    output logic [15:0] LED
);
    logic [7:0] rx_data;
    logic       rx_valid, rx_error;
    logic       ev_valid, ev_ext, ev_break;
    logic [7:0] ev_code;
    logic [3:0] lane_down, lane_press;
    logic       enter_down, enter_press;

    logic [3:0] por = 4'hF;                 // power-on reset
    always_ff @(posedge CLK100MHZ) por <= {por[2:0], 1'b0};
    wire rst = por[3];

    ps2_receiver rx (.clk(CLK100MHZ), .rst(rst), .ps2_clk(PS2_CLK), .ps2_data(PS2_DATA),
                     .data(rx_data), .valid(rx_valid), .error(rx_error));
    scan_decoder dec (.clk(CLK100MHZ), .rst(rst), .data(rx_data), .valid(rx_valid),
                      .ev_valid(ev_valid), .ev_code(ev_code), .ev_ext(ev_ext), .ev_break(ev_break));
    key_tracker  trk (.clk(CLK100MHZ), .rst(rst), .ev_valid(ev_valid), .ev_code(ev_code),
                      .ev_ext(ev_ext), .ev_break(ev_break),
                      .lane_down(lane_down), .lane_press(lane_press),
                      .enter_down(enter_down), .enter_press(enter_press));

    logic toggle, err_latch;
    logic [7:0] last_byte;
    always_ff @(posedge CLK100MHZ) begin
        if (|lane_press) toggle <= ~toggle;
        if (rx_error)    err_latch <= 1'b1;
        if (rx_valid)    last_byte <= rx_data;
    end
    
    logic [7:0] err_count;
    always_ff @(posedge CLK100MHZ) begin
        if (BTNC)         err_count <= 8'd0;
        else if (rx_error && err_count != 8'hFF)
                          err_count <= err_count + 8'd1;
    end

    assign LED[7:6] = 2'b00;
    assign LED[15:8] = err_count;   // shows the error count in binary

    assign LED[3:0]  = lane_down;
    assign LED[4]    = enter_down;
    assign LED[5]    = toggle;        // flips once per new press
    //assign LED[6]    = err_latch;
    //assign LED[7]    = 1'b0;
    //assign LED[15:8] = last_byte;
endmodule