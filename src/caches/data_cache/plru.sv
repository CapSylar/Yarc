// Implements pseudo least recently used
// Pure combinational module
`default_nettype none

module plru
#(  parameter unsigned NUM_WAYS = 0,
    
    localparam unsigned AGE_WIDTH = NUM_WAYS - 1,
    localparam unsigned WAY_WIDTH = $clog2(NUM_WAYS))
(
    input wire [AGE_WIDTH-1:0] age_bits_i,
    input wire [WAY_WIDTH-1:0] access_idx_i,

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
logic [$clog2(AGE_WIDTH):0] old_idx1; // index into the age vector

// calculate the next state according to what way was currently accessed
always_comb begin
    old_idx1 = access_idx_i + (AGE_WIDTH);
    idx1 = (old_idx1-1) / 2; // TODO: document

    age_bits_next_o = age_bits_i;

    for (int i = 0; i < WAY_WIDTH; ++i) begin

        /*
            * If index is odd -> we are the left subchild and we want
            * to set the parent to point right
            * so simply assign
        */
        age_bits_next_o[idx1] = old_idx1[0];

        // update indices to travel up the tree
        old_idx1 = idx1;
        idx1 = (idx1-1) / 2;
    end
end

endmodule: plru
