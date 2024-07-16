
/*
    __   __                    ______  _         _     __                         
    \ \ / /                    | ___ \| |       | |   / _|                        
     \ V /   __ _  _ __   ___  | |_/ /| |  __ _ | |_ | |_   ___   _ __  _ __ ___  
      \ /   / _` || '__| / __| |  __/ | | / _` || __||  _| / _ \ | '__|| '_ ` _ \ 
      | |  | (_| || |   | (__  | |    | || (_| || |_ | |  | (_) || |   | | | | | |
      \_/   \__,_||_|    \___| \_|    |_| \__,_| \__||_|   \___/ |_|   |_| |_| |_|

      - contains:
        - core
        - mtimer
*/                                                                                  

module yarc_platform
import platform_pkg::*;
(
    input clk_i,
    input rstn_i,

    // Platform <-> DMEM
    wishbone_if.MASTER dmem_wb_if,

    // Platform <-> IMEM
    wishbone_if.MASTER imem_wb_if,
    wishbone_if.MASTER imem_rw_wb_if,

    // Platform <-> Framebuffer memory
    wishbone_if.MASTER fb_wb_if,

    // Platform <-> Peripherals
    output logic [7:0] led_status_o,

    // uart lines
    input logic uart_rx_i,
    output logic uart_tx_o,

    input pixel_clk_i,
    input pixel_rstn_i,
    input pixel_clk_5x_i,

    // hdmi lines
	output logic [3:0] hdmi_channel_o
);

wishbone_if #(.ADDRESS_WIDTH(MAIN_WB_AW), .DATA_WIDTH(MAIN_WB_DW)) lsu_wb_if();
wishbone_if #(.ADDRESS_WIDTH(MAIN_WB_AW), .DATA_WIDTH(MAIN_WB_DW)) instr_fetch_wb_if();
wishbone_if #(.ADDRESS_WIDTH(MAIN_WB_AW), .DATA_WIDTH(MAIN_WB_DW)) icache_wb_if();

// fetch side interconnect
fetch_intercon fetch_intercon_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    .cpu_fetch_if(instr_fetch_wb_if),

    .iccm_if(imem_wb_if),

    .icache_if(icache_wb_if)
);

wishbone_if #(.ADDRESS_WIDTH(SEC_WB_AW), .DATA_WIDTH(SEC_WB_DW)) mem_instr_cache_wb_if();
// Instruction Cache for DDR3 Memory
instruction_cache #(.NUM_SETS_LOG2(9)) // 512 sets => 1024 cache lines
instruction_cache_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    .cpu_if(icache_wb_if),

    .mem_if(mem_instr_cache_wb_if)
);

// Main wbxbar slaves
wishbone_if #(.ADDRESS_WIDTH(MAIN_WB_AW), .DATA_WIDTH(MAIN_WB_DW)) main_slave_wb_if [MAIN_XBAR_NUM_SLAVES]();

main_xbar main_xbar_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    // masters
    .lsu_wb_if(lsu_wb_if),
    // .instr_fetch_wb_if(instr_fetch_wb_if),

    // slaves
    .slave_wb_if(main_slave_wb_if)
);

// dmem
wb_connect dmem_connect (.wb_if_i(main_slave_wb_if[MAIN_XBAR_DMEM_SLAVE_IDX]), .wb_if_o(dmem_wb_if));

// imem
wb_connect imem_connect (.wb_if_i(main_slave_wb_if[MAIN_XBAR_IMEM_SLAVE_IDX]), .wb_if_o(imem_rw_wb_if));

// Peripheral wxbar
wishbone_if #(.ADDRESS_WIDTH(PERIPH_WB_AW), .DATA_WIDTH(PERIPH_WB_DW)) periph_slave_wb_if [PERIPH_XBAR_NUM_SLAVES]();

periph_xbar periph_xbar_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    .master_wb_if(main_slave_wb_if[MAIN_XBAR_PERIPHERAL_SLAVE_IDX]),
    .slave_wb_if(periph_slave_wb_if)
);

// interrupt lines
logic irq_timer;
logic irq_external = '0;

// mtimer
mtimer mtimer_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    .wb_if(periph_slave_wb_if[PERIPH_XBAR_MTIMER_SLAVE_IDX]),

    .timer_int_o(irq_timer)
);

// led driver
led_driver led_driver_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    .wb_if(periph_slave_wb_if[PERIPH_XBAR_LED_DRIVER_SLAVE_IDX]),
    
    .led_status_o(led_status_o)
);

logic uart_rx_int, uart_tx_int;
logic uart_rxfifo_int, uart_txfifo_int;

// wb_uart32
wbuart 
#(.INITIAL_SETUP(WBUART_INITIAL_SETUP),
  .LGFLEN(WB_UART_LGFLEN),
  .HARDWARE_FLOW_CONTROL_PRESENT(WB_UART_HW_FLOW_CTR_PR))
wbuart_i
(
    .i_clk(clk_i),
    .i_reset(~rstn_i),

    // wishbone connections
    .i_wb_cyc(periph_slave_wb_if[PERIPH_XBAR_WBUART_SLAVE_IDX].cyc),
    .i_wb_stb(periph_slave_wb_if[PERIPH_XBAR_WBUART_SLAVE_IDX].stb),
    .i_wb_we(periph_slave_wb_if[PERIPH_XBAR_WBUART_SLAVE_IDX].we),
    .i_wb_addr(periph_slave_wb_if[PERIPH_XBAR_WBUART_SLAVE_IDX].addr[1:0]),
    .i_wb_data(periph_slave_wb_if[PERIPH_XBAR_WBUART_SLAVE_IDX].wdata),
    .i_wb_sel(periph_slave_wb_if[PERIPH_XBAR_WBUART_SLAVE_IDX].sel),
    
    .o_wb_stall(periph_slave_wb_if[PERIPH_XBAR_WBUART_SLAVE_IDX].stall),
    .o_wb_ack(periph_slave_wb_if[PERIPH_XBAR_WBUART_SLAVE_IDX].ack),
    .o_wb_data(periph_slave_wb_if[PERIPH_XBAR_WBUART_SLAVE_IDX].rdata),

    // uart connections
    .i_uart_rx(uart_rx_i),
    .o_uart_tx(uart_tx_o),
    .i_cts_n('0),
    .o_rts_n(),

    // uart interrupts
    .o_uart_rx_int(uart_rx_int),
    .o_uart_tx_int(uart_tx_int),
    .o_uart_rxfifo_int(uart_rxfifo_int),
    .o_uart_txfifo_int(uart_txfifo_int)
);
// zero out the rest of the control lines
assign periph_slave_wb_if[PERIPH_XBAR_WBUART_SLAVE_IDX].err = '0;
assign periph_slave_wb_if[PERIPH_XBAR_WBUART_SLAVE_IDX].rty = '0;

wishbone_if #(.ADDRESS_WIDTH(SEC_WB_AW), .DATA_WIDTH(SEC_WB_DW)) video_fb_wb_if();
wishbone_if #(.ADDRESS_WIDTH(SEC_WB_AW), .DATA_WIDTH(SEC_WB_DW)) cpu_fb_wb_if();
wishbone_if #(.ADDRESS_WIDTH(SEC_WB_AW), .DATA_WIDTH(SEC_WB_DW)) sec_xbar_slaves_if[SEC_XBAR_NUM_SLAVES]();

video_core
#(
)
video_core_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    .pixel_clk_i(pixel_clk_i),
    .pixel_rstn_i(pixel_rstn_i),
    .pixel_clk_5x_i(pixel_clk_5x_i),

    .config_if(periph_slave_wb_if[PERIPH_XBAR_VIDEO_SLAVE_IDX]),
    .fetch_if(video_fb_wb_if),

    .hdmi_channel_o(hdmi_channel_o)
);

sec_xbar sec_xbar_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    .cpu_wb_if(main_slave_wb_if[MAIN_XBAR_FB_SLAVE_IDX]),
    .video_wb_if(video_fb_wb_if),
    .instr_cache_wb_if(mem_instr_cache_wb_if),

    .slave_wb_if(sec_xbar_slaves_if)
);

wb_connect fb_connect (.wb_if_i(sec_xbar_slaves_if[SEC_XBAR_FB_SLAVE_IDX]), .wb_if_o(fb_wb_if));

// Core Top
core_top core_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    // Core WB LSU Interface
    .lsu_wb_if(lsu_wb_if),
    // Core WB Instruction Fetch interface
    .instr_fetch_wb_if(instr_fetch_wb_if),

    // interrupts
    .irq_timer_i(irq_timer),
    .irq_external_i('0)
);

endmodule: yarc_platform
