module dmem(
    input wire clk,
    input wire [15:0] addr,
    input wire [15:0] write_data,
    input wire mem_write,
    input wire mem_read,
    output reg [15:0] read_data
);

    reg [15:0] mem [0:255];  //256 x 16-b memory
    integer i;

    initial begin
        for (i=0; i<256; i=i+1)
                mem[i] = 16'd0;
    end

    always @(posedge clk ) begin

         if (mem_write) begin
            mem[addr[7:0]] <= write_data;

        end
    end

    always @(*) begin
        if (mem_read)
            read_data = mem[addr[7:0]];
        else
            read_data = 16'd0;

    end

endmodule