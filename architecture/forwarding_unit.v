`timescale 1ns/1ns

// ============================================
// Forwarding Unit
// ============================================
// Detects data hazards and generates forwarding control signals
// for EX1 stage to forward data from EX2 or MEM stages
//
// Forwarding encoding:
// 00 = No forwarding (use data from ID/EX pipeline register)
// 01 = Forward from MEM stage
// 10 = Forward from EX2 stage (higher priority)

module forwarding_unit (
    // Source registers from ID/EX pipeline
    input wire [3:0] idex_rs1,
    input wire [3:0] idex_rs2,

    // EX2 stage (EX/MEM pipeline) info
    input wire exmem_reg_write,
    input wire exmem_mem_to_reg,
    input wire [3:0] exmem_rd,

    // MEM stage (MEM/WB pipeline) info
    input wire memwb_reg_write,
    input wire [3:0] memwb_rd,

    // Forwarding control outputs
    output reg [1:0] forward_a,    // Forwarding control for rs1
    output reg [1:0] forward_b     // Forwarding control for rs2
);

    always @(*) begin
        // Default: no forwarding
        forward_a = 2'b00;
        forward_b = 2'b00;

        // ====== Forwarding for rs1 (operand A) ======
        
        // EX2 hazard (most recent - highest priority)
        // Forward from EX2 if:
        // 1. EX2 will write to a register (exmem_reg_write)
        // 2. NOT a load instruction (load data not ready yet)
        // 3. Destination is not R0
        // 4. Destination matches source rs1
        if (exmem_reg_write && !exmem_mem_to_reg &&
            exmem_rd != 4'd0 &&
            exmem_rd == idex_rs1) begin
            forward_a = 2'b10;
        end
        // MEM hazard (older data - lower priority)
        // Forward from MEM if:
        // 1. MEM will write to a register
        // 2. Destination is not R0
        // 3. No EX2 hazard for same register (EX2 has priority)
        // 4. Destination matches source rs1
        else if (memwb_reg_write && memwb_rd != 4'd0 &&
                 !(exmem_reg_write && !exmem_mem_to_reg && exmem_rd == idex_rs1) &&
                 memwb_rd == idex_rs1) begin
            forward_a = 2'b01;
        end

        // ====== Forwarding for rs2 (operand B) ======
        
        // EX2 hazard (most recent - highest priority)
        if (exmem_reg_write && !exmem_mem_to_reg &&
            exmem_rd != 4'd0 &&
            exmem_rd == idex_rs2) begin
            forward_b = 2'b10;
        end
        // MEM hazard (older data - lower priority)
        else if (memwb_reg_write && memwb_rd != 4'd0 &&
                 !(exmem_reg_write && !exmem_mem_to_reg && exmem_rd == idex_rs2) &&
                 memwb_rd == idex_rs2) begin
            forward_b = 2'b01;
        end
    end

endmodule