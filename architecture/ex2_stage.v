`timescale 1ns/1ns

module ex2_stage(
    input clk,
    input rst,
    input wire [15:0] alu_in1,
    input wire [15:0] alu_in2,
    input wire [3:0] alu_op,
    output reg [15:0] alu_result,
    output reg zero
);

    always @(*) begin
        case(alu_op)
            `ALU_ADD : alu_result = alu_in1 + alu_in2;
            `ALU_SUB : alu_result = alu_in1 - alu_in2;
            `ALU_AND : alu_result = alu_in1 & alu_in2;
            `ALU_OR : alu_result = alu_in1 | alu_in2 ;
            `ALU_XOR : alu_result = alu_in1 ^ alu_in2;
            `ALU_SLT : alu_result = ($signed(alu_in1) < $signed(alu_in2) ) ? 16'b1 : 16'b0;
            default : alu_result = 16'b0;
    endcase

    zero = (alu_result == 16'b0) ;
    end
endmodule