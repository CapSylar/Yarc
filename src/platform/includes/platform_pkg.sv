package platform_pkg;

localparam MAIN_WB_AW_BYTE = 32; // address is byte addressable

localparam integer MAIN_WB_DW = 32; // wishbone data width
localparam integer UNUSED_BITS = $clog2(MAIN_WB_DW/8); // unused bits due to bus addressable word size > byte
localparam integer MAIN_WB_AW = MAIN_WB_AW_BYTE - UNUSED_BITS; // wishbone address width

// IMEM and DMEM memory parameters
localparam integer DMEM_SIZE_BYTES_POT = 15; // 32KiB
localparam integer IMEM_SIZE_BYTES_POT = 15; // 32KiB

localparam DMEM_SIZE_WORDS_POT = DMEM_SIZE_BYTES_POT - UNUSED_BITS;
localparam IMEM_SIZE_WORDS_POT = IMEM_SIZE_BYTES_POT - UNUSED_BITS;

localparam logic [MAIN_WB_AW-1:0] IMEM_BASE_ADDR =  32'h8000_0000 >> UNUSED_BITS;
localparam logic [MAIN_WB_AW-1:0] IMEM_MASK =       32'hF000_0000 >> UNUSED_BITS;

// The first half of the address space is for memories
localparam logic [MAIN_WB_AW-1:0] DMEM_BASE_ADDR =    32'h9000_0000 >> UNUSED_BITS;
localparam logic [MAIN_WB_AW-1:0] DMEM_MASK =         32'hF000_0000 >> UNUSED_BITS;

// address space for DDR3 RAM (512MiB)
localparam logic [MAIN_WB_AW-1:0] FB_BASE_ADDR =     32'hC000_0000 >> UNUSED_BITS;
localparam logic [MAIN_WB_AW-1:0] FB_MASK =          32'hE000_0000 >> UNUSED_BITS;

localparam logic [MAIN_WB_AW-1:0] PERIPHERALS_BASE_ADDR = 32'hA000_0000 >> UNUSED_BITS;
localparam logic [MAIN_WB_AW-1:0] PERIPHERALS_MASK = 32'hF000_0000 >> UNUSED_BITS;

// the second half for peripherals
// MTIMER
// 8 bytes for mtimer and 8 bytes for mtimecmp
localparam logic [MAIN_WB_AW-1:0] MTIMER_BASE_ADDR =  32'hA000_0000 >> UNUSED_BITS;
localparam logic [MAIN_WB_AW-1:0] MTIMER_MASK =       32'hFFFF_FFF0 >> UNUSED_BITS;

// LED DRIVER
// 4 bytes
localparam logic [MAIN_WB_AW-1:0] LED_DRIVER_BASE_ADDR =  32'hA000_0010 >> UNUSED_BITS;
localparam logic [MAIN_WB_AW-1:0] LED_DRIVER_MASK =       32'hFFFF_FFFC >> UNUSED_BITS;

// WBUART
// 4 bytes * 4 = 16 bytes
localparam logic [MAIN_WB_AW-1:0] WBUART_BASE_ADDR =      32'hA000_0020 >> UNUSED_BITS;
localparam logic [MAIN_WB_AW-1:0] WBUART_MASK =           32'hFFFF_FFF0 >> UNUSED_BITS;

// VIDEO CORE
// 4 bytes * 8 = 32 bytes
localparam logic [MAIN_WB_AW-1:0] VIDEO_BASE_ADDR =        32'hA000_0040 >> UNUSED_BITS;
localparam logic [MAIN_WB_AW-1:0] VIDEO_MASK =             32'hFFFF_FFE0 >> UNUSED_BITS;

// Main Wbxbar (cpu(fetch and data interfaces) and video core with memories)
localparam MAIN_XBAR_NUM_MASTERS = 2;
localparam MAIN_XBAR_NUM_SLAVES = 4; // 2 memories + 2 ports to other interconnects

// master indices
localparam MAIN_XBAR_FETCH_MASTER_IDX = 0;
localparam MAIN_XBAR_LSU_MASTER_IDX = 1;

// slave indices
localparam MAIN_XBAR_IMEM_SLAVE_IDX = 0;
localparam MAIN_XBAR_DMEM_SLAVE_IDX =  1;
localparam MAIN_XBAR_FB_SLAVE_IDX = 2; // this is an interconnect
localparam MAIN_XBAR_PERIPHERAL_SLAVE_IDX = 3; // this is an interconnect

localparam bit [MAIN_WB_AW*MAIN_XBAR_NUM_SLAVES-1:0] MAIN_XBAR_BASE_ADDRESSES = 
    {PERIPHERALS_BASE_ADDR, FB_BASE_ADDR, DMEM_BASE_ADDR, IMEM_BASE_ADDR};
localparam bit [MAIN_WB_AW*MAIN_XBAR_NUM_SLAVES-1:0] MAIN_XBAR_MASKS = 
    {PERIPHERALS_MASK, FB_MASK, DMEM_MASK, IMEM_MASK};

localparam MAIN_XBAR_LGMAXBURST = 6;
localparam MAIN_XBAR_OPT_TIMEOUT = 0;
localparam MAIN_XBAR_OPT_DBLBUFFER = 0;
localparam MAIN_XBAR_OPT_LOWPOWER = 0;

// secondary Wbxbar (master port coming from the main wbxbar + video)
localparam SEC_WB_AW = ddr3_parameters_pkg::wb_addr_bits;
localparam SEC_WB_DW = ddr3_parameters_pkg::wb_data_bits;

localparam SEC_XBAR_NUM_MASTERS = 2;
localparam SEC_XBAR_NUM_SLAVES = 1;

// master indices
localparam SEC_XBAR_VIDEO_MASTER_IDX = 0;
localparam SEC_XBAR_CPU_MASTER_IDX = 1;

// slave indices
localparam SEC_XBAR_FB_SLAVE_IDX = 0;

// make sure the index of the slaves in the following arrays match the indices above
localparam bit [SEC_WB_AW*SEC_XBAR_NUM_SLAVES-1:0] SEC_XBAR_BASE_ADDRESSES = {'0};
localparam bit [SEC_WB_AW*SEC_XBAR_NUM_SLAVES-1:0] SEC_XBAR_MASKS = {'0};

localparam SEC_XBAR_LGMAXBURST = 6;
localparam SEC_XBAR_OPT_TIMEOUT = 0;
localparam SEC_XBAR_OPT_DBLBUFFER = 0;
localparam SEC_XBAR_OPT_LOWPOWER = 0;

// Peripheral Interconnect
localparam PERIPH_WB_AW = MAIN_WB_AW;
localparam PERIPH_WB_DW = MAIN_WB_DW;

localparam PERIPH_XBAR_NUM_MASTERS = 1;
localparam PERIPH_XBAR_NUM_SLAVES = 4;

localparam PERIPH_XBAR_MTIMER_SLAVE_IDX = 0;
localparam PERIPH_XBAR_LED_DRIVER_SLAVE_IDX = 1;
localparam PERIPH_XBAR_WBUART_SLAVE_IDX = 2;
localparam PERIPH_XBAR_VIDEO_SLAVE_IDX = 3;

// make sure the index of the slaves in the following arrays match the indices above
localparam bit [PERIPH_WB_AW*PERIPH_XBAR_NUM_SLAVES-1:0] PERIPH_XBAR_BASE_ADDRESSES = 
    {VIDEO_BASE_ADDR, WBUART_BASE_ADDR, LED_DRIVER_BASE_ADDR, MTIMER_BASE_ADDR};
localparam bit [PERIPH_WB_AW*PERIPH_XBAR_NUM_SLAVES-1:0] PERIPH_XBAR_MASKS = 
    {VIDEO_MASK, WBUART_MASK, LED_DRIVER_MASK, MTIMER_MASK};

localparam PERIPH_XBAR_LGMAXBURST = 6;
localparam PERIPH_XBAR_OPT_TIMEOUT = 0;
localparam PERIPH_XBAR_OPT_DBLBUFFER = 0;
localparam PERIPH_XBAR_OPT_LOWPOWER = 0;

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

localparam CLK_FREQUENCY = 83 * 1000_000; // 80Mhz
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
