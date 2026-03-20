module alu (
    output reg [7:0] alu_out,
    output           zero,
    input      [7:0] accum,
    input      [7:0] data,
    input      [2:0] opcode,
    input            clk,
    input            reset
);

    assign zero = (accum == 8'b0) ? 1'b1 : 1'b0;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            alu_out <= 8'd0;
        end else begin
            case (opcode)
                3'b000:  alu_out <= accum;                      // Pass Accum
                3'b001:  alu_out <= accum + data;               // Add
                3'b010:  alu_out <= accum - data;               // Sub
                3'b011:  alu_out <= accum & data;               // AND
                3'b100:  alu_out <= accum ^ data;               // XOR
                3'b101:  alu_out <= ~accum + 8'b1;              // 2's Complement (Negate)
                3'b110:  alu_out <= (accum * 5) + (accum / 8);  // Custom Math
                3'b111: begin                                   // Conditional Pass
                    if (accum >= 8'd32)
                        alu_out <= data;
                    else
                        alu_out <= ~data;
                end
                default: alu_out <= 8'd0;
            endcase
        end
    end

endmodule
