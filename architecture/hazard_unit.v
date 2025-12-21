module hazard_unit (
    input wire [3:0] ifid_rs1,
    input wire [3:0] ifid_rs2,

    input wire [3:0] idex_rd,

    input wire idex_mem_read,

    output reg pc_write,
    output reg ifid_write,
    output reg idex_flush
);

    always @(*) begin
        //default - koi stall nahi
        pc_write = 1'b1;
        ifid_write = 1'b1;
        idex_flush = 1'b0;

        if (idex_mem_read &&
            (idex_rd != 4'd0) &&
            ((idex_rd == ifid_rs1) ||
            (idex_rd == ifid_rs2))) begin

                //stall
                pc_write = 1'b0;
                ifid_write  = 1'b0;
                idex_flush = 1'b1;
            end
    end

endmodule