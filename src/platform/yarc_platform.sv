
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
    wishbone_if.MASTER dmem_wb,

    // Platform <-> Peripherals
    output logic [7:0] led_status_o
);
import platform_pkg::*;

wishbone_if wb_if();
wishbone_if led_wb_if();

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

// led driver
led_driver led_driver_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    .wb_if(led_wb_if.SLAVE),
    
    .led_status_o(led_status_o)
);

typedef enum
{
    DMEM,
    TIMER,
    LED_DRIVER,
    NOTHING
} addressed_e;

addressed_e addressed_d, addressed_q;

always_ff @(posedge clk_i)
begin
    if (!rstn_i) addressed_q <= NOTHING;
    else addressed_q <= addressed_d;
end

// address decoder for LSU lines
always_comb begin: decoder

    addressed_d = NOTHING;

    if (wb_if.cyc)
    begin
        if ((wb_if.addr & DMEM_MASK) == DMEM_BASE_ADDR)
        begin
            addressed_d = DMEM;
        end
        
        if ((wb_if.addr & MTIMER_MASK) == MTIMER_BASE_ADDR)
        begin
            addressed_d = TIMER;
        end

        if ((wb_if.addr & LED_DRIVER_MASK) == LED_DRIVER_BASE_ADDR)
        begin
            addressed_d = LED_DRIVER;
        end
    end
end

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

always_comb
begin
    dmem_wb.cyc = '0;
    dmem_wb.stb = '0;
    dmem_wb.lock = '0;
    dmem_wb.we = '0;
    dmem_wb.addr = '0;
    dmem_wb.sel = '0;
    dmem_wb.wdata = '0;

    led_wb_if.cyc = '0;
    led_wb_if.stb = '0;
    led_wb_if.lock = '0;
    led_wb_if.we = '0;
    led_wb_if.addr = '0;
    led_wb_if.sel = '0;
    led_wb_if.wdata = '0;

    case (addressed_d)
        DMEM:
        begin
            dmem_wb.cyc = wb_if.cyc;
            dmem_wb.stb = wb_if.stb;
            dmem_wb.lock = wb_if.lock;
            dmem_wb.we = wb_if.we;
            dmem_wb.addr = wb_if.addr;
            dmem_wb.sel = wb_if.sel;
            dmem_wb.wdata = wb_if.wdata;
        end

        LED_DRIVER:
        begin
            led_wb_if.cyc = wb_if.cyc;
            led_wb_if.stb = wb_if.stb;
            led_wb_if.lock = wb_if.lock;
            led_wb_if.we = wb_if.we;
            led_wb_if.addr = wb_if.addr;
            led_wb_if.sel = wb_if.sel;
            led_wb_if.wdata = wb_if.wdata;
        end
        default:;
    endcase
end

// handle return signals
always_comb
begin
    wb_if.rdata = '0;
    wb_if.rty = '0;
    wb_if.ack = '0;
    wb_if.stall = '0;
    wb_if.err = '0;

    case (addressed_q)
        DMEM:
        begin
            wb_if.rdata = dmem_wb.rdata;
            wb_if.rty = dmem_wb.rty;
            wb_if.ack = dmem_wb.ack;
            wb_if.stall = dmem_wb.stall;
            wb_if.err = dmem_wb.err;
        end

        LED_DRIVER:
        begin
            wb_if.rdata = led_wb_if.rdata;
            wb_if.rty = led_wb_if.rty;
            wb_if.ack = led_wb_if.ack;
            wb_if.stall = led_wb_if.stall;
            wb_if.err = led_wb_if.err;
        end

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

    // Core WB Data Interface
    .wb_if(wb_if.MASTER),

    // interrupts
    .irq_timer_i(irq_timer),
    .irq_external_i('0)
);

endmodule: yarc_platform