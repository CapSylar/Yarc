
module wb_sim_memory
#(parameter DATA_WIDTH = 128, parameter SIZE_POT_WORDS = 22, parameter bit INIT_MEM = 0, parameter string MEMFILE = "" )
(
    input clk_i,

    input cyc_i,
    input stb_i,

    input we_i,
    input [SIZE_POT_WORDS-1:0] addr_i,
    input [DATA_WIDTH/8 -1:0] sel_i,
    input [DATA_WIDTH-1:0] wdata_i,

    output logic [DATA_WIDTH-1:0] rdata_o,
    output logic rty_o,
    output logic ack_o,
    output logic stall_o,
    output logic err_o
);

localparam AW = SIZE_POT_WORDS;

// in clock cycles
localparam INITIAL_STALL = 100_000;
localparam MAX_INFLIGHT_RQS = 20;
localparam SWITCH_DELAY = 10;
localparam SAME_DELAY = 5;
localparam MAX_DELAY = (SWITCH_DELAY > SAME_DELAY) ? SWITCH_DELAY : SAME_DELAY;

// memory
logic [127:0] mem [logic [AW-1:0]]; // associative memory

wire request = cyc_i & stb_i & ~stall_o;
wire read_req = request & ~we_i;
wire write_req = request & we_i;

// initialize memory
initial begin
    if (INIT_MEM) begin
        $readmemh(MEMFILE, mem);
    end
end

initial begin
    // stall for some time
    ack_o = 1'b0;
    err_o = 1'b0;
    rty_o = 1'b0;
    stall_o = 1'b1;
end

int initial_stall = INITIAL_STALL;

always @(posedge clk_i) begin: stall_control
    if (initial_stall > 0) begin
        --initial_stall; // decrement counter
    end
end

always @(*) begin: drive_wb_stall
    stall_o = '0;

    if (initial_stall)
        stall_o = 1'b1;

    if (queue.size() >= MAX_INFLIGHT_RQS-1)
        stall_o = 1'b1;
end

typedef struct
{
    bit we;
    bit [AW-1:0] addr;

    bit [DATA_WIDTH-1:0] wdata; // if any
    bit [DATA_WIDTH/8-1:0] sel; // if any
} request_t;


// queue of requests
request_t queue [$:MAX_INFLIGHT_RQS];
request_t temp_req;

always @(posedge clk_i) begin: registering_requests

    if (request) begin
        temp_req = '{
            we: we_i,
            addr: addr_i,
            wdata: wdata_i,
            sel: sel_i
        };

        // enqueue
        queue.push_back(temp_req);
    end

end

int req_delay = MAX_DELAY;
request_t fetched_req;

always @(posedge clk_i) begin: handling_requests
    ack_o = '0;
    rdata_o = '0;

    if (queue.size() > 0) begin
        if (req_delay == '0) begin // handle the request now

            // fetch a request
            fetched_req = queue.pop_front();

            // handle write req
            if (fetched_req.we) begin
                for (int i = 0; i < DATA_WIDTH/8; ++i) begin: select_wise_write
                    if (fetched_req.sel[i])
                        mem[fetched_req.addr][i*8 +: 8] = fetched_req.wdata[i*8 +: 8];
                end
                ack_o = 1'b1;
            end else begin // handle read req
                // check for the existance of this value
                if (mem.exists(fetched_req.addr)) begin
                    rdata_o = mem[fetched_req.addr];
                end else begin
                    rdata_o = '0;
                end
                ack_o = 1'b1;
            end

            // reset timer
            req_delay = MAX_DELAY;

            // handle write
        end else if (req_delay > '0) begin
            --req_delay;
        end
    end
end

endmodule: wb_sim_memory
