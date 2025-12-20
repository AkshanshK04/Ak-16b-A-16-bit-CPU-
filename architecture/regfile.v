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

    reg [15:0] regs [0:15];
    integer i;

    // WRITE (synchronous)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 16; i = i + 1)
                regs[i] <= 16'd0;
        end else if (reg_write && rd != 4'd0) begin
            regs[rd] <= rd_data;
        end
    end

    wire [15:0] rs1_raw; 
    assign rs1_raw = (rs1==4'd0) ? 16'd0 : regs[rs1];
    wire [15:0] rs2_raw; 
    assign rs2_raw = (rs2==4'd0) ? 16'd0 : regs[rs2];
    assign rs1_data = (reg_write && (rd==rs1) && (rd != 4'd0)) ? rd_data : rs1_raw;
    assign rs2_data = (reg_write && (rd==rs2) && (rd != 4'd0)) ? rd_data : rs2_raw;

endmodule
