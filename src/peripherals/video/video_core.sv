module video_core
import video_pkg::*;
(
	input clk_i,
    input rstn_i,

    input pixel_clk_i,
	input pixel_rstn_i,
    input pixel_clk_5x_i,

	wishbone_if.SLAVE config_if,

    wishbone_if.MASTER fetch_if,
    
    // hdmi signal outputs
	output logic [3:0] hdmi_channel_o
);

// the frame starts in the blanking area after reset
localparam [9:0] X_COUNTER_INITIAL_VALUE = '0;
localparam [9:0] Y_COUNTER_INITIAL_VALUE = 'd481;

// module configuration registers
video_config_t video_config;
video_addr_t video_addr;

video_core_ctrl video_core_ctrl_i
(
	.clk_i(clk_i),
	.rstn_i(rstn_i),

	.config_if(config_if),

	.video_config_o(video_config),
	.video_addr_o(video_addr)
);

logic wb_cyc, wb_stb, wb_ack, wb_stall;
logic [31:0] wb_addr_d, wb_addr_q;

assign wb_ack = fetch_if.ack;
assign wb_stall = fetch_if.stall;

localparam ASIZE = 9;
localparam DSIZE = 128;

logic ff_we;
logic [DSIZE-1:0] ff_wdata;
logic ff_full;
logic [ASIZE:0] ff_fill_count;

logic async_ff_re;
logic [DSIZE-1:0] async_ff_rdata;
logic async_ff_empty;

async_fifo #(.DATA_WIDTH(DSIZE), .ADDR_WIDTH(ASIZE)) afifo_i
(
	// write side
	.wclk_i(clk_i),
	.wrstn_i(rstn_i),
	.we_i(ff_we),
	.wdata_i(ff_wdata),
	.full_o(ff_full),
	.wfill_count_o(ff_fill_count),

	// read side
	.rclk_i(pixel_clk_i),
	.rrstn_i(pixel_rstn_i),
	.re_i(async_ff_re),
	.rdata_o(async_ff_rdata),
	.empty_o(async_ff_empty)
);

logic ff_re;
logic ff_rsize;
logic [31:0] ff_rdata;
logic ff_empty;

assign ff_rsize = '0; // fixed to 16-bit reads for now

// fifo frontend adapter placed at the read side of the fifo above
// allows use to read in 16 or 32-bit chunks without specializing the fifo
fifo_adapter fifo_adapter_i
(
	.clk_i(pixel_clk_i),
	.rstn_i(pixel_rstn_i),

	// connection to fifo
	.empty_i(async_ff_empty),
	.re_o(async_ff_re),
	.rdata_i(async_ff_rdata),

	// adapter read interface
	.re_i(ff_re),
	.rsize_i(ff_rsize),
	.rdata_o(ff_rdata),
	.empty_o(ff_empty)
);

assign ff_we = wb_ack;
assign ff_wdata = fetch_if.rdata;

logic [ASIZE:0] req_pending_d, req_pending_q;
wire [ASIZE:0] max_ff_count = {1'b1, {(ASIZE){1'b0}}};
wire ff_one_till_full = (req_pending_q + ff_fill_count == (max_ff_count-1'b1));

// ==================================== fetching part ====================================
// read data from the framebuffer into the line fifos

// *fetch_start* pulses when the fetching logic should start fetching data from the framebuffer
// and store it in the fifo
logic fetch_start;
logic [10:0] reqs_left_d, reqs_left_q; // contains the number left for this frame

assign wb_req_ok = wb_cyc & wb_stb & ~wb_stall;

enum {IDLE, FETCHING, FIFO_FULL, WAIT_OUTSTANDING} state, next;
always_ff @(posedge clk_i)
	if (!rstn_i) state <= IDLE;
	else	     state <= next;

always_comb begin
	next = state;

	wb_cyc = '0;
	wb_stb = '0;

	wb_addr_d = wb_addr_q;
	reqs_left_d = reqs_left_q;

	case (state)
		IDLE: begin
			// fetching starts if the module is enabled and the update period is over
			if (video_config.is_enabled && fetch_start) begin

				wb_addr_d = video_addr.fb_address;
				reqs_left_d = 'd300; // TODO: only for text mode, change
				next = FETCHING;
			end
		end

		FETCHING: begin
			wb_cyc = 1'b1;
			wb_stb = 1'b1;

			if (wb_req_ok) begin
				wb_addr_d += 'd1;
				reqs_left_d -= 1'd1;
			end

			if (reqs_left_d == '0) begin
				next = WAIT_OUTSTANDING; // if no requests are left to send
			end else if (wb_req_ok && ff_one_till_full) begin
				// we can't issue more requests currently since there is no way to store them
				// back off and wait for some fifo space to become available
				next = FIFO_FULL;
			end
		end

		FIFO_FULL: begin
			wb_cyc = 1'b1;

			if (!ff_full)
				next = FETCHING;
		end

		WAIT_OUTSTANDING: begin // stay here till all acks have been received
			wb_cyc = 1'b1;

			if (req_pending_q == '0)
				next = IDLE;
		end
	endcase
end

// bookkeeping logic
always_comb begin: count_pending_reqs

	req_pending_d = req_pending_q;

	if (fetch_if.ack) begin
		req_pending_d = req_pending_d - 1;
	end

	if (wb_req_ok) begin
		req_pending_d = req_pending_d + 1;
	end
end

always_ff @(posedge clk_i) begin
	if (!rstn_i) begin
		req_pending_q <= '0;
		wb_addr_q <= '0;
		reqs_left_q <= '0;
	end else begin
		req_pending_q <= req_pending_d;
		wb_addr_q <= wb_addr_d;
		reqs_left_q <= reqs_left_d;
	end
end

/*
	In the normal frambuffer mode, each fetched 4-byte word corresponds to a screen pixel. The pixel
	is popped from the fifo and not needed again for this frame.
	The matter at hand is different in the case of vga text mode, where a fetched glyph dictates the colors
	of several pixels, crossing several lines. In this case, we can't simply pop from the fifo since the data
	will be needed again.

	We devised a small 256 byte line buffer used for storing vga text mode characters after popping them from the fifo.
*/

logic read_char, flush_line_buffer;
logic [7:0] char_idx;
logic [15:0] text_mode_data;

text_mode_line_buffer text_mode_line_buffer_i
(
	.clk_i(pixel_clk_i),
	.rstn_i(pixel_rstn_i),

	// fifo interface port
	.empty_i(ff_empty),
	.re_o(ff_re),
	.rdata_i(ff_rdata[15:0]),

	// read port
	.re_i(read_char),
	.pop_line_i(flush_line_buffer),
	.empty_o(),
	.char_idx_i(char_idx),
	.data_o(text_mode_data)
);

// ===================================== drawing part ==============================================
// fetched data from the line fifos and display the pixels

// testing a simple hdmi(really dvi) driver
// create a 640x480 image

logic [23:0] rgb; // red, green and blue
// we really have a 800 x 525 pixel area

logic [9:0] x_counter;
logic [9:0] y_counter;

// another set of counters that are 2 "pixels" ahead of the other ones
// since we will pipeline the access to the fifo and its computation
// we will use these counters to make things easier
logic [9:0] ahead_x_counter;
logic [9:0] ahead_y_counter;
logic ahead_draw_area_x; // within bounds w.r.t x
logic ahead_draw_area_y; // within bounds w.r.t y
logic ahead_draw_area; // x & y duhh

logic hsync, vsync;
logic draw_area;

assign fetch_start = (x_counter == '0 && y_counter == 'd500); // TODO: check for a potential CDC problem here

// text mode line buffer only needs to be cleared every 7th line in the draw area only
// since we don't to clear the line buffer in the vsync area
assign flush_line_buffer = (ahead_y_counter < 'd479) & // 479 and not 480 because we don't want to flush on the last line of the frame
	(ahead_x_counter == 'd640) &
	(ahead_y_counter[3:0] == 4'hf); // flush every 16th line since characters span 16 lines

// read 2 cycles before we actually need something
assign read_char = ahead_draw_area; // read from line buffer only in draw area
assign char_idx = ahead_x_counter[9:3]; // every 8 pixels, change character

logic [2:0] char_pixel_x_d, char_pixel_x_q; // x pixel offset inside glyph
logic [3:0] char_pixel_y_d, char_pixel_y_q; // y pixel offset inside glyph

assign char_pixel_x_d = ahead_x_counter[2:0];
assign char_pixel_y_d = ahead_y_counter[3:0];

// outputs the final rgb data for text mode
vga_text_decoder vga_text_decoder_i
(
	.clk_i(pixel_clk_i),
	.rstn_i(pixel_rstn_i),

	.vga_data_i(text_mode_data),
	.char_pixel_x_i(char_pixel_x_q),
	.char_pixel_y_i(char_pixel_y_q),

	.rgb_o(rgb)
);

always_ff @(posedge pixel_clk_i or negedge pixel_rstn_i)
begin
	if (!pixel_rstn_i)
	begin
		x_counter <= X_COUNTER_INITIAL_VALUE;
		y_counter <= Y_COUNTER_INITIAL_VALUE;
	end
	else
	begin
		x_counter <= (x_counter == 'd799) ? '0 : x_counter + 1'b1;

		if (x_counter == 'd799)
			y_counter <= (y_counter == 'd524) ? '0 : y_counter + 1'b1;
	end
end

always_ff @(posedge pixel_clk_i or negedge pixel_rstn_i)
begin
	if (!pixel_rstn_i)
	begin
		ahead_x_counter <= X_COUNTER_INITIAL_VALUE + 'd2; // 2 pixel ahead
		ahead_y_counter <= Y_COUNTER_INITIAL_VALUE;
	end
	else
	begin
		ahead_x_counter <= (ahead_x_counter == 'd799) ? '0 : ahead_x_counter + 1'b1;

		if (ahead_x_counter == 'd799)
			ahead_y_counter <= (ahead_y_counter == 'd524) ? '0 : ahead_y_counter + 1'b1;
	end
end

assign ahead_draw_area_x = (ahead_x_counter < 'd640);
assign ahead_draw_area_y = (ahead_y_counter < 'd480);
assign ahead_draw_area = ahead_draw_area_x & ahead_draw_area_y;

// create the hsync and vsync signals
assign hsync = (x_counter >= 'd656) & (x_counter < 'd757);
assign vsync = (y_counter >= 'd490) & (y_counter < 'd492);
assign draw_area = (x_counter < 'd640) & (y_counter < 'd480);

// hdmi phy
hdmi_phy hdmi_phy_i
(
	.pixel_clk_i(pixel_clk_i),
	.pixel_clk_5x_i(pixel_clk_5x_i),
	.rstn_i(pixel_rstn_i),

	.rgb_i(rgb),

	.hsync(hsync),
	.vsync(vsync),

	.draw_area_i(draw_area),

	// output hdmi channels
	.hdmi_channel_o(hdmi_channel_o)
);

always_ff @(posedge pixel_clk_i, negedge pixel_rstn_i) begin
	if (!pixel_rstn_i) begin
		char_pixel_x_q <= '0;
		char_pixel_y_q <= '0;
	end else begin
		char_pixel_x_q <= char_pixel_x_d;
		char_pixel_y_q <= char_pixel_y_d;
	end
end

// assign wishbone signals
assign fetch_if.cyc = wb_cyc;
assign fetch_if.stb = wb_stb;
assign fetch_if.we = '0;
assign fetch_if.addr = wb_addr_q;
assign fetch_if.sel = '1;
assign fetch_if.wdata = '0;

endmodule: video_core
