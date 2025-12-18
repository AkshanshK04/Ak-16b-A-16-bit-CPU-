module if_stage(
    input wire clk,
    input wire rst,
    input wire stall_if,
    input wire branch_taken,
    input wire [15:0] branch_target,

    output wire [15:0] if_pc,
    output wire [15:0] if_instr
);

    wire [15:0] next_pc;
    assign next_pc = branch_taken ? branch_target 
                                    : (if_pc + 16'd1);
    pc u_pc(
        .clk (clk),
        .rst (rst),
        .pc_en (!stall_if),
        .next_pc ( next_pc),
        .pc_cur (if_pc)
    );

    imem u_imem(
        .clk (clk),
        .addr (if_pc),
        .instr (if_instr)
    );

endmodule