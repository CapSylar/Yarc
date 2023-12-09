// Machine Timer Register

module timer
(
    input clk_i,
    input rstn_i,

    input en_i,
    // read port
    input read_i,
    input [31:0] addr_i,
    output [31:0] rdata_o,
    
    // write port
    // NOTE: does not take in byte_sel, fixed granularity to 4 bytes
    input [31:0] wdata_i,

    output timer_int_o
);

logic [63:0] mtime_q, mtime_d;
logic [63:0] mtimecmp_q, mtimecmp_d;

logic [31:0] rdata;
wire [1:0] addr = addr_i[4:2]; // the two LSBs are don't cares, 4-byte granularity

// combinational reads
always_comb
begin: read_logic
    rdata = '0;

    unique case (addr)
        2'b00: rdata = mtime_q[31:0];
        2'b01: rdata = mtime_q[63:32];
        2'b10: rdata = mtimecmp_q[31:0];
        2'b11: rdata = mtimecmp_q[63:32];
        default:;
    endcase
end

always_comb
begin: write_logic

    mtime_d = mtime_q;
    mtimecmp_d = mtimecmp_q;

    if (en_i && !read_i)
        unique case(addr)
            2'b00:
                mtime_d[31:0] = wdata_i;
            2'b01:
                mtime_d[63:32] = wdata_i;
            2'b10:
                mtimecmp_d[31:0] = wdata_i;
            2'b11:
                mtimecmp_d[63:32] = wdata_i;
        endcase
    else
        mtime_d = mtime_q + 1'b1;
end

// mtime
always_ff @(posedge clk_i, negedge rstn_i)
begin: mtime
    if (!rstn_i)
        mtime_q <= '0;
    else
        mtime_q <= mtime_d;
end

// mtimecmp
always_ff @(posedge clk_i, negedge rstn_i)
begin: mtimecmp
    if (!rstn_i)
        mtimecmp_q <= '0;
    else
        mtimecmp_q <= mtimecmp_d;
end

// assign outputs
assign rdata_o = rdata;
assign timer_int_o = (mtime_q >= mtimecmp_q);

endmodule: timer

