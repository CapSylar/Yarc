// contains everything related the implementation of vga text mode

module video_text_mode
#(  parameter unsigned X_COUNTER_INIT_VALUE = 0,
    parameter unsigned Y_COUNTER_INIT_VALUE = 0)
(
    input sys_clk_i,
    input sys_rstn_i,

    input pixel_clk_i,
    input pixel_rstn_i,
	
	input enable_i,
	input frame_pulse_i,

    // interface with fifo adapter
    input adapter_empty_i,
    input [31:0] adapter_rdata_i,
    output logic adapter_re_o,
    output logic adapter_rsize_o,

    output logic [23:0] rgb_o
);

logic read_char, flush_line_buffer;
logic [7:0] char_idx;
logic [15:0] text_mode_data;

/*
	In the normal frambuffer mode, each fetched 4-byte word corresponds to a screen pixel. The pixel
	is popped from the fifo and not needed again for this frame.
	The matter at hand is different in the case of vga text mode, where a fetched glyph dictates the colors
	of several pixels, crossing several lines. In this case, we can't simply pop from the fifo since the data
	will be needed again.

	We devised a small 256 byte line buffer used for storing vga text mode characters after popping them from the fifo.
*/
text_mode_line_buffer text_mode_line_buffer_i
(
	.clk_i(pixel_clk_i),
	.rstn_i(pixel_rstn_i),

	.enable_i(enable_i),

	// fifo interface port
	.empty_i(adapter_empty_i),
	.re_o(adapter_re_o),
	.rdata_i(adapter_rdata_i[15:0]),

	// read port
	.re_i(read_char),
	.pop_line_i(flush_line_buffer),
	.empty_o(),
	.char_idx_i(char_idx),
	.data_o(text_mode_data)
);

assign adapter_rsize_o = '0; // 16-bit reads

// another set of counters that are 2 "pixels" ahead of the other ones
// since we will pipeline the access to the fifo and its computation
// we will use these counters to make things easier
logic [9:0] ahead_x_counter;
logic [9:0] ahead_y_counter;
logic ahead_draw_area_x; // within bounds w.r.t x
logic ahead_draw_area_y; // within bounds w.r.t y
logic ahead_draw_area; // x & y duhh

always_ff @(posedge pixel_clk_i or negedge pixel_rstn_i)
begin
	if (!pixel_rstn_i)
	begin
		ahead_x_counter <= X_COUNTER_INIT_VALUE + 'd2; // 2 pixel ahead
		ahead_y_counter <= Y_COUNTER_INIT_VALUE;
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

// text mode line buffer only needs to be cleared every 7th line in the draw area only
// since we don't to clear the line buffer in the vsync area
assign flush_line_buffer = 	(ahead_x_counter == 'd640) & ((ahead_y_counter == 'd524) | // flush line should happen on the last line in vsync
	(ahead_y_counter[3:0] == 4'hf) // flush every 16th line since characters span 16 lines
	& (ahead_y_counter < 'd479)); // 479 and not 480 because we don't want to flush on the last line of the frame

// read 2 cycles before we actually need something
assign read_char = ahead_draw_area; // read from line buffer only in draw area
assign char_idx = ahead_x_counter[9:3]; // every 8 pixels, change character

logic [2:0] char_pixel_x_d, char_pixel_x_q; // x pixel offset inside glyph
logic [3:0] char_pixel_y_d, char_pixel_y_q; // y pixel offset inside glyph

assign char_pixel_x_d = ahead_x_counter[2:0];
assign char_pixel_y_d = ahead_y_counter[3:0];

always_ff @(posedge pixel_clk_i, negedge pixel_rstn_i) begin
	if (!pixel_rstn_i) begin
		char_pixel_x_q <= '0;
		char_pixel_y_q <= '0;
	end else begin
		char_pixel_x_q <= char_pixel_x_d;
		char_pixel_y_q <= char_pixel_y_d;
	end
end

// outputs the final rgb data for text mode
vga_text_decoder vga_text_decoder_i
(
	.clk_i(pixel_clk_i),
	.rstn_i(pixel_rstn_i),

	.vga_data_i(text_mode_data),
	.char_pixel_x_i(char_pixel_x_q),
	.char_pixel_y_i(char_pixel_y_q),
	
	.frame_pulse_i(frame_pulse_i),

	.rgb_o(rgb_o)
);

endmodule: video_text_mode
