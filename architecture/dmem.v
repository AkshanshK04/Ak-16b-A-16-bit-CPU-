`timescale 1ns/1ns

module dmem(
    input wire clk,
    input wire [15:0] addr,
    input wire [15:0] write_data,
    input wire mem_write,
    input wire mem_read,
    output reg [15:0] read_data
);

    // 256 x 16-bit data memory
    reg [15:0] mem [0:255];
    integer i;

    // Initialize memory to zero
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 16'd0;
    end

    // Synchronous write (on clock edge)
    always @(posedge clk) begin
        if (mem_write) begin
            mem[addr[7:0]] <= write_data;
        end
    end

    // Asynchronous read (combinational)
    always @(*) begin
        if (mem_read)
            read_data = mem[addr[7:0]];
        else
            read_data = 16'd0;
    end

endmodule