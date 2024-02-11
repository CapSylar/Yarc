// simulation only testbench
// takes in the uart rx line
// prints out character using $display

module rxuart_printer
(
    input clk_i,
    input reset_i,

    // uart rx line
    input uart_rx_i
);

logic data_ready;
logic [7:0] rdata;

byte character;

rxuartlite
#(.CLOCKS_PER_BAUD(694))
rxuartlite_i
(
    .i_clk(clk_i),
    .i_reset(reset_i),

    .i_uart_rx(uart_rx_i),
    
    .o_wr(data_ready),
    .o_data(rdata)
);

// when data is ready, print it to the screen

always @(posedge data_ready)
begin
    character = rdata;
    $write("%c", character);
end

endmodule: rxuart_printer