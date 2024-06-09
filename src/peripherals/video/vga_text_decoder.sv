// takes in 2 bytes, vga attribute and vga code point
// outputs 24-bit rgb color data

module vga_text_decoder
(
    input clk_i,
    input rstn_i,

    input [15:0] vga_data_i,
    input [2:0] char_pixel_x_i,
    input [3:0] char_pixel_y_i,

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

// TODO: implement

logic bit_one;
assign bit_one = glyph[{~char_pixel_y_i, ~char_pixel_x_i}];

assign rgb_o = bit_one ? 24'hff_ff_ff : '0;

endmodule: vga_text_decoder
