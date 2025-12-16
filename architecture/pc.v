module pc(
    input clk,
    input rst,
    input pc_write,
    input [15:0] next_pc ,
    output reg [15:0] pc
);

    always @(posedge clk or posedge rst) begin
        if (rst) 
            pc<= 16'd0;
        else if ( pc_write)
            pc<=next_pc;
    end
endmodule
        