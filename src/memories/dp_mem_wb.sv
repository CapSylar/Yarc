// simulation memory with 2 read ports and 1 write port
module dp_mem_wb
#(parameter int WIDTH = 32, parameter int SIZE_POT = 10, parameter string MEMFILE = "")
(
    input clk_i,
    input rstn_i,

    // port1
    // writes from this port are ignored
    wishbone_if.SLAVE wb_if1,

    // port 2
    wishbone_if.SLAVE wb_if2
);

logic [WIDTH-1:0] mem [2**SIZE_POT];

localparam ADDR_WIDTH = SIZE_POT;
wire [ADDR_WIDTH-1:0] addr1 = wb_if1.addr[ADDR_WIDTH-1+2:2]; // 4-byte addressable
wire [ADDR_WIDTH-1:0] addr2 = wb_if2.addr[ADDR_WIDTH-1+2:2]; // 4-byte addressable

// load memory image
initial
begin
    $readmemh(MEMFILE, mem);
end

// port1 logic
wire port1_addressed = wb_if1.cyc & wb_if1.stb & !wb_if1.we;

logic [WIDTH-1:0] port1_rdata_q, port1_rdata_d;
logic port1_ack_q, port1_ack_d;

always_comb
begin
    port1_rdata_d = '0;
    port1_ack_d = '0;

    if (port1_addressed)
    begin
        port1_ack_d = 1'b1;
        port1_rdata_d = mem[addr1];
    end
end

always_ff @(posedge clk_i)
begin
    if (!rstn_i)
    begin
        port1_rdata_q <= '0;
        port1_ack_q <= '0;
    end
    else
    begin
        port1_rdata_q <= port1_rdata_d;
        port1_ack_q <= port1_ack_d;
    end
end

// port2 logic
wire port2_addressed = wb_if2.cyc & wb_if2.stb;

logic [WIDTH-1:0] port2_rdata_d, port2_rdata_q;
logic port2_ack_d, port2_ack_q;

always_comb
begin
    port2_ack_d = '0;
    port2_rdata_d = '0;

    if (port2_addressed)
    begin
        port2_ack_d = 1'b1;

        if (!wb_if2.we)
            port2_rdata_d = mem[addr2];
    end
end

always_ff @(posedge clk_i)
begin
    if (!rstn_i)
    begin
        port2_ack_q <= '0;
        port2_rdata_q <= '0;
    end
    else
    begin
        port2_ack_q <= port2_ack_d;
        port2_rdata_q <= port2_rdata_d;
    end
end

// handle write for port b
always_ff @(posedge clk_i)
begin
    if (port2_addressed & wb_if2.we)
    begin
        // for each byte, if the corresponding bit in wsel_byte in 1, write it
        for (int i = 0; i < WIDTH/8 ; ++i)
            if (wb_if2.sel[i])
                mem[addr2][(i+1)*8 -1 -:8] <= wb_if2.wdata[(i+1)*8 -1 -:8];
    end
end

// wishbone interface slave outputs
// port1
assign wb_if1.rdata = port1_rdata_q;
assign wb_if1.rty = '0;
assign wb_if1.ack = port1_ack_q;
assign wb_if1.stall = '0;
assign wb_if1.err = '0;

// port2
assign wb_if2.rdata = port2_rdata_q;
assign wb_if2.rty = '0;
assign wb_if2.ack = port2_ack_q;
assign wb_if2.stall = '0;
assign wb_if2.err = '0;

endmodule: dp_mem_wb