`timescale 1ns/1ns

// ============================================
// EX1/EX2 Pipeline Register
// ============================================
// Pipeline register between EX1 and EX2 stages
// Stores all data and control signals needed by EX2 stage
//
// This is the COMPLETE version with all control signals

module pipe_ex1_ex2 (
    input wire clk,
    input wire rst,

    // Data inputs from EX1
    input wire [15:0] ex1_alu_result,
    input wire [15:0] ex1_rs2_data,
    input wire [15:0] ex1_branch_target,
    input wire [3:0] ex1_rd,
    input wire ex1_zero,

    // Control inputs from EX1
    input wire ex1_reg_write,
    input wire ex1_mem_read,
    input wire ex1_mem_write,
    input wire ex1_mem_to_reg,
    input wire ex1_branch,
    input wire ex1_branch_ne,

    // Data outputs to EX2
    output reg [15:0] ex2_alu_result,
    output reg [15:0] ex2_rs2_data,
    output reg [15:0] ex2_branch_target,
    output reg [3:0] ex2_rd,
    output reg ex2_zero,

    // Control outputs to EX2
    output reg ex2_reg_write,
    output reg ex2_mem_read,
    output reg ex2_mem_write,
    output reg ex2_mem_to_reg,
    output reg ex2_branch,
    output reg ex2_branch_ne
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset: Clear all registers
            ex2_alu_result <= 16'd0;
            ex2_rs2_data <= 16'd0;
            ex2_branch_target <= 16'd0;
            ex2_rd <= 4'd0;
            ex2_zero <= 1'b0;
            
            ex2_reg_write <= 1'b0;
            ex2_mem_read <= 1'b0;
            ex2_mem_write <= 1'b0;
            ex2_mem_to_reg <= 1'b0;
            ex2_branch <= 1'b0;
            ex2_branch_ne <= 1'b0;
        end 
        else begin
            // Normal operation: Latch all inputs
            ex2_alu_result <= ex1_alu_result;
            ex2_rs2_data <= ex1_rs2_data;
            ex2_branch_target <= ex1_branch_target;
            ex2_rd <= ex1_rd;
            ex2_zero <= ex1_zero;
            
            ex2_reg_write <= ex1_reg_write;
            ex2_mem_read <= ex1_mem_read;
            ex2_mem_write <= ex1_mem_write;
            ex2_mem_to_reg <= ex1_mem_to_reg;
            ex2_branch <= ex1_branch;
            ex2_branch_ne <= ex1_branch_ne;
        end
    end

endmodule