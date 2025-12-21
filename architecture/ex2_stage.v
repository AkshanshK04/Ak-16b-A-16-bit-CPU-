`timescale 1ns/1ns

module ex2_stage(
    input wire [15:0] alu_result_in,
    input wire [15:0] rs2_data_in,
    input wire [3:0] rd_in,

    input wire reg_write_in,
    input wire mem_read_in,
    input wire mem_write_in,
    input wire mem_to_reg_in,

    output wire [15:0] alu_result_out,
    output wire [15:0] rs2_data_out,
    output wire [3:0] rd_out,

    output wire reg_write_out,
    output wire mem_read_out,
    output wire mem_write_out,
    output wire mem_to_reg_out
);

    assign alu_result_out = alu_result_in;
    assign rs2_data_out = rs2_data_in;
    assign rd_out = rd_in;

    assign reg_write_out = reg_write_in;
    assign mem_read_out = mem_read_in;
    assign mem_write_out = mem_write_in;
    assign mem_to_reg_out = mem_to_reg_in;

endmodule