`timescale 1ns/1ns
`include "def_opcode.v"

// ============================================
// IF (Instruction Fetch) Stage
// ============================================
// Responsibilities:
// 1. Maintain Program Counter (PC)
// 2. Fetch instruction from instruction memory
// 3. Handle PC updates (sequential, branch, jump)
// 4. Support stall and flush operations

module if_stage(
    input wire clk,
    input wire rst,
    
    // Control signals
    input wire stall_if,          // 1 = freeze PC (for load-use hazard)
    input wire flush_if,          // 1 = flush and update PC (for branch/jump)
    input wire halt,              // 1 = halt processor
    
    // Branch control
    input wire branch_taken,      // 1 = branch condition met
    input wire [15:0] branch_target,  // Target address for branch
    
    // Jump control
    input wire jump_taken,        // 1 = jump instruction detected
    input wire [15:0] jump_target,    // Target address for jump

    // Outputs
    output reg [15:0] if_pc,      // Current PC value
    output wire [15:0] if_instr   // Fetched instruction
);

    // ====== Instruction Memory ======
    imem u_imem (
        .addr(if_pc),
        .instr(if_instr)
    );

    // ====== PC Update Logic ======
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset: Start execution from address 0
            if_pc <= 16'd0;
        end
        else if (!stall_if && !halt) begin
            // Normal operation: update PC
            
            if (jump_taken) begin
                // Jump has highest priority (detected in ID stage)
                if_pc <= jump_target;
            end
            else if (branch_taken) begin
                // Branch taken (detected in EX2 stage)
                if_pc <= branch_target;
            end
            else begin
                // Sequential execution: PC = PC + 1
                if_pc <= if_pc + 16'd1;
            end
        end
        // else: stall_if or halt is active, PC remains unchanged
    end

endmodule