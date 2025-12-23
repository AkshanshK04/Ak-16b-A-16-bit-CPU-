`ifndef AK16_OPCODE_V
`define AK16_OPCODE_V

// AK-16 CPU Opcode Definitions

// Instruction format: [15:12] Opcode | [11:8] rd | [7:4] rs1 | [3:0] rs2/imm

// ============ System Instructions ============
`define OP_NOP  4'h0    // NOP treated as ADD R0, R0, R0
`define OP_HALT 4'hF    // Halt processor

// ============ R-type Instructions ============
`define OP_ADD  4'h0    // rd = rs1 + rs2
`define OP_SUB  4'h1    // rd = rs1 - rs2
`define OP_AND  4'h2    // rd = rs1 & rs2
`define OP_OR   4'h3    // rd = rs1 | rs2
`define OP_XOR  4'h4    // rd = rs1 ^ rs2
`define OP_SLT  4'h5    // rd = (rs1 < rs2) ? 1 : 0 (signed)

// ============ I-type Instructions ============
`define OP_ADDI 4'h6    // rd = rs1 + sign_ext(imm)
`define OP_ANDI 4'h7    // rd = rs1 & sign_ext(imm)
`define OP_ORI  4'h8    // rd = rs1 | sign_ext(imm)
`define OP_XORI 4'h9    // rd = rs1 ^ sign_ext(imm)

// ============ Memory Instructions ============
`define OP_LW   4'hA    // rd = mem[rs1 + sign_ext(imm)]
`define OP_SW   4'hB    // mem[rs1 + sign_ext(imm)] = rs2

// ============ Control Flow Instructions ============
`define OP_BEQ  4'hC    // if (rs1 == rs2) PC = PC + sign_ext(rd)
`define OP_BNE  4'hD    // if (rs1 != rs2) PC = PC + sign_ext(rd)
`define OP_JUMP 4'hE    // PC = sign_ext(imm)

// ============ ALU Operation Codes ============
`define ALU_ADD 4'b0000 // Addition
`define ALU_SUB 4'b0001 // Subtraction
`define ALU_AND 4'b0010 // Bitwise AND
`define ALU_OR  4'b0011 // Bitwise OR
`define ALU_XOR 4'b0100 // Bitwise XOR
`define ALU_SLT 4'b0101 // Set Less Than (signed)

`endif // AK16_OPCODE_V