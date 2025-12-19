module pipe_if_id (
    input wire clk,
    input wire rst,
    input wire stall_id,
    input wire flush_id,
    input wire [15:0] if_pc,
    input wire [15:0] if_instr,

    output reg [15:0] id_pc,
    output reg [15:0] id_instr
);

    always @( posedge clk or posedge rst) begin
        if ( rst) begin
            id_pc  <= 16'd0;
            id_instr <= 16'h0000;  // NOP 
        end 
        else if (flush_id)begin
            id_pc <= 16'd0;
            id_instr <= 16'h0000;
        end
        else if (!stall_id ) begin
            id_pc <= if_pc;
            id_instr <= if_instr;
        end
    end

endmodule