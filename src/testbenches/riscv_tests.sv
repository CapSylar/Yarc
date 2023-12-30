// this testbench will host the core when running the riscv-tests
// https://github.com/riscv-software-src/riscv-tests

module riscv_tests
import riscv_pkg::*;
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

logic rstn = '0;
logic rstn_t = '0;

// Instantiate Core with Memories
// ******************************************************************************************

wishbone_if imem_wb_if();
wishbone_if dmem_wb_if();

localparam SIZE_POT = 14;
dp_mem_wb #(.WIDTH(32), .SIZE_POT(SIZE_POT), .MEMFILE(MEMFILE))
mem_i
(
    .clk_i(clk),
    .rstn_i(rstn),

    // port1 - R
    .wb_if1(imem_wb_if.SLAVE),

    // port2 - R/W
    .wb_if2(dmem_wb_if.SLAVE)
);

yarc_platform yarc_platform_i
(
    .clk_i(clk),
    .rstn_i(rstn),

    // Core <-> DMEM
    .dmem_wb(dmem_wb_if.MASTER),

    // Core <-> IMEM
    .imem_wb(imem_wb_if.MASTER),

    // Platform <-> Peripherals
    .led_status_o()
);

exc_t trap;
assign trap = yarc_platform_i.core_i.mem2_trap;

logic stop_sim;

always_ff @(posedge clk, negedge rstn)
    if (!rstn) stop_sim <= '0;
    else stop_sim <= (trap == ECALL_MMODE || trap == ECALL_UMODE);


// ******************************************************************************************
task automatic eval_result(output success);
    int ticks = 0;
    success = 0;

    for (; ticks < max_ticks; ++ticks)
    begin
        @(posedge clk);
        // $display("tick %d", ticks);
        // stop the test when a trap is detected
        if (stop_sim)
        begin
            // test has stopped, check if the test passed or failed
            if (yarc_platform_i.core_i.reg_file_i.regf[3] == 1 && 
                yarc_platform_i.core_i.reg_file_i.regf[17] == 93 &&
                yarc_platform_i.core_i.reg_file_i.regf[10] == 0 )
            begin
                success = 1;
            end

            break;
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
    rstn_t = 1'b0;
    repeat(5) @(posedge clk);
    rstn_t = 1'b1;

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
    for (bit [SIZE_POT+2-1:2] start = begin_signature[SIZE_POT+2-1:2]; start < end_signature[SIZE_POT+2-1:2]; start += 4)
    begin
        for (int i = 3; i >= 0; --i) // 4 32-bit words per line
        begin
            $fwrite(fd, "%x", mem_i.mem[start + i]);
        end
        $fwrite(fd, "\n");
    end

    $fclose(fd);

endtask: dump_sig

endmodule: riscv_tests