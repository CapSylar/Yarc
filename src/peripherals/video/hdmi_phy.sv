module hdmi_phy
(
    input pixel_clk_i,
    input rstn_i,

    input [23:0] rgb_i,

    input hsync,
    input vsync,

    input draw_area_i,

    // output channels
    output logic [3:0] hdmi_channel_o
);

logic [7:0] red, green, blue;
logic [9:0] tmds_red, tmds_green, tmds_blue;

assign {red, green, blue} = rgb_i;

tmds_encoder tms_encoder_0 (.clk(pixel_clk_i), .rstn_i(rstn_i), .vd_i(blue),    .cd_i({vsync, hsync}), .vde_i(draw_area), .tmds_o(tmds_blue));
tmds_encoder tms_encoder_1 (.clk(pixel_clk_i), .rstn_i(rstn_i), .vd_i(green),   .cd_i('0), .vde_i(draw_area), .tmds_o(tmds_green));
tmds_encoder tms_encoder_2 (.clk(pixel_clk_i), .rstn_i(rstn_i), .vd_i(red),     .cd_i('0), .vde_i(draw_area), .tmds_o(tmds_red));

logic [3:0] tmds_plus_clock_serial; // outputs of serdes written here
assign hdmi_channel_o = tmds_plus_clock_serial;

// prepare data for input into the serde primitives
logic [9:0] tmds_serde_inputs [3:0];
assign tmds_serde_inputs = '{10'b00000_11111, tmds_red, tmds_green, tmds_blue};

generate
	for (genvar i = 0; i < 4; ++i)
	begin: gen_serializers
		serializer serializer_i
		(
			.clk_i(pixel_clk_i),
		 	.rstn_i(rstn_i),
			.serial_clk_i(pixel_clk_5x_i),
			.data_i(tmds_serde_inputs[i]),
			.serial_data_o(tmds_plus_clock_serial[i])
		);
	end
endgenerate

endmodule: hdmi_phy
