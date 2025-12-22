`timescale 1ns/1ns

// ============================================
// IF/ID Pipeline Register
// ============================================
// Pipeline register between IF and ID stages
// Stores PC and instruction for decode stage
//
// Features:
// - Supports stall (freeze register for load-use hazard)
// - Supports flush (clear register for branch/jump)
// - NOP instruction inserted on flush (0x0000 = ADD R0,R0,R0)

module pipe_if_id (
    input wire clk,
    input wire rst,
    input wire stall,           // 1 = freeze register (don't update)
    input wire flush,           // 1 = clear register (insert NOP)
    
    // Inputs from IF stage
    input wire [15:0] if_pc,
    input wire [15:0] if_instr,

    // Outputs to ID stage
    output reg [15:0] id_pc,
    output reg [15:0] id_instr
);

    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            // Reset or flush: Insert NOP
            id_pc <= 16'd0;
            id_instr <= 16'h0000;  // NOP (ADD R0, R0, R0)
        end 
        else if (!stall) begin
            // Normal operation: Latch inputs
            id_pc <= if_pc;
            id_instr <= if_instr;
        end
        // else: Stall active, registers frozen (keep current values)
    end

endmodule