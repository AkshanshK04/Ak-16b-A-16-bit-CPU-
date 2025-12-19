`timescale 1ns/1ns

module pipe_ex_mem (
    input wire clk,
    input wire rst,
    input wire flush_mem,

    // ips from ex2 stage
    input wire [15:0] ex2_alu_result,
    input wire ex2_rs2_data,
    input wire ex2_rd,

    input wire ex2_reg_write,
    input wire ex2_mem_read,
    input wire ex2_mem_write,
    input wire ex2_mem_to_reg,
    input wire ex2_branch,
    input wire ex2_branch_ne,
    input wire ex2_zero,

    //ops to mem stage
    output reg [15:0] mem_alu_result,
    output reg [15:0] mem_rs2_data,
    output reg [3:0] mem_rd,

    output reg mem_reg_write,
    output reg mem_mem_read,
    output reg mem_mem_write,
    output reg mem_mem_to_reg,
    output reg mem_branch,
    output reg mem_branch_ne,
    output reg mem_zero
);

    always @(posedge clk or posedge rst ) begin
        if ( rst || flush_mem) begin
            mem_alu_result <= 16'd0;
            mem_rs2_data <= 16'd0;
            mem_rd <= 4'd0;
            
            mem_reg_write <= 1'b0;
            mem_mem_read <= 1'b0;
            mem_mem_write <= 1'b0;
            mem_mem_to_reg <= 1'b0;
            mem_branch <= 1'b0;
            mem_branch_ne <= 1'b0;
            mem_zero <= 1'b0;
        end
        else begin
            mem_alu_result <= ex2_alu_result;
            mem_rs2_data <= ex2_rs2_data;
            mem_rd <= ex2_rd;

            mem_reg_write <= ex2_reg_write;
            mem_mem_read <= ex2_mem_read;
            mem_mem_write <= ex2_mem_write;
            mem_mem_to_reg <= ex2_mem_to_reg;
            mem_branch <= ex2_branch;
            mem_branch_ne <= ex2_branch_ne;
            mem_zero <= ex2_zero;
        end
    end
endmodule
