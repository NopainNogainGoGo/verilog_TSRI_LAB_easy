module LBP (
    input             clk,
    input             reset,
    input      [7:0]  gray_data,
    
    output     [5:0]  gray_addr,
    output            gray_req,
    output reg [5:0]  lbp_addr,
    output reg        lbp_write,
    output     [7:0]  lbp_data,
    output reg        finish
);


    localparam IDLE    = 2'd0,
               PROCESS = 2'd1,
               WRITE   = 2'd2,
               DONE    = 2'd3;

    reg [1:0] curr_state, next_state;
    reg [3:0] step;             // 0: 讀 gc, 1~8: 讀 g0~g7 並計算
    reg [5:0] center_addr;      // 目前中心像素的地址 
    reg [7:0] gc;               // 僅儲存中心像素
    reg [7:0] lbp;              // 作為 Shift Register 使用
    reg [5:0] offset;           // 共享加法器的偏移量

    // ==========================================
    // 共享加法器與地址
    // ==========================================
    assign gray_req  = (curr_state == PROCESS && step <= 4'd8);
    assign lbp_data = lbp;
    assign gray_addr = center_addr + offset;

    // 6-bit 補數
    always @(*) begin
        case(step)
            4'd0: offset = 6'd0;   // 中心像素 (gc)
            4'd1: offset = 6'd55;  // -9 (g0)
            4'd2: offset = 6'd56;  // -8 (g1)
            4'd3: offset = 6'd57;  // -7 (g2)
            4'd4: offset = 6'd63;  // -1 (g3)
            4'd5: offset = 6'd1;   // +1 (g4)
            4'd6: offset = 6'd7;   // +7 (g5)
            4'd7: offset = 6'd8;   // +8 (g6)
            4'd8: offset = 6'd9;   // +9 (g7)
            default: offset = 6'd0;
        endcase
    end

    // ==========================================
    // FSM 
    // ==========================================
    always @(posedge clk or posedge reset) begin
        if(reset) curr_state <= IDLE;
        else      curr_state <= next_state;
    end

    always @(*) begin
        case(curr_state)
            IDLE:    next_state = PROCESS;
            PROCESS: next_state = (step == 4'd8) ? WRITE : PROCESS;
            WRITE:   begin
                // 是否處理完最後一個像素 (地址 54, 座標 6,6)
                if (center_addr == 6'd54) next_state = DONE;
                else                      next_state = PROCESS;
            end
            DONE:    next_state = DONE;
            default: next_state = PROCESS;
        endcase
    end

    // ==========================================
    // Step Counter
    // ==========================================
    always @(posedge clk or posedge reset) begin
        if (reset) 
            step <= 4'd0;
        else if (curr_state == PROCESS)
            step <= step + 1'b1;
        else 
            step <= 4'd0;
    end

    // ==========================================
    // center_addr
    // ==========================================
    always @(posedge clk or posedge reset) begin
        if (reset) 
            center_addr <= 6'd9;
        else if (curr_state == WRITE) begin
            // 換行：x=6 時跳 3 格，否則跳 1 格
            if (center_addr[2:0] == 3'd6) 
                center_addr <= center_addr + 6'd3;
            else 
                center_addr <= center_addr + 6'd1;
        end
    end

    // ==========================================
    // Center Pixel 
    // ==========================================
    always @(posedge clk or posedge reset) begin
        if (reset) 
            gc <= 8'd0;
        else if (curr_state == PROCESS && step == 4'd0) 
            gc <= gray_data;
    end

    // ==========================================
    // LBP Result
    // ==========================================
    always @(posedge clk or posedge reset) begin
        if (reset) 
            lbp <= 8'd0;
        else if (curr_state == PROCESS)
            lbp <= { (gray_data >= gc), lbp[7:1] };
    end

    // ==========================================
    // lbp_addr & lbp_write
    // ==========================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            lbp_addr  <= 6'd0;
            lbp_write <= 1'b0;
        end else if (curr_state == WRITE) begin
            lbp_addr  <= center_addr;
            lbp_write <= 1'b1;
        end else begin
            lbp_write <= 1'b0;
        end
    end


    // ==========================================
    // finish
    // ==========================================
    always @(posedge clk or posedge reset) begin
        if (reset) 
            finish <= 1'b0;
        else if (curr_state == DONE) 
            finish <= 1'b1;
        else 
            finish <= 1'b0;
    end

endmodule
