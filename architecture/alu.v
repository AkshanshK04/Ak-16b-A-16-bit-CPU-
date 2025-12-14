module alu(
    input [15:0] a, b,
    input [3:0] alu_control,
    output reg [15:0] alu_result,
    output zero
);

    

    always @(*) begin
        case(alu_control)
            4'h0: alu_result = a+b ;
            4'h1: alu_result = a-b;
            4'h2: alu_result = a&b;
            4'h3: alu_result= a |b;
            4'h4: alu_result = a ^b;
            4'h5: alu_result = (a < b ) ? 16'd1 : 16'd0;
            default: alu_result = 16'd0;
        endcase
    end

    assign zero = (alu_result == 16'b0);
endmodule