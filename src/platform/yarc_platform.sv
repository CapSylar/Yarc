
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
(
    input clk_i,
    input rstn_i,

    // Platform <-> IMEM
    output imem_en_o,
    output [31:0] imem_raddr_o,
    input [31:0] imem_rdata_i,

    // Platform <-> DMEM
    wishbone_if.MASTER wb_if,

    // Platform <-> Peripherals
    output logic [7:0] led_status_o
);

import platform_pkg::*;

assign led_status_o = '0;

// timer lines
// logic timer_en;
// logic irq_timer;
// logic [31:0] timer_rdata;

// timer
// timer timer_i
// (
//     .clk_i(clk_i),
//     .rstn_i(rstn_i),

//     .en_i(timer_en),
//     .read_i(lsu_read_o),
//     .addr_i(lsu_addr_o),
//     .rdata_o(timer_rdata),

//     .wdata_i(lsu_wdata_o),
    
//     .timer_int_o(irq_timer)
// );

// led driver lines
// logic led_driver_en;
// logic [31:0] led_driver_rdata;

// led driver
// led_driver led_driver_i
// (
//     .clk_i(clk_i),
//     .rstn_i(rstn_i),

//     .en_i(led_driver_en),
//     .read_i(lsu_read_o),
//     .addr_i(lsu_addr_o),
//     .rdata_o(led_driver_rdata),

//     .wdata_i(lsu_wdata_o),
    
//     .led_status_o(led_status_o)
// );

// typedef enum
// {
//     DMEM,
//     TIMER,
//     LED_DRIVER,
//     NOTHING
// } addressed_e;

// addressed_e addressed_d, addressed_q;

// always_ff @(posedge clk_i)
// begin
//     if (!rstn_i) addressed_q <= NOTHING;
//     else addressed_q <= addressed_d;
// end

// // address decoder for LSU lines
// always_comb begin: decoder

//     addressed_d = NOTHING;

//     if (lsu_en_o)
//     begin
//         if ((lsu_addr_o & DMEM_MASK) == DMEM_BASE_ADDR)
//         begin
//             addressed_d = DMEM;
//         end
        
//         if ((lsu_addr_o & MTIMER_MASK) == MTIMER_BASE_ADDR)
//         begin
//             addressed_d = TIMER;
//         end

//         if ((lsu_addr_o & LED_DRIVER_MASK) == LED_DRIVER_BASE_ADDR)
//         begin
//             addressed_d = LED_DRIVER;
//         end
//     end
// end

// assign dmem_en_o = (addressed_d == DMEM);
// assign timer_en = (addressed_d == TIMER);
// assign led_driver_en = (addressed_d == LED_DRIVER);

// address mux
// always_comb begin: rdata_mux
//     lsu_rdata_i = '0;

//     unique case (addressed_q)
//         DMEM: lsu_rdata_i = dmem_rdata_i;
//         TIMER: lsu_rdata_i = timer_rdata;
//         LED_DRIVER: lsu_rdata_i = led_driver_rdata;
//         default:;
//     endcase
// end

// Core Top
core_top core_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    // Core <-> Imem interface
    .imem_en_o(imem_en_o),
    .imem_raddr_o(imem_raddr_o),
    .imem_rdata_i(imem_rdata_i),

    // Core WB Data Interface
    .wb_if(wb_if),

    // interrupts
    .irq_timer_i(irq_timer),
    .irq_external_i('0)
);

endmodule: yarc_platform