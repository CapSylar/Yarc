package platform_pkg;

// The first half of the address space is for memories
localparam logic [31:0] DMEM_BASE_ADDR =    32'h8000_0000;
localparam logic [31:0] DMEM_MASK =         32'hF000_0000;

// the second half for peripherals
// MTIMER
// 8 bytes for mtimer and 8 bytes for mtimecmp
localparam logic [31:0] MTIMER_BASE_ADDR =  32'hA000_0000;
localparam logic [31:0] MTIMER_MASK =       32'hFFFF_FFF0;

// LED DRIVER
// 4 bytes
localparam logic [31:0] LED_DRIVER_BASE_ADDR =  32'hA000_0010;
localparam logic [31:0] LED_DRIVER_MASK =       32'hFFFF_FFFC;

localparam NUM_SLAVES = 3;

localparam DMEM_SLAVE_INDEX = 0;
localparam MTIMER_SLAVE_INDEX = 1;
localparam LED_DRIVER_SLAVE_INDEX = 2;

// make sure the index of the slaves in the following arrays match the indices above
localparam bit [31:0] START_ADDRESS [NUM_SLAVES] = 
    {DMEM_BASE_ADDR, MTIMER_BASE_ADDR, LED_DRIVER_BASE_ADDR};
localparam bit [31:0] MASK [NUM_SLAVES] = 
    {DMEM_MASK, MTIMER_MASK, LED_DRIVER_MASK};

endpackage: platform_pkg