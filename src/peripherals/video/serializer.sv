module serializer
(
    input clk_i,
    input rstn_i,

    input serial_clk_i,

    input [9:0] data_i,
    output logic serial_data_o
);

`ifdef SYNTHESIS // use xilinx OSERDESE2 primitives

logic [1:0] cascade;

OSERDESE2 #(
    .DATA_RATE_OQ("DDR"),
    .DATA_RATE_TQ("SDR"),
    .DATA_WIDTH(10),
    .SERDES_MODE("MASTER"),
    .TRISTATE_WIDTH(1),
    .TBYTE_CTL("FALSE"),
    .TBYTE_SRC("FALSE")
) primary (
    .OQ(serial_data_o),
    .OFB(),
    .TQ(),
    .TFB(),
    .SHIFTOUT1(),
    .SHIFTOUT2(),
    .TBYTEOUT(),
    .CLK(serial_clk_i),
    .CLKDIV(clk_i),
    .D1(data_i[0]),
    .D2(data_i[1]),
    .D3(data_i[2]),
    .D4(data_i[3]),
    .D5(data_i[4]),
    .D6(data_i[5]),
    .D7(data_i[6]),
    .D8(data_i[7]),
    .TCE(1'b0),
    .OCE(1'b1),
    .TBYTEIN(1'b0),
    .RST(~rstn_i),
    .SHIFTIN1(cascade[0]),
    .SHIFTIN2(cascade[1]),
    .T1(1'b0),
    .T2(1'b0),
    .T3(1'b0),
    .T4(1'b0)
);

OSERDESE2 #(
    .DATA_RATE_OQ("DDR"),
    .DATA_RATE_TQ("SDR"),
    .DATA_WIDTH(10),
    .SERDES_MODE("SLAVE"),
    .TRISTATE_WIDTH(1),
    .TBYTE_CTL("FALSE"),
    .TBYTE_SRC("FALSE")
) secondary (
    .OQ(),
    .OFB(),
    .TQ(),
    .TFB(),
    .SHIFTOUT1(cascade[0]),
    .SHIFTOUT2(cascade[1]),
    .TBYTEOUT(),
    .CLK(serial_clk_i),
    .CLKDIV(clk_i),
    .D1(1'b0),
    .D2(1'b0),
    .D3(data_i[8]),
    .D4(data_i[9]),
    .D5(1'b0),
    .D6(1'b0),
    .D7(1'b0),
    .D8(1'b0),
    .TCE(1'b0),
    .OCE(1'b1),
    .TBYTEIN(1'b0),
    .RST(~rstn_i),
    .SHIFTIN1(1'b0),
    .SHIFTIN2(1'b0),
    .T1(1'b0),
    .T2(1'b0),
    .T3(1'b0),
    .T4(1'b0)
);

`else // use simulation equivalent

logic [3:0] bit_pos;
// the serial clock is only 5 times faster than clk_i, we need to clock out on both clock edges
always_ff@ (serial_clk_i or negedge rstn_i)
begin
    if (!rstn_i)
    begin
        serial_data_o <= '0;
        bit_pos <= '0;
    end
    else
    begin
        serial_data_o <= data_i[bit_pos];
        bit_pos <= (bit_pos == 'd9) ? '0 : bit_pos + 1'b1;
    end
end

`endif // SYNTHESIS

endmodule: serializer