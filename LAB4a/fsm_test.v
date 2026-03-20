//******************************************************************************
// Module: test_fsm
// Description: Testbench for Serial Input Bitstream Pattern Detector (0010)
//******************************************************************************

`timescale 1ns/10ps
`define CYCLE 10
`define TOTAL_CYCLES  3000
module test_fsm;

    // --- 1. Signal Declaration ---
    reg         clk;
    reg         reset, EN, bit_in;
    wire        det_out;
    
    // Simulation / Verification Signals
    reg         answer;
    reg  [3:0]  cnt;     // Bit counter (9 down to 0)
    reg  [9:0]  data;    // Test data sequence
    reg  [4:0]  shifter; // Record input history for golden pattern
    reg  [31:0] cycle;   // Cycle counter for debugging
    
    // Parameters
    parameter [2:0] A0=3'b000, A1=3'b001, A2=3'b010, A3=3'b011, A4=3'b100;

    // --- 2. DUT Instance ---
    fsm_bspd i_fsm (
        .clk    (clk),
        .reset  (reset),
        .bit_in (bit_in),
        .det_out(det_out)
    );

    // --- 3. Clock Generation ---
    initial clk = 0;
    always #(`CYCLE/2) clk = ~clk;


    // Waveform DataBase (Verdi/Debussy) ---
    initial begin
        $fsdbDumpfile("fsm.fsdb");
        $fsdbDumpvars(0, test_fsm);
    end


    // --- 4. Initial Setup & Finish Flag ---
    initial begin
        reset  = 1'b1;
        EN     = 1'b1;
        bit_in = 1'b0;
        answer = 1'b0;
        
        #13 reset = 1'b0; // Asynchronous-like reset release
        
		wait (cycle == `TOTAL_CYCLES);

        $display("\n************************************************************");
        $display("  [PASS] Time: %0t, Finish testing PASS!!", $time);
        $display("************************************************************\n");
        $finish;
    end

    //窮舉（Exhaustive Testing）出所有可能的輸入組合
    // Counter: Controls which bit of 'data' is currently being fed
    always @(posedge clk) begin
        if (reset) 
            cnt <= 4'd9;
        else if (cnt == 0) 
            cnt <= 4'd9;
        else 
            cnt <= cnt - 1;
    end

    // Data: Increments every 10 cycles to provide various patterns
    always @(posedge clk) begin
        if (reset) 
            data <= 10'd0;
        else if (cnt == 0) 
            data <= data + 1;
    end

    // Shifter: Stores the history of bit_in to determine the expected answer
    always @(posedge clk) begin
        if (reset) 
            shifter <= 5'bxxxxx;
        else begin
			shifter <= {shifter[3:0], data[cnt]};
        end
    end

    // Input Driver
    always @(posedge clk) begin
        if (reset) 
            bit_in <= 1'b0;
        else 
            bit_in <= data[cnt];
    end

    // --- 6. Golden Pattern (Answer) Generation ---
    // Target Pattern: 0 -> 0 -> 1 -> 0
    always @(*) begin
        if (!shifter[3] && !shifter[2] && shifter[1] && !shifter[0]) 
            answer = 1'b1;
        else 
            answer = 1'b0;
    end

    // --- 7. Checker: Self-Checking Logic ---
    always @(posedge clk) begin
        if (reset) begin
            cycle <= 0;
        end else begin
            cycle <= cycle + 1;
            
            // Check output after a small delay to avoid race conditions
            #(`CYCLE/5); 
            if (det_out !== answer) begin // 使用 !== 可以捕捉到 x（未知態）或 z（高阻抗）造成的錯誤
                $display("\n[ERROR] Time: %0t, Cycle: %d", $time, cycle);
                $display("        Expected: %b, Got: %b", answer, det_out);
                $display("************************************************************\n");
                #(`CYCLE * 2);
                $finish;
            end
        end
    end

endmodule
