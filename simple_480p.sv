module simple_480p (
    input  logic clk_pix,
    input  logic rst_pix,

    output logic [9:0] sx,
    output logic [9:0] sy,

    output logic hsync,
    output logic vsync,
    output logic de
);

    //horizontal
    localparam int H_ACTIVE = 640;
    localparam int H_FRONT = 16;
    localparam int H_SYNC = 96;
    localparam int H_BACK = 48;
    
    localparam int H_SYNC_START = H_ACTIVE + H_FRONT;
    localparam int H_SYNC_END = H_SYNC_START + H_SYNC;
    localparam int H_TOTAL = H_ACTIVE + H_FRONT + H_SYNC + H_BACK;
    
    //vertical
    localparam int V_ACTIVE = 480;
    localparam int V_FRONT = 10;
    localparam int V_SYNC = 2;
    localparam int V_BACK = 33;
    
    localparam int V_SYNC_START = V_ACTIVE + V_FRONT;
    localparam int V_SYNC_END = V_SYNC_START + V_SYNC;
    localparam int V_TOTAL = V_ACTIVE + V_FRONT + V_SYNC + V_BACK;
    
    always_ff @(posedge clk_pix) begin
        if (rst_pix) begin
            sx <= '0;
            sy <= '0;
        end
        else if (sx == H_TOTAL - 1) begin
            sx <= '0;
            if (sy == V_TOTAL - 1) begin
                sy <= '0;
            end
            else sy <= sy + 1;
        end
        else sx <= sx + 1;
    end
    
    always_comb begin
        hsync = !((sx >= H_SYNC_START) && (sx < H_SYNC_END));
        vsync = !((sy >= V_SYNC_START) && (sy < V_SYNC_END));
        de = ((sx < H_ACTIVE) && (sy < V_ACTIVE));
    end
    
endmodule