`timescale 1ns/1ns

module ex1_stage(
    input clk,
    input rst,
    input [15:0] rs1_data,
    input [15:0] rs2_data,
    input [15:0] imm,
    input alu_src,      // 0=rs2, 1=imm
    output reg [15:0] alu_in1,
    output reg [ 15:0] alu_in2
);

    always @(*) begin
        alu_in1 = rs1_data;
        alu_in2 = (alu_src) ? imm : rs2_data;
    end
endmodule
