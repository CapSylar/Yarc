
// Should be a pretty straighforward D$
// 4-way set associative
// write-through with a write buffer
// read misses should bypass write buffer
// on a load hazard (the wanted data is in the write buffer), 
// we wait til the entire write buffer is flushed

module data_cache
#(
    parameter unsigned NUM_SETS_LOG2 = 0
)
(
    input clk_i,
    input rstn_i,

    // cpu <-> D$
    wishbone_if.SLAVE cpu_if,

    // D$ <-> memory
    wishbone_if.MASTER mem_if
);

localparam unsigned NUM_SETS = 2**NUM_SETS_LOG2;
localparam unsigned INDEX_W = NUM_SETS_LOG2;
localparam unsigned OFFSET_W = 2;
localparam unsigned NUM_WAYS = 4;

localparam unsigned CPU_AW = $bits(cpu_if.addr);
localparam unsigned TAG_W = CPU_AW - INDEX_W - OFFSET_W;
// tag store
logic valid_bits [NUM_WAYS-1:0][NUM_SETS-1:0];// indicates that the corresponding cache line in valid
logic [NUM_SETS-1:0] set_age; // a bit for each set for now

localparam unsigned DATA_W = 32;
localparam unsigned LINE_W = (2**OFFSET_W) * DATA_W;

logic is_cpu_req_d, is_cpu_req_q;

// Memory Instantiations
// ***********************************************************
logic [TAG_W-1:0] tag_addr_d, tag_addr_q;
logic [INDEX_W-1:0] index_addr_d, index_addr_q;
logic [OFFSET_W-1:0] offset_addr_d, offset_addr_q;
logic [CPU_AW-1:0] cpu_addr_d, cpu_addr_q;

always_comb begin
    cpu_addr_d = cpu_addr_q;

    if (is_cpu_req_d) begin // save the address when a request happens
        cpu_addr_d = cpu_if.addr;
    end
end

assign {tag_addr_d, index_addr_d, offset_addr_d} = cpu_addr_d;
assign {tag_addr_q, index_addr_q, offset_addr_q} = cpu_addr_q;

logic valid_bits_re; // we read all of them at once
logic valid_bits_we [NUM_WAYS-1:0];
logic valid_bits_rdata [NUM_WAYS-1:0];
logic valid_bits_wdata; // only one is written at a time
logic [INDEX_W-1:0] valid_bits_raddr;
logic [INDEX_W-1:0] valid_bits_waddr;

// valid_bits_e read and write
generate
    for (genvar i = 0; i < NUM_WAYS; ++i) begin
        always_ff@(posedge clk_i) begin
            if (!rstn_i) begin
                valid_bits[i] <= '{default: '0};
            end else begin
                if (valid_bits_re) begin
                    valid_bits_rdata[i] <= valid_bits[i][valid_bits_raddr];
                end

                if (valid_bits_we[i]) begin
                    valid_bits[i][valid_bits_waddr] <= valid_bits_wdata;
                end
            end
        end
    end
endgenerate

logic tag_mem_re; // we read all of them at once
logic tag_mem_we [NUM_WAYS-1:0];
logic [TAG_W-1:0] tag_mem_rdata [NUM_WAYS-1:0];
logic [TAG_W-1:0] tag_mem_wdata; // only one is written at a time
logic [INDEX_W-1:0] tag_mem_raddr;
logic [INDEX_W-1:0] tag_mem_waddr;

generate
    for (genvar i = 0; i < NUM_WAYS; ++i) begin
        sdp_mem #(.DW(TAG_W), .AW(INDEX_W), .INIT_MEM('0)) tag_mem
        (
            .clk_i(clk_i),

            .en_a_i(tag_mem_re),
            .addr_a_i(tag_mem_raddr),
            .rdata_a_o(tag_mem_rdata[i]),

            .en_b_i(tag_mem_we[i]),
            .addr_b_i(tag_mem_waddr),
            .wdata_b_i(tag_mem_wdata)
        );
    end
endgenerate

logic data_mem_re;
logic data_mem_we [NUM_WAYS-1:0];
logic [LINE_W-1:0] data_mem_rdata [NUM_WAYS-1:0];
logic [LINE_W-1:0] data_mem_wdata;
logic [INDEX_W-1:0] data_mem_raddr;
logic [INDEX_W-1:0] data_mem_waddr;

generate
    for (genvar i = 0; i < NUM_WAYS; ++i) begin
        sdp_mem #(.DW(LINE_W), .AW(INDEX_W), .INIT_MEM('0)) data_mem
        (
            .clk_i(clk_i),

            .en_a_i(data_mem_re),
            .addr_a_i(data_mem_raddr),
            .rdata_a_o(data_mem_rdata[i]),

            .en_b_i(data_mem_we[i]),
            .addr_b_i(data_mem_waddr),
            .wdata_b_i(data_mem_wdata)
        );
    end
endgenerate

// ***********************************************************

logic replace_way_idx; // index pointing to the way that will get replaced
logic [LINE_W-1:0] mem_if_rdata_q;

// wb sigs
assign is_cpu_req_d = cpu_if.cyc & cpu_if.stb & !cpu_if.stall;

logic read_stores; // this signals that the tag and data stores are to be read
assign read_stores = is_cpu_req_d;

logic get_decision;
assign get_decision = is_cpu_req_q;

logic cpu_if_stall;
logic miss;
logic memory_send_req;
logic memory_resp_valid;
logic update_age;
logic restart;

// cache FSM
enum {RUNNING, WAIT_MEMORY, REFILL} state, next;
always_ff @(posedge clk_i)
    if (!rstn_i) state <= RUNNING;
    else         state <= next;

always_comb begin
    next = state;

    cpu_if_stall = '0;
    memory_send_req = '0;
    update_age = '0;
    restart = '0;

    valid_bits_we = '{default: '0};
    tag_mem_we = '{default: '0};
    data_mem_we = '{default: '0};

    unique case (state)
        /*
        In this state, the cache accepts pipelined requests and handles them
        as soon as a request misses, the cpu wb bus is stalled and the state 
        changes to REFILL
        */
        RUNNING: begin
            if (miss) begin
                cpu_if_stall = 1'b1; // can't accept anymore requests
                memory_send_req = 1'b1;
                next = WAIT_MEMORY;
            end
        end

        // request the missing cache line from the backing storage
        WAIT_MEMORY: begin
            cpu_if_stall = 1'b1; // can't accept anymore requests
            if (memory_resp_valid) begin
                next = REFILL;
            end
        end

        // the memory has given us a response, we need to place the 
        // loaded line in the storage
        REFILL: begin
            cpu_if_stall = 1'b1; // can't accept anymore requests

            // write the tag, data and valid bits in the way that will be replaced
            tag_mem_we[replace_way_idx] = 1'b1;
            tag_mem_waddr = index_addr_q;
            tag_mem_wdata = tag_addr_q;
            data_mem_we[replace_way_idx] = 1'b1;
            data_mem_waddr = index_addr_q;
            data_mem_wdata = mem_if_rdata_q;
            valid_bits_we[replace_way_idx] = 1'b1;
            valid_bits_waddr = index_addr_q;
            valid_bits_wdata = 1'b1;

            // early restart
            restart = 1'b1;

            update_age = 1'b1;
            next = RUNNING;
        end
    endcase
end

logic mem_if_cyc;
logic mem_if_stb;
logic [$bits(mem_if.sel)-1:0] mem_if_sel;
logic [$bits(mem_if.addr)-1:0] mem_if_addr;

// memory wishbone fsm
enum {IDLE, REQUEST} wbstate, wbnext;
always_ff @(posedge clk_i)
    if (!rstn_i) wbstate <= IDLE;
    else         wbstate <= wbnext;

always_comb begin
    wbnext = wbstate;

    mem_if_sel = '1;
    mem_if_addr = '0;
    mem_if_cyc = '0;
    mem_if_stb = '0;

    memory_resp_valid = '0;

    unique case (wbstate)

        IDLE: begin
            if (memory_send_req) begin // FIXME: what is mem_if is stalled ?
                mem_if_cyc = 1'b1;
                mem_if_stb = 1'b1;
                mem_if_addr = cpu_addr_q[CPU_AW-1 : 2]; // TODO: localparam this
                wbnext = REQUEST;
            end
        end

        REQUEST: begin
            mem_if_cyc = 1'b1;

            if (mem_if.ack) begin
                memory_resp_valid = 1'b1;
                wbnext = IDLE;
            end
        end
    endcase
end

always_ff @(posedge clk_i) begin
    if (memory_resp_valid) begin // hold the loaded word
        mem_if_rdata_q <= mem_if.rdata;
    end
end

assign tag_mem_re = read_stores;
assign data_mem_re = read_stores;
assign valid_bits_re = read_stores;
assign tag_mem_raddr = index_addr_d;
assign data_mem_raddr = index_addr_d;
assign valid_bits_raddr = index_addr_d;

// logic that determines if hit or miss
logic [NUM_WAYS-1:0] line_valid ; // determines which way is valid
logic [$clog2(NUM_WAYS)-1:0] line_valid_idx ;
logic hit;
logic [DATA_W-1:0] read_word; // the word requested by the cpu

generate
    for (genvar i = 0; i < NUM_WAYS; ++i) begin: calc_line_valid
        assign line_valid[i] = (tag_addr_q == tag_mem_rdata[i]) & (valid_bits_rdata[i]);
    end
endgenerate

always_comb begin: calc_valid_index
    for (int i = 0 ; i < NUM_WAYS; ++i) begin
        line_valid_idx = i;
        if (line_valid[i]) begin
            break;
        end
    end
end

assign hit = get_decision ? |line_valid : '0;
assign miss = get_decision ? !hit : '0;
assign read_word = get_data_from_line(offset_addr_q, data_mem_rdata[line_valid_idx]);

function [DATA_W-1:0] get_data_from_line (logic [OFFSET_W-1:0] offset, logic [LINE_W-1:0] line_data);
    get_data_from_line = DATA_W'(line_data >> (DATA_W * offset));
endfunction

logic cpu_if_ack;
logic [DATA_W-1:0] cpu_if_rdata;

// cpu wishbone logic
always_comb begin
    cpu_if_ack = restart | hit;
    cpu_if_rdata = restart ? get_data_from_line(offset_addr_q, mem_if_rdata_q)
        : read_word;
end

always_ff @(posedge clk_i) begin
    if (!rstn_i) begin
        cpu_addr_q <= '0;

        is_cpu_req_q <= '0;
    end else begin
        cpu_addr_q <= cpu_addr_d;

        is_cpu_req_q <= is_cpu_req_d;
    end
end

always_ff @(posedge clk_i) begin
    if (!rstn_i) begin
        set_age <= '{default: '0};
    end else if (update_age) begin
        set_age[index_addr_q] = ~replace_way_idx; // the new points now points to the other way
    end
end

// Replacement logic
assign replace_way_idx = set_age[index_addr_q];

// assign cpu wishbone outputs
assign cpu_if.rdata = cpu_if_rdata;
assign cpu_if.rty = '0;
assign cpu_if.ack = cpu_if_ack;
assign cpu_if.stall = cpu_if_stall;
assign cpu_if.err = '0;

// assign memory wishbone outputs
assign mem_if.cyc = mem_if_cyc;
assign mem_if.stb = mem_if_stb;
assign mem_if.we = '0;
assign mem_if.addr = mem_if_addr;
assign mem_if.sel = mem_if_sel;
assign mem_if.wdata = '0;

endmodule: data_cache
