
interface fifo_types #(
    parameter unsigned DW = 0,
    parameter unsigned SEL_W = 0,
    parameter unsigned AW = 0
);

typedef struct packed {
    logic [DW-1:0] data;
    logic [SEL_W-1:0] sel;
    logic [AW-1:0] address;
} fifo_line_t;

endinterface: fifo_types
