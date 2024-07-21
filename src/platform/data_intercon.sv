
module data_intercon
import platform_pkg::*;
(
    input clk_i,
    input rstn_i,

    // CPU Master <-> Data mux
    wishbone_if.SLAVE cpu_if,

    // ICCM Slave <-> Data mux
    wishbone_if.MASTER dccm_if,

    // I$ Slave <-> Data mux
    wishbone_if.MASTER dcache_if,

    // Main Mux Connection <-> Data mux
    wishbone_if.MASTER main_mux_if
);

wishbone_if #() slave_wb_if [DATA_INTERCON_NUM_SLAVES]();

wb_connect dccm_connect (.wb_if_i(slave_wb_if[DATA_INTERCON_DCCM_SLAVE_INDEX]), .wb_if_o(dccm_if));
wb_connect dcache_connect (.wb_if_i(slave_wb_if[DATA_INTERCON_DCACHE_SLAVE_INDEX]), .wb_if_o(dcache_if));
wb_connect main_mux_connect (.wb_if_i(slave_wb_if[DATA_INTERCON_MAIN_MUX_SLAVE_INDEX]), .wb_if_o(main_mux_if));

wb_interconnect 
#(  .NUM_SLAVES(DATA_INTERCON_NUM_SLAVES-1), // -1 because an extra slave will be created by passing in SLAVE_FOR_NO_MATCH
    .AW(DATA_INTERCON_WB_AW),
    .START_ADDRESS(DATA_INTERCON_BASE_ADDRESSES),
    .MASK(DATA_INTERCON_MASKS),
    .SLAVE_FOR_NO_MATCH(1'b1)
)
wb_interconnect_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    .intercon_if(cpu_if),

    .wb_if(slave_wb_if)
);

endmodule: data_intercon
