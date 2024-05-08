package hdmi_pkg;

localparam int HDMI_CONFIG = 0;
localparam int HDMI_ADDR = 1;

typedef struct packed {
    logic is_enabled;
} hdmi_config_t;

typedef struct packed {
    logic [31:0] fb_address;
} hdmi_addr_t;

endpackage: hdmi_pkg
