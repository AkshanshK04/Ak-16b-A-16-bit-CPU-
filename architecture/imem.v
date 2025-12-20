module imem(
    input wire clk,
    input wire [15:0] addr,    //word addressable
    output reg [15:0] instr
);

    reg [15:0] mem [0:65535];  // 64K x 16-bit memory...thats too much for imem, but whatever
    initial begin
        $readmemh("program.hex", mem);
    end

    //Synchronous read as FPGA BRAM style
    always @(posedge clk) begin
        instr = mem[addr];
    end

endmodule
