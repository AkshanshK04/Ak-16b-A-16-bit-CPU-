`timescale 1ns/1ns
`include "def_opcode.v"

module id_stage(
    input wire clk,
    input wire rst,

    input wire  [15:0] id_instr,  // instr from IF stage
    input wire [15:0] id_pc,

    input wire [15:0] wb_rd_data,    // for write back
    input wire wb_reg_write,    // write enable from WB stage
    input wire [3:0] wb_rd,   //rd from WB stage\

    output wire [3:0] opcode,
    output wire [3:0] rd,
    output wire [3:0] rs1,
    output wire [3:0] rs2,
    output wire [15:0] rs1_data,
    output wire [15:0] rs2_data,
    output wire [15:0] imm,
    output wire [15:0] pc_out

);

    
    // decoding instruction
    assign opcode = id_instr[15:12];
    assign rd = id_instr[11:8];
    assign rs1 = id_instr[7:4];
    assign rs2 = id_instr[3:0];
    assign imm = {{12{id_instr[3]}}, id_instr[3:0]}; // simple 4bit imm

    assign pc_out = id_pc;
    
    regfile u_regfile (
        .clk(clk),
        .rst(rst),
        .reg_write(wb_reg_write),
        .rs1(rs1),
        .rs2(rs2),
        .rd(wb_rd),
        .rd_data(wb_rd_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)

);

        
endmodule