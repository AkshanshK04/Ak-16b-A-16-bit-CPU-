`include "def_opcode.v"

module cpu_top(
    input clk,
    input rst
);

    //program counter wires
    wire [15:0] pc;
    reg [15:0] next_pc;
    wire [15:0] pc_plus_1;
    
    assign pc_plus_1 = pc + 16'd1;
    //instruction 
    wire [15:0] instr;

    wire[3:0] opcode ;
    assign opcode = instr[15:12];
    wire[3:0] rd = instr[11:8];
    wire[3:0] rs1 = instr[7:4];
    wire[3:0] rs2 = instr[3:0];

    wire signed [15:0] imm = {{12{instr[3]}}, instr[3:0]};

    //control signals 
    wire reg_write, alu_src;
    wire mem_read, mem_write, mem_to_reg;
    wire branch, branch_ne, pc_write;
    wire [3:0] alu_op;

    //regfile
    wire [15:0] rs1_data, rs2_data;
    wire [15:0] rd_data;

    //ALU- the undisputed champion
    wire [15:0] alu_b = alu_src ? imm : rs2_data;
    wire [15:0] alu_result;
    wire  zero;
    //data memory
    wire [15:0] mem_out;
    assign rd_data = mem_to_reg ? mem_out : alu_result;
    always @(*) begin
    next_pc = pc + 16'd1;   // default

    // BEQ
    if (opcode == 4'hD && zero) begin
        next_pc = pc + 16'd1 + imm;
    end
    // JUMP
    else if (opcode == 4'h4) begin
        next_pc = imm;
    end
    end



    pc  u_pc(clk,rst, pc_write, next_pc, pc);
    imem u_imem(pc, instr);
    control u_ctrl (.opcode(opcode),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .branch(branch),
        .branch_ne(branch_ne),
        .pc_write(pc_write),
        .alu_op(alu_op)
    );
    
    regfile u_rf(.clk(clk),
        .rst(rst),
        .reg_write(reg_write),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .rd_data(rd_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    alu u_alu(.a(rs1_data),
        .b(alu_b),
        .alu_op(alu_op),
        .alu_result(alu_result),
        .zero(zero)
    );
    
    dmem u_dmem(
        .clk(clk),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .addr(alu_result),
        .wdata(rs2_data),
        .rdata(mem_out)
    );

    
endmodule