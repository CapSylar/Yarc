package video_pkg;

localparam int VIDEO_CONFIG = 0;
localparam int VIDEO_ADDR = 1;

typedef struct packed {
    logic is_enabled;
} video_config_t;

typedef struct packed {
    logic [31:0] fb_address;
} video_addr_t;

endpackage: video_pkg
