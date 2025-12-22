`timescale 1ns/1ns

module pipe_mem_wb(
    input wire clk,
    input wire rst,
    input wire flush,           

    // Inputs from MEM stage
    input wire mem_to_reg_in,
    input wire reg_write_in,
    input wire [15:0] alu_result_in,
    input wire [15:0] mem_data_in,
    input wire [3:0] rd_in,

    // Outputs to WB stage
    output reg mem_to_reg,
    output reg reg_write,
    output reg [15:0] alu_result,
    output reg [15:0] mem_data,
    output reg [3:0] rd
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mem_to_reg <= 1'b0;
            reg_write  <= 1'b0;
            alu_result <= 16'd0;
            mem_data   <= 16'd0;
            rd         <= 4'd0;
        end
        else if (flush) begin
            //  Inject NOP into WB
            mem_to_reg <= 1'b0;
            reg_write  <= 1'b0;
            alu_result <= 16'd0;
            mem_data   <= 16'd0;
            rd         <= 4'd0;
        end
        else begin
            mem_to_reg <= mem_to_reg_in;
            reg_write  <= reg_write_in;
            alu_result <= alu_result_in;
            mem_data   <= mem_data_in;
            rd         <= rd_in;
        end
    end

endmodule
