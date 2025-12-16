`ifndef AK16_OPCODE_V
`define AK16_OPCODE_V
//let me define opcodes for ak-16bit

// AK-16b cpu opcodes

//Instruction format:
// [15:12] - Opcode , [11:8] - rd/rs2, [7:4] - rs1, [3:0] - rs2/ imm
//System
`define OPCODE_NOP 4'h0
`define OPCODE_HALT 4'hF

//R-type 
`define OPCODE_ADD 4'h1
`define OPCODE_SUB 4'h2
`define OPCODE_AND 4'h3
`define OPCODE_OR 4'h4
`define OPCODE_XOR 4'h5
`define OPCODE_SLT 4'h6

//I-type
`define OPCODE_ADDI 4'h7
`define OPCODE_ANDI 4'h8
`define OPCODE_ORI 4'h9
`define OPCODE_XORI 4'hA
//Memory
`define OPCODE_LOAD 4'hB
`define OPCODE_STORE 4'hC

//control flow
`define OPCODE_BEQ 4'hD
`define OPCODE_BNE 4'hE
//4'hF is reserved for HALT


//ALU OP defs
`define ALU_ADD 4'h0
`define ALU_SUB 4'h1
`define ALU_AND 4'h2
`define ALU_OR 4'h3
`define ALU_XOR 4'h4
`define ALU_SLT 4'h5
`endif 
