module FIR(Dout, Din, clk, reset);
parameter b0=7;
parameter b1=17;
parameter b2=32;
parameter b3=46;
parameter b4=52;
parameter b5=46;
parameter b6=32;
parameter b7=17;
parameter b8=7;

output	[17:0]	Dout;
input 	[7:0] 	Din;
input 		clk, reset;
reg	[7:0]	D_reg[7:0];
integer	i;
wire [5:0] num[8:0];


always@(posedge clk)begin
	if(reset)begin
		for(i=0;i<8;i=i+1)begin
			D_reg[i] <= 8'b0;
		end
	end
	else begin
		D_reg[0] <= Din;
		for(i=0;i<7;i=i+1)begin
			D_reg[i+1] <= D_reg[i];
		end
	end
end

assign Dout= Din[0]*b0 + D_reg[0]*b1+D_reg[1]*b2+D_reg[2]*b3+D_reg[3]*b4+D_reg[4]*b5+D_reg[5]*b6+D_reg[6]*b7+D_reg[7]*b8;                           
endmodule
