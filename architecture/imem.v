module imem(
    input  [15:0] addr,
    output [15:0] instr
);

    reg [15:0] mem [0:255];
    integer i;
    initial begin
        // Initialize all memory to NOP
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 16'h0000;
        $readmemh("program.hex", mem);
        
        // Debug: Display loaded instructions
        $display("\n=== Instruction Memory Loaded ===");
        $display("Addr | Instruction");
        $display("-----|------------");
        for (i = 0; i < 20; i = i + 1) begin
            if (mem[i] != 16'h0000)
                $display(" %02h  |    %04h", i, mem[i]);
        end
        $display("========================\n");
    end

    assign instr = mem[addr[7:0]];

endmodule
