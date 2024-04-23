// a clean wrapper around ddr3_top

module yarc_ddr3_top
import ddr3_parameters_pkg::*;
(
    input wire i_controller_clk, i_ddr3_clk, i_ref_clk, //i_controller_clk = CONTROLLER_CLK_PERIOD, i_ddr3_clk = DDR3_CLK_PERIOD, i_ref_clk = 200MHz
    input wire i_ddr3_clk_90, //required only when ODELAY_SUPPORTED is zero
    input wire i_rst_n,
    //
    // Wishbone inputs
    wishbone_if.SLAVE wb_if,
    //
    // DDR3 I/O Interface
    output wire o_ddr3_clk_p, o_ddr3_clk_n,
    output wire o_ddr3_reset_n,
    output wire o_ddr3_cke, // CKE
    output wire o_ddr3_cs_n, // chip select signal
    output wire o_ddr3_ras_n, // RAS#
    output wire o_ddr3_cas_n, // CAS#
    output wire o_ddr3_we_n, // WE#
    output wire[ROW_BITS-1:0] o_ddr3_addr,
    output wire[BA_BITS-1:0] o_ddr3_ba_addr,
    inout wire[(NUM_DQ_BITS*LANES)-1:0] io_ddr3_dq,
    inout wire[(NUM_DQ_BITS*LANES)/8-1:0] io_ddr3_dqs, io_ddr3_dqs_n,
    output wire[LANES-1:0] o_ddr3_dm,
    output wire o_ddr3_odt // on-die termination
);

// DDR3 Controller 
ddr3_top #(
    .ROW_BITS(ROW_BITS),   //width of row address
    .COL_BITS(COL_BITS), //width of column address
    .BA_BITS(BA_BITS), //width of bank address
    .DQ_BITS(NUM_DQ_BITS),  //width of DQ
    .CONTROLLER_CLK_PERIOD(CONTROLLER_CLK_PERIOD), //ns, period of clock input to this DDR3 controller module
    .DDR3_CLK_PERIOD(DDR3_CLK_PERIOD), //ns, period of clock input to DDR3 RAM device 
    .ODELAY_SUPPORTED(ODELAY_SUPPORTED), //set to 1 when ODELAYE2 is supported
    .LANES(LANES), //8 lanes of DQ
    .AUX_WIDTH(AUX_WIDTH),
    .OPT_LOWPOWER(OPT_LOWPOWER), //1 = low power, 0 = low logic
    .OPT_BUS_ABORT(OPT_BUS_ABORT),  //1 = can abort bus, 0 = no absort (i_wb_cyc will be ignored, ideal for an AXI implementation which cannot abort transaction)
    .MICRON_SIM(MICRON_SIM),
    .SECOND_WISHBONE(SECOND_WISHBONE)
    ) ddr3_top
    (
        //clock and reset
        .i_controller_clk(i_controller_clk),
        .i_ddr3_clk(i_ddr3_clk), //i_controller_clk has period of CONTROLLER_CLK_PERIOD, i_ddr3_clk has period of DDR3_CLK_PERIOD 
        .i_ref_clk(i_ref_clk),
        .i_ddr3_clk_90(i_ddr3_clk_90),
        .i_rst_n(i_rst_n), 
        // Wishbone inputs
        .i_wb_cyc(wb_if.cyc), //bus cycle active (1 = normal operation, 0 = all ongoing transaction are to be cancelled)
        .i_wb_stb(wb_if.stb), //request a transfer
        .i_wb_we(wb_if.we), //write-enable (1 = write, 0 = read)
        .i_wb_addr(wb_if.addr[$bits(ddr3_top.i_wb_addr)-1:0]), //burst-addressable {row,bank,col} 
        .i_wb_data(wb_if.wdata), //write data, for a 4:1 controller data width is 8 times the number of pins on the device
        .i_wb_sel(wb_if.sel), //byte strobe for write (1 = write the byte)
        .i_aux('0), //for AXI-interface compatibility (given upon strobe)
        // Wishbone outputs
        .o_wb_stall(wb_if.stall), //1 = busy, cannot accept requests
        .o_wb_ack(wb_if.ack), //1 = read/write request has completed
        .o_wb_data(wb_if.rdata), //read data, for a 4:1 controller data width is 8 times the number of pins on the device
        .o_aux(),
        // Wishbone 2 (PHY) inputs
        .i_wb2_cyc('0), //bus cycle active (1 = normal operation, 0 = all ongoing transaction are to be cancelled)
        .i_wb2_stb('0), //request a transfer
        .i_wb2_we('0), //write-enable (1 = write, 0 = read)
        .i_wb2_addr('0), //burst-addressable {row,bank,col} 
        .i_wb2_data('0), //write data, for a 4:1 controller data width is 8 times the number of pins on the device
        .i_wb2_sel('0), //byte strobe for write (1 = write the byte)
        // Wishbone 2 (Controller) outputs
        .o_wb2_stall(), //1 = busy, cannot accept requests
        .o_wb2_ack(), //1 = read/write request has completed
        .o_wb2_data(), //read data, for a 4:1 controller data width is 8 times the number of pins on the device
        // PHY Interface (to be added later)
        .o_ddr3_clk_p(o_ddr3_clk_p),
        .o_ddr3_clk_n(o_ddr3_clk_n),
        .o_ddr3_cke(o_ddr3_cke), // CKE
        .o_ddr3_cs_n(o_ddr3_cs_n), // chip select signal
        .o_ddr3_odt(o_ddr3_odt), // on-die termination
        .o_ddr3_ras_n(o_ddr3_ras_n), // RAS#
        .o_ddr3_cas_n(o_ddr3_cas_n), // CAS#
        .o_ddr3_we_n(o_ddr3_we_n), // WE#
        .o_ddr3_reset_n(o_ddr3_reset_n),
        .o_ddr3_addr(o_ddr3_addr),
        .o_ddr3_ba_addr(o_ddr3_ba_addr),
        .io_ddr3_dq(io_ddr3_dq),
        .io_ddr3_dqs(io_ddr3_dqs),
        .io_ddr3_dqs_n(io_ddr3_dqs_n),
        .o_ddr3_dm(o_ddr3_dm),

        .o_debug1(),
        .o_debug2(),
        .o_debug3(),
        .o_ddr3_debug_read_dqs_p(),
        .o_ddr3_debug_read_dqs_n()
    );

assign wb_if.err = '0;
assign wb_if.rty = '0;

endmodule: yarc_ddr3_top
