// Implements pseudo least recently used
`default_nettype none

module plru
#(  parameter unsigned NUM_WAYS = 0,
    
    localparam unsigned AGE_WIDTH = NUM_WAYS - 1,
    localparam unsigned WAY_WIDTH = $clog2(NUM_WAYS))
(
    input wire [AGE_WIDTH-1:0] age_bits_i,
    output logic [AGE_WIDTH-1:0] age_bits_next_o,

    output logic [WAY_WIDTH-1:0] lru_idx_o
);

// TODO: document

logic [$clog2(AGE_WIDTH)-1:0] idx0; // index into the age vector

// determine the LRU way from the age_bits
always_comb begin: plru_get_lru
    idx0 = '0;
    lru_idx_o = '0;

    for (int i = 0; i < WAY_WIDTH; ++i) begin
        if (age_bits_i[idx0]) begin // go right
            idx0 = 2 * idx0 + 2;
        end else begin // go left
            idx0 = 2 * idx0 + 1;
        end
    end

    lru_idx_o = idx0 - (AGE_WIDTH);
end

logic [$clog2(AGE_WIDTH)-1:0] idx1; // index into the age vector

always_comb begin
    idx1 = '0;
    age_bits_next_o = age_bits_i;

    for (int i = 0; i < WAY_WIDTH; ++i) begin

        // flip the nodes we travel through
        age_bits_next_o[idx1] = ~age_bits_next_o[idx1];

        // update index
        idx1 = 2 * idx1 + (age_bits_i[idx1] ? 2 : 1);
    end
end

endmodule: plru
