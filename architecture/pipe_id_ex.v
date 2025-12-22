`timescale 1ns/1ns

// ============================================
// ID/EX Pipeline Register
// ============================================
// Pipeline register between ID and EX1 stages
// Stores all data and control signals needed by EX1 stage
//
// This is the COMPLETE version with all control signals
// Note: The simple version only passes data, but we need
// control signals for proper pipeline operation

module pipe_id_ex (
    input wire clk,
    input wire rst,
    input wire flush,

    // Data inputs from ID stage
    input wire [15:0] id_pc,
    input wire [15:0] id_rs1_data,
    input wire [15:0] id_rs2_data,
    input wire [15:0] id_imm,
    input wire [3:0] id_rs1,
    input wire [3:0] id_rs2,
    input wire [3:0] id_rd,
    input wire [3:0] id_alu_op,

    // Control inputs from ID stage
    input wire id_reg_write,
    input wire id_alu_src,
    input wire id_mem_read,
    input wire id_mem_write,
    input wire id_mem_to_reg,
    input wire id_branch,
    input wire id_branch_ne,

    // Data outputs to EX1 stage
    output reg [15:0] ex_pc,
    output reg [15:0] ex_rs1_data,
    output reg [15:0] ex_rs2_data,
    output reg [15:0] ex_imm,
    output reg [3:0] ex_rs1,
    output reg [3:0] ex_rs2,
    output reg [3:0] ex_rd,
    output reg [3:0] ex_alu_op,

    // Control outputs to EX1 stage
    output reg ex_reg_write,
    output reg ex_alu_src,
    output reg ex_mem_read,
    output reg ex_mem_write,
    output reg ex_mem_to_reg,
    output reg ex_branch,
    output reg ex_branch_ne
);

    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            // Reset or flush: Insert bubble (NOP)
            ex_pc <= 16'd0;
            ex_rs1_data <= 16'd0;
            ex_rs2_data <= 16'd0;
            ex_imm <= 16'd0;
            ex_rs1 <= 4'd0;
            ex_rs2 <= 4'd0;
            ex_rd <= 4'd0;
            ex_alu_op <= 4'd0;
            
            ex_reg_write <= 1'b0;
            ex_alu_src <= 1'b0;
            ex_mem_read <= 1'b0;
            ex_mem_write <= 1'b0;
            ex_mem_to_reg <= 1'b0;
            ex_branch <= 1'b0;
            ex_branch_ne <= 1'b0;
        end
        else begin
            // Normal operation: Latch all inputs
            ex_pc <= id_pc;
            ex_rs1_data <= id_rs1_data;
            ex_rs2_data <= id_rs2_data;
            ex_imm <= id_imm;
            ex_rs1 <= id_rs1;
            ex_rs2 <= id_rs2;
            ex_rd <= id_rd;
            ex_alu_op <= id_alu_op;
            
            ex_reg_write <= id_reg_write;
            ex_alu_src <= id_alu_src;
            ex_mem_read <= id_mem_read;
            ex_mem_write <= id_mem_write;
            ex_mem_to_reg <= id_mem_to_reg;
            ex_branch <= id_branch;
            ex_branch_ne <= id_branch_ne;
        end
    end

endmodule