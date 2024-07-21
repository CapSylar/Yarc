
module fetch_intercon
import platform_pkg::*;
(
    input clk_i,
    input rstn_i,

    // CPU Master <-> Fetch mux
    wishbone_if.SLAVE cpu_fetch_if,

    // ICCM Slave <-> Fetch mux
    wishbone_if.MASTER iccm_if,

    // I$ Slave <-> Fetch mux
    wishbone_if.MASTER icache_if
);

wishbone_if #() slave_wb_if[FETCH_INTERCON_NUM_SLAVES]();

wb_connect iccm_connect (.wb_if_i(slave_wb_if[FETCH_INTERCON_ICCM_SLAVE_INDEX]), .wb_if_o(iccm_if));
wb_connect icache_connect (.wb_if_i(slave_wb_if[FETCH_INTERCON_ICACHE_SLAVE_INDEX]), .wb_if_o(icache_if));

wb_interconnect 
#(  .NUM_SLAVES(FETCH_INTERCON_NUM_SLAVES),
    .AW(FETCH_INTERCON_WB_AW),
    .START_ADDRESS(FETCH_INTERCON_BASE_ADDRESSES),
    .MASK(FETCH_INTERCON_MASKS),
    .SLAVE_FOR_NO_MATCH(1'b0)
)
wb_interconnect_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    .intercon_if(cpu_fetch_if),

    .wb_if(slave_wb_if)
);

endmodule: fetch_intercon
