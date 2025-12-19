`timescale 1ns/1ns

module ex1_stage(
    input wire clk,
    input wire rst,

    //from id/ex pipeline
    input wire [15:0] ex_rs1_data,
    input wire [15:0] ex_rs2_data,
    input wire [15:0] ex_imm,
    input wire ex_alu_src,      // 0=rs2, 1=imm

    //forwarding unit 
    input wire [15:0] exmem_alu_result,
    input wire [15:0] memwb_wb_data,

    //forwarding control
    input wire [1:0] forward_a,
    input wire [1:0] forward_b,

    output reg [15:0] alu_in1,
    output reg [ 15:0] alu_in2
);

    reg [15:0] src_a;
    reg [15:0] src_b;
    

    //forwarding mux for rs1
    always @(*) begin
        case(forward_a)
            2'b00 : src_a = ex_rs1_data;
            2'b01 : src_a = memwb_wb_data;
            2'b10 : src_a = exmem_alu_result;
            default : src_a = ex_rs1_data;
        endcase
    end

    //forwarding mux for rs2
    always @(*) begin
        case(forward_b) 
            2'b00 :  src_b = ex_rs2_data;
            2'b01 : src_b = memwb_wb_data;
            2'b10 : src_b = exmem_alu_result;
            default : src_b = ex_rs2_data;
        endcase
    end

    always @(*) begin
        alu_in1 = src_a;
        alu_in2 = (ex_alu_src) ? ex_imm : src_b;
    end
endmodule
