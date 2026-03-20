module SDAM(reset_n, scl, sda, avalid, aout, dvalid, dout);
    input       reset_n;
    input       scl;  
    input       sda;

    output reg  avalid, dvalid;
    output reg [7:0]  aout;
    output reg [15:0] dout;

    localparam  IDLE  = 3'd0,
                START = 3'd1, 
                ADDR  = 3'd2, 
                DATA  = 3'd3, 
                FINISH = 3'd4;

    reg [2:0] curr_state, next_state;
    reg [3:0] cnt; 

    // cs
    always @(posedge scl or negedge reset_n) begin
        if(!reset_n) curr_state <= IDLE;
        else         curr_state <= next_state;
    end

    // ns
    always @(*) begin
        case(curr_state)
            IDLE   : next_state = (!sda) ? START : IDLE;
            START  : next_state = ADDR; // T3: 1為寫入, 0為讀取。本題假設只會出現寫入
            ADDR   : next_state = (cnt == 4'd7)  ? DATA : ADDR;
            DATA   : next_state = (cnt == 4'd15) ? FINISH : DATA;
            FINISH : next_state = IDLE; // 回到 IDLE 等待下一次 T1/T2
            default: next_state = IDLE;
        endcase
    end

    // Counter
    always @(posedge scl or negedge reset_n) begin
        if(!reset_n) 
            cnt <= 4'b0;
        else if (curr_state != next_state) // 狀態轉換時重置
            cnt <= 4'b0;
        else if (curr_state == ADDR || curr_state == DATA)
            cnt <= cnt + 4'b1;
    end

    // Data Buffering (LSB first)
    always @(posedge scl) begin
        if (curr_state == ADDR) aout[cnt] <= sda;
        if (curr_state == DATA) dout[cnt] <= sda;
    end

    // Valid Signal 
    always @(posedge scl or negedge reset_n) begin
        if (!reset_n) avalid <= 1'b0;
        else          avalid <= (next_state == FINISH);
    end

    always @(posedge scl or negedge reset_n) begin
        if (!reset_n) dvalid <= 1'b0;
        else          dvalid <= (next_state == FINISH);
    end

endmodule
