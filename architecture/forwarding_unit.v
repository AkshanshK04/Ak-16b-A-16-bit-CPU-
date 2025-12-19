module forwarding_unit (
    //source regs from id/ex
    input wire [3:0] idex_rs1,
    input wire [3:0] idex_rs2,

    //ex/mem stage info
    input wire exmem_reg_write,
    input wire [3:0] exmem_rd,

    //mem/wb stage info
    input wire memwb_reg_write,
    input wire [3:0] memwb_rd,

    //forwarding control ops
    //00 = no forward, 10= from ex/mem , 01= from mem/wb
    output reg [1:0] forward_a,
    output reg [1:0] forward_b 
);

    always @(*) begin
        //default : no forwarding
        forward_a = 2'b00;
        forward_b = 2'b00;

        // ex/mem hazard (roman reigns)
        if (exmem_reg_write && (exmem_rd != 4'd0) &&
            (exmem_rd == idex_rs1))
            forward_a = 2'b10;
        
        if (exmem_reg_write && (exmem_rd != 4'd0) &&
            (exmem_rd == idex_rs2))
            forward_b = 2'b10;

        // mem/wb hazard
        if (memwb_reg_write && (memwb_rd != 4'd0) &&
            !(exmem_reg_write && (exmem_rd != 4'd0) &&
            (exmem_rd == idex_rs1)) &&
            (memwb_rd == idex_rs1))
            forward_a = 2'b01;
        
        if (memwb_reg_write && (memwb_rd != 4'd0) &&
            !(exmem_reg_write && (exmem_rd != 4'd0) &&
            (exmem_rd == idex_rs2)) &&
            (memwb_rd == idex_rs2))
            forward_b = 2'b01;
    end
endmodule