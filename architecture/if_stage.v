`timescale 1ns/1ns
`include "def_opcode.v"

module if_stage(
    input wire clk,
    input wire rst,
    input wire stall_if,
    input wire flush_if,
    input wire halt,

    input wire branch_taken,
    input wire [15:0] branch_target,

    output reg [15:0] if_pc,
    output wire [15:0] if_instr
);

    // Instruction memory instance
    imem u_imem (
        .addr(if_pc),
        .instr(if_instr)
    );

    // PC update logic
    always @(posedge clk or posedge rst) begin
        if (rst)
            if_pc <= 16'd0;
        else if (!stall_if && !halt) begin
            if_pc <= flush_if ? branch_target : if_pc + 16'd1;
        end
    end
endmodule
