`timescale 1ns/1ns

// ============================================
// EX2 Stage - Passthrough Stage
// ============================================
// This stage is a simple passthrough between EX1 and MEM
// It provides an extra pipeline stage for timing optimization
// and allows for future enhancements if needed

module ex2_stage(
    // Data inputs
    input wire [15:0] alu_result_in,
    input wire [15:0] rs2_data_in,
    input wire [3:0] rd_in,

    // Control inputs
    input wire reg_write_in,
    input wire mem_read_in,
    input wire mem_write_in,
    input wire mem_to_reg_in,

    // Data outputs
    output wire [15:0] alu_result_out,
    output wire [15:0] rs2_data_out,
    output wire [3:0] rd_out,

    // Control outputs
    output wire reg_write_out,
    output wire mem_read_out,
    output wire mem_write_out,
    output wire mem_to_reg_out
);

    // Passthrough assignments - all signals go directly through
    assign alu_result_out = alu_result_in;
    assign rs2_data_out = rs2_data_in;
    assign rd_out = rd_in;

    assign reg_write_out = reg_write_in;
    assign mem_read_out = mem_read_in;
    assign mem_write_out = mem_write_in;
    assign mem_to_reg_out = mem_to_reg_in;

endmodule