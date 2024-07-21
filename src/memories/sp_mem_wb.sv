
// single port memory with wishbone interface
// reading and writing are both synchronous operations
// should map into xilinx's BRAM

module sp_mem_wb
#(parameter DATA_WIDTH = 32, parameter SIZE_POT_WORDS = 10, parameter string MEMFILE = "")
(
    input clk_i,

    wishbone_if.SLAVE wb_if
);

logic [DATA_WIDTH-1:0] mem [2**SIZE_POT_WORDS];
logic [DATA_WIDTH-1:0] rdata_q, rdata_d;

localparam AW = SIZE_POT_WORDS;
logic [AW-1:0] mem_addr;

assign mem_addr = wb_if.addr[AW-1:0];

// load memory image
initial
begin
    $readmemh(MEMFILE, mem);
end

logic is_addressed;
assign is_addressed = wb_if.cyc & wb_if.stb;

always_comb
begin: handle_reads
    rdata_d = rdata_q;

    if (is_addressed & !wb_if.we)
        rdata_d = mem[mem_addr];
end

always_ff @(posedge clk_i)
begin : write_mem
    if (is_addressed & wb_if.we)
    begin
        // for each byte, if the corresponding bit in wsel_byte in 1, write it
        for (int i = 0; i < DATA_WIDTH/8 ; ++i)
            if (wb_if.sel[i])
                mem[mem_addr][(i+1)*8 -1 -:8] <= wb_if.wdata[(i+1)*8 -1 -:8];
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
assign wb_if.rdata = rdata_q;
assign wb_if.rty = '0;
assign wb_if.ack = ack_q;
assign wb_if.stall = '0;
assign wb_if.err = '0;

endmodule: sp_mem_wb
