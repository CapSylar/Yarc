// Machine Timer Register

module mtimer
(
    input clk_i,
    input rstn_i,

    // NOTE: does not take in byte_sel, fixed granularity to 4 bytes
    wishbone_if.SLAVE wb_if,

    output timer_int_o
);

wire is_addressed = wb_if.cyc & wb_if.stb;

logic [63:0] mtime_q, mtime_d;
logic [63:0] mtimecmp_q, mtimecmp_d;

logic [31:0] rdata_d, rdata_q;
logic ack_q;

wire [1:0] addr = wb_if.addr[4:2]; // the two LSBs are don't cares, 4-byte granularity

// combinational reads
always_comb
begin: read_logic
    rdata_d = '0;

    unique case (addr)
        2'b00: rdata_d = mtime_q[31:0];
        2'b01: rdata_d = mtime_q[63:32];
        2'b10: rdata_d = mtimecmp_q[31:0];
        2'b11: rdata_d = mtimecmp_q[63:32];
        default:;
    endcase
end

always_comb
begin: write_logic

    mtime_d = mtime_q;
    mtimecmp_d = mtimecmp_q;

    if (is_addressed & wb_if.we)
        unique case(addr)
            2'b00:
                mtime_d[31:0] = wb_if.wdata;
            2'b01:
                mtime_d[63:32] = wb_if.wdata;
            2'b10:
                mtimecmp_d[31:0] = wb_if.wdata;
            2'b11:
                mtimecmp_d[63:32] = wb_if.wdata;
        endcase
    else
        mtime_d = mtime_q + 1'b1;
end

// mtime
always_ff @(posedge clk_i)
begin: mtime
    if (!rstn_i)
        mtime_q <= '0;
    else
        mtime_q <= mtime_d;
end

// mtimecmp
always_ff @(posedge clk_i)
begin: mtimecmp
    if (!rstn_i)
        mtimecmp_q <= '0;
    else
        mtimecmp_q <= mtimecmp_d;
end

// wb logic
always_ff @(posedge clk_i)
begin
    if (!rstn_i)
    begin
        rdata_q <= '0;
        ack_q <= '0;
    end
    else
    begin
        rdata_q <= rdata_d;
        ack_q <= is_addressed;
    end
end

// assign outputs
assign wb_if.rdata = rdata_q;
assign wb_if.rty = '0;
assign wb_if.ack = ack_q;
assign wb_if.stall = '0;
assign wb_if.err = '0;
// interrupt output
assign timer_int_o = (mtime_q >= mtimecmp_q);

endmodule: mtimer