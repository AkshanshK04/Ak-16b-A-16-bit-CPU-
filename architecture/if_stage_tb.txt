`timescale 1ns/1ns
module if_stage_tb;

    reg clk;
    reg rst;
    reg stall_if;
    reg branch_taken;
    reg [15:0] branch_target;

    wire [15:0] if_pc;
    wire [15:0] if_instr;

    if_stage dut (
        .clk (clk),
        .rst(rst),
        .stall_if( stall_if),
        .branch_taken(branch_taken),
        .branch_target(branch_target),
        .if_pc(if_pc),
        .if_instr(if_instr)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("if_stage.vcd");
        $dumpvars(0, if_stage_tb);

        rst =1 ;
        stall_if = 0;
        branch_taken = 0;
        branch_target = 16'd0;

        #20;
        rst = 0;
        #50;
        branch_taken = 1;
        branch_target = 16'd10;
        #10;
        branch_taken=0;

        #50;
        $finish;
    end

    initial begin
        $monitor("T=%0t | PC =%d | INSTR = %h",
                    $time, if_pc, if_instr);
    end
endmodule