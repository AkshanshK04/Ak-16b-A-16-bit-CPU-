`ifndef AK16_OPCODE_V
`define AK16_OPCODE_V
//let me define opcodes for ak-16bit

// AK-16b cpu opcodes

//Instruction format:
// [15:12] - Opcode , [11:8] - rd, [7:4] - rs1, [3:0] - rs2/ imm
//System
//`define OP_NOP 4'h0
`define OP_HALT 4'hF

//R-type 
`define OP_ADD 4'h0
`define OP_SUB 4'h1
`define OP_AND 4'h2
`define OP_OR 4'h3
`define OP_XOR 4'h4
`define OP_SLT 4'h5

//I-type
`define OP_ADDI 4'h6
`define OP_ANDI 4'h7
`define OP_ORI 4'h8
`define OP_XORI 4'h9
//Memory
`define OP_LW 4'hA
`define OP_SW 4'hB

//control flow
`define OP_BEQ 4'hC
`define OP_BNE 4'hD
`define OP_JUMP 4'hE
//4'hF is reserved for HALT


//ALU OP defs
`define ALU_ADD 4'b0000
`define ALU_SUB 4'b0001
`define ALU_AND 4'b0010
`define ALU_OR  4'b0011
`define ALU_XOR 4'b0100
`define ALU_SLT 4'b0101

`endif 
