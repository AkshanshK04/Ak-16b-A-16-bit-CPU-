`timescale 1ns/1ns

module pipe_mem_wb(
    input wire clk,
    input wire rst,
    input wire flush_wb,

    //ips from mem stage
    input wire [15:0] mem_alu_result,
    input wire [15:0] mem_read_data,
    input wire [3:0] mem_rd,

    input wire mem_reg_write,
    input wire mem_mem_to_reg,

    // ops to WB stage
    output reg [15:0] wb_alu_result,
    output reg [15:0] wb_read_data,
    output reg [3:0] wb_rd,

    output reg wb_reg_write,
    output reg wb_mem_to_reg
);

    always @(posedge clk or posedge rst ) begin
        if (rst || flush_wb) begin
            wb_alu_result <= 16'd0;
            wb_read_data <= 16'd0;
            wb_rd <= 4'd0;

            wb_reg_write <= 1'b0;
            wb_mem_to_reg <= 1'b0;
        end
        else begin
            wb_alu_result <= mem_alu_result;
            wb_read_data <= mem_read_data;
            wb_rd <= mem_rd;

            wb_reg_write <= mem_reg_write;
            wb_mem_to_reg <= mem_mem_to_reg;
        end
    end
endmodule 