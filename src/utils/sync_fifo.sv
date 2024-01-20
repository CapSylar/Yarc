// taken from zipcpu
// implement a synchronous circular fifo

module sync_fifo 
#(parameter unsigned BW = 8, parameter unsigned FF_SIZE_POT = 8)
(
    input clk_i,
    input rstn_i,

    // write port
    input wr_i,
    input [BW-1:0] data_i,

    // read port
    input rd_i,
    output logic [BW-1:0] data_o,

    // status
    output logic full_o,
    output logic empty_o,
    output logic [FF_SIZE_POT:0] fill_count_o
);

logic [BW-1:0] mem [2**FF_SIZE_POT];
logic [FF_SIZE_POT:0] wr_addr, rd_addr; // one additional bit

wire is_write = wr_i && !full_o;
wire is_read = rd_i && !empty_o;

// write logic
always_ff @(posedge clk_i)
    if (!rstn_i)
        wr_addr <= '0;
    else if (is_write)
        wr_addr <= wr_addr + 1'b1;

always_ff @(posedge clk_i)
    if (is_write)
        mem[wr_addr[FF_SIZE_POT-1:0]] <= data_i;

// read logic
always_ff @(posedge clk_i)
    if (!rstn_i)
        rd_addr <= '0;
    else if (is_read)
        rd_addr <= rd_addr + 1'b1;

// data out is not piped, this will prevent mem from being synth as a BRAM on xilinx fpgas
assign data_o = mem[rd_addr[FF_SIZE_POT-1:0]];

// calculate status flags
assign fill_count_o = wr_addr - rd_addr;
assign empty_o = (fill_count_o == '0);
assign full_o = (fill_count_o == {1'b1, {(FF_SIZE_POT){1'b0}} });

endmodule : sync_fifo