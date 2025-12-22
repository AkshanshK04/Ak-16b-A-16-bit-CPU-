`timescale 1ns/1ns
`include "def_opcode.v"

module ex1_stage(
    input wire [15:0] pc_in,

    // From ID/EX pipeline
    input wire [3:0] alu_op,
    input wire [3:0] rd,
    input wire [15:0] rs1_data,
    input wire [15:0] rs2_data,
    input wire [15:0] imm,

    input wire alu_src,      // 0=rs2, 1=imm

    // Forwarding unit signals
    input wire [1:0] forward_a,
    input wire [1:0] forward_b,
    input wire [15:0] ex2_alu_result,
    input wire [15:0] mem_wb_data,

    // Outputs
    output wire [15:0] alu_result,
    output wire zero,
    output wire [15:0] branch_target,
    output wire [3:0] rd_out
);

    assign rd_out = rd;
    
    reg [15:0] op_a, op_b;

    // Forwarding mux for rs1 (operand A)
    // 00 = no forward (use rs1_data from ID/EX)
    // 01 = forward from MEM stage
    // 10 = forward from EX2 stage
    always @(*) begin
        case(forward_a)
            2'b10: op_a = ex2_alu_result;   // Forward from EX2
            2'b01: op_a = mem_wb_data;   // Forward from MEM
            default: op_a = rs1_data;       // No forwarding
        endcase
    end

    // Forwarding mux for rs2 (operand B before alu_src mux)
    // 00 = no forward (use rs2_data from ID/EX)
    // 01 = forward from MEM stage
    // 10 = forward from EX2 stage
    always @(*) begin
        case(forward_b) 
            2'b10: op_b = ex2_alu_result;   // Forward from EX2
            2'b01: op_b = mem_wb_data;   // Forward from MEM
            default: op_b = rs2_data;       // No forwarding
        endcase
    end

    // ALU operand B selection: immediate or register
    wire [15:0] alu_b = alu_src ? imm : op_b;

    // ALU instance
    alu u_alu(
        .a(op_a),
        .b(alu_b),
        .alu_op(alu_op),
        .alu_result(alu_result),
        .zero(zero)
    );

    // Branch target calculation (PC + immediate offset)
    assign branch_target = pc_in + imm;

endmodule