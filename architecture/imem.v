module imem(
    input wire clk,
    input wire rst,
    input wire stall,
    input wire [15:0] addr,    //word addressable
    output reg [15:0] instr
);

    reg [15:0] mem [0:65535];  // 64K x 16-bit memory...thats too much for imem, but whatever
    initial begin
        $readmemh("program.hex", mem);
    end

    //Synchronous read as FPGA BRAM style
    reg [15:0] instr_next;
    always @(*) begin
        instr_next = mem[addr];
    end

    always @(posedge clk or posedge rst ) begin
        if (rst) 
            instr <= 16'd0;
        else if (!stall)
            instr <= instr_next;
    end

endmodule
