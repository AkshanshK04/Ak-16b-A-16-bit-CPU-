`timescale 1ns/1ns

module pipe_ex2_mem (
    input wire clk,
    input wire rst,

    input wire [15:0] alu_out,
    input wire [15:0] rs2_data,
    input wire [3:0] rd,

    // mem ops
    output reg [15:0] mem_alu_out,
    output reg [15:0] mem_rs2
    output reg [3:0]  mem_rd
);

    always @(posedge clk or posedge rst ) begin
        if (rst) begin
            mem_alu_out <= 16'd0;
            mem_rs2 <= 16'd0;
            mem_rd <= 4'd0;

        end
        else  begin
            
            // normal transfer bw ex2-mem
            mem_alu_out <= alu_out;
            mem_rs2 <= rs2_data;
            mem_rd <= rd;
            
        end
    end
endmodule