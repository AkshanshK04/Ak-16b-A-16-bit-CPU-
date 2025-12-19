module dmem(
    input wire clk,
    input wire rst,
    input wire [15:0] addr,
    input wire [15:0] wdata,
    input wire mem_write,
    input wire mem_read,
    output reg [15:0] rdata
);

    reg [15:0] mem [0:255];  //256 x 16-b memory
    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i=0; i<256; i=i+1)
                mem[i] <= 16'd0;
            rdata <= 16'd0;
        end
        else begin
            if (mem_write) 
                mem[addr[7:0]] <= wdata;

            if (mem_read)
                rdata <= mem[addr[7:0]];
            else 
                rdata <= 16'd0;
        end
    end

endmodule