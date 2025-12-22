`timescale 1ns/1ns

// ============================================
// EX2 Stage (EX/MEM Pipeline Register)
// ============================================

module ex2_stage(
    input wire clk,
    input wire rst,

    // Inputs from EX1 stage
    input wire [15:0] alu_result_in,
    input wire [15:0] rs2_data_in,
    input wire [3:0] rd_in,

    input wire reg_write_in,
    input wire mem_read_in,
    input wire mem_write_in,
    input wire mem_to_reg_in,

    // Outputs to MEM stage
    output reg [15:0] alu_result_out,
    output reg [15:0] rs2_data_out,
    output reg [3:0] rd_out,

    output reg reg_write_out,
    output reg mem_read_out,
    output reg mem_write_out,
    output reg mem_to_reg_out
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            alu_result_out <= 16'd0;
            rs2_data_out   <= 16'd0;
            rd_out         <= 4'd0;

            reg_write_out  <= 1'b0;
            mem_read_out   <= 1'b0;
            mem_write_out  <= 1'b0;
            mem_to_reg_out <= 1'b0;
        end
        else begin
            alu_result_out <= alu_result_in;
            rs2_data_out   <= rs2_data_in;
            rd_out         <= rd_in;

            reg_write_out  <= reg_write_in;
            mem_read_out   <= mem_read_in;
            mem_write_out  <= mem_write_in;
            mem_to_reg_out <= mem_to_reg_in;
        end
    end

endmodule
