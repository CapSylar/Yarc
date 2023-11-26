
//
//    __   __                    ______  _         _     __                         
//    \ \ / /                    | ___ \| |       | |   / _|                        
//     \ V /   __ _  _ __   ___  | |_/ /| |  __ _ | |_ | |_   ___   _ __  _ __ ___  
//      \ /   / _` || '__| / __| |  __/ | | / _` || __||  _| / _ \ | '__|| '_ ` _ \ 
//      | |  | (_| || |   | (__  | |    | || (_| || |_ | |  | (_) || |   | | | | | |
//      \_/   \__,_||_|    \___| \_|    |_| \__,_| \__||_|   \___/ |_|   |_| |_| |_|
//                                                                                  

// contains the core, mtimer without memories                                                                             
module yarc_platform
(
    input clk_i,
    input rstn_i,

    // Platform <-> IMEM
    output imem_en_o,
    output [31:0] imem_raddr_o,
    input [31:0] imem_rdata_i,

    // Platform <-> DMEM
    output logic dmem_en_o,
    output logic [31:0] dmem_addr_o,
    output logic dmem_read_o,
    input [31:0] dmem_rdata_i,
    output logic [3:0] dmem_wsel_byte_o,
    output logic [31:0] dmem_wdata_o
);
import platform_pkg::*;

logic lsu_en_o;
logic [31:0] lsu_addr_o;
logic lsu_read_o;
logic [31:0] lsu_rdata_i;
logic [3:0] lsu_wsel_byte_o;
logic [31:0] lsu_wdata_o;

// timer lines
logic timer_en;
logic irq_timer;
logic [31:0] timer_rdata;

// timer
timer timer_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    .en_i(timer_en),
    .read_i(lsu_read_o),
    .addr_i(lsu_addr_o),
    .rdata_o(timer_rdata),

    .wdata_i(lsu_wdata_o),
    
    .timer_int_o(irq_timer)
);

// address decoder for LSU lines
always_comb begin: decoder

    dmem_en_o = '0;
    timer_en = '0;

    if (lsu_en_o)
    begin
        if ((lsu_addr_o & DMEM_MASK) == DMEM_BASE_ADDR)
            dmem_en_o = 1'b1;
        
        if ((lsu_addr_o & MTIMER_MASK) == MTIMER_BASE_ADDR)
            timer_en = 1'b1;
    end
end

// address mux
always_comb begin: rdata_mux
    lsu_rdata_i = '0;

    unique case (1'b1)
        dmem_en_o: lsu_rdata_i = dmem_rdata_i;
        timer_en: lsu_rdata_i = timer_rdata;
        default:;
    endcase
end

// Core Top
core_top core_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    // Core <-> Imem interface
    .imem_en_o(imem_en_o),
    .imem_raddr_o(imem_raddr_o),
    .imem_rdata_i(imem_rdata_i),

    // Core <-> DMEM, Peripherals...
    .lsu_en_o(lsu_en_o),
    .lsu_addr_o(lsu_addr_o),
    // read port
    .lsu_read_o(lsu_read_o),
    .lsu_rdata_i(lsu_rdata_i),
    // write port
    .lsu_wsel_byte_o(lsu_wsel_byte_o),
    .lsu_wdata_o(lsu_wdata_o),

    // interrupts
    .irq_timer_i(irq_timer),
    .irq_external_i('0)
);

// assign outputs
// DMEM lines
// assign DMEM lines
assign dmem_addr_o = lsu_addr_o;
assign dmem_read_o = lsu_read_o;
assign dmem_wsel_byte_o = lsu_wsel_byte_o;
assign dmem_wdata_o = lsu_wdata_o;
endmodule: yarc_platform