
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

    // Platform <-> Peripherals
    output logic [7:0] led_status_o,

    // uart lines
    input logic uart_rx_i,
    output logic uart_tx_o,

    input pixel_clk_i,
    input pixel_clk_5x_i,
    // hdmi lines
	output hdmi_tx_clk_n_o,
	output hdmi_tx_clk_p_o,
	output [2:0] hdmi_tx_n_o,
	output [2:0] hdmi_tx_p_o
);

wishbone_if lsu_wb_if();

// Wb interconnect
wishbone_if slave_wb_if [NUM_SLAVES]();

wb_interconnect
#(.NUM_SLAVES(NUM_SLAVES), .START_ADDRESS(START_ADDRESS), .MASK(MASK))
wb_interconnect_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    // interconnect <-> Master
    .intercon_if(lsu_wb_if),
    // interconnect <-> Slaves
    .wb_if(slave_wb_if)
);

// dmem
// assign signals to dmem_wb
assign dmem_wb_if.cyc = slave_wb_if[DMEM_SLAVE_INDEX].cyc;
assign dmem_wb_if.stb = slave_wb_if[DMEM_SLAVE_INDEX].stb;
assign dmem_wb_if.lock = slave_wb_if[DMEM_SLAVE_INDEX].lock;
assign dmem_wb_if.we = slave_wb_if[DMEM_SLAVE_INDEX].we;
assign dmem_wb_if.addr = slave_wb_if[DMEM_SLAVE_INDEX].addr;
assign dmem_wb_if.sel = slave_wb_if[DMEM_SLAVE_INDEX].sel;
assign dmem_wb_if.wdata = slave_wb_if[DMEM_SLAVE_INDEX].wdata;

assign slave_wb_if[DMEM_SLAVE_INDEX].rdata = dmem_wb_if.rdata;
assign slave_wb_if[DMEM_SLAVE_INDEX].rty = dmem_wb_if.rty;
assign slave_wb_if[DMEM_SLAVE_INDEX].ack = dmem_wb_if.ack;
assign slave_wb_if[DMEM_SLAVE_INDEX].stall = dmem_wb_if.stall;
assign slave_wb_if[DMEM_SLAVE_INDEX].err = dmem_wb_if.err;

// interrupt lines
logic irq_timer;
logic irq_external;
assign irq_external = '0;

// mtimer
mtimer mtimer_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    .wb_if(slave_wb_if[MTIMER_SLAVE_INDEX]),

    .timer_int_o(irq_timer)
);

// led driver
led_driver led_driver_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    .wb_if(slave_wb_if[LED_DRIVER_SLAVE_INDEX]),
    
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
    .i_wb_cyc(slave_wb_if[WBUART_SLAVE_INDEX].cyc),
    .i_wb_stb(slave_wb_if[WBUART_SLAVE_INDEX].stb),
    .i_wb_we(slave_wb_if[WBUART_SLAVE_INDEX].we),
    .i_wb_addr(slave_wb_if[WBUART_SLAVE_INDEX].addr[3:2]),
    .i_wb_data(slave_wb_if[WBUART_SLAVE_INDEX].wdata),
    .i_wb_sel(slave_wb_if[WBUART_SLAVE_INDEX].sel),
    
    .o_wb_stall(slave_wb_if[WBUART_SLAVE_INDEX].stall),
    .o_wb_ack(slave_wb_if[WBUART_SLAVE_INDEX].ack),
    .o_wb_data(slave_wb_if[WBUART_SLAVE_INDEX].rdata),

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
assign slave_wb_if[WBUART_SLAVE_INDEX].err = '0;
assign slave_wb_if[WBUART_SLAVE_INDEX].rty = '0;

// hdmi frambuffer + hdmi video driver
hdmi_core
#()
hdmi_core_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    .pixel_clk_i(pixel_clk_i),
    .pixel_clk_5x_i(pixel_clk_5x_i),

    .wb_if(slave_wb_if[HDMI_SLAVE_INDEX]),

    .hdmi_tx_clk_n_o(hdmi_tx_clk_n_o),
    .hdmi_tx_clk_p_o(hdmi_tx_clk_p_o),
    .hdmi_tx_n_o(hdmi_tx_n_o),
    .hdmi_tx_p_o(hdmi_tx_p_o)
);

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