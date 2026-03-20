module encoder(
    input clk,reset,
    input [31:0]ml,
    output reg [4:0] match_label,
    output reg match_hit
   );


reg [23:0] reg1;
reg [15:0] reg2;
reg [7:0]  reg3;

reg reg1_hit, reg2_hit, reg3_hit;
reg [4:0] reg1_label, reg2_label, reg3_label;
//**************************Priority_Encoder************************************************

// stage1
always @ (posedge clk or posedge reset)begin
    if (reset)begin
        reg1_hit <=0 ;
        reg1_label <=0;
    end
    else begin
        casez(ml[7:0])
            8'bzzzzzzz1:begin reg1_hit <=1 ;reg1_label <=0; end
            8'bzzzzzz10:begin reg1_hit <=1 ;reg1_label <=1; end
            8'bzzzzz100:begin reg1_hit <=1 ;reg1_label <=2; end
            8'bzzzz1000:begin reg1_hit <=1 ;reg1_label <=3; end
            8'bzzz10000:begin reg1_hit <=1 ;reg1_label <=4; end
            8'bzz100000:begin reg1_hit <=1 ;reg1_label <=5; end
            8'bz1000000:begin reg1_hit <=1 ;reg1_label <=6; end
            8'b10000000:begin reg1_hit <=1 ;reg1_label <=7; end
            default: begin reg1_hit <=0 ; reg1_label <=0; end
        endcase
        reg1 <= ml[31:8];
    end
end


// stage2
always @ (posedge clk or posedge reset)begin
    if (reset)begin
        reg2_hit <=0 ;
        reg2_label <=0;
    end
    else if (reg1_hit)begin
        reg2_hit <= reg1_hit;
        reg2_label <= reg1_label;
    end
    else begin
        casez(reg1[7:0])
            8'bzzzzzzz1:begin reg2_hit <=1 ;reg2_label <=8; end
            8'bzzzzzz10:begin reg2_hit <=1 ;reg2_label <=9; end
            8'bzzzzz100:begin reg2_hit <=1 ;reg2_label <=10; end
            8'bzzzz1000:begin reg2_hit <=1 ;reg2_label <=11; end
            8'bzzz10000:begin reg2_hit <=1 ;reg2_label <=12; end
            8'bzz100000:begin reg2_hit <=1 ;reg2_label <=13; end
            8'bz1000000:begin reg2_hit <=1 ;reg2_label <=14; end
            8'b10000000:begin reg2_hit <=1 ;reg2_label <=15; end
            default: begin reg2_hit <=0 ; reg2_label <=0; end
        endcase
        reg2 <= reg1[23:8];
    end
end

//stage3
always @ (posedge clk or posedge reset)begin
    if (reset)begin
        reg3_hit <=0 ;
        reg3_label <=0;
    end
    else if (reg2_hit)begin
        reg3_hit <= reg2_hit;
        reg3_label <= reg2_label;
    end
    else begin
        casez(reg2[7:0])
            8'bzzzzzzz1:begin reg3_hit <=1 ;reg3_label <=16; end
            8'bzzzzzz10:begin reg3_hit <=1 ;reg3_label <=17; end
            8'bzzzzz100:begin reg3_hit <=1 ;reg3_label <=18; end
            8'bzzzz1000:begin reg3_hit <=1 ;reg3_label <=19; end
            8'bzzz10000:begin reg3_hit <=1 ;reg3_label <=20; end
            8'bzz100000:begin reg3_hit <=1 ;reg3_label <=21; end
            8'bz1000000:begin reg3_hit <=1 ;reg3_label <=22; end
            8'b10000000:begin reg3_hit <=1 ;reg3_label <=23; end
            default: begin reg3_hit <=0 ; reg3_label <=0; end
        endcase
        reg3 <= reg2[15:8];
    end
end

//stage4
always @ (posedge clk or posedge reset)begin
    if (reset)begin
        match_hit <=0 ;
        match_label <=0;
    end
    else if(reg3_hit)begin
        match_hit<=reg3_hit;
        match_label<=reg3_label;
    end
    else begin
        casez(reg3[7:0])
            8'bzzzzzzz1:begin match_hit <=1 ;match_label <=24; end
            8'bzzzzzz10:begin match_hit <=1 ;match_label <=25; end
            8'bzzzzz100:begin match_hit <=1 ;match_label <=26; end
            8'bzzzz1000:begin match_hit <=1 ;match_label <=27; end
            8'bzzz10000:begin match_hit <=1 ;match_label <=28; end
            8'bzz100000:begin match_hit <=1 ;match_label <=29; end
            8'bz1000000:begin match_hit <=1 ;match_label <=30; end
            8'b10000000:begin match_hit <=1 ;match_label <=31; end
            default: begin match_hit <=0 ; match_label <=0; end
        endcase
    end
end


endmodule