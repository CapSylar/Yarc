
package ddr3_parameters_pkg;

// ddr3 parameters used for the yarc project
// on the nexys video board
`define den4096Mb
`define sg125
`define x16
`include "4096Mb_ddr3_parameters.vh"

localparam real CONTROLLER_CLK_PERIOD = 12_000.0; //ps, clock period of the controller interface
localparam real DDR3_CLK_PERIOD = 3_000.0; //ps, clock period of the DDR3 RAM device (must be 1/4 of the CONTROLLER_CLK_PERIOD) 0
localparam CONTROLLER_REF_CLK = 5_000; //ps, 200Mhz
localparam AUX_WIDTH = 4; //width of aux line (must be >= 4) 
localparam LANES = 2;
localparam WB2_ADDR_BITS = 7; // width of 2nd wishbone address bus 
localparam WB2_DATA_BITS = 32; // width of 2nd wishbone data bus

localparam OPT_LOWPOWER = 1; //1 = low power, 0 = low logic
localparam OPT_BUS_ABORT = 1;  //1 = can abort bus, 0 = no abort (i_wb_cyc will be ignored, ideal for an AXI implementation which cannot abort transaction)

localparam MICRON_SIM = 1; //enable faster simulation for micron ddr3 model (shorten POWER_ON_RESET_HIGH and INITIAL_CKE_LOW)
localparam ODELAY_SUPPORTED = 0; //set to 1 when ODELAYE2 is supported
localparam SECOND_WISHBONE = 0; //set to 1 if 2nd wishbone is needed 

localparam NUM_DQ_BITS = 8;
localparam serdes_ratio = $rtoi(CONTROLLER_CLK_PERIOD/DDR3_CLK_PERIOD);
localparam wb_addr_bits = ROW_BITS + COL_BITS + BA_BITS - $clog2(serdes_ratio*2);
localparam wb_data_bits = NUM_DQ_BITS*LANES*serdes_ratio*2;
localparam wb_sel_bits = wb_data_bits / 8;
localparam wb2_sel_bits = WB2_DATA_BITS / 8;
//4 is the width of a single ddr3 command {cs_n, ras_n, cas_n, we_n} plus 3 (ck_en, odt, reset_n) plus bank bits plus row bits
localparam cmd_len = 4 + 3 + BA_BITS + ROW_BITS;

endpackage: ddr3_parameters_pkg
