module if_stage(
    input wire clk,
    input wire rst,

    // control from hazard
    input wire stall_if, //PC stall hai
    input wire flush_if,  // flush branch pe / jump 
    input wire halt,   // halt ka instruction

    //branch ka control
    input wire branch_taken,
    input wire [15:0] branch_target,

    output wire [15:0] if_pc,
    output reg [15:0] if_instr
);

    wire [15:0] next_pc;
    wire pc_en;

    //pc enable logic 
    assign pc_en = (!stall_if) && (!halt);
    //next pc
    assign next_pc = branch_taken ? branch_target 
                                    : (if_pc + 16'd1);
    pc u_pc(
        .clk (clk),
        .rst (rst),
        .pc_en (pc_en),
        .next_pc ( next_pc),
        .pc_cur (if_pc)
    );

    wire [15:0] imem_instr;
    imem u_imem(
        .clk (clk),
        .addr (if_pc),
        .instr (imem_instr)
    );

    //output reg -- if stage
    always @(posedge clk or posedge rst ) begin
        if (rst) begin
            if_instr <= 16'hE000;   //NOP
        end
        else if (flush_if) begin
            if_instr <= 16'hE000;   //i will inject NOP on branch/jmp
        end
        else if (!stall_if && !halt) begin
            if_instr <= imem_instr;
        end
    end

endmodule