package platform_pkg;

// The first half of the address space is for memories
localparam logic [31:0] DMEM_BASE_ADDR =    32'h9000_0000;
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

endpackage: platform_pkg