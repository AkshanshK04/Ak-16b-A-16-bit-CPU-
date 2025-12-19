`timescale 1ns/1ns

module cpu_top_pipeline (
    input wire clk,
    input wire rst
);
    wire [15:0] ex_pc ;
    wire [15:0] ex_branch_target;
    assign ex_branch_target = ex_pc + ex_imm;

    //reg for halt
    reg halted;

    //if stage wiring
    wire [15:0] if_pc;
    wire [15:0] if_instr;

    always @(posedge clk or posedge rst) begin
        if (rst) 
            halted <= 1'b0;
        else if (id_opcode == `OP_HALT)
            halted <= 1'b1;
    end 


    //HALT Latch
    always @(posedge clk or posedge rst ) begin
        if (rst)
            halted <= 1'b0;
        else if (id_halt)
            halted <= 1'b1;
    end

    wire branch_taken;
    wire [15:0] branch_target;

    if_stage u_if (
        .clk(clk),
        .rst(rst),
        .stall_if(halted)  ,   // for hazard
        .flush_if(branch_taken),
        .halt(id_halt),
        .branch_taken(branch_taken),
        .branch_target(branch_target),
        .if_pc(if_pc),
        .if_instr(if_instr)
    );

    //iF/ID pipeline regsiter
    wire [15:0] id_pc;
    wire [15:0] id_instr;

    pipe_if_id u_if_id (
        .clk(clk),
        .rst(rst),
        .stall_id(halted),
        .flush_id(branch_taken),
        .if_pc(if_pc),
        .if_instr(if_instr),
        .id_pc(id_pc),
        .id_instr(id_instr)
    );

    //IDstage + control 
    wire [3:0] id_opcode = id_instr[15:12];
    wire [3:0] id_rd = id_instr[11:8];
    wire [3:0] id_rs1 = id_instr[7:4];
    wire [3:0] id_rs2 = id_instr[3:0];
    wire [15:0] id_imm = {{12{id_instr[3]}}, id_instr[3:0]};

    // control signals
    wire id_reg_write, id_alu_src;
    wire id_mem_read, id_mem_write, id_mem_to_reg;
    wire id_branch , id_branch_ne;
    wire [3:0] id_alu_op;
    wire id_halt;

    control u_ctrl(
        .opcode(id_opcode),
        .reg_write(id_reg_write),
        .alu_src(id_alu_src),
        .mem_read(id_mem_read),
        .mem_write(id_mem_write),
        .mem_to_reg(id_mem_to_reg),
        .branch(id_branch),
        .branch_ne(id_branch_ne),
        .pc_write(),
        .alu_op(id_alu_op),
        .halt(id_halt)
    );

    //regfile
    wire [15:0] id_rs1_data, id_rs2_data;
    wire [15:0] wb_data;
    wire wb_reg_write;
    wire [3:0] wb_rd;

    regfile u_rf(
        .clk(clk),
        .rst(rst),
        .reg_write(wb_reg_write),
        .rs1(id_rs1),
        .rs2(id_rs2),
        .rd(wb_rd),
        .rd_data(wb_data),
        .rs1_data(id_rs1_data),
        .rs2_data(id_rs2_data)
    );

    //ID/EX pipeline register
    wire [15:0] ex_rs1_data , ex_rs2_data, ex_imm;
    wire [3:0] ex_rd;
    wire ex_reg_write , ex_alu_src;
    wire ex_mem_read; 
    wire ex_mem_write, ex_mem_to_reg;
    wire ex_branch, ex_branch_ne;
    wire [3:0] ex_alu_op;

    pipe_id_ex u_id_ex(
        .clk(clk),
        .rst(rst),
        .stall_ex(halted),
        .flush_ex(branch_taken),

        .id_rs1_data(id_rs1_data),
        .id_rs2_data(id_rs2_data),
        .id_imm(id_imm),
        .id_rd(id_rd),
        .id_pc(id_pc),

        .id_reg_write(id_reg_write),
        .id_alu_src(id_alu_src),
        .id_mem_read(id_mem_read),
        .id_mem_write(id_mem_write),
        .id_mem_to_reg(id_mem_to_reg),
        .id_branch(id_branch),
        .id_branch_ne(id_branch_ne),
        .id_alu_op(id_alu_op),

        .ex_rs1_data(ex_rs1_data),
        .ex_rs2_data(ex_rs2_data),
        .ex_imm(ex_imm),
        .ex_rd(ex_rd),
        .ex_pc(ex_pc),

        .ex_reg_write(ex_reg_write),
        .ex_alu_src(ex_alu_src),
        .ex_mem_read(ex_mem_read),
        .ex_mem_write(ex_mem_write),
        .ex_mem_to_reg(ex_mem_to_reg),
        .ex_branch(ex_branch),
        .ex_branch_ne(ex_branch_ne),
        .ex_alu_op(ex_alu_op)
    );

    //EX-1
    wire [15:0] ex1_alu_in1, ex1_alu_in2;

    ex1_stage u_ex1(
        .clk(clk),
        .rst(rst),
        .ex_rs1_data(ex_rs1_data),
        .ex_rs2_data(ex_rs2_data),
        .ex_imm(ex_imm),
        .ex_alu_src(ex_alu_src),
        .alu_in1(ex1_alu_in1),
        .alu_in2(ex1_alu_in2)
    );

    // EX-2
    wire [15:0] ex2_alu_result;
    wire ex2_zero;

    ex2_stage u_ex2 (
        .clk(clk),
        .rst(rst),
        .alu_in1(ex1_alu_in1),
        .alu_in2(ex1_alu_in2),
        .alu_op(ex_alu_op),
        .alu_result(ex2_alu_result),
        .zero(ex2_zero)
    );

    // ex-mem pipe
    wire [15:0] mem_alu_result, mem_rs2_data;
    wire [3:0] mem_rd;
    wire mem_reg_write, mem_mem_read, mem_mem_write, mem_mem_to_reg;
    wire mem_branch, mem_branch_ne, mem_zero;
    wire [15:0] mem_branch_target;

    pipe_ex2_mem u_ex_mem (
        .clk(clk),
        .rst(rst),
        .flush_mem(branch_taken),

        .ex2_alu_result(ex2_alu_result),
        .ex2_rs2_data(ex_rs2_data),
        .ex2_rd(ex_rd),
        .ex2_branch_target(ex_branch_target),

        .ex2_reg_write(ex_reg_write),
        .ex2_mem_read(ex_mem_read),
        .ex2_mem_write(ex_mem_write),
        .ex2_mem_to_reg(ex_mem_to_reg),
        .ex2_branch(ex_branch),
        .ex2_branch_ne(ex_branch_ne),
        .ex2_zero(ex2_zero),

        .mem_alu_result(mem_alu_result),
        .mem_rs2_data(mem_rs2_data),
        .mem_rd(mem_rd),
        .mem_branch_target(mem_branch_target),

        .mem_reg_write(mem_reg_write),
        .mem_mem_read(mem_mem_read),
        .mem_mem_write(mem_mem_write),
        .mem_mem_to_reg(mem_mem_to_reg),
        .mem_branch(mem_branch),
        .mem_branch_ne(mem_branch_ne),
        .mem_zero(mem_zero)
    );

    // mem stage
    wire [15:0] mem_read_data;
    dmem u_dmem (
        .clk(clk),
        .addr(mem_alu_result),
        .wdata(mem_rs2_data),
        .mem_write(mem_mem_write),
        .mem_read(mem_mem_read),
        .rdata(mem_read_data)
    );

    // mem-wb pipe
    wire [15:0] wb_alu_result, wb_read_data ;
    wire wb_mem_to_reg ;
    
    pipe_mem_wb u_mem_wb (
        .clk(clk),
        .rst(rst),
        .flush_wb(branch_taken),
        .mem_alu_result(mem_alu_result),
        .mem_read_data(mem_read_data),
        .mem_rd(mem_rd),
        .mem_reg_write(mem_reg_write),
        .mem_mem_to_reg(mem_mem_to_reg),
        .wb_alu_result(wb_alu_result),
        .wb_read_data(wb_read_data),
        .wb_rd(wb_rd),
        .wb_reg_write(wb_reg_write),
        .wb_mem_to_reg(wb_mem_to_reg)
    );

    // wb stage
    assign wb_data = wb_mem_to_reg ? wb_read_data : wb_alu_result;

    // branch decision
    assign branch_taken = (mem_branch && mem_zero) || (mem_branch_ne && !mem_zero);
    assign branch_target = mem_branch_target; //
endmodule
