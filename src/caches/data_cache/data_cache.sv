
// Should be a pretty straighforward D$
// 4-way set associative
// write-through with a write buffer
// read misses should bypass write buffer

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
localparam unsigned CPU_DW = $bits(cpu_if.wdata);

localparam unsigned TAG_W = CPU_AW - INDEX_W - OFFSET_W;
// tag store
logic valid_bits [NUM_WAYS-1:0][NUM_SETS-1:0];// indicates that the corresponding cache line in valid
logic [NUM_SETS-1:0] set_age; // a bit for each set for now

localparam unsigned DATA_W = 32;
localparam unsigned LINE_W = (2**OFFSET_W) * DATA_W;

typedef struct packed {
    logic [TAG_W-1:0] tag;
    logic [INDEX_W-1:0] index;
    logic [OFFSET_W-1:0] offset;
} req_addr_t;

logic is_cpu_req_d, is_cpu_req_q;
logic cpu_if_we_d, cpu_if_we_q;
req_addr_t cpu_if_addr_d, cpu_if_addr_q;
logic [CPU_DW/8-1:0] cpu_if_sel_d, cpu_if_sel_q;
logic [CPU_DW-1:0] cpu_if_wdata_d, cpu_if_wdata_q;

localparam unsigned SB_DW = 32;
localparam unsigned SB_AW = 3;

logic sb_we, sb_re;
logic [SB_DW-1:0] sb_wdata, sb_rdata;
logic sb_empty, sb_full;
logic [SB_AW:0] sb_fill_count;

// -------------------- Memory Instantiations --------------------

always_comb begin
    cpu_if_we_d = cpu_if_we_q;
    cpu_if_addr_d = cpu_if_addr_q;
    cpu_if_sel_d = cpu_if_sel_q;
    cpu_if_wdata_d = cpu_if_wdata_q;

    // save the request when one is present
    if (is_cpu_req_d) begin
        cpu_if_we_d = cpu_if.we;
        cpu_if_addr_d = cpu_if.addr;
        cpu_if_sel_d = cpu_if.sel;
        cpu_if_wdata_d = cpu_if.wdata;
    end
end

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
logic [LINE_W/8-1:0] data_mem_wsel;
logic [INDEX_W-1:0] data_mem_raddr;
logic [INDEX_W-1:0] data_mem_waddr;

generate
    for (genvar i = 0; i < NUM_WAYS; ++i) begin
        sdp_mem_with_sel #(.DW(LINE_W), .AW(INDEX_W), .INIT_MEM('0)) data_mem
        (
            .clk_i(clk_i),

            .en_a_i(data_mem_re),
            .addr_a_i(data_mem_raddr),
            .rdata_a_o(data_mem_rdata[i]),

            .en_b_i(data_mem_we[i]),
            .addr_b_i(data_mem_waddr),
            .wdata_b_i(data_mem_wdata),
            .wsel_b_i(data_mem_wsel)
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
logic miss, read_miss, read_hit;
logic write_miss, write_hit;
logic memory_send_req;
logic memory_resp_valid;
logic update_age;
logic restart;

logic install_cache_line;
logic write_into_cache_line;

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

    sb_we = '0;
    sb_wdata = '0;

    unique case (state)
        /*
        In this state, the cache accepts pipelined requests and handles them
        as soon as a request misses, the cpu wb bus is stalled and the state 
        changes to REFILL
        */
        RUNNING: begin
            unique case (1'b1)
                read_miss: begin
                    cpu_if_stall = 1'b1; // can't access anymore requests
                    memory_send_req = 1'b1;
                    next = WAIT_MEMORY;
                end

                write_miss: begin
                    sb_we = 1'b1; // append to write buffer
                    // TODO: do we need to stall the interface ? we can keep going i think
                    // FIXME: need to stall if the write buffer is full 
                end

                write_hit: begin
                    sb_we = 1'b1; // append to write buffer
                    write_into_cache_line = 1'b1;
                    // update the cache line
                end
                default: begin end
            endcase
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
            install_cache_line = 1'b1;

            // early restart
            restart = 1'b1;

            update_age = 1'b1;
            next = RUNNING;
        end
    endcase
end


logic mem_if_cyc;
logic mem_if_stb;
logic mem_if_we;
logic [$bits(mem_if.sel)-1:0] mem_if_sel;
logic [$bits(mem_if.addr)-1:0] mem_if_addr;
logic [LINE_W-1:0] mem_if_wdata;

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
                mem_if_addr = cpu_if_addr_q[CPU_AW-1 : 2]; // TODO: localparam this
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
assign tag_mem_raddr = cpu_if_addr_d.index;
assign data_mem_raddr = cpu_if_addr_d.index;
assign valid_bits_raddr = cpu_if_addr_d.index;

// ------------------- Hit or Miss logic -------------------

logic [NUM_WAYS-1:0] cache_line_valid ; // determines which way is valid
logic [$clog2(NUM_WAYS)-1:0] cache_line_valid_idx ;
logic cache_hit;
logic sb_hit;
logic [DATA_W-1:0] read_word; // the word requested by the cpu

logic sb_check;
logic [CPU_AW-1:0] sb_check_address;
logic sb_match;

// read hit = hit in cache line | hit in write buffer
// write hit = hit in cache line only (we don't check the write buffer)

generate
    for (genvar i = 0; i < NUM_WAYS; ++i) begin: calc_line_valid
        assign cache_line_valid[i] = (cpu_if_addr_q.tag == tag_mem_rdata[i]) & (valid_bits_rdata[i]);
    end
endgenerate

assign sb_check = is_cpu_req_d; // results are valid at the next posedge
assign sb_check_address = cpu_if_addr_d;
assign sb_hit = get_decision & sb_match;

always_comb begin: calc_valid_index
    for (int i = 0 ; i < NUM_WAYS; ++i) begin
        cache_line_valid_idx = i;
        if (cache_line_valid[i]) begin
            break;
        end
    end
end

assign cache_hit = get_decision & |cache_line_valid;

assign read_hit = !cpu_if_we_q & (cache_hit | sb_hit);
assign write_hit = cpu_if_we_q & (cache_hit);

assign read_miss = get_decision & !cpu_if_we_q & !read_hit;
assign write_miss = get_decision & cpu_if_we_q & !write_hit;

assign read_word = get_data_from_line(cpu_if_addr_q.offset, data_mem_rdata[cache_line_valid_idx]);

function [DATA_W-1:0] get_data_from_line (logic [OFFSET_W-1:0] offset, logic [LINE_W-1:0] line_data);
    get_data_from_line = DATA_W'(line_data >> (DATA_W * offset));
endfunction

logic cpu_if_ack;
logic [DATA_W-1:0] cpu_if_rdata;

// cpu wishbone logic
always_comb begin
    cpu_if_ack = restart | cache_hit;
    cpu_if_rdata = restart ? get_data_from_line(cpu_if_addr_q.offset, mem_if_rdata_q)
        : read_word;
end

always_ff @(posedge clk_i) begin
    if (!rstn_i) begin
        cpu_if_addr_q <= '0;
        cpu_if_we_q <= '0;
        cpu_if_wdata_q <= '0;
        cpu_if_sel_q <= '0;
        is_cpu_req_q <= '0;
    end else begin
        cpu_if_addr_q <= cpu_if_addr_d;
        cpu_if_we_q <= cpu_if_we_d;
        cpu_if_wdata_q <= cpu_if_wdata_d;
        cpu_if_sel_q <= cpu_if_sel_d;
        is_cpu_req_q <= is_cpu_req_d;
    end
end

always_ff @(posedge clk_i) begin
    if (!rstn_i) begin
        set_age <= '{default: '0};
    end else if (update_age) begin
        set_age[cpu_if_addr_q.index] = ~replace_way_idx; // the new points now points to the other way
    end
end

// Replacement logic
assign replace_way_idx = set_age[cpu_if_addr_q.index];

// ------------------- Logic that interacts with the tag, data memories -------------------
always_comb begin
    // defaults
    valid_bits_we = '{default: '0};
    tag_mem_we = '{default: '0};
    data_mem_we = '{default: '0};
    data_mem_wsel = {($size(data_mem_wsel)){1'b1}};

    tag_mem_waddr = cpu_if_addr_q.index;
    tag_mem_wdata = cpu_if_addr_q.tag;
    data_mem_waddr = cpu_if_addr_q.index;

    valid_bits_waddr = cpu_if_addr_q.index;
    valid_bits_wdata = 1'b1;

    unique case (1'b1)
        install_cache_line: begin
            tag_mem_we[replace_way_idx] = 1'b1;
            data_mem_we[replace_way_idx] = 1'b1;
            data_mem_wdata = mem_if_rdata_q;
            valid_bits_we[replace_way_idx] = 1'b1;
        end

        write_into_cache_line: begin
            data_mem_we[cache_line_valid_idx] = 1'b1;

            // the written word is smaller than the cache line
            // position it correctly
            data_mem_wdata = cpu_if_wdata_q << (8 * cpu_if_addr_q.offset);
            data_mem_wsel = cpu_if_sel_q << (8 * cpu_if_addr_q.offset);
        end
    endcase
end

// --------------------- Write Buffer ---------------------
write_buffer 
#(
    .STORED_DATA_WIDTH(SB_DW),
    .STORED_ADDRESS_WIDTH(CPU_AW),
    .DEPTH_LOG2(SB_AW)
)
write_buffer_i 
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    // write side
    .we_i(sb_we),
    .store_data_i(cpu_if_wdata_q),
    .store_sel_i(cpu_if_sel_q),
    .store_address_i(cpu_if_addr_q),

    // read side
    .re_i(sb_re),
    .rdata_o(sb_rdata),

    // status
    .fill_count_o(sb_fill_count),
    .empty_o(sb_empty),
    .full_o(sb_full),

    // logic for load hazard detection
    .check_i(sb_check),
    .check_address_i(sb_check_address),
    .check_sel_i('0),
    .check_data_i('0),
    .check_we_i('0),
    .hit_o(sb_match)
);

// assign cpu wishbone outputs
assign cpu_if.rdata = cpu_if_rdata;
assign cpu_if.rty = '0;
assign cpu_if.ack = cpu_if_ack;
assign cpu_if.stall = cpu_if_stall;
assign cpu_if.err = '0;

// assign memory wishbone outputs
assign mem_if.cyc = '0;
assign mem_if.stb = '0;
assign mem_if.we = mem_if_we;
assign mem_if.addr = mem_if_addr;
assign mem_if.sel = mem_if_sel;
assign mem_if.wdata = mem_if_wdata;

endmodule: data_cache
