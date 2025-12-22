`timescale 1ns/1ns

// ============================================
// Instruction Memory (IMEM)
// ============================================
// Read-only memory that stores program instructions
// - 256 words × 16-bit
// - Asynchronous read (combinational)
// - Initialized from "program.hex" file

module imem(
    input wire [15:0] addr,
    output wire [15:0] instr
);

    // 256 x 16-bit instruction memory
    reg [15:0] mem [0:255];

    // Initialize memory from hex file at simulation start
    initial begin
        $readmemh("program.hex", mem);
    end

    // Asynchronous read - instruction available immediately
    // Uses lower 8 bits of address (256 word address space)
    assign instr = mem[addr[7:0]];

endmodule