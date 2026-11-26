module pulse4_top (
    input  logic        CLK100MHZ,
    input  logic        PS2_CLK,
    input  logic        PS2_DATA,

    output logic [3:0]  VGA_R,
    output logic [3:0]  VGA_G,
    output logic [3:0]  VGA_B,
    output logic        VGA_HS,
    output logic        VGA_VS,
    output logic [15:0] LED
);

    // ---------- Pixel clock ----------
    logic clk_pix, clk_locked;

    clk_wiz_vga clk_gen (
        .clk_in1  (CLK100MHZ),
        .clk_out1 (clk_pix),
        .reset    (1'b0),
        .locked   (clk_locked)
    );

    // ---------- Pixel-domain reset ----------
    logic [2:0] reset_pipe = 3'b111;
    wire        rst_pix = reset_pipe[2];

    always_ff @(posedge clk_pix or negedge clk_locked) begin
        if (!clk_locked) reset_pipe <= 3'b111;
        else             reset_pipe <= {reset_pipe[1:0], 1'b0};
    end

    // ---------- Game-domain reset (100 MHz) ----------
    logic [3:0] por = 4'hF;
    always_ff @(posedge CLK100MHZ) por <= {por[2:0], 1'b0};
    wire rst_game = por[3];

    // ---------- Keyboard (100 MHz domain) ----------
    logic [3:0] lane_down, lane_press;
    logic       enter_down, enter_press, kb_error;

    keyboard_input kb (
        .clk(CLK100MHZ), .rst(rst_game),
        .ps2_clk(PS2_CLK), .ps2_data(PS2_DATA),
        .lane_down(lane_down), .lane_press(lane_press),
        .enter_down(enter_down), .enter_press(enter_press),
        .rx_error(kb_error)
    );

    // ---------- Cross lane_down into the pixel domain ----------
    (* ASYNC_REG = "TRUE" *) logic [3:0] lane_meta, lane_pix;
    always_ff @(posedge clk_pix) begin
        lane_meta <= lane_down;
        lane_pix  <= lane_meta;
    end

    // ---------- Display timing ----------
    logic [9:0] sx, sy;
    logic       hsync, vsync, de;

    simple_480p timing (
        .clk_pix(clk_pix), .rst_pix(rst_pix),
        .sx(sx), .sy(sy), .hsync(hsync), .vsync(vsync), .de(de)
    );

    // ---------- Song timeline and test note (100 MHz domain) ----------
    logic playing = 1'b0;
    always_ff @(posedge CLK100MHZ) if (enter_press) playing <= 1'b1;

    logic signed [31:0] song_time;
    logic               song_zero;

    song_timer timer (
        .clk(CLK100MHZ), .reset(rst_game),
        .start(enter_press), .running(playing),
        .tick_ms(), .song_zero(song_zero), .song_time_ms(song_time)
    );
    
    logic               nv;
    logic [1:0]         nl;
    logic signed [10:0] ny;

    single_note_scheduler note_sched (
        .clk(CLK100MHZ), .song_time_ms(song_time),
        .note_visible(nv), .note_lane(nl), .note_y(ny)
    );
    
    // ---------- Snapshot into the pixel domain ----------
    logic [13:0] view_pix;
    snapshot_cdc #(.W(14)) view_cdc (
        .clk_src(CLK100MHZ), .src_data({nv, nl, ny}),
        .clk_dst(clk_pix),   .dst_data(view_pix)
    );

    // ---------- Note drawing and mixing ----------
    logic        note_on;
    logic [11:0] note_rgb;

    note_renderer note_r (
        .de(de), .sx(sx), .sy(sy),
        .note_visible(view_pix[13]), .note_lane(view_pix[12:11]),
        .note_y(view_pix[10:0]),
        .note_on(note_on), .note_rgb(note_rgb)
    );

    // ---------- Drawing ----------
    logic [3:0] pf_r, pf_g, pf_b;

    playfield_renderer playfield (
        .de(de), .sx(sx), .sy(sy),
        .lane_down(lane_pix),
        .red(pf_r), .green(pf_g), .blue(pf_b)
    );
    
    wire [11:0] out_rgb = note_on ? note_rgb : {pf_r, pf_g, pf_b};

    always_ff @(posedge clk_pix) begin
        VGA_HS <= hsync;
        VGA_VS <= vsync;
        {VGA_R, VGA_G, VGA_B} <= out_rgb;
    end

    // ---------- Debug LEDs ----------
    assign LED[3:0]  = lane_down;
    assign LED[4]    = enter_down;
    assign LED[15:5] = '0;

endmodule