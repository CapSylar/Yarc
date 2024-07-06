// takes in 2 bytes, vga attribute and vga code point
// outputs 24-bit rgb color data

module vga_text_decoder
(
    input clk_i,
    input rstn_i,

    input [15:0] vga_data_i,
    input [2:0] char_pixel_x_i,
    input [3:0] char_pixel_y_i,

    input frame_pulse_i, // a signal that goes high for one cycle once per frame

    output logic [23:0] rgb_o
);

logic [7:0] attribute;
logic [7:0] codepoint;

assign {attribute, codepoint} = vga_data_i;

// 16x8 vga text mode character = 128 bits for a single glyph
logic [127:0] glyph; 
glyphmap glyphmap_i
(
    .codepoint_i(codepoint),
    .glyph_o(glyph)
);

logic [23:0] fg_rgb, bg_rgb; // foreground and background
logic is_blink;
logic bit_one;

attribute_map attribute_map_i
(
    .attribute_i(attribute),
    .fg_rgb_o(fg_rgb),
    .bg_rgb_o(bg_rgb),
    .is_blink_o(is_blink)
);

logic [5:0] blink_counter_q;
// blink counter

always_ff @(posedge clk_i, negedge rstn_i) begin
    if (!rstn_i) begin
        blink_counter_q <= '0;
    end else if (frame_pulse_i)
        blink_counter_q <= blink_counter_q + 1'b1;
end

assign show_fg = ~is_blink | is_blink & blink_counter_q[5];
assign bit_one = glyph[{~char_pixel_y_i, ~char_pixel_x_i}];

logic [23:0] rgb_d, rgb_q;
assign rgb_d = (bit_one & show_fg) ? fg_rgb : bg_rgb;

always_ff @(posedge clk_i) begin
    rgb_q <= rgb_d;
end

assign rgb_o = rgb_q;

endmodule: vga_text_decoder
