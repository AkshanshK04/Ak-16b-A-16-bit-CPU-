module regfile(
    input clk,
    input rst,
    input reg_write,
    input [3:0] rs1,
    input [3:0] rs2,
    input [3:0] rd,
    input [15:0] rd_data,
    output [15:0] rs1_data,
    output [15:0] rs2_data
);

    reg [15:0] regs [0:15];
    integer i;

    // WRITE (synchronous)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 16; i = i + 1)
                regs[i] <= 16'd0;
        end else if (reg_write && rd != 0) begin
            regs[rd] <= rd_data;
        end
    end

    wire [15:0] rs1_data_raw = (rs1==0) ? 0 : regs[rs1];
    wire [15:0] rs2_data_raw = (rs2==0) ? 0 : regs[rs2];
    assign rs1_data = (reg_write && (rd==rs1) && (rs1 == 4'd0)) ? rd_data : rs1_data_raw;
    assign rs2_data = (reg_write && (rd==rs2) && (rs2 == 4'd0)) ? rd_data : rs2_data_raw;

endmodule
