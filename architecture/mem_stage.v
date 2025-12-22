`timescale 1ns/1ns
`include "def_opcode.v"

// mem stage

module mem_stage (
    input wire clk,
    input wire rst,

    input wire mem_read_in,
    input wire mem_write_in,
    input wire mem_to_reg_in,
    input wire reg_write_in,

    input wire [15:0] alu_result_in,
    input wire [15:0] rs2_data_in,
    input wire [3:0] rd_in,

    output reg mem_to_reg_out,
    output reg reg_write_out,
    output reg [15:0] alu_result_out,
    output reg [15:0] mem_data_out,
    output reg [3:0] rd_out
);


    reg [15:0] dmem[0:255];
    integer i;
    initial begin 
        for ( i=0; i<256; i=i+1)
            dmem[i] = 16'd0;
    end
    wire [7:0] mem_addr = alu_result_in[7:0];

    always @(posedge clk or posedge rst ) begin
        if (rst) begin
            mem_data_out <= 16'd0;
        end
        else begin 
            if (mem_write_in) begin
                dmem[mem_addr] <= rs2_data_in;
            end

            if (mem_read_in) begin
                mem_data_out <= dmem[mem_addr];
            end
            else begin
                mem_data_out <= 16'd0;
            end
        end
    end

    always @(posedge clk or posedge rst ) begin
        if (rst) begin
            mem_to_reg_out <= 1'b0;
            reg_write_out <= 1'b0;
            alu_result_out <= 16'd0;
            rd_out <= 4'd0;
        end
        else begin 
            mem_to_reg_out <= mem_to_reg_in;
            reg_write_out <= reg_write_in;
            alu_result_out <= alu_result_in;
            rd_out <= rd_in;
        end
    end
endmodule
