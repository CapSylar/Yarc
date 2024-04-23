package platform_pkg;

localparam BYTE_ADDRESS_WIDTH = 32;
localparam integer DATA_WIDTH = 32;

localparam integer UNUSED_BITS = $clog2(DATA_WIDTH/8); // unused bits due to bus addressable word size > byte
localparam integer WB_AW = BYTE_ADDRESS_WIDTH - UNUSED_BITS; // wishbone address width
localparam integer WB_DW = DATA_WIDTH; // wishbone data width

// IMEM and DMEM memory parameters
localparam integer DMEM_SIZE_BYTES_POT = 15; // 32KiB
localparam integer IMEM_SIZE_BYTES_POT = 15; // 32KiB

localparam DMEM_SIZE_WORDS_POT = DMEM_SIZE_BYTES_POT - UNUSED_BITS;
localparam IMEM_SIZE_WORDS_POT = IMEM_SIZE_BYTES_POT - UNUSED_BITS;

// The first half of the address space is for memories
localparam logic [WB_AW-1:0] DMEM_BASE_ADDR =    32'h9000_0000 >> UNUSED_BITS;
localparam logic [WB_AW-1:0] DMEM_MASK =         32'hF000_0000 >> UNUSED_BITS;

// address space for DDR3 RAM (512MiB)
localparam logic [WB_AW-1:0] DDR3_BASE_ADDR =     32'hC000_0000 >> UNUSED_BITS;
localparam logic [WB_AW-1:0] DDR3_MASK =          32'hE000_0000 >> UNUSED_BITS;

// the second half for peripherals
// MTIMER
// 8 bytes for mtimer and 8 bytes for mtimecmp
localparam logic [WB_AW-1:0] MTIMER_BASE_ADDR =  32'hA000_0000 >> UNUSED_BITS;
localparam logic [WB_AW-1:0] MTIMER_MASK =       32'hFFFF_FFF0 >> UNUSED_BITS;

// LED DRIVER
// 4 bytes
localparam logic [WB_AW-1:0] LED_DRIVER_BASE_ADDR =  32'hA000_0010 >> UNUSED_BITS;
localparam logic [WB_AW-1:0] LED_DRIVER_MASK =       32'hFFFF_FFFC >> UNUSED_BITS;

// WBUART
// 4 bytes * 4 = 16 bytes
localparam logic [WB_AW-1:0] WBUART_BASE_ADDR =      32'hA000_0020 >> UNUSED_BITS;
localparam logic [WB_AW-1:0] WBUART_MASK =           32'hFFFF_FFF0 >> UNUSED_BITS;

// HDMI CORE
// 2^20 bytes
localparam logic [WB_AW-1:0] HDMI_BASE_ADDR =        32'hA010_0000 >> UNUSED_BITS;
localparam logic [WB_AW-1:0] HDMI_MASK =             32'hFFF0_0000 >> UNUSED_BITS;

localparam NUM_SLAVES = 5;

localparam DMEM_SLAVE_INDEX = 0;
localparam DDR3_SLAVE_INDEX = 1;
localparam MTIMER_SLAVE_INDEX = 2;
localparam LED_DRIVER_SLAVE_INDEX = 3;
localparam WBUART_SLAVE_INDEX = 4;

// make sure the index of the slaves in the following arrays match the indices above
localparam bit [WB_AW*NUM_SLAVES-1:0] START_ADDRESSES = 
    {WBUART_BASE_ADDR, LED_DRIVER_BASE_ADDR, MTIMER_BASE_ADDR, DDR3_BASE_ADDR, DMEM_BASE_ADDR};
localparam bit [WB_AW*NUM_SLAVES-1:0] MASKS = 
    {WBUART_MASK, LED_DRIVER_MASK, MTIMER_MASK, DDR3_MASK, DMEM_MASK};

// wbuart32 config register
typedef struct packed
{
  bit hardware_flow_off; // 1 -> off
  bit [1:0] bits_per_word; // 0 -> 8 bits per word
  bit num_stop_bits; // 0 -> 1 stop bit
  bit parity_used; // 0 -> no parity used
  bit [1:0] parity_settings; // leave at 0 if parity is not used
  bit [23:0] baud_clks; // clocks per baud
} wbuart_conf_t;

localparam CLK_FREQUENCY = 80 * 1000_000; // 80Mhz
localparam UART_BAUD_RATE = 921600; // Baud per second
localparam [23:0] CLKS_PER_BAUD = CLK_FREQUENCY / UART_BAUD_RATE;

localparam wbuart_conf_t WBUART_INITIAL_SETUP = '{
    hardware_flow_off: 1'b1,
    bits_per_word: 2'b0,
    num_stop_bits: 1'b0,
    parity_used: 1'b0,
    parity_settings: 2'b0,
    baud_clks: CLKS_PER_BAUD
};
localparam [3:0] WB_UART_LGFLEN = 4;
localparam WB_UART_HW_FLOW_CTR_PR = '0;

endpackage: platform_pkg
