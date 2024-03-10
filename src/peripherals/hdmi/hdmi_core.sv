module hdmi_core(
	input clk_i,
    input rstn_i,

    input pixel_clk_i,
    input pixel_clk_5x_i,

    wishbone_if.SLAVE wb_if,
    
    // hdmi signal outputs
	output logic hdmi_clk_o,
	output logic [2:0] hdmi_data_o
);

// testing a simple hdmi(really dvi) driver
// create a 640x480 image

// we really have a 800 x 525 pixel area

logic [9:0] x_counter;
logic [9:0] y_counter;

logic hsync, vsync;
logic draw_area;

logic [7:0] red, green, blue;

localparam int FB_DEPTH = 20;
localparam int FB_WIDTH = 32;

// wishbone logic
wire is_addressed = wb_if.cyc & wb_if.stb;
logic ack_q;

always_ff @(posedge clk_i)
begin
	if (!rstn_i)
	begin
		ack_q <= '0;
	end
	else
	begin
		ack_q <= is_addressed;
	end
end

assign wb_if.ack = ack_q;
assign wb_if.rty = '0;
assign wb_if.stall = '0;
assign wb_if.err = '0;

logic [FB_DEPTH-1:0] fb_cpu_addr;
logic [FB_DEPTH-1:0] fb_pixel_raddr;
logic [FB_WIDTH-1:0] fb_pixel_rdata, fb_pixel_rdata_q, fb_pixel_rdata_q2;

assign fb_cpu_addr = wb_if.addr[FB_DEPTH-1:0];

logic fetch_pixel;

// framebuffer
tdp_mem
#(.WIDTH(FB_WIDTH), .DEPTH(FB_DEPTH))
tdp_mem_i
(
	// port 1 a - cpu side
	.clk_a_i(clk_i),
	.en_a_i(is_addressed),
	.we_a_i(wb_if.we),
	.wsel_byte_a_i(wb_if.sel),
	.addr_a_i(fb_cpu_addr),
	.wdata_a_i(wb_if.wdata),
	.rdata_a_o(wb_if.rdata),

	// port 2 b - hdmi logic side
	.clk_b_i(pixel_clk_i),
	.en_b_i(fetch_pixel),
	.addr_b_i(fb_pixel_raddr),
	.rdata_b_o(fb_pixel_rdata)
);

logic pixel_wait;

always_comb
begin
	fetch_pixel = '0;

	if ((y_counter == 'd524 || (y_counter >= '0 && y_counter < 'd479)) && // in correct Y
		(x_counter == 'd799 || (x_counter >= '0 && x_counter < 'd638))) // in correct X
	begin
		if (!pixel_wait)
			fetch_pixel = 1'b1;
	end
end

always_ff @(posedge pixel_clk_i)
begin
	if (!rstn_i)
	begin
		fb_pixel_rdata_q <= '0;
		fb_pixel_rdata_q2 <= '0;
	end
	else
	begin
		fb_pixel_rdata_q <= fb_pixel_rdata;
		fb_pixel_rdata_q2 <= fb_pixel_rdata_q;
	end
end

always_ff @(posedge pixel_clk_i)
begin
	if (!rstn_i)
	begin
		fb_pixel_raddr <= '0;
	end
	else if (fetch_pixel)
	begin
		fb_pixel_raddr <= fb_pixel_raddr + 1'b1;
	end
end

// the memory pumps out 32 bit words, we need 24 bits at a time
// this means we sometimes need data from adjacent memory words

logic [23:0] formatted_pixel_data;

always_comb
begin
	formatted_pixel_data = '0;
	pixel_wait = '0;

	case (fb_pixel_rdata[1:0])
		2'd0: formatted_pixel_data = {fb_pixel_rdata_q[23:0]};
		2'd1: formatted_pixel_data = {fb_pixel_rdata_q[15:0],fb_pixel_rdata_q2[31-:8]};
		2'd2: begin
			formatted_pixel_data = {fb_pixel_rdata_q[7:0],fb_pixel_rdata_q2[31-:16]};
			pixel_wait = 1'b1;
		end
		2'd3: formatted_pixel_data = {fb_pixel_rdata_q2[31-:24]};
	endcase
end


assign red = formatted_pixel_data[7:0];
assign green = formatted_pixel_data[15-:8];
assign blue = formatted_pixel_data[23-:8];

always_ff @(posedge pixel_clk_i or negedge rstn_i)
begin
	if (!rstn_i)
	begin
		x_counter <= '0;
		y_counter <= '0;
	end
	else
	begin
		x_counter <= (x_counter == 'd799) ? '0 : x_counter + 1'b1;

		if (x_counter == 'd799)
			y_counter <= (y_counter == 'd524) ? '0 : y_counter + 1'b1;
	end
end

// create the hsync and vsync signals

assign hsync = (x_counter >= 'd656) & (x_counter < 'd757);
assign vsync = (y_counter >= 'd490) & (y_counter < 'd492);
assign draw_area = (x_counter < 'd640) & (y_counter < 'd480);

logic [9:0] tmds_red, tmds_green, tmds_blue;

tmds_encoder tms_encoder_0 (.clk(pixel_clk_i), .rstn_i(rstn_i), .vd_i(blue), .cd_i({vsync, hsync}), .vde_i(draw_area), .tmds_o(tmds_blue));
tmds_encoder tms_encoder_1 (.clk(pixel_clk_i), .rstn_i(rstn_i), .vd_i(green), .cd_i('0), .vde_i(draw_area), .tmds_o(tmds_green));
tmds_encoder tms_encoder_2 (.clk(pixel_clk_i), .rstn_i(rstn_i), .vd_i(red), .cd_i('0), .vde_i(draw_area), .tmds_o(tmds_red));

// TODO: refactor these assignments
logic tmds_plus_clock_serial [3:0]; // outputs of serdes written here
assign hdmi_clk_o = tmds_plus_clock_serial[3];
assign hdmi_data_o[2] = tmds_plus_clock_serial[2];
assign hdmi_data_o[1] = tmds_plus_clock_serial[1];
assign hdmi_data_o[0] = tmds_plus_clock_serial[0];

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
endmodule: hdmi_core