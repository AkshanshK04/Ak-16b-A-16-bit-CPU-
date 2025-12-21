`timescale 1ns/1ns

module cpu_tb_pipeline;

    reg clk;
    reg rst;

    // Instantiate CPU
    cpu_top_pipeline dut (
        .clk(clk),
        .rst(rst)
    );

    // Clock generation: 10ns period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // VCD dump
    initial begin
        $dumpfile("cpu_pipeline.vcd");
        $dumpvars(0, cpu_tb_pipeline);
    end

    // Reset
    initial begin
        rst = 1;
        #20;
        rst = 0;
    end

    // Display pipeline snapshot
    initial begin
        $display("\n=== AK-16 PIPELINE CPU SIM START ===\n");
        $monitor(
            "T=%0t | IF_PC=%h | ID_INSTR=%h | EX_RD=%h | WB_RD=%h | WB_W=%b",
            $time,
            dut.if_pc,
            dut.id_instr,
            dut.ex_rd,
            dut.wb_rd,
            dut.wb_reg_write
        );
    end

    // Stop after certain cycles or on HALT
    initial begin
        #3000;
        dump_state();
        $finish;
    end

    always @(posedge clk) begin
        if (dut.halted && !rst) begin
            $display("\n=== HALT DETECTED ===");
            dump_state();
            #20;
            $finish;
        end
    end

    // Task: dump registers & memory
    task dump_state;
        integer i;
        begin
            $display("\n=== REGISTER FILE ===");
            for (i = 0; i < 16; i = i + 1)
                $display("R%0d = %04h (%0d)",
                         i,
                         dut.u_rf.regs[i],
                         $signed(dut.u_rf.regs[i]));

            $display("\n=== DATA MEMORY [0..7] ===");
            for (i = 0; i < 8; i = i + 1)
                $display("mem[%0d] = %04h",
                         i,
                         dut.u_dmem.mem[i]);
        end
    endtask

endmodule
