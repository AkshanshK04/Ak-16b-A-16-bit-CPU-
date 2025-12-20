module pipe_ex1_ex2 (
    input wire clk,
    input wire rst,

    input wire [15:0] alu_out,
    input wire [15:0] rs2_fwd,
    input wire [3:0] rd,

    output reg [15:0] ex2_alu_out,
    output reg [15:0] ex2_rs2,
    output reg [3:0] ex2_rd
);

    always @(posedge clk or posedge rst) begin
        if (rs1) begin
            ex2_alu_out <= 16'd0;
            ex2_rs2 <= 16'd0;
            ex2_rd <= 4'd0;
        end 
        else begin
            ex2_alu_out <= alu_out;
            ex2_rs2 <= rs2_fwd;
            ex2_rd <= rd;
        end
    end
endmodule