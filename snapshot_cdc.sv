module snapshot_cdc #(
    parameter int W = 14
) (
    input  logic         clk_src,
    input  logic [W-1:0] src_data,
    input  logic         clk_dst,
    output logic [W-1:0] dst_data
);
    logic         req     = 1'b0;
    logic         ack_dst = 1'b0;
    logic [W-1:0] hold;

    (* ASYNC_REG = "TRUE" *) logic [1:0] ack_sync = 2'b00;
    (* ASYNC_REG = "TRUE" *) logic [1:0] req_sync = 2'b00;

    // Source side: when the last transfer is acknowledged, publish a new one
    always_ff @(posedge clk_src) begin
        ack_sync <= {ack_sync[0], ack_dst};
        if (ack_sync[1] == req) begin
            hold <= src_data;
            req  <= ~req;
        end
    end

    // Destination side: copy once the request is seen, then acknowledge
    always_ff @(posedge clk_dst) begin
        req_sync <= {req_sync[0], req};
        if (req_sync[1] != ack_dst) begin
            dst_data <= hold;
            ack_dst  <= req_sync[1];
        end
    end
endmodule