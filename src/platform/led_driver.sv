// a peripheral module to drive 8 LEDs

module led_driver
(
    input clk_i,
    input rstn_i,

    input en_i,

    // read port
    input read_i,
    input [31:0] addr_i,
    output [31:0] rdata_o,
    // write port
    input [31:0] wdata_i,

    output [7:0] led_status_o
);

logic [7:0] led_status_q, led_status_d;
logic [31:0] rdata;

// combinational reads
always_comb
begin: read_logic
    rdata = {24'd0, led_status_q};
end

always_comb
begin: write_logic
    led_status_d = led_status_q;

    if (en_i && !read_i)
        led_status_d = wdata_i[7:0];
end

always_ff @(posedge clk_i, negedge rstn_i)
begin
    if (!rstn_i)
        led_status_q <= '0;
    else
        led_status_q <= led_status_d;
end

// assign outputs
assign led_status_o = led_status_q;
assign rdata_o = rdata;

endmodule: led_driver