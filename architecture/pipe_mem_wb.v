`timescale 1ns/1ns

module pipe_mem_wb(
    input wire clk,
    input wire rst,

    //ips from mem stage
    input wire [15:0] alu_out,
    input wire [15:0] mem_data,
    input wire [3:0] rd,

    
    // ops to WB stage
    output reg [15:0] wb_data,
    output reg [3:0] wb_rd,

    
);

    always @(posedge clk or posedge rst ) begin
        if (rst) begin
           
            wb_data <= 16'd0;
            wb_rd <= 4'd0;

        end
        else begin
            wb_data <= mem_data ? mem_data : alu_out;
            wb_rd <= rd;
        end
    end
endmodule 