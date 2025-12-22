`timescale 1ns/1ns

// ============================================
// Hazard Detection Unit
// ============================================
// Detects load-use data hazards and generates stall signals
//
// Load-Use Hazard occurs when:
// - A load instruction (LW) is in EX1 stage
// - The following instruction in ID stage needs the loaded data
// 
// Solution: Stall pipeline for 1 cycle
// - Freeze PC (don't fetch new instruction)
// - Freeze IF/ID register (keep current instruction in ID)
// - Insert bubble in ID/EX (flush to NOP)

module hazard_unit (
    // Source registers from IF/ID pipeline (ID stage)
    input wire [3:0] ifid_rs1,
    input wire [3:0] ifid_rs2,

    // Destination register from ID/EX pipeline (EX1 stage)
    input wire [3:0] idex_rd,

    // Control signal from ID/EX pipeline
    input wire idex_mem_read,

    // Stall control outputs
    output reg pc_write,      // 1 = update PC, 0 = freeze PC
    output reg ifid_write,    // 1 = update IF/ID, 0 = freeze IF/ID
    output reg idex_flush     // 1 = insert bubble (NOP) in ID/EX
);

    always @(*) begin
        // Default: no stall
        pc_write = 1'b1;
        ifid_write = 1'b1;
        idex_flush = 1'b0;

        // Detect load-use hazard:
        // If there's a load instruction in EX1 (idex_mem_read = 1)
        // AND its destination register (idex_rd) matches either source
        // register (ifid_rs1 or ifid_rs2) of the instruction in ID stage
        // AND destination is not R0 (R0 is always 0, no hazard possible)
        if (idex_mem_read &&
            (idex_rd != 4'd0) &&
            ((idex_rd == ifid_rs1) || (idex_rd == ifid_rs2))) begin
            
            // Stall the pipeline:
            pc_write = 1'b0;      // Freeze PC (don't fetch next instruction)
            ifid_write = 1'b0;    // Freeze IF/ID (keep current instruction)
            idex_flush = 1'b1;    // Insert bubble (NOP) in EX1 stage
        end
    end

endmodule