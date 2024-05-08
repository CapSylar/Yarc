
module hdmi_core_ctrl
import hdmi_pkg::*;
(
    input clk_i,
    input rstn_i,

    wishbone_if.SLAVE config_if,

    // outputs config registers
    output hdmi_config_t hdmi_config_o,
    output hdmi_addr_t hdmi_addr_o
);

wire is_addressed  = config_if.cyc & config_if.stb;

logic [31:0] wb_data_d, wb_data_q;
logic ack_d, ack_q;

hdmi_config_t hdmi_config_q;
hdmi_addr_t hdmi_addr_q;

logic hdmi_config_we, hdmi_addr_we;

always_comb begin :wb_read

    case (config_if.addr)
        HDMI_CONFIG: wb_data_d = 32'(hdmi_config_q);
        HDMI_ADDR: wb_data_d = 32'(hdmi_addr_q);
    endcase
end

always_comb begin: wb_write
    hdmi_config_we = '0;
    hdmi_addr_we = '0;

    if (is_addressed && config_if.we) begin
        case (config_if.addr)
            HDMI_CONFIG: hdmi_config_we = 1'b1;
            HDMI_ADDR: hdmi_addr_we = 1'b1;
            default:;
        endcase
    end
end

assign ack_d = is_addressed;

always_ff @(posedge clk_i) begin
    if (!rstn_i) begin
        wb_data_q <= '0;
        ack_q <= '0;
    end else begin
        wb_data_q <= wb_data_d;
        ack_q <= ack_d;
    end
end

// config registers
localparam HDMI_CFG_SZ = $bits(hdmi_config_t);
reg_bw #(.WIDTH(HDMI_CFG_SZ), .RESET_VALUE('0)) hdmi_config_reg
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    .rdata_o(hdmi_config_q),
    .we_i(hdmi_config_we),
    .wsel_i(config_if.sel[$bits(hdmi_config_reg.wsel_i)-1:0]),
    .wdata_i(config_if.wdata[HDMI_CFG_SZ-1:0])
);

localparam HDMI_ADDR_SZ = $bits(hdmi_addr_t);
reg_bw #(.WIDTH(HDMI_ADDR_SZ) , .RESET_VALUE('0)) hdmi_addr_reg
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    .rdata_o(hdmi_addr_q),
    .we_i(hdmi_addr_we),
    .wsel_i(config_if.sel[$bits(hdmi_addr_reg.wsel_i)-1:0]),
    .wdata_i(config_if.wdata[HDMI_ADDR_SZ-1:0])
);

// assign wishbone signals
assign config_if.rdata = wb_data_q;
assign config_if.ack = ack_q;
assign config_if.stall = '0;
assign config_if.err = '0;
assign config_if.rty = '0;

// assign outputs
assign hdmi_config_o = hdmi_config_t'(hdmi_config_q);
assign hdmi_addr_o = hdmi_addr_t'(hdmi_addr_q);

endmodule: hdmi_core_ctrl
