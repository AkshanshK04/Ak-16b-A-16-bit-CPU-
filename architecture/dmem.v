module dmem(
    input clk,
    input [15:0] addr,
    input [15:0] wdata,
    input mem_write,
    input mem_read,
    output [15:0] rdata
);

    reg [15:0] mem [0:255];

    always @(posedge clk) begin
        if (mem_write) 
            mem[addr[7:0]] <= wdata;
    end

    assign rdata = mem_read ? mem[addr[7:0]] : 16'd0;

endmodule