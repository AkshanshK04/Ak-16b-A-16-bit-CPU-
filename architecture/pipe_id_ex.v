module pipe_id_ex(
    input wire clk,
    input wire rst,
    input wire stall _ex,
    input wire flush_ex,

    //data ips from ID stage
    input wire [15:0] id_rs1_data,
    input wire [15:0] id_rs2_data,
    input wire [15:0] id_imm,
    input wire[3:0] id_rd,

    // control signals from id stage
    input wire id_reg_write,
    input wire id_alu_src,
    input wire id_mem_read,
    input wire id_mem_write,
    input wire id_mem_to_reg,
    input wire id_branch,
    input wire id_branch_ne,
    input wire [3:0] id_alu_op,

    //outputs to ex stage
    output reg [15:0] ex_rs1_data,
    output reg [15:0] ex_rs2_data,
    output reg [15:0] ex_imm,
    output reg [3:0] ex_rd,

    output reg ex_reg_write,
    output reg ex_alu_src,
    output reg ex_mem_read,
    output reg ex_mem_write,
    output reg ex_mem_to_reg,
    output reg ex_branch,
    output reg ex_branch_ne,
    output reg [3:0] ex_alu_op,
);

    always @(*) begin
        if( rst || flush_ex) begin
            //flushing ex stage
            ex_rs1_data <= 16'd0;
            ex_rs2_data <= 16'd0;
            ex_imm <= 16'd0;
            ex_rd <= 4'b0;

            ex_reg_write <= 1'b0;
            ex_alu_src <= 1'b0;
            ex_mem_read <= 1'b0;
            ex_mem_write <= 1'b0;
            ex_mem_to_reg <= 1'b0;
            ex_branch <= 1'b0;
            ex_branch_ne <= 1'b0;
            ex_alu_op <= `ALU_ADD;
        end
        else if (!stall_ex) begin
            // we will apss signals from id to ex
            ex_rs1_data <= id_rs1_data;
            ex_rs2_data <= id_rs2_data;
            ex_imm <= id_imm;
            ex_rd <= id_rd;

            ex_reg_write <= id_reg_write;
            ex_alu_src <= id_alu_src;
            ex_mem_read <= id_mem_read;
            ex_mem_write <= id_mem_write;
            ex_mem_to_reg <= id_mem_to_reg;
            ex_branch <= id_branch;
            ex_branch_ne <= id_branch_ne;
            ex_alu_op <= id_alu_op;
        end
    end
endmodule