module pc(
    input wire clk,
    input wire rst,
    input wire pc_en,   // use for stall control
    input wire [15:0] next_pc ,
    output reg [15:0] pc_cur
);

    always @(posedge clk or posedge rst) begin
        if (rst) 
            pc_cur<= 16'd0;
        else if ( pc_en)
            pc_cur<=next_pc;
        else
            pc_cur <= pc_cur;
    end
endmodule
        