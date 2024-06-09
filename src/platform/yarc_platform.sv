
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
    wishbone_if.MASTER instr_fetch_wb_if,

    // Platform <-> Framebuffer memory
    wishbone_if.MASTER fb_wb_if,

    // Platform <-> Peripherals
    output logic [7:0] led_status_o,

    // uart lines
    input logic uart_rx_i,
    output logic uart_tx_o,

    input pixel_clk_i,
    input pixel_clk_5x_i,

    // hdmi lines
	output logic [3:0] hdmi_channel_o
);

wishbone_if #(.ADDRESS_WIDTH(MAIN_WB_AW), .DATA_WIDTH(MAIN_WB_DW)) lsu_wb_if();

// Wb interconnect
wishbone_if #(.ADDRESS_WIDTH(MAIN_WB_AW), .DATA_WIDTH(MAIN_WB_DW)) slave_wb_if [MAIN_XBAR_NUM_SLAVES]();

main_xbar main_xbar_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    .master_wb_if(lsu_wb_if),
    .slave_wb_if(slave_wb_if)
);

// dmem
// assign signals to dmem_wb
assign dmem_wb_if.cyc = slave_wb_if[MAIN_XBAR_DMEM_SLAVE_IDX].cyc;
assign dmem_wb_if.stb = slave_wb_if[MAIN_XBAR_DMEM_SLAVE_IDX].stb;
assign dmem_wb_if.we = slave_wb_if[MAIN_XBAR_DMEM_SLAVE_IDX].we;
assign dmem_wb_if.addr = slave_wb_if[MAIN_XBAR_DMEM_SLAVE_IDX].addr;
assign dmem_wb_if.sel = slave_wb_if[MAIN_XBAR_DMEM_SLAVE_IDX].sel;
assign dmem_wb_if.wdata = slave_wb_if[MAIN_XBAR_DMEM_SLAVE_IDX].wdata;

assign slave_wb_if[MAIN_XBAR_DMEM_SLAVE_IDX].rdata = dmem_wb_if.rdata;
assign slave_wb_if[MAIN_XBAR_DMEM_SLAVE_IDX].rty = dmem_wb_if.rty;
assign slave_wb_if[MAIN_XBAR_DMEM_SLAVE_IDX].ack = dmem_wb_if.ack;
assign slave_wb_if[MAIN_XBAR_DMEM_SLAVE_IDX].stall = dmem_wb_if.stall;
assign slave_wb_if[MAIN_XBAR_DMEM_SLAVE_IDX].err = dmem_wb_if.err;

// interrupt lines
logic irq_timer;
logic irq_external = '0;

// mtimer
mtimer mtimer_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    .wb_if(slave_wb_if[MAIN_XBAR_MTIMER_SLAVE_IDX]),

    .timer_int_o(irq_timer)
);

// led driver
led_driver led_driver_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    .wb_if(slave_wb_if[MAIN_XBAR_LED_DRIVER_SLAVE_IDX]),
    
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
    .i_wb_cyc(slave_wb_if[MAIN_XBAR_WBUART_SLAVE_IDX].cyc),
    .i_wb_stb(slave_wb_if[MAIN_XBAR_WBUART_SLAVE_IDX].stb),
    .i_wb_we(slave_wb_if[MAIN_XBAR_WBUART_SLAVE_IDX].we),
    .i_wb_addr(slave_wb_if[MAIN_XBAR_WBUART_SLAVE_IDX].addr[1:0]),
    .i_wb_data(slave_wb_if[MAIN_XBAR_WBUART_SLAVE_IDX].wdata),
    .i_wb_sel(slave_wb_if[MAIN_XBAR_WBUART_SLAVE_IDX].sel),
    
    .o_wb_stall(slave_wb_if[MAIN_XBAR_WBUART_SLAVE_IDX].stall),
    .o_wb_ack(slave_wb_if[MAIN_XBAR_WBUART_SLAVE_IDX].ack),
    .o_wb_data(slave_wb_if[MAIN_XBAR_WBUART_SLAVE_IDX].rdata),

    // uart connections
    .i_uart_rx(uart_rx_i),
    .o_uart_tx(uart_tx_o),
    .i_cts_n(),
    .o_rts_n(),

    // uart interrupts
    .o_uart_rx_int(uart_rx_int),
    .o_uart_tx_int(uart_tx_int),
    .o_uart_rxfifo_int(uart_rxfifo_int),
    .o_uart_txfifo_int(uart_txfifo_int)
);
// zero out the rest of the control lines
assign slave_wb_if[MAIN_XBAR_WBUART_SLAVE_IDX].err = '0;
assign slave_wb_if[MAIN_XBAR_WBUART_SLAVE_IDX].rty = '0;

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
    .pixel_clk_5x_i(pixel_clk_5x_i),

    .config_if(slave_wb_if[MAIN_XBAR_VIDEO_SLAVE_IDX]),
    .fetch_if(video_fb_wb_if),

    .hdmi_channel_o(hdmi_channel_o)
);

sec_xbar sec_xbar_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    .cpu_wb_if(slave_wb_if[MAIN_XBAR_FB_SLAVE_IDX]),
    .video_wb_if(video_fb_wb_if),

    .slave_wb_if(sec_xbar_slaves_if)
);

// fb interface signals (can't assign interfaces in sv yet :( )
assign fb_wb_if.cyc = sec_xbar_slaves_if[SEC_XBAR_FB_SLAVE_IDX].cyc;
assign fb_wb_if.stb = sec_xbar_slaves_if[SEC_XBAR_FB_SLAVE_IDX].stb;
assign fb_wb_if.we = sec_xbar_slaves_if[SEC_XBAR_FB_SLAVE_IDX].we;
assign fb_wb_if.addr = sec_xbar_slaves_if[SEC_XBAR_FB_SLAVE_IDX].addr;
assign fb_wb_if.sel = sec_xbar_slaves_if[SEC_XBAR_FB_SLAVE_IDX].sel;
assign fb_wb_if.wdata = sec_xbar_slaves_if[SEC_XBAR_FB_SLAVE_IDX].wdata;
assign sec_xbar_slaves_if[SEC_XBAR_FB_SLAVE_IDX].rdata = fb_wb_if.rdata;
assign sec_xbar_slaves_if[SEC_XBAR_FB_SLAVE_IDX].rty = fb_wb_if.rty;
assign sec_xbar_slaves_if[SEC_XBAR_FB_SLAVE_IDX].ack = fb_wb_if.ack;
assign sec_xbar_slaves_if[SEC_XBAR_FB_SLAVE_IDX].stall = fb_wb_if.stall;
assign sec_xbar_slaves_if[SEC_XBAR_FB_SLAVE_IDX].err = fb_wb_if.err;

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
