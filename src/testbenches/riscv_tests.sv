// this testbench will host the core when running the riscv-tests
// https://github.com/riscv-software-src/riscv-tests

module riscv_tests
#(parameter string MEMFILE = "", parameter int max_ticks = 100000)
();

// clk generation
logic clk;

// drive clock
initial
begin
    clk = 0;
    forever
    begin
        #5;
        clk = ~clk;
    end
end

logic rstn, rstn_t;

// Instantiate Core with Memories
// ******************************************************************************************

logic [31:0] imem_raddr;
logic [31:0] imem_rdata;
logic [31:0] dmem_addr;
logic dmem_read;
logic [31:0] dmem_rdata;
logic [3:0] dmem_wsel_byte;
logic [31:0] dmem_wdata;

core_top core_i
(
    .clk_i(clk),
    .rstn_i(rstn),

    .imem_read_o(),
    .imem_raddr_o(imem_raddr),
    .imem_rdata_i(imem_rdata),

    .dmem_addr_o(dmem_addr),
    .dmem_read_o(dmem_read),
    .dmem_rdata_i(dmem_rdata),
    .dmem_wsel_byte_o(dmem_wsel_byte),
    .dmem_wdata_o(dmem_wdata)
);

wire trap = core_i.mem_wb_trap;

wire imem_en = imem_raddr[31]; // starts at 0x8000_0000
wire dmem_en = dmem_addr[31]; // start at 0x8000_0000

localparam DEPTH = 14;

dp_mem #(.WIDTH(32), .DEPTH(DEPTH), .MEMFILE(MEMFILE))
mem_i
(
    .clk_i(clk),

    .en_a_i(imem_en),
    .addr_a_i(imem_raddr[DEPTH+2-1:2]),
    .rdata_a_o(imem_rdata),

    .en_b_i(dmem_en),
    .addr_b_i(dmem_addr[DEPTH+2-1:2]),
    .rdata_b_o(dmem_rdata),
    .wsel_byte_b_i(dmem_wsel_byte),
    .wdata_b_i(dmem_wdata)
);

// ******************************************************************************************

// catch write_tohost, the simulation is ended
// always_ff @(posedge clk)
// begin: write_tohost

// end

task automatic eval_result(output success);
    int ticks = 0;
    success = 0;

    for (; ticks < max_ticks; ++ticks)
    begin
        @(posedge clk);
        // $display("tick %d", ticks);
        // stop the test when a trap is detected
        if (trap)
        begin
            if (core_i.reg_file_i.regf[3] == 1 && 
                core_i.reg_file_i.regf[17] == 93 &&
                core_i.reg_file_i.regf[10] == 0 )
            begin
                success = 1;
                break;
            end
        end
    end

    if (ticks == max_ticks)
        $display("test timed out!");

endtask: eval_result

always @(posedge clk)
begin
    rstn <= rstn_t;    
end

initial
begin
    rstn_t = 1;
    @(posedge clk);
    rstn_t = 0;
    repeat(2) @(posedge clk);
    rstn_t = 1;

    $display("Running Riscv Tests!");
    run_test();

    $finish;
end

logic [31:0] begin_signature, end_signature;
string sig_filename_o;

// handles trace
initial begin
        logic [31:0] value;

        // check for start and end of memory signature
        void'($value$plusargs("begin_signature=%0h", begin_signature));
        void'($value$plusargs("end_signature=%0h", end_signature));
        void'($value$plusargs("sig_filename_o=%s", sig_filename_o)); // file to write the signature to

        $dumpfile("logs/vlt_dump.vcd");
        $dumpvars();
end

task automatic run_test();
    bit success = 0;
    eval_result(success);

    if (success)
        $display("TEST OK");
    else
        $display("TEST FAILED");

    // dump the memory signature so it can be checked with a reference
    $display("sig start: %x || sig end: %x", begin_signature, end_signature);
    $display("write sig file to %s", sig_filename_o);
    dump_sig();
endtask: run_test

task automatic dump_sig();

    int i;
    int fd;
    fd = $fopen(sig_filename_o, "w");
    
    if (!fd)
    begin
        $display("could not create file %s to dump signature", sig_filename_o);
        return;
    end

    i = 0;
    for (bit [DEPTH+2-1:2] start = begin_signature[DEPTH+2-1:2]; start < end_signature[DEPTH+2-1:2]; start += 4)
    begin
        for (int i = 3; i >= 0; --i)
            $fwrite(fd, "%x", mem_i.mem[start + i]);
        $fwrite(fd, "\n");
    end

    $fclose(fd);

endtask: dump_sig

endmodule: riscv_tests