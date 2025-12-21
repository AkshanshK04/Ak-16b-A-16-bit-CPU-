`timescale 1ns/1ns

module imem(
    input wire [15:0] addr,
    output wire [15:0] instr
);
    reg [15:0] mem [0:255];

    initial begin
        $readmemh("program.hex", mem);
    end

    assign instr = mem[addr]; // continuous assignment to wire
endmodule
