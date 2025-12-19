`include "def_opcode.v"

module control (
    input [3:0] opcode,
    output reg reg_write ,
    output reg alu_src ,
    output reg mem_read,
    output reg mem_write,
    output reg mem_to_reg,
    output reg branch,
    output reg branch_ne,
    output reg pc_write,
    output reg [3:0] alu_op 
    
);

    always @(*) begin
        // Default values
        reg_write = 0;
        alu_src = 0;
        mem_read=0;
        mem_write=0;
        mem_to_reg=0;
        branch = 0;
        branch_ne =0;
        pc_write = 1;
        alu_op = `ALU_ADD;

        case (opcode)
            `OP_ADD : begin reg_write=1; alu_op=`ALU_ADD; end
            `OP_SUB : begin reg_write=1; alu_op=`ALU_SUB;  end
            `OP_AND : begin reg_write=1; alu_op=`ALU_AND; end
            `OP_OR  : begin reg_write=1; alu_op=`ALU_OR;  end
            `OP_XOR : begin reg_write=1; alu_op=`ALU_XOR; end
            `OP_SLT : begin reg_write=1; alu_op=`ALU_SLT;  end

            `OP_ADDI : begin reg_write=1; alu_op=`ALU_ADD; alu_src=1; end 
            `OP_ANDI : begin reg_write=1; alu_op=`ALU_AND; alu_src=1; end
            `OP_ORI : begin reg_write=1; alu_op=`ALU_OR; alu_src=1; end
            `OP_XORI : begin reg_write=1; alu_op=`ALU_XOR; alu_src=1; end

            `OP_LW : begin reg_write=1;  alu_src=1; mem_read=1; mem_to_reg=1; end
            `OP_SW : begin  alu_src=1; mem_write=1; end
            
            `OP_BEQ : begin branch =1 ; alu_op=`ALU_SUB; alu_src=0; reg_write = 1'b0;end 
            `OP_BNE : begin branch_ne =1 ; alu_op=`ALU_SUB; alu_src=0; reg_write = 1'b0; end

            `OP_HALT : pc_write =0;         
        endcase
    end
endmodule