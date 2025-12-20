module pipe_id_ex(
    input wire clk,
    input wire rst,
    input wire flush,

    //data ips from ID stage
    input wire [15:0] id_pc,
    input wire [15:0] id_instr,
    input wire [15:0] rs1_data,
    input wire [15:0] rs2_data,

    //outputs to ex stage
    output reg [15:0] ex_pc,
    output reg [15:0] ex_instr,
    output reg [15:0] ex_rs1,
    output reg [15:0] ex_rs2
    
);

    always @(posedge clk or posedge rst) begin
        if( rst || flush) begin
            //flushing ex stage
            ex_pc <= 16'd0;
            ex_instr <= 16'hE000;
            ex_rs1 <= 16'd0;
            ex_rs2 <= 16'd0;

        end
        else  begin
            // we will apss signals from id to ex
            ex_pc <= id_pc;
            ex_instr <= id_instr;
            ex_rs1 <= rs1_data;
            ex_rs2 <= rs2_data;

        end
    end
endmodule