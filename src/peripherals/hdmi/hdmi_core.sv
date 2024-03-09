module hdmi_core(
	input clk_i,
    input rstn_i,

    input pixel_clk_i,
    input pixel_clk_5x_i,

    wishbone_if.SLAVE wb_if,
    
    // hdmi signal outputs
	output logic hdmi_tx_clk_n_o,
	output logic hdmi_tx_clk_p_o,
	output logic [2:0] hdmi_tx_n_o,
	output logic [2:0] hdmi_tx_p_o
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

logic fb_pixel_read_en;
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

tmds_encoder tms_encoder_0 (.clk(pixel_clk_i), .rstn_i(rstn_i), .VD(blue), .CD({vsync, hsync}), .VDE(draw_area), .TMDS(tmds_blue));
tmds_encoder tms_encoder_1 (.clk(pixel_clk_i), .rstn_i(rstn_i), .VD(green), .CD('0), .VDE(draw_area), .TMDS(tmds_green));
tmds_encoder tms_encoder_2 (.clk(pixel_clk_i), .rstn_i(rstn_i), .VD(red), .CD('0), .VDE(draw_area), .TMDS(tmds_red));

logic tmds_clk;
logic [2:0] tmds_data;

logic tmds_plus_clock_serial [3:0]; // outputs of serdes written here
// assign tmds_plus_clock_serial = '{tmds_clk, tmds_data[2], tmds_data[1], tmds_data[0]};
assign tmds_clk = tmds_plus_clock_serial[3];
assign tmds_data[2] = tmds_plus_clock_serial[2];
assign tmds_data[1] = tmds_plus_clock_serial[1];
assign tmds_data[0] = tmds_plus_clock_serial[0];

// prepare data for input into the serde primitives
logic [9:0] tmds_serde_inputs [3:0];
assign tmds_serde_inputs = '{10'b00000_11111, tmds_red, tmds_green, tmds_blue};

logic [1:0] cascade [3:0]; // used for interconnect between OSERDE2 blocks

// generate a reset signal for each oserdes2 block
logic internal_reset = 1'b1;
always_ff @(posedge pixel_clk_i)
begin
	internal_reset <= '0;
end

generate 
	for (genvar i = 0; i < 4; ++i)
	begin
		OSERDESE2 #(
			.DATA_RATE_OQ("DDR"),
			.DATA_RATE_TQ("SDR"),
			.DATA_WIDTH(10),
			.SERDES_MODE("MASTER"),
			.TRISTATE_WIDTH(1),
			.TBYTE_CTL("FALSE"),
			.TBYTE_SRC("FALSE")
		) primary (
			.OQ(tmds_plus_clock_serial[i]),
			.OFB(),
			.TQ(),
			.TFB(),
			.SHIFTOUT1(),
			.SHIFTOUT2(),
			.TBYTEOUT(),
			.CLK(pixel_clk_5x),
			.CLKDIV(pixel_clk_i),
			.D1(tmds_serde_inputs[i][0]),
			.D2(tmds_serde_inputs[i][1]),
			.D3(tmds_serde_inputs[i][2]),
			.D4(tmds_serde_inputs[i][3]),
			.D5(tmds_serde_inputs[i][4]),
			.D6(tmds_serde_inputs[i][5]),
			.D7(tmds_serde_inputs[i][6]),
			.D8(tmds_serde_inputs[i][7]),
			.TCE(1'b0),
			.OCE(1'b1),
			.TBYTEIN(1'b0),
			.RST(~rstn_i || internal_reset),
			.SHIFTIN1(cascade[i][0]),
			.SHIFTIN2(cascade[i][1]),
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
			.SHIFTOUT1(cascade[i][0]),
			.SHIFTOUT2(cascade[i][1]),
			.TBYTEOUT(),
			.CLK(pixel_clk_5x),
			.CLKDIV(pixel_clk_i),
			.D1(1'b0),
			.D2(1'b0),
			.D3(tmds_serde_inputs[i][8]),
			.D4(tmds_serde_inputs[i][9]),
			.D5(1'b0),
			.D6(1'b0),
			.D7(1'b0),
			.D8(1'b0),
			.TCE(1'b0),
			.OCE(1'b1),
			.TBYTEIN(1'b0),
			.RST(~rstn_i || internal_reset),
			.SHIFTIN1(1'b0),
			.SHIFTIN2(1'b0),
			.T1(1'b0),
			.T2(1'b0),
			.T3(1'b0),
			.T4(1'b0)
		);
	end
endgenerate

	OBUFDS obufds_clk (.I(tmds_clk), .O(hdmi_tx_clk_p_o), .OB(hdmi_tx_clk_n_o));
	OBUFDS obufds_c0 (.I(tmds_data[0]), .O(hdmi_tx_p_o[0]), .OB(hdmi_tx_n_o[0]));
	OBUFDS obufds_c1 (.I(tmds_data[1]), .O(hdmi_tx_p_o[1]), .OB(hdmi_tx_n_o[1]));
	OBUFDS obufds_c2 (.I(tmds_data[2]), .O(hdmi_tx_p_o[2]), .OB(hdmi_tx_n_o[2]));
endmodule: hdmi_core

module tmds_encoder(
	input clk,
	input rstn_i,
	input [7:0] VD,  // video data (red, green or blue)
	input [1:0] CD,  // control data
	input VDE,  // video data enable, to choose between CD (when VDE=0) and VD (when VDE=1)
	output logic [9:0] TMDS
);
	wire [3:0] Nb1s = VD[0] + VD[1] + VD[2] + VD[3] + VD[4] + VD[5] + VD[6] + VD[7];
	wire XNOR = (Nb1s>4'd4) || (Nb1s==4'd4 && VD[0]==1'b0);
	wire [8:0] q_m = {~XNOR, q_m[6:0] ^ VD[7:1] ^ {7{XNOR}}, VD[0]};

	logic [3:0] balance_acc = 0;
	wire [3:0] balance = q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7] - 4'd4;
	wire balance_sign_eq = (balance[3] == balance_acc[3]);
	wire invert_q_m = (balance==0 || balance_acc==0) ? ~q_m[8] : balance_sign_eq;
	wire [3:0] balance_acc_inc = balance - ({q_m[8] ^ ~balance_sign_eq} & ~(balance==0 || balance_acc==0));
	wire [3:0] balance_acc_new = invert_q_m ? balance_acc-balance_acc_inc : balance_acc+balance_acc_inc;
	wire [9:0] TMDS_data = {invert_q_m, q_m[8], q_m[7:0] ^ {8{invert_q_m}}};
	wire [9:0] TMDS_code = CD[1] ? (CD[0] ? 10'b1010101011 : 10'b0101010100) : (CD[0] ? 10'b0010101011 : 10'b1101010100);

	always @(posedge clk, negedge rstn_i)
	begin
		if (!rstn_i)
			TMDS <= '0;
		else
			TMDS <= VDE ? TMDS_data : TMDS_code;
	end

	always @(posedge clk, negedge rstn_i)
	begin
		if (!rstn_i)
			balance_acc <= '0;
		else
			balance_acc <= VDE ? balance_acc_new : 4'h0;
	end

endmodule: tmds_encoder