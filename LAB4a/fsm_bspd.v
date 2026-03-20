// Serial Input BitStream Pattern Detector
module fsm_bspd(clk, reset, bit_in, det_out);
input 	clk, reset, bit_in;
output 	det_out;


localparam S0 = 2'd0,
           S1 = 2'd1,
           S2 = 2'd2,
           S3 = 2'd3;

// 4 state
reg [1:0] curr_state, next_state;


//cs
always @(posedge clk or posedge reset) begin
    if(reset) curr_state <= S0;
    else      curr_state <= next_state;
end


//ns
always @(*) begin
    case(curr_state)
        S0 : next_state = bit_in ? S0 : S1;
        S1 : next_state = bit_in ? S0 : S2;
        S2 : next_state = bit_in ? S3 : S2;
        S3 : next_state = bit_in ? S0 : S1;
        default: next_state = S0;
    endcase
end


//output

assign det_out = (curr_state == S3 && !bit_in) ? 1'b1 : 1'b0;


endmodule
