`timescale 1ns/1ns

module cpu_tb_pipeline;

    reg clk;
    reg rst;

    // Instantiate CPU
    cpu_top_pipeline dut (
        .clk(clk),
        .rst(rst)
    );

    // Clock generation: 10ns period (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // VCD dump for waveform viewing
    initial begin
        $dumpfile("cpu_pipeline.vcd");
        $dumpvars(0, cpu_tb_pipeline);
    end

    // Reset sequence
    initial begin
        rst = 1;
        #25;  // Hold reset for 2.5 cycles
        rst = 0;
        $display("=== Reset released at T=%0t ===\n", $time);
    end

    // Display pipeline snapshot header
    initial begin
        $display("\n=== AK-16 6-STAGE PIPELINE CPU SIMULATION START ===");
        $display("=== Stages: IF -> ID -> EX1 -> EX2 -> MEM -> WB ===\n");
        $display("Time    | IF_PC | IF_INSTR | ID_INSTR | EX1_RD | EX2_RD | MEM_RD | WB_RD | WB_W");
        $display("--------|-------|----------|----------|--------|--------|--------|-------|-----");
    end

    // Monitor pipeline state every cycle
    always @(posedge clk) begin
        if (!rst) begin
            $display("%7t | %04h  |   %04h   |   %04h   |   %1h    |   %1h    |   %1h    |  %1h    |  %b",
                $time,
                dut.if_pc,
                dut.if_instr,
                dut.id_instr,
                dut.ex1_rd,
                dut.ex2_rd,
                dut.mem_rd,
                dut.wb_rd,
                dut.wb_reg_write
            );
        end
    end

    // Timeout after max cycles
    initial begin
        #10000;  // 10us = 1000 cycles
        $display("\n=== TIMEOUT: Maximum cycles reached ===");
        dump_state();
        $finish;
    end

    // Detect HALT and finish
    always @(posedge clk) begin
        if (dut.halted && !rst) begin
            #20;  // Wait 2 cycles to let pipeline drain
            $display("\n=== HALT DETECTED at T=%0t ===", $time);
            dump_state();
            $display("\n=== SIMULATION COMPLETE ===\n");
            $finish;
        end
    end

    // Task: dump final state of registers & memory
    task dump_state;
        integer i;
        begin
            $display("\n========================================");
            $display("=== FINAL PROCESSOR STATE ===");
            $display("========================================");
            
            $display("\n=== REGISTER FILE ===");
            for (i = 0; i < 16; i = i + 1) begin
                $display("R%-2d = 0x%04h (%6d) %s",
                         i,
                         dut.u_rf.regs[i],
                         $signed(dut.u_rf.regs[i]),
                         (i == 0) ? "<- Always 0" : ""
                );
            end

            $display("\n=== DATA MEMORY [0..15] ===");
            for (i = 0; i < 16; i = i + 1) begin
                if (i % 4 == 0) $write("\n");
                $write("mem[%2d]=0x%04h  ", i, dut.u_dmem.mem[i]);
            end
            $display("\n");
            
            $display("\n=== PIPELINE STATE ===");
            $display("IF  stage: PC=0x%04h, Instr=0x%04h", dut.if_pc, dut.if_instr);
            $display("ID  stage: Instr=0x%04h", dut.id_instr);
            $display("EX1 stage: RD=%1h", dut.ex1_rd);
            $display("EX2 stage: RD=%1h", dut.ex2_rd);
            $display("MEM stage: RD=%1h", dut.mem_rd);
            $display("WB  stage: RD=%1h, Write=%b", dut.wb_rd, dut.wb_reg_write);
            
            $display("\n=== CONTROL SIGNALS ===");
            $display("Halted: %b", dut.halted);
            $display("Stall:  %b", dut.stall_signal);
            $display("Flush:  %b", dut.flush_signal);
            $display("========================================\n");
        end
    endtask

endmodule