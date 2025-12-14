`timescale 1ns/1ns

module cpu_tb;
    reg clk;
    reg rst;

    cpu_top dut(.clk(clk), .rst(rst));

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        //waveform dump
        $dumpfile("cpu_tb.vcd");
        $dumpvars(0, cpu_tb);
        
        // Display header
        $display("\n=== AK-16b CPU Simulation ===\n");


        rst=1;
        #15;
        rst=0;

        $display("Time=%0t : After reset, starting execution...\n", $time);
        repeat(15) begin 
            @(posedge clk);
            #1;
        
            $display("Time=%0t | PC=%0d | Instr=0x%04h" , $time, dut.pc , dut.instr);
             $display("  Control: RegWrite=%b ALUSrc=%b ALUOp=%h MemRead=%b MemWrite=%b", 
                dut.reg_write, dut.alu_src, dut.alu_op, dut.mem_read, dut.mem_write);
            $display("  ALU: rs1=%0d, rs2/imm=%0d → result=%0d (zero=%b)",
                dut.rs1_data, dut.alu_b, dut.alu_result, dut.zero);
            $display("  Registers: R1=%0d R2=%0d R3=%0d R4=%0d R5=%0d R6=%0d",
                dut.rf.regs[1], dut.rf.regs[2], dut.rf.regs[3],
                dut.rf.regs[4], dut.rf.regs[5], dut.rf.regs[6]);
            $display("");
        end
        
        $display("\n=== Final Register State ===");
        $display("R0=%0d R1=%0d R2=%0d R3=%0d R4=%0d R5=%0d R6=%0d R7=%0d",
            dut.rf.regs[0], dut.rf.regs[1], dut.rf.regs[2], dut.rf.regs[3],
            dut.rf.regs[4], dut.rf.regs[5], dut.rf.regs[6], dut.rf.regs[7]
        );
        $display("R8=%0d R9=%0d R10=%0d R11=%0d R12=%0d R13=%0d R14=%0d R15=%0d\n",
            dut.rf.regs[8], dut.rf.regs[9], dut.rf.regs[10], dut.rf.regs[11],
            dut.rf.regs[12], dut.rf.regs[13], dut.rf.regs[14], dut.rf.regs[15]
        );
        
        $display("Simulation complete!\n");
        $finish;
    end

    initial begin
        #5000;
        $display("error");
        $finish;
    end
endmodule