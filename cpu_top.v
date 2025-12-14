`include "def_opcode.v"

module cpu_top(
    input clk,
    input rst
);

    //program counter wires
    wire [7:0] pc;
    wire [7:0] next_pc = pc+1;

    //instruction 
    wire [15:0] instr;

    //control signals 
    wire reg_write, alu_src;
    wire mem_read, mem_write, mem_to_reg;
    wire [3:0] alu_op;

    //regfile
    wire [15:0] rs1_data, rs2_data;
    wire [3:0] rs1_sel, rs2_sel, rd_sel;

    //ALU- the undisputed champion
    wire [15:0] alu_b;
    wire [15:0] alu_result;
    wire  zero;
    //dta memory
    wire [15:0] mem_read_data;
    wire [15:0] write_back_data;

    assign rs1_sel  = (instr[15:12] == `OPCODE_ADDI ||
                       instr[15:12] == `OPCODE_ANDI ||
                       instr[15:12] == `OPCODE_ORI  ||
                       instr[15:12] == `OPCODE_XORI ||
                       instr[15:12] == `OPCODE_LW   ||
                       instr[15:12] == `OPCODE_SW ) ? instr[7:4] : instr[11:8];

    assign rs2_sel = instr[7:4];

    assign rd_sel  = (instr[15:12] == `OPCODE_ADDI ||
                       instr[15:12] == `OPCODE_ANDI ||
                       instr[15:12] == `OPCODE_ORI  ||
                       instr[15:12] == `OPCODE_XORI ||
                       instr[15:12] == `OPCODE_LW ) ? instr[11:8] : instr[3:0];

    //pc
    pc pc0(.clk(clk), .rst(rst), .next_pc(next_pc), .pc(pc));
    
    //intruction memory
    imem imem0(.addr(pc), .instr(instr));
    
    
    //control unit - acknowledge me 
    control cu(
        .opcode(instr[15:12]),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .alu_op(alu_op),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg)
    );
    
    // register file
    regfile rf(
        .clk(clk),
        .rst(rst),
        .reg_write(reg_write),
        .rs1(rs1_sel),
        .rs2(rs2_sel),
        .rd(rd_sel),
        .rd_data(write_back_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    //ALU input mux
    assign alu_b = alu_src ? { 12'b0, instr[3:0]} : rs2_data;

    //ALU
    alu alu0(
        .a(rs1_data),
        .b(alu_b),
        .alu_control(alu_op),
        .alu_result(alu_result),
        .zero(zero)
    );

    dmem dmem0(
        .clk(clk),
        .addr(alu_result[7:0]) ,
        .write_data(rs2_data),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .read_data(mem_read_data)
    );

    assign write_back_data = mem_to_reg ? mem_read_data : alu_result ;
    
endmodule