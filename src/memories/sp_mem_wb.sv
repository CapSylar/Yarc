
// single port memory with wishbone interface
// reading and writing are both synchronous operations
// should map into xilinx's BRAM

module sp_mem_wb
#(parameter DATA_WIDTH = 32, parameter SIZE_POT_WORDS = 10, parameter string MEMFILE = "")
(
    input clk_i,

    input cyc_i,
    input stb_i,

    input we_i,
    input [SIZE_POT_WORDS-1:0] addr_i,
    input [DATA_WIDTH/8 -1:0] sel_i,
    input [DATA_WIDTH-1:0] wdata_i,

    output logic [DATA_WIDTH-1:0] rdata_o,
    output logic rty_o,
    output logic ack_o,
    output logic stall_o,
    output logic err_o
);

logic [DATA_WIDTH-1:0] mem [2**SIZE_POT_WORDS];
logic [DATA_WIDTH-1:0] rdata_q, rdata_d;

// load memory image
initial
begin
    $readmemh(MEMFILE, mem);
end

logic is_addressed;
assign is_addressed = cyc_i & stb_i;

always_comb
begin: handle_reads
    rdata_d = rdata_q;

    if (is_addressed & !we_i)
        rdata_d = mem[addr_i];
end

always_ff @(posedge clk_i)
begin : write_mem
    if (is_addressed & we_i)
    begin
        // for each byte, if the corresponding bit in wsel_byte in 1, write it
        for (int i = 0; i < DATA_WIDTH/8 ; ++i)
            if (sel_i[i])
                mem[addr_i][(i+1)*8 -1 -:8] <= wdata_i[(i+1)*8 -1 -:8];
    end
end

logic ack_q, ack_d;

always_comb
begin: handle_wb_control_sigs
    // when addressed, the memory simply replies with an ack_o on the next cycle
    ack_d = '0;

    if (is_addressed)
        ack_d = 1'b1;
end

always_ff @(posedge clk_i)
begin
    rdata_q <= rdata_d;
    ack_q <= ack_d;
end

// assign outputs
assign rdata_o = rdata_q;
assign rty_o = '0;
assign ack_o = ack_q;
assign stall_o = '0;
assign err_o = '0;

endmodule: sp_mem_wb
