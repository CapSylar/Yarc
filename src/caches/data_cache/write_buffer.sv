`default_nettype none
// a simple write buffer(FIFO) for the data cache
// is not capable of doing write coalescing

module write_buffer
#(
    // width of the stored data in a fifo line
    parameter unsigned STORED_DATA_WIDTH = 0,
    // width of the address that is stored along side the data
    parameter unsigned STORED_ADDRESS_WIDTH = 0,
    // depth of fifo buffer log2, 3 => 8 entries
    parameter unsigned DEPTH_LOG2 = 0,

    localparam unsigned SEL_W = STORED_DATA_WIDTH / 8,
    localparam unsigned FIFO_DW = STORED_DATA_WIDTH + SEL_W + STORED_ADDRESS_WIDTH,
    localparam unsigned NUM_ELEMS = 2**DEPTH_LOG2
)
(
    input wire clk_i,
    input wire rstn_i,

    // write side
    input wire we_i,
    input wire [STORED_DATA_WIDTH-1:0] store_data_i,
    input wire [SEL_W-1:0] store_sel_i,
    input wire [STORED_ADDRESS_WIDTH-1:0] store_address_i,

    // read side
    input wire re_i,
    output logic [FIFO_DW-1:0] rdata_o,

    output logic [STORED_ADDRESS_WIDTH:0] fill_count_o,
    output logic empty_o,
    output logic full_o,

    // hit logic for load hazard detection
    input wire check_i,

    input wire [STORED_ADDRESS_WIDTH-1:0] check_address_i,
    input wire [SEL_W-1:0] check_sel_i,

    output logic hit_o,
    output logic [STORED_DATA_WIDTH-1:0] hit_data_o
);

typedef struct packed {
    logic [STORED_DATA_WIDTH-1:0] data;
    logic [SEL_W-1:0] sel;
    logic [STORED_ADDRESS_WIDTH-1:0] address;
} fifo_line_t;

// -------------------------- FIFO LOGIC --------------------------
fifo_line_t mem [NUM_ELEMS];

// one additional bit that allows us to detect wrap arounds
logic [STORED_ADDRESS_WIDTH:0] wr_addr, rd_addr; 
logic [STORED_ADDRESS_WIDTH-1:0] wr_addr_mem, rd_addr_mem; // these are used to access fifo memory

assign wr_addr_mem = wr_addr[STORED_ADDRESS_WIDTH-1:0];
assign rd_addr_mem = rd_addr[STORED_ADDRESS_WIDTH-1:0];

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
        mem[wr_addr_mem] <= '{data: store_data_i, sel: store_sel_i, address: store_address_i};
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
assign full_o = (fill_count_o == {1'b1, {(STORED_ADDRESS_WIDTH){1'b0}}});
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

// transit buffer
// for now, saves the last check request
logic req_q;
logic [STORED_ADDRESS_WIDTH-1:0] check_address_q;
logic [SEL_W-1:0] check_sel_q;

always_ff @(posedge clk_i) begin
    if (!rstn_i) begin
        req_q <= '0;
    end else begin
        req_q <= check_i;
        check_address_q <= check_address_i;
        check_sel_q <= check_sel_i;
    end
end

// ----------------------------- Write Buffer Logic -----------------------------
// when a check comes in, check the tag address of all valid entries
logic [NUM_ELEMS-1:0] line_address_match;
logic [NUM_ELEMS-1:0] line_hit;
logic [$clog2(NUM_ELEMS)-1:0] line_hit_idx;
logic hit_d, hit_q;
logic [STORED_DATA_WIDTH-1:0] hit_data_d, hit_data_q;

always_comb begin
    line_address_match = '0;

    /*
     * - addresses need to check
     * - read word needs to be included the written word of the entry
    */
    for (int i = 0; i < NUM_ELEMS; ++i) begin
        line_address_match[i] = (mem[i].address == check_address_i) &&
            ((mem[i].sel & check_sel_i) == check_sel_i);
    end
end

always_comb begin
    line_hit = '0;

    for (int i = 0; i < NUM_ELEMS; ++i) begin
        if (valid_q[i] & line_address_match[i]) begin
            line_hit[i] = 1'b1;
        end

    end
end

always_comb begin
    line_hit_idx = '0;

    for (int i = 0; i < NUM_ELEMS; ++i) begin
        if (line_hit[i]) begin
            line_hit_idx = i;
            break;
        end
    end
end

assign hit_d = |line_hit; // is any line hit
assign hit_data_d = mem[line_hit_idx].data;

always_ff @(posedge clk_i) begin
    if (!rstn_i) begin
        hit_q <= '0;
        hit_data_q <= '0;
    end else begin
        hit_q <= hit_d;
        hit_data_q <= hit_data_d;
    end
end

assign hit_o = hit_q;
assign hit_data_o = hit_data_q;

endmodule: write_buffer
