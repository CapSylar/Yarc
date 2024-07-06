module attribute_map (
           input [7:0] attribute_i,
           output logic [23:0] fg_rgb_o,
           output logic [23:0] bg_rgb_o,
           output logic is_blink_o
);

// See https://en.wikipedia.org/wiki/Video_Graphics_Array#Color_palette

assign is_blink_o = attribute_i[7];

assign bg_rgb_o = attribute_i[6:4] == 3'b000 ? 24'h000000
    : attribute_i[6:4] == 3'b001 ? 24'h0000AA
    : attribute_i[6:4] == 3'b010 ? 24'h00AA00
    : attribute_i[6:4] == 3'b011 ? 24'h00AAAA
    : attribute_i[6:4] == 3'b100 ? 24'hAA0000
    : attribute_i[6:4] == 3'b101 ? 24'hAA00AA
    : attribute_i[6:4] == 3'b110 ? 24'hAA5500
    : attribute_i[6:4] == 3'b111 ? 24'hAAAAAA
    : 24'h000000;

assign fg_rgb_o = attribute_i[3:0] == 4'h0 ? 24'h000000
    : attribute_i[3:0] == 4'h1 ? 24'h0000AA
    : attribute_i[3:0] == 4'h2 ? 24'h00AA00
    : attribute_i[3:0] == 4'h3 ? 24'h00AAAA
    : attribute_i[3:0] == 4'h4 ? 24'hAA0000
    : attribute_i[3:0] == 4'h5 ? 24'hAA00AA
    : attribute_i[3:0] == 4'h6 ? 24'hAA5500
    : attribute_i[3:0] == 4'h7 ? 24'hAAAAAA
    : attribute_i[3:0] == 4'h8 ? 24'h555555
    : attribute_i[3:0] == 4'h9 ? 24'h5555FF
    : attribute_i[3:0] == 4'hA ? 24'h55FF55
    : attribute_i[3:0] == 4'hB ? 24'h55FFFF
    : attribute_i[3:0] == 4'hC ? 24'hFF5555
    : attribute_i[3:0] == 4'hD ? 24'hFF55FF
    : attribute_i[3:0] == 4'hE ? 24'hFFFF55
    : attribute_i[3:0] == 4'hF ? 24'hFFFFFF
    : 24'h000000;

endmodule: attribute_map
