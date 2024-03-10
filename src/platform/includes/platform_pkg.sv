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

// WBUART
// 4 bytes * 4 = 16 bytes
localparam logic [31:0] WBUART_BASE_ADDR =      32'hA000_0020;
localparam logic [31:0] WBUART_MASK =           32'hFFFF_FFF0;

// HDMI CORE
// 2^20 bytes
localparam logic [31:0] HDMI_BASE_ADDR =        32'hA010_0000;
localparam logic [31:0] HDMI_MASK =             32'hFFF0_0000;

localparam NUM_SLAVES = 5;

localparam DMEM_SLAVE_INDEX = 0;
localparam MTIMER_SLAVE_INDEX = 1;
localparam LED_DRIVER_SLAVE_INDEX = 2;
localparam WBUART_SLAVE_INDEX = 3;
localparam HDMI_SLAVE_INDEX = 4;

// make sure the index of the slaves in the following arrays match the indices above
localparam bit [31:0] START_ADDRESS [NUM_SLAVES] = 
    {DMEM_BASE_ADDR, MTIMER_BASE_ADDR, LED_DRIVER_BASE_ADDR, WBUART_BASE_ADDR, HDMI_BASE_ADDR};
localparam bit [31:0] MASK [NUM_SLAVES] = 
    {DMEM_MASK, MTIMER_MASK, LED_DRIVER_MASK, WBUART_MASK, HDMI_MASK};

// wbuart32 config register
typedef struct packed
{
  bit hardware_flow_off; // 1 -> off
  bit [1:0] bits_per_word; // 0 -> 8 bits per word
  bit num_stop_bits; // 0 -> 1 stop bit
  bit parity_used; // 0 -> no parity used
  bit [2:0] parity_settings; // leave at 0 if parity is not used
  bit [23:0] baud_clks; // clocks per baud
} wbuart_conf_t;

localparam wbuart_conf_t WBUART_INITIAL_SETUP = '{
    hardware_flow_off: 1'b1,
    bits_per_word: 2'b0,
    num_stop_bits: 1'b0,
    parity_used: 1'b0,
    parity_settings: 3'b0,
    baud_clks: 24'd694
};
localparam [3:0] WB_UART_LGFLEN = 4;
localparam WB_UART_HW_FLOW_CTR_PR = '0;

endpackage: platform_pkg