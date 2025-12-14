`include "def_opcode.v"

module control (
    input [3:0] opcode,
    output reg reg_write ,
    output reg alu_src ,
    output reg [3:0] alu_op ,
    output reg mem_read,
    output reg mem_write,
    output reg mem_to_reg
);

    always @(*) begin
        // Default values
        reg_write = 0;
        alu_src = 0;
        mem_read=0;
        mem_write=0;
        mem_to_reg=0;
        alu_op = `ALU_ADD;

        case (opcode)
            `OPCODE_ADD : begin reg_write=1; alu_op=`ALU_ADD; end
            `OPCODE_SUB : begin reg_write=1; alu_op=`ALU_SUB;  end
            `OPCODE_AND : begin reg_write=1; alu_op=`ALU_AND; end
            `OPCODE_OR  : begin reg_write=1; alu_op=`ALU_OR;  end
            `OPCODE_XOR : begin reg_write=1; alu_op=`ALU_XOR; end
            `OPCODE_SLT : begin reg_write=1; alu_op=`ALU_SLT;  end
            `OPCODE_ADDI : begin reg_write=1; alu_op=`ALU_ADD; alu_src=1; end 
            `OPCODE_ANDI : begin reg_write=1; alu_op=`ALU_AND; alu_src=1; end
            `OPCODE_ORI : begin reg_write=1; alu_op=`ALU_OR; alu_src=1; end
            `OPCODE_XORI : begin reg_write=1; alu_op=`ALU_XOR; alu_src=1; end
            `OPCODE_LW : begin reg_write=1; alu_op=`ALU_ADD; alu_src=1; mem_read=1; mem_to_reg=1; end
            `OPCODE_SW : begin alu_op=`ALU_ADD; alu_src=1; mem_write=1; end
            default : begin 
                // For other opcodes like BEQ, BNE, J, JAL
                reg_write = 0; 
                alu_src = 0; 
                alu_op = `ALU_ADD; 
            end
            
        endcase
    end
endmodule