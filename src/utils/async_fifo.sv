// a simple async fifo
// presents full, empty and fill count on both write and read sides

module async_fifo
#(
    parameter integer DATA_WIDTH = 32,
    parameter integer ADDR_WIDTH = 3,


    localparam integer DW = DATA_WIDTH,
    localparam integer AW = ADDR_WIDTH
)
(
    // write side
    input wclk_i,
    input wrstn_i,
    input we_i,
    input [DW-1:0] wdata_i,
    output logic full_o,
    output logic [AW:0] wfill_count_o,

    // read side
    input rclk_i,
    input rrstn_i,
    input re_i,
    output logic [DW-1:0] rdata_o,
    output logic empty_o
);

// fifo memory
logic [DW-1:0] mem [2**(AW)];

logic [AW:0] wbin_d, wbin_q; // binary pointer that points to the fifo address to be written next
logic [AW:0] wgrey_d, wgrey_q;
logic full_d, full_q;
logic [AW:0] rgrey_wq1, rgrey_wq2, rgrey_wq2_bin;
logic [AW-1:0] waddr;
logic [AW:0] wfill_count_d, wfill_count_q;

logic [DW-1:0] rdata_d, rdata_q;
logic [AW:0] rbin_d, rbin_q; // binary pointer that points to the fifo address that will be read next
logic [AW:0] rgrey_d, rgrey_q;
logic empty_d, empty_q;
logic [AW:0] wgrey_rq1, wgrey_rq2;
logic [AW-1:0] raddr;

// write side
assign wbin_d = wbin_q + (we_i & ~full_q);
assign wgrey_d = (wbin_d >> 1) ^ wbin_d; // convert to grey code
assign full_d = wgrey_d == {~rgrey_wq2[AW:AW-1], rgrey_wq2[AW-2:0]};

for (genvar i = 0; i <= AW; ++i) begin: grey_to_binary
    assign rgrey_wq2_bin[i] = ^rgrey_wq2[AW:i];
end

assign wfill_count_d = 
    (rgrey_wq2_bin[AW] == wbin_d[AW]) ? ({1'b0,wbin_d[AW-1:0]} - {1'b0,rgrey_wq2_bin[AW-1:0]})
                                      : ({1'b1,wbin_d[AW-1:0]} - {1'b0,rgrey_wq2_bin[AW-1:0]});

always_ff @(posedge wclk_i or negedge wrstn_i) begin
    if (!wrstn_i) begin
        wbin_q <= '0;
        wgrey_q <= '0;
        full_q <= '0;
        wfill_count_q <= '0;
    end else begin
        wbin_q <= wbin_d;
        wgrey_q <= wgrey_d;
        full_q <= full_d;
        wfill_count_q <= wfill_count_d;
    end
end

always_ff @(posedge wclk_i or negedge wrstn_i) begin: rd_to_wr_cdc
    if (!wrstn_i) begin
        {rgrey_wq2, rgrey_wq1} <= '0;
    end else begin
        {rgrey_wq2, rgrey_wq1} <= {rgrey_wq1, rgrey_q};
    end
end

assign waddr = wbin_q[AW-1:0];
// write to the fifo
always_ff @(posedge wclk_i) begin
    if (we_i && !full_q)
        mem[waddr] <= wdata_i;
end

// read side

assign rbin_d = rbin_q + (re_i & ~empty_q);
assign rgrey_d = (rbin_d >> 1) ^ rbin_d;
assign empty_d = (rgrey_d == wgrey_rq2);

always_ff @(posedge rclk_i or negedge rrstn_i) begin
    if (!rrstn_i) begin
        rbin_q <= '0;
        rgrey_q <= '0;
        empty_q <= '0;
    end else begin
        rbin_q <= rbin_d;
        rgrey_q <= rgrey_d;
        empty_q <= empty_d;
    end
end

always_ff @(posedge rclk_i or negedge rrstn_i) begin: wr_to_rd_cdc
    if (!rrstn_i) begin
        {wgrey_rq2, wgrey_rq1} <= '0;
    end else begin
        {wgrey_rq2, wgrey_rq1} <= {wgrey_rq1, wgrey_q};
    end
end

assign raddr = rbin_q[AW-1:0];
assign rdata_d = mem[raddr];
// read from the fifo
always_ff @(posedge rclk_i) begin
    if (!rrstn_i) begin
        rdata_q <= '0;
    end else if (re_i && !empty_q) begin
        rdata_q <= rdata_d;
    end
end

// assign outputs
assign wfill_count_o = wfill_count_q;
assign full_o = full_q;
assign empty_o = empty_q;
assign rdata_o = rdata_q;

endmodule: async_fifo
