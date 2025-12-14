module imem(
    input  [7:0] addr,
    output [15:0] instr
);

    reg [15:0] mem [0:255];
    integer i;
    initial begin
        
        for (i=0; i<256; i=i+1)
            mem[i] = 16'd0;
        $readmemh("program.hex", mem);
    end

    assign instr = mem[addr];

endmodule
