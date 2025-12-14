module dmem(
    input clk,
    input [7:0] addr,
    input [15:0] write_data,
    input mem_write,
    input mem_read,
    output [15:0] read_data
);

    reg [15:0] memory[0:255];
    integer i;
    initial begin
        
        for (i=0; i<256; i=i+1)
            memory[i] = 16'd0;
    end

    assign read_data = mem_read ? memory[addr] : 16'b0;

    always @(posedge clk) begin
        if (mem_write) 
            memory[addr] <= write_data;
    end
endmodule