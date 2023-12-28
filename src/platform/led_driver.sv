// a peripheral module to drive 8 LEDs

module led_driver
(
    input clk_i,
    input rstn_i,

    wishbone_if.SLAVE wb_if,

    output [7:0] led_status_o
);

wire is_addressed = wb_if.cyc & wb_if.stb;

logic [7:0] led_status_q, led_status_d;
logic [31:0] rdata;
logic ack_q;

// combinational reads
always_comb
begin: read_logic
    rdata = {24'd0, led_status_q};
end

always_comb
begin: write_logic
    led_status_d = led_status_q;

    if (is_addressed & wb_if.we)
        led_status_d = wb_if.wdata[7:0];
end

always_ff @(posedge clk_i)
begin
    if (!rstn_i)
    begin
        led_status_q <= '0;
        ack_q <= '0;
    end
    else
    begin
        led_status_q <= led_status_d;
        ack_q <= is_addressed;
    end
end

// assign outputs
assign led_status_o = led_status_q;

// assign to wishbone interface
assign wb_if.rdata = rdata;
assign wb_if.rty = '0;
assign wb_if.ack = ack_q;
assign wb_if.stall = '0;
assign wb_if.err = '0;

endmodule: led_driver