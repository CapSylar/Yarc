
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
    output logic [7:0] led_status_o
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