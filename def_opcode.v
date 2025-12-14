//let me define opcodes for ak-16b
//R-type 
`define OPCODE_ADD 4'h0
`define OPCODE_SUB 4'h1
`define OPCODE_AND 4'h2
`define OPCODE_OR 4'h3
`define OPCODE_XOR 4'h4
`define OPCODE_SLT 4'h5

//I-type
`define OPCODE_ADDI 4'h6
`define OPCODE_ANDI 4'h7
`define OPCODE_ORI 4'h8
`define OPCODE_XORI 4'h9
//Memory
`define OPCODE_LW 4'hA
`define OPCODE_SW 4'hB

//control flow
`define OPCODE_BEQ 4'hC
`define OPCODE_BNE 4'hD
`define OPCODE_J 4'hE
`define OPCODE_JAL 4'hF

//ALU OP defs
`define ALU_ADD 4'h0
`define ALU_SUB 4'h1
`define ALU_AND 4'h2
`define ALU_OR 4'h3
`define ALU_XOR 4'h4
`define ALU_SLT 4'h5
