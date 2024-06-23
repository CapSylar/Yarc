module txuart_sender
#(parameter CLKS_PER_BAUD)
(
    input clk_i,
    input reset_i,

    output logic tx_uart_o
);

logic wr, busy;
logic [7:0] data;

txuartlite 
#(.CLOCKS_PER_BAUD(CLKS_PER_BAUD))
txuartlite_i
(
    .i_clk(clk_i),
    .i_reset(reset_i),
    .i_wr(wr),
    .i_data(data),

    .o_uart_tx(tx_uart_o),
    .o_busy(busy)
);

string message = "hello, world! It is a beautiful day!";

initial
begin
    wr = '0;
    data = '0;

    #200_174_000ns;

    for (int i = 0; i < message.len(); ++i) begin

        do begin
            @(posedge clk_i);
        end while(busy);

        wr = 1'b1;
        data = message.getc(i);

        @(posedge clk_i);
        wr = '0;
    end

    @(posedge clk_i);
    wr = '0;
end

endmodule: txuart_sender
