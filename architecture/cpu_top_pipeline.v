`timescale 1ns/1ns
`include "def_opcode.v"

module cpu_top_pipeline (
    input wire clk,
    input wire rst
);

    // Wires for all stages 
    
    // IF Stage
    wire [15:0] if_pc, if_instr;
    wire if_stall, if_flush;
    
    // ID Stage
    wire [15:0] id_pc, id_instr;
    wire [3:0] id_opcode, id_rd, id_rs1, id_rs2;
    wire [15:0] id_rs1_data, id_rs2_data, id_imm;
    wire id_reg_write, id_alu_src, id_mem_read, id_mem_write, id_mem_to_reg;
    wire id_branch, id_branch_ne, id_jump;
    wire [3:0] id_alu_op;
    wire id_halt, id_pc_write;
    
    // EX1 Stage
    wire [15:0] ex1_pc, ex1_rs1_data, ex1_rs2_data, ex1_imm;
    wire [3:0] ex1_rd, ex1_rs1, ex1_rs2, ex1_alu_op;
    wire ex1_reg_write, ex1_alu_src, ex1_mem_read, ex1_mem_write, ex1_mem_to_reg;
    wire ex1_branch, ex1_branch_ne;
    wire [15:0] ex1_alu_result, ex1_branch_target;
    wire ex1_zero;
    wire [1:0] forward_a, forward_b;
    wire [15:0] ex1_rs1_fwd, ex1_rs2_fwd;
    
    // EX2 Stage  
    wire [15:0] ex2_alu_result, ex2_rs2_data, ex2_branch_target;
    wire [3:0] ex2_rd;
    wire ex2_reg_write, ex2_mem_read, ex2_mem_write, ex2_mem_to_reg;
    wire ex2_branch, ex2_branch_ne, ex2_zero;
    
    // MEM Stage
    wire [15:0] mem_alu_result, mem_rs2_data, mem_read_data, mem_branch_target;
    wire [3:0] mem_rd;
    wire mem_reg_write, mem_mem_read, mem_mem_write, mem_mem_to_reg;
    wire mem_branch, mem_branch_ne, mem_zero;
    
    // WB Stage
    wire [15:0] wb_alu_result, wb_mem_data, wb_write_data;
    wire [3:0] wb_rd;
    wire wb_reg_write, wb_mem_to_reg;
    
    // Control signals
    wire stall_signal, flush_signal;
    wire branch_taken, jump_taken;
    wire [15:0] jump_target;
    wire ifid_write_en;
    
    // HALT logic
    reg halted;
    always @(posedge clk or posedge rst) begin
        if (rst)
            halted <= 1'b0;
        else if (id_halt)
            halted <= 1'b1;
    end

    // Hazard Detection
    hazard_unit u_hazard (
        .ifid_rs1(id_rs1),
        .ifid_rs2(id_rs2),
        .idex_rd(ex1_rd),
        .idex_mem_read(ex1_mem_read),
        .pc_write(id_pc_write),
        .ifid_write(ifid_write_en),
        .idex_flush(flush_signal)
    );
    
    // Stall when hazard detected
    assign stall_signal = ~ifid_write_en;
    
    // Jump detection in ID stage 
    assign jump_taken = id_jump && !stall_signal;
    assign jump_target = {{4{id_instr[11]}}, id_instr[11:0]};  // Sign-extend 12-bit for JUMP
    
    // Branch decision in EX2 stage
    assign branch_taken = (ex2_branch && ex2_zero) || (ex2_branch_ne && !ex2_zero);
    
    // Flush IF/ID if branch or jump taken
    assign if_flush = branch_taken || jump_taken;
    
    // IF Stage 
    if_stage u_if (
        .clk(clk),
        .rst(rst),
        .stall_if(stall_signal || halted),
        .flush_if(if_flush),
        .halt(halted),
        .branch_taken(branch_taken),
        .branch_target(ex2_branch_target),
        .jump_taken(jump_taken),
        .jump_target(jump_target),
        .if_pc(if_pc),
        .if_instr(if_instr)
    );

    // IF/ID Pipeline 
    pipe_if_id u_if_id (
        .clk(clk),
        .rst(rst),
        .stall(stall_signal),
        .flush(if_flush),
        .if_pc(if_pc),
        .if_instr(if_instr),
        .id_pc(id_pc),
        .id_instr(id_instr)
    );

    // ID Stage 
    assign id_opcode = id_instr[15:12];
    assign id_rd = id_instr[11:8];
    assign id_rs1 = id_instr[7:4];
    assign id_rs2 = id_instr[3:0];
    assign id_imm = {{12{id_instr[3]}}, id_instr[3:0]};  // Sign-extend 4-bit immediate

    control u_ctrl (
        .opcode(id_opcode),
        .is_nop(id_instr == 16'h0000),
        .reg_write(id_reg_write),
        .alu_src(id_alu_src),
        .mem_read(id_mem_read),
        .mem_write(id_mem_write),
        .mem_to_reg(id_mem_to_reg),
        .branch(id_branch),
        .branch_ne(id_branch_ne),
        .jump(id_jump),
        .alu_op(id_alu_op),
        .halt(id_halt)
    );

    regfile u_rf (
        .clk(clk),
        .rst(rst),
        .reg_write(wb_reg_write),
        .rs1(id_rs1),
        .rs2(id_rs2),
        .rd(wb_rd),
        .rd_data(wb_write_data),
        .rs1_data(id_rs1_data),
        .rs2_data(id_rs2_data)
    );

    // ID/EX Pipeline
    pipe_id_ex u_id_ex (
        .clk(clk),
        .rst(rst),
        .flush(flush_signal || if_flush),
        .id_pc(id_pc),
        .id_rs1(id_rs1),
        .id_rs2(id_rs2),
        .id_rd(id_rd),
        .id_rs1_data(id_rs1_data),
        .id_rs2_data(id_rs2_data),
        .id_imm(id_imm),
        .id_alu_op(id_alu_op),
        .id_reg_write(id_reg_write),
        .id_alu_src(id_alu_src),
        .id_mem_read(id_mem_read),
        .id_mem_write(id_mem_write),
        .id_mem_to_reg(id_mem_to_reg),
        .id_branch(id_branch),
        .id_branch_ne(id_branch_ne),
        .ex_pc(ex1_pc),
        .ex_rs1(ex1_rs1),
        .ex_rs2(ex1_rs2),
        .ex_rd(ex1_rd),
        .ex_rs1_data(ex1_rs1_data),
        .ex_rs2_data(ex1_rs2_data),
        .ex_imm(ex1_imm),
        .ex_alu_op(ex1_alu_op),
        .ex_reg_write(ex1_reg_write),
        .ex_alu_src(ex1_alu_src),
        .ex_mem_read(ex1_mem_read),
        .ex_mem_write(ex1_mem_write),
        .ex_mem_to_reg(ex1_mem_to_reg),
        .ex_branch(ex1_branch),
        .ex_branch_ne(ex1_branch_ne)
    );

    // Forwarding Unit 
    forwarding_unit u_fwd (
        .idex_rs1(ex1_rs1),
        .idex_rs2(ex1_rs2),
        .exmem_reg_write(ex2_reg_write),
        .exmem_mem_to_reg(ex2_mem_to_reg),
        .exmem_rd(ex2_rd),
        .memwb_reg_write(mem_reg_write),
        .memwb_rd(mem_rd),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    // EX1 Stage 
    // Forwarding muxes - forward from EX2 or MEM stage
    assign ex1_rs1_fwd = (forward_a == 2'b10) ? ex2_alu_result :
                         (forward_a == 2'b01) ? mem_alu_result : 
                         ex1_rs1_data;
    
    assign ex1_rs2_fwd = (forward_b == 2'b10) ? ex2_alu_result :
                         (forward_b == 2'b01) ? mem_alu_result : 
                         ex1_rs2_data;
    
    // ALU input B mux: immediate or register
    wire [15:0] alu_input_b = ex1_alu_src ? ex1_imm : ex1_rs2_fwd;
    
    // ALU instance
    alu u_alu (
        .a(ex1_rs1_fwd),
        .b(alu_input_b),
        .alu_op(ex1_alu_op),
        .alu_result(ex1_alu_result),
        .zero(ex1_zero)
    );
    
    // Branch target calculation
    assign ex1_branch_target = ex1_pc + ex1_imm;

    // EX1/EX2 Pipeline
    pipe_ex1_ex2 u_ex1_ex2 (
        .clk(clk),
        .rst(rst),
        .ex1_alu_result(ex1_alu_result),
        .ex1_rs2_data(ex1_rs2_fwd),
        .ex1_rd(ex1_rd),
        .ex1_branch_target(ex1_branch_target),
        .ex1_zero(ex1_zero),
        .ex1_reg_write(ex1_reg_write),
        .ex1_mem_read(ex1_mem_read),
        .ex1_mem_write(ex1_mem_write),
        .ex1_mem_to_reg(ex1_mem_to_reg),
        .ex1_branch(ex1_branch),
        .ex1_branch_ne(ex1_branch_ne),
        .ex2_alu_result(ex2_alu_result),
        .ex2_rs2_data(ex2_rs2_data),
        .ex2_rd(ex2_rd),
        .ex2_branch_target(ex2_branch_target),
        .ex2_zero(ex2_zero),
        .ex2_reg_write(ex2_reg_write),
        .ex2_mem_read(ex2_mem_read),
        .ex2_mem_write(ex2_mem_write),
        .ex2_mem_to_reg(ex2_mem_to_reg),
        .ex2_branch(ex2_branch),
        .ex2_branch_ne(ex2_branch_ne)
    );

    // EX2/MEM Pipeline
    pipe_ex2_mem u_ex2_mem (
        .clk(clk),
        .rst(rst),
        .flush_mem(1'b0),
        .ex2_alu_result(ex2_alu_result),
        .ex2_rs2_data(ex2_rs2_data),
        .ex2_rd(ex2_rd),
        .ex2_branch_target(ex2_branch_target),
        .ex2_reg_write(ex2_reg_write),
        .ex2_mem_read(ex2_mem_read),
        .ex2_mem_write(ex2_mem_write),
        .ex2_mem_to_reg(ex2_mem_to_reg),
        .ex2_branch(ex2_branch),
        .ex2_branch_ne(ex2_branch_ne),
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

    // MEM Stage
    dmem u_dmem (
        .clk(clk),
        .addr(mem_alu_result),
        .write_data(mem_rs2_data),
        .mem_write(mem_mem_write),
        .mem_read(mem_mem_read),
        .read_data(mem_read_data)
    );

    // MEM/WB Pipeline
    pipe_mem_wb u_mem_wb (
        .clk(clk),
        .rst(rst),
        .mem_to_reg_in(mem_mem_to_reg),
        .reg_write_in(mem_reg_write),
        .alu_result_in(mem_alu_result),
        .mem_data_in(mem_read_data),
        .rd_in(mem_rd),
        .mem_to_reg(wb_mem_to_reg),
        .reg_write(wb_reg_write),
        .alu_result(wb_alu_result),
        .mem_data(wb_mem_data),
        .rd(wb_rd)
    );

    // WB Stage
    assign wb_write_data = wb_mem_to_reg ? wb_mem_data : wb_alu_result;

endmodule