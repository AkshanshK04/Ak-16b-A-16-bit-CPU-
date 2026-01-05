`timescale 1ns/1ns

// Program Counter (PC) Register
// Functionality:
// Holds current program counter value
// Updates on clock edge when enabled
// Can be stalled for hazard handling

module pc(
    input wire clk,
    input wire rst,
    input wire pc_en,           // 1 = update PC, 0 = stall (freeze PC)
    input wire [15:0] next_pc,  // Next PC value to load
    output reg [15:0] pc_cur    // Current PC value
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset: Initialize PC to 0
            pc_cur <= 16'd0;
        end
        else if (pc_en) begin
            // Enabled: Update PC with next value
            pc_cur <= next_pc;
        end
        // else: Disabled (stalled), PC remains unchanged
    end

endmodule