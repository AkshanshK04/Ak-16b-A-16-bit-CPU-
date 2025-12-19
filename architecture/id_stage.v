`timescale 1ns/1ns
`include "def_opcode.v"

module id_stage(
    input wire clk,
    input wire rst,
    input wire  [15:0] instr,  // instr from IF stage

    input wire [15:0] wb_data,    // for write back
    input wire wb_reg_write,    // write enable from WB stage
    input wire [3:0] wb_rd,   //rd from WB stage\

    output reg [3:0] opcode,
    output reg [3:0] rd,
    output reg [3:0] rs1,
    output reg [3:0] rs2,
    output reg [15:0] rs1_data,
    output reg [15:0] rs2_data,
    output reg [15:0] imm,

    //control signals
    output reg reg_write,
    output reg alu_src,
    output reg mem_read,
    output reg mem_write,
    output reg mem_to_reg,
    output reg branch,
    output reg branch_ne,
    output reg halt,
    output reg [3:0] alu_op
);

    reg [15:0] regfile [0:15] ;

    integer i;
    always @( posedge clk or posedge rst ) begin
        if (rst) begin
            for (i=0; i<16; i=i+1)
                regfile[i] <= 16'b0;
        end
        else if (wb_reg_write && wb_rd != 4'd0) begin
            regfile[wb_rd] <= wb_data;   // write-back stage
        end
    end
    
    // decoding instruction
    always @(*) begin
        opcode = instr[15:12];
        rd = instr[11:8];
        rs1 = instr[7:4];
        rs2 = instr[3:0];
        imm = {{12{instr[3]}}, instr[3:0]}; // simple 4bit imm

        rs1_data = (rs1 == 4'd0) ? 16'd0 : regfile[rs1];
        rs2_data = (rs2 == 4'd0) ? 16'd0 : regfile[rs2];

        //default control signals bolte
        reg_write = 0;
        alu_src = 1'b0;
        mem_read = 1'b0;
        mem_write = 1'b0;
        mem_to_reg = 1'b0;
        branch = 1'b0;
        branch_ne =  1'b0;
        halt = 1'b0;
        alu_op = `ALU_ADD;

        case(opcode)
            //R-type 
            `OP_ADD : begin reg_write = 1 ; alu_op = `ALU_ADD; end
            `OP_SUB : begin reg_write = 1; alu_op = `ALU_SUB; end
            `OP_AND : begin reg_write = 1 ; alu_op = `ALU_AND; end
            `OP_OR : begin reg_write = 1; alu_op = `ALU_OR; end
            `OP_XOR : begin reg_write = 1; alu_op = `ALU_XOR; end
            `OP_SLT : begin reg_write = 1; alu_op = `ALU_SLT; end

            //I type
            `OP_ADDI : begin reg_write = 1; alu_src =1; alu_op = `ALU_ADD; end
            `OP_ANDI : begin reg_write = 1; alu_src =1; alu_op = `ALU_AND; end
            `OP_ORI : begin reg_write = 1; alu_src = 1; alu_op = `ALU_OR; end
            `OP_XORI : begin reg_write = 1; alu_src = 1; alu_op = `ALU_XOR; end

            //memory
            `OP_LW : begin reg_write = 1; alu_src =1 ; mem_read =1 ; mem_to_reg =1 ; alu_op = `ALU_ADD; end
            `OP_SW : begin alu_src =1 ; mem_write = 1; alu_op = `ALU_ADD; end

            //branch
            `OP_BEQ : begin branch =1; alu_op = `ALU_SUB; end
            `OP_BNE : begin branch =1; alu_op = `ALU_SUB; end

            //halt 
            `OP_HALT : begin halt =1 ; end
            default : begin /*eat 5 star - do nothing*/ end
    endcase
    end
endmodule