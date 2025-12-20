`include "def_opcode.v"

module alu(
    input [15:0] a, b,
    input [3:0] alu_op,
    output reg [15:0] alu_result,
    output  wire zero
);

    

    always @(*) begin
        alu_result = 16'd0;
        
        case(alu_op)
            `ALU_ADD: alu_result = a + b ;
            `ALU_SUB: alu_result = a - b;
            `ALU_AND: alu_result = a & b;
            `ALU_OR: alu_result= a | b;
            `ALU_XOR: alu_result = a ^ b;
            `ALU_SLT: alu_result = ($signed(a) < $signed(b) ) ? 16'd1 : 16'd0;
            default: alu_result = 16'd0;
        endcase
    end

    assign zero = (alu_result == 16'b0);
endmodule