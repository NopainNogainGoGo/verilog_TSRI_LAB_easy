module LBP (
    input             clk,           // 時鐘信號
    input             reset,         // 重置信號 (High Active)
    input      [7:0]  gray_data,     // 從記憶體讀取的灰階像素值
    
    output reg [5:0]  gray_addr,     // 要讀取的灰階記憶體地址
    output reg        gray_req,      // 灰階記憶體讀取請求
    output reg [5:0]  lbp_addr,      // LBP 結果寫入地址
    output reg        lbp_write,     // LBP 記憶體寫入致能
    output reg [7:0]  lbp_data,      // 計算出的 LBP 值
    output reg        finish         // 完成信號
);

localparam IDLE    = 3'd0,
           READ    = 3'd1,
           COMPUTE = 3'd2,
           WRITE   = 3'd3,
           DONE    = 3'd4;

reg [2:0] curr_state, next_state;
reg [2:0] x, y;         // 座標 (1~6，避開邊界)
reg [3:0] cnt;          // 0-8 9 addr
reg [7:0] buffer [0:8]; //  3x3 pixel



// cs
always @(posedge clk or posedge reset) begin
    if(reset) curr_state <= IDLE;
    else      curr_state <= next_state;
end

//ns
always @(*) begin
    case(curr_state)
        IDLE:    next_state = READ;
        READ:    next_state = (cnt == 4'd8) ? COMPUTE : READ;
        COMPUTE: next_state = WRITE;
        WRITE:   if (x == 3'd6 && y == 3'd6) next_state = DONE;
                 else next_state = READ;
        DONE:    next_state = DONE;
        default: next_state = IDLE;
    endcase
end


wire [5:0] target_addr = {y, x};    // y*8 + x

always @(posedge clk or posedge reset) begin
    if(reset) begin
        x <= 3'd1;
        y <= 3'd1;
    end else if (curr_state == WRITE && x == 3'd6) begin
        x <= 3'd1;
        y <= y + 1'b1;
    end else if (curr_state == WRITE)
        x <= x + 1'b1;
end

always @(posedge clk or posedge reset) begin
    if(reset)      cnt <= 4'd0;
    else if(curr_state == READ) cnt <= cnt + 1'b1;
    else           cnt <= 4'd0;
end

// 3x3 filter
always @(*) begin
    case(cnt)
        4'd0: gray_addr = target_addr - 6'd9; // p0: (y-1, x-1)
        4'd1: gray_addr = target_addr - 6'd8; // p1: (y-1, x)
        4'd2: gray_addr = target_addr - 6'd7; // p2: (y-1, x+1)
        4'd3: gray_addr = target_addr - 6'd1; // p3: (y,   x-1)
        4'd4: gray_addr = target_addr;        // p4: (y,   x) -> gc
        4'd5: gray_addr = target_addr + 6'd1; // p5: (y,   x+1)
        4'd6: gray_addr = target_addr + 6'd7; // p6: (y+1, x-1)
        4'd7: gray_addr = target_addr + 6'd8; // p7: (y+1, x)
        4'd8: gray_addr = target_addr + 6'd9; // p8: (y+1, x+1)
        default: gray_addr = target_addr;
    endcase
end

always @(*) begin
    gray_req = (curr_state == READ);
end

integer i;
always @(posedge clk or posedge reset) begin
    if(reset) begin
        for(i=0; i<9; i=i+1) 
            buffer[i] <= 8'd0;
    end else if(curr_state == READ) begin
        buffer[cnt] <= gray_data;
    end
end

wire [7:0] lbp_result;
assign lbp_result[0] = (buffer[0] >= buffer[4]);
assign lbp_result[1] = (buffer[1] >= buffer[4]);
assign lbp_result[2] = (buffer[2] >= buffer[4]);
assign lbp_result[3] = (buffer[3] >= buffer[4]);

assign lbp_result[4] = (buffer[5] >= buffer[4]);
assign lbp_result[5] = (buffer[6] >= buffer[4]);
assign lbp_result[6] = (buffer[7] >= buffer[4]);
assign lbp_result[7] = (buffer[8] >= buffer[4]);

always @(posedge clk or posedge reset) begin
    if(reset) begin
        lbp_data  <= 8'd0;
        lbp_addr  <= 6'd0;
        lbp_write <= 1'b0;
    end else if(curr_state == COMPUTE) begin
        lbp_data  <= lbp_result;
        lbp_addr  <= target_addr;
        lbp_write <= 1'b1;
    end else begin
        lbp_write <= 1'b0;
    end
end

always @(posedge clk or posedge reset) begin
    if(reset) finish <= 1'b0;
    else      finish <= (curr_state == DONE);
end

endmodule
