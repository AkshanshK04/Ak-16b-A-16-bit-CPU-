`timescale 1ns/1ns
`include "def_opcode.v"

module id_stage(
    input clk,
    input rst,
    input [15:0] instr,  // instr from IF stage
    input [15:0] regfile_data_in,    // for write back
    input reg_write_wb,    // write enable from WB stage
    input [3:0] rd_wb,   //rd from WB stage
    output reg [3:0] opcode,
    output reg [3:0] rd,
    output reg [3:0] rs1,
    output reg [3:0] rs2,
    output reg [15:0] rs1_data,
    output reg [15:0] rs2_data,
    output reg [15:0] imm,
    output reg reg_write,
    output reg [3:0] alu_op
);

    reg [15:0] regfile [0:15] ;

    integer i;
    always @( posedge clk or posedge rst ) begin
        if (rst) begin
            for (i=0; i<16; i=i+1)
                regfile[i] <= 16'b0;
        end
        else if (reg_write_wb) begin
            regfile[rd_wb] <= regfile_data_in;   // write-back stage
        end
    end
    
    // decoding instruction
    always @(*) begin
        opcode = instr[15:12];
        rd = instr[11:8];
        rs1 = instr[7:4];
        rs2 = instr[3:0];
        imm = {12'b0, instr[3:0]}; // simple 4bit imm

        rs1_data = regfile[rs1];
        rs2_data = regfile[rs2];

        //default control signals bolte
        reg_write = 0;
        alu_op = 4'h0;

        case(opcode)
            `OP_ADD : begin reg_write = 1 ; alu_op = `ALU_ADD; end
            `OP_SUB : begin reg_write = 1; alu_op = `ALU_SUB; end
            `OP_AND : begin reg_write = 1 ; alu_op = `ALU_AND; end
            `OP_OR : begin reg_write = 1; alu_op = `ALU_OR; end
            `OP_XOR : begin reg_write = 1; alu_op = `ALU_XOR; end
            `OP_SLT : begin reg_write = 1; alu_op = `ALU_SLT; end

            `OP_ADDI : begin reg_write = 1; alu_op = `ALU_ADD; end
            `OP_ANDI : begin reg_write = 1; alu_op = `ALU_AND; end
            `OP_ORI : begin reg_write = 1; alu_op = `ALU_OR; end
            `OP_XORI : begin reg_write = 1; alu_op = `ALU_XOR; end

            default : begin /*eat 5 star - do nothing*/ end
    endcase
    end
endmodule