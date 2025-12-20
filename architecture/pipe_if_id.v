module pipe_if_id (
    input wire clk,
    input wire rst,
    input wire stall,
    input wire flush,
    input wire [15:0] if_pc,
    input wire [15:0] if_instr,

    output reg [15:0] id_pc,
    output reg [15:0] id_instr
);

    always @( posedge clk or posedge rst) begin
        if ( rst || flush) begin
            id_pc  <= 16'd0;
            id_instr <= 16'hE000;  // NOP 
        end 
        else if (!stall ) begin
            id_pc <= if_pc;
            id_instr <= if_instr;
        end
    end

endmodule