
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

    // Platform <-> DDR3
    wishbone_if.MASTER ddr3_wb_if,

    // Platform <-> Peripherals
    output logic [7:0] led_status_o,

    // uart lines
    input logic uart_rx_i,
    output logic uart_tx_o

    // input pixel_clk_i,
    // input pixel_clk_5x_i

    // hdmi lines
	// output logic hdmi_clk_o,
	// output logic [2:0] hdmi_data_o
);

wishbone_if lsu_wb_if();

// Wb interconnect
wishbone_if slave_wb_if [NUM_SLAVES]();

localparam NUM_MASTERS = 1;

// master interconnect lines
logic [NUM_MASTERS-1:0] mcyc, mstb, mwe;
logic [NUM_MASTERS*WB_AW-1:0] maddr;
logic [NUM_MASTERS*WB_DW-1:0] mdata_o;
logic [NUM_MASTERS*WB_DW/8-1:0] msel;
logic [NUM_MASTERS-1:0] mstall, mack, merr;
logic [NUM_MASTERS*WB_DW-1:0] mdata_i;

// slave interconnect lines
logic [NUM_SLAVES-1:0] scyc, sstb, swe;
logic [NUM_SLAVES*WB_AW-1:0] saddr;
logic [NUM_SLAVES*WB_DW-1:0] sdata_i;
logic [NUM_SLAVES*WB_DW/8-1:0] ssel;
logic [NUM_SLAVES-1:0] sstall, sack, serr;
logic [NUM_SLAVES*WB_DW-1:0] sdata_o;

// Zipcpu wishbone crossbar
wbxbar
#(.NM(NUM_MASTERS), .NS(NUM_SLAVES), .AW(WB_AW), .DW(WB_DW),
    .SLAVE_ADDR(START_ADDRESSES), .SLAVE_MASK(MASKS),
    .LGMAXBURST(6), .OPT_TIMEOUT(0),
    .OPT_DBLBUFFER(0), .OPT_LOWPOWER(0))
wbxbar_i
(
    .i_clk(clk_i),
    .i_reset(~rstn_i),

    // master bus inputs
    .i_mcyc(mcyc),
    .i_mstb(mstb),
    .i_mwe(mwe),
    .i_maddr(maddr),
    .i_mdata(mdata_o),
    .i_msel(msel),

    // master return data
    .o_mstall(mstall),
    .o_mack(mack),
    .o_mdata(mdata_i),
    .o_merr(merr),

    .o_scyc(scyc),
    .o_sstb(sstb),
    .o_swe(swe),
    .o_saddr(saddr),
    .o_sdata(sdata_i),
    .o_ssel(ssel),

    // slave return data
    .i_sstall(sstall),
    .i_sack(sack),
    .i_sdata(sdata_o),
    .i_serr(serr)
);

// connect the master wire side to the systemverilog interfaces
assign mcyc = lsu_wb_if.cyc;
assign mstb = lsu_wb_if.stb;
assign mwe = lsu_wb_if.we;
assign maddr = lsu_wb_if.addr;
assign mdata_o = lsu_wb_if.wdata;
assign msel = lsu_wb_if.sel;

assign lsu_wb_if.stall = mstall;
assign lsu_wb_if.ack = mack;
assign lsu_wb_if.rdata = mdata_i;
assign lsu_wb_if.err = merr;

// connect the slave wire side to the systemverilog interfaces
genvar i;
generate
    for (i = 0 ; i < NUM_SLAVES; ++i) begin: connect_slave_wb_ifs
        assign slave_wb_if[i].cyc = scyc[i];
        assign slave_wb_if[i].stb = sstb[i];
        assign slave_wb_if[i].we = swe[i];
        assign slave_wb_if[i].addr = saddr[i*WB_AW +: WB_AW];
        assign slave_wb_if[i].wdata = sdata_i[i*WB_DW +: WB_DW];
        assign slave_wb_if[i].sel = ssel[i*WB_DW/8 +: WB_DW/8];

        assign sstall[i] = slave_wb_if[i].stall;
        assign sack[i] = slave_wb_if[i].ack;
        assign sdata_o[i*WB_DW +: WB_DW] = slave_wb_if[i].rdata;
        assign serr[i] = slave_wb_if[i].err;
    end
endgenerate

// dmem
// assign signals to dmem_wb
assign dmem_wb_if.cyc = slave_wb_if[DMEM_SLAVE_INDEX].cyc;
assign dmem_wb_if.stb = slave_wb_if[DMEM_SLAVE_INDEX].stb;
assign dmem_wb_if.we = slave_wb_if[DMEM_SLAVE_INDEX].we;
assign dmem_wb_if.addr = slave_wb_if[DMEM_SLAVE_INDEX].addr;
assign dmem_wb_if.sel = slave_wb_if[DMEM_SLAVE_INDEX].sel;
assign dmem_wb_if.wdata = slave_wb_if[DMEM_SLAVE_INDEX].wdata;

assign slave_wb_if[DMEM_SLAVE_INDEX].rdata = dmem_wb_if.rdata;
assign slave_wb_if[DMEM_SLAVE_INDEX].rty = dmem_wb_if.rty;
assign slave_wb_if[DMEM_SLAVE_INDEX].ack = dmem_wb_if.ack;
assign slave_wb_if[DMEM_SLAVE_INDEX].stall = dmem_wb_if.stall;
assign slave_wb_if[DMEM_SLAVE_INDEX].err = dmem_wb_if.err;

// ddr3 interface signals
assign ddr3_wb_if.cyc = slave_wb_if[DDR3_SLAVE_INDEX].cyc;
assign ddr3_wb_if.stb = slave_wb_if[DDR3_SLAVE_INDEX].stb;
assign ddr3_wb_if.we = slave_wb_if[DDR3_SLAVE_INDEX].we;
assign ddr3_wb_if.addr = slave_wb_if[DDR3_SLAVE_INDEX].addr;
assign ddr3_wb_if.sel = slave_wb_if[DDR3_SLAVE_INDEX].sel;
assign ddr3_wb_if.wdata = slave_wb_if[DDR3_SLAVE_INDEX].wdata;

assign slave_wb_if[DDR3_SLAVE_INDEX].rdata = ddr3_wb_if.rdata;
assign slave_wb_if[DDR3_SLAVE_INDEX].rty = ddr3_wb_if.rty;
assign slave_wb_if[DDR3_SLAVE_INDEX].ack = ddr3_wb_if.ack;
assign slave_wb_if[DDR3_SLAVE_INDEX].stall = ddr3_wb_if.stall;
assign slave_wb_if[DDR3_SLAVE_INDEX].err = ddr3_wb_if.err;

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
    .i_wb_addr(slave_wb_if[WBUART_SLAVE_INDEX].addr[1:0]),
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

// NOTE: development on the hdmi core is halted for now
// hdmi frambuffer + hdmi video driver
// hdmi_core
// #()
// hdmi_core_i
// (
//     .clk_i(clk_i),
//     .rstn_i(rstn_i),

//     .pixel_clk_i(pixel_clk_i),
//     .pixel_clk_5x_i(pixel_clk_5x_i),

//     .wb_if(slave_wb_if[HDMI_SLAVE_INDEX]),

//     .hdmi_clk_o(hdmi_clk_o),
//     .hdmi_data_o(hdmi_data_o)
// );

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
