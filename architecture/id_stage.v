`timescale 1ns/1ns
`include "def_opcode.v"

// ============================================
// ID (Instruction Decode) Stage
// ============================================
// Responsibilities:
// 1. Decode instruction fields (opcode, rd, rs1, rs2)
// 2. Sign-extend immediate value
// 3. Read register file
// 4. Pass PC forward for branch calculation

module id_stage(
    input wire clk,
    input wire rst,

    // From IF/ID pipeline
    input wire [15:0] id_instr,
    input wire [15:0] id_pc,

    // From WB stage (for register write-back)
    input wire [15:0] wb_rd_data,
    input wire wb_reg_write,
    input wire [3:0] wb_rd,

    // Outputs to ID/EX pipeline
    output wire [3:0] opcode,
    output wire [3:0] rd,
    output wire [3:0] rs1,
    output wire [3:0] rs2,
    output wire [15:0] rs1_data,
    output wire [15:0] rs2_data,
    output wire [15:0] imm_i,
    output wire [15:0] imm_b,
    output wire [15:0] pc_out,
    output wire is_nop
);

    assign is_nop = (id_instr ==  16'h0000);
    // ====== Instruction Decode ======
    // Extract fields from 16-bit instruction
    // Format: [15:12] opcode | [11:8] rd | [7:4] rs1 | [3:0] rs2/imm
    assign opcode = id_instr[15:12];
    assign rd = id_instr[11:8];
    assign rs1 = id_instr[7:4];
    assign rs2 = id_instr[3:0];
    
    // Sign-extend 4-bit immediate to 16 bits
    // If bit[3] = 1 (negative), fill upper 12 bits with 1's
    // If bit[3] = 0 (positive), fill upper 12 bits with 0's
    assign imm_i = {{12{id_instr[3]}}, id_instr[3:0]};
    assign imm_b = {{12{id_instr[11]}}, id_instr[11:8]};

    // Pass PC forward for branch target calculation
    assign pc_out = id_pc;
    
    // ====== Register File ======
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