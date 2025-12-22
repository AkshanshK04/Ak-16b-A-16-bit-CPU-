`timescale 1ns/1ns

// ============================================
// Register File
// ============================================
// 16 general-purpose registers (R0-R15)
// - R0 is hardwired to 0 (reads always return 0, writes ignored)
// - Synchronous write on clock edge
// - Asynchronous read (combinational)
// - Internal forwarding for back-to-back read after write

module regfile(
    input wire clk,
    input wire rst,
    input wire reg_write,
    input wire [3:0] rs1,
    input wire [3:0] rs2,
    input wire [3:0] rd,
    input wire [15:0] rd_data,
    output wire [15:0] rs1_data,
    output wire [15:0] rs2_data
);

    // 16 x 16-bit register array
    reg [15:0] regs [0:15];
    integer i;

    // ====== Synchronous Write ======
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset: Clear all registers
            for (i = 0; i < 16; i = i + 1)
                regs[i] <= 16'd0;
        end 
        else if (reg_write && rd != 4'd0) begin
            // Write to register (except R0)
            regs[rd] <= rd_data;
        end
    end

    // ====== Asynchronous Read with Internal Forwarding ======
    // Read register values (R0 always returns 0)
    wire [15:0] rs1_raw = (rs1 == 4'd0) ? 16'd0 : regs[rs1];
    wire [15:0] rs2_raw = (rs2 == 4'd0) ? 16'd0 : regs[rs2];
    
    // Internal forwarding: If reading same register being written,
    // forward the write data directly (solves read-after-write hazard)
    assign rs1_data = (reg_write && (rd == rs1) && (rd != 4'd0)) ? rd_data : rs1_raw;
    assign rs2_data = (reg_write && (rd == rs2) && (rd != 4'd0)) ? rd_data : rs2_raw;

endmodule