`default_nettype none
// a simple write buffer(FIFO) for the data cache
// is not capable of doing write coalescing

module write_buffer
#(
    parameter unsigned DW = 32,
    parameter unsigned AW = 3,

    localparam unsigned NUM_ELEMS = 2**AW
)
(
    input wire clk_i,
    input wire rstn_i,

    // write side
    input wire we_i,
    input wire [DW-1:0] wdata_i,

    // read side
    input wire re_i,
    output logic [DW-1:0] rdata_o,

    output logic [AW:0] fill_count_o,
    output logic empty_o,
    output logic full_o,

    // expose fifo contents
    output logic [DW-1:0] fifo_mem_o [NUM_ELEMS],
    output logic [NUM_ELEMS-1:0] valid_o
);

logic [DW-1:0] mem [NUM_ELEMS];
assign fifo_mem_o = mem;

// one additional bit that allows us to detect wrap arounds
logic [AW:0] wr_addr, rd_addr; 
logic [AW-1:0] wr_addr_mem, rd_addr_mem; // these are used to access fifo memory

assign wr_addr_mem = wr_addr[AW-1:0];
assign rd_addr_mem = rd_addr[AW-1:0];

logic we, re;
assign we = we_i & ~full_o;
assign re = re_i & ~empty_o;

always_ff @(posedge clk_i) begin
    if (!rstn_i) begin
        wr_addr <= '0;
    end else if (we) begin
        wr_addr <= wr_addr + 1'b1;
    end
end

// writing to fifo
always_ff @(posedge clk_i) begin
    if (we) begin
        mem[wr_addr_mem] <= wdata_i;
    end
end

always_ff @(posedge clk_i) begin
    if (!rstn_i) begin
        rd_addr <= '0;
    end else if (re) begin
        rd_addr <= rd_addr + 1'b1;
    end
end

// reading from fifo
always_ff @(posedge clk_i) begin
    if (re) begin
        rdata_o <= mem[rd_addr_mem];
    end
end

// assign status signals
assign fill_count_o = wr_addr - rd_addr;
assign full_o = (fill_count_o == {1'b1, {(AW){1'b0}}});
assign empty_o = (fill_count_o == '0);

logic [NUM_ELEMS-1:0] valid_d, valid_q;

always_comb begin
    valid_d = valid_q;

    if (we) begin
        valid_d[wr_addr_mem] = 1'b1;
    end

    if (re) begin
        valid_d[rd_addr_mem] = '0;
    end
end

always_ff @(posedge clk_i) begin
    if (!rstn_i) begin
        valid_q <= '0;
    end else begin
        valid_q <= valid_d;
    end
end

assign valid_o = valid_q;

endmodule: write_buffer
