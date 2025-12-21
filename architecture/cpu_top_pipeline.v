`timescale 1ns/1ns
`include "def_opcode.v"

module cpu_top_pipeline (
    input wire clk,
    input wire rst
);

    // ---------------- IF stage ----------------
    wire [15:0] if_pc, if_instr;

    // ---------------- ID stage ----------------
    wire [15:0] id_pc, id_instr;
    wire [3:0] id_opcode = id_instr[15:12];
    wire [3:0] id_rd = id_instr[11:8];
    wire [3:0] id_rs1 = id_instr[7:4];
    wire [3:0] id_rs2 = id_instr[3:0];
    wire [15:0] id_imm = {{12{id_instr[3]}}, id_instr[3:0]};

    wire [15:0] id_rs1_data, id_rs2_data;
    wire id_reg_write, id_alu_src;
    wire id_mem_read, id_mem_write, id_mem_to_reg;
    wire id_branch, id_branch_ne, id_jump;
    wire [3:0] id_alu_op;
    wire id_halt;

    // ---------------- EX stage ----------------
    wire [15:0] ex_pc, ex_rs1_data, ex_rs2_data, ex_imm;
    wire [3:0] ex_rd;
    wire ex_reg_write, ex_alu_src;
    wire ex_mem_read, ex_mem_write, ex_mem_to_reg;
    wire ex_branch, ex_branch_ne;
    wire [3:0] ex_alu_op;

    wire [15:0] ex1_alu_result;
    wire ex1_zero;

    // Forwarding signals
    wire [1:0] forward_a, forward_b;

    // ---------------- MEM stage ----------------
    wire [15:0] mem_alu_result, mem_rs2_data, mem_branch_target;
    wire [3:0] mem_rd;
    wire mem_reg_write, mem_mem_read, mem_mem_write, mem_mem_to_reg;
    wire mem_branch, mem_branch_ne, mem_zero;

    // ---------------- WB stage ----------------
    wire [15:0] wb_alu_result, wb_read_data, wb_data;
    wire wb_mem_to_reg;
    wire wb_reg_write;
    wire [3:0] wb_rd;

    // HALT latch
    reg halted;
    always @(posedge clk or posedge rst) begin
        if (rst)
            halted <= 1'b0;
        else if (id_halt)
            halted <= 1'b1;
    end

    imem u_imem(
    .addr(if_pc),
    .instr(if_instr)
    );


    // ---------------- IF Stage ----------------
    if_stage u_if (
        .clk(clk),
        .rst(rst),
        .stall_if(halted),
        .flush_if(mem_branch || mem_branch_ne),
        .halt(id_halt),
        .branch_taken((mem_branch && mem_zero) || (mem_branch_ne && !mem_zero)),
        .branch_target(mem_branch_target),
        .if_pc(if_pc),
        .if_instr(if_instr)
    );

    // ---------------- IF/ID Pipeline ----------------
    pipe_if_id u_if_id (
        .clk(clk),
        .rst(rst),
        .stall(stall_signal),
        .flush(flush_signal),
        .if_pc(if_pc),
        .if_instr(if_instr),
        .id_pc(id_pc),
        .id_instr(id_instr)
    );

    // ---------------- Control ----------------
    control u_ctrl (
        .opcode(id_opcode),
        .stall(1'b0),
        .reg_write(id_reg_write),
        .alu_src(id_alu_src),
        .mem_read(id_mem_read),
        .mem_write(id_mem_write),
        .mem_to_reg(id_mem_to_reg),
        .branch(id_branch),
        .branch_ne(id_branch_ne),
        .jump(id_jump),
        .pc_write(),
        .alu_op(id_alu_op),
        .halt(id_halt)
    );

    // ---------------- Register File ----------------
    regfile u_rf (
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

    // ---------------- ID/EX Pipeline ----------------
    pipe_id_ex u_id_ex (
        .clk(clk),
        .rst(rst),
        .flush(mem_branch || mem_branch_ne),
        .id_pc(id_pc),
        .id_instr(id_instr),
        .rs1_data(id_rs1_data),
        .rs2_data(id_rs2_data),
        .ex_pc(ex_pc),
        .ex_instr(),
        .ex_rs1(ex_rs1_data),
        .ex_rs2(ex_rs2_data)
    );

    // ---------------- Forwarding Unit ----------------
    forwarding_unit u_fwd (
        .idex_rs1(ex_rd),
        .idex_rs2(ex_rd),
        .exmem_reg_write(mem_reg_write),
        .exmem_mem_to_reg(mem_mem_to_reg),
        .exmem_rd(mem_rd),
        .memwb_reg_write(wb_reg_write),
        .memwb_rd(wb_rd),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    // ---------------- EX1 Stage ----------------
    ex1_stage u_ex1 (
        .pc_in(ex_pc),
        .alu_op(ex_alu_op),
        .rd(ex_rd),
        .rs1_data(ex_rs1_data),
        .rs2_data(ex_rs2_data),
        .imm(ex_imm),
        .alu_src(ex_alu_src),
        .forward_a(forward_a),
        .forward_b(forward_b),
        .ex2_alu_result(mem_alu_result),
        .wb_data(wb_data),
        .alu_result(ex1_alu_result),
        .zero(ex1_zero),
        .branch_target(mem_branch_target),
        .rd_out(ex_rd)
    );

    // ---------------- EX2 Stage ----------------
    ex2_stage u_ex2 (
        .alu_result_in(ex1_alu_result),
        .rs2_data_in(ex_rs2_data),
        .rd_in(ex_rd),
        .reg_write_in(ex_reg_write),
        .mem_read_in(ex_mem_read),
        .mem_write_in(ex_mem_write),
        .mem_to_reg_in(ex_mem_to_reg),
        .alu_result_out(mem_alu_result),
        .rs2_data_out(mem_rs2_data),
        .rd_out(mem_rd),
        .reg_write_out(mem_reg_write),
        .mem_read_out(mem_mem_read),
        .mem_write_out(mem_mem_write),
        .mem_to_reg_out(mem_mem_to_reg)
    );

    // ---------------- MEM Stage ----------------
    dmem u_dmem (
        .clk(clk),
        .addr(mem_alu_result),
        .write_data(mem_rs2_data),
        .mem_write(mem_mem_write),
        .mem_read(mem_mem_read),
        .read_data(wb_read_data)
    );

    pipe_mem_wb u_mem_wb (
        .clk(clk),
        .rst(rst),
        .mem_to_reg_in(mem_mem_to_reg),
        .reg_write_in(mem_reg_write),
        .alu_result_in(mem_alu_result),
        .mem_data_in(wb_read_data),
        .rd_in(mem_rd),
        .mem_to_reg(wb_mem_to_reg),
        .reg_write(wb_reg_write),
        .alu_result(wb_alu_result),
        .mem_data(wb_read_data),
        .rd(wb_rd)
    );

    // ---------------- WB Stage ----------------
    assign wb_data = wb_mem_to_reg ? wb_read_data : wb_alu_result;

    // Branch decision
    assign mem_branch = id_branch;
    assign mem_branch_ne = id_branch_ne;
    assign mem_zero = ex1_zero;
    assign mem_branch_target = ex_pc + ex_imm;

endmodule
