`timescale 1ns/10ps
`define TCLK 20

module tb;

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] accum;
    reg [7:0] data;
    reg [2:0] opcode;

    // Outputs
    wire [7:0] alu_out;
    wire zero;

    // Instantiate the Unit Under Test (UUT)
    alu uut (
        .alu_out(alu_out), 
        .zero(zero), 
        .opcode(opcode), 
        .data(data), 
        .accum(accum), 
        .clk(clk), 
        .reset(reset)
    );

    // Clock Generation
    initial clk = 0;
    always #(`TCLK/2) clk = ~clk;

    // Waveform Dumping
    initial begin
        $fsdbDumpfile("alu.fsdb");
        $fsdbDumpvars(0, tb);
    end

    // Test Sequence
    initial begin
        // Initialize Inputs
        reset = 1;
        accum = 0;
        data = 0;
        opcode = 0;

        // Reset Pulse
        #(`TCLK * 2);
        reset = 0;
        #(`TCLK);

        // --- Test Case 1: ADD (001) ---
        @(negedge clk);
        opcode = 3'b001; accum = 8'h0A; data = 8'h05; // 10 + 5
        @(posedge clk); 
        #5 $display("ADD:  %d + %d = %d", accum, data, alu_out);

        // --- Test Case 2: SUB (010) ---
        @(negedge clk);
        opcode = 3'b010; accum = 8'h14; data = 8'h04; // 20 - 4
        @(posedge clk);
        #5 $display("SUB:  %d - %d = %d", accum, data, alu_out);

        // --- Test Case 3: AND (011) ---
        @(negedge clk);
        opcode = 3'b011; accum = 8'hFF; data = 8'h0F; 
        @(posedge clk);
        #5 $display("AND:  %h & %h = %h", accum, data, alu_out);

        // --- Test Case 4: XOR (100) ---
        @(negedge clk);
        opcode = 3'b100; accum = 8'hAA; data = 8'h55; 
        @(posedge clk);
        #5 $display("XOR:  %h ^ %h = %h", accum, data, alu_out);

        // --- Test Case 5: ABS (101) ---
        @(negedge clk);
        opcode = 3'b101; accum = -8'd10; // 2's complement for -10
        @(posedge clk);
        #5 $display("ABS:  abs(%d) = %d", -10, alu_out);

        // --- Test Case 6: NEG (110) ---
        @(negedge clk);
        opcode = 3'b110; accum = 8'd7; 
        @(posedge clk);
        #5 $display("NEG:  -(%d) = %d (as signed)", accum, $signed(alu_out));

        // --- Test Case 7: ZERO Flag ---
        @(negedge clk);
        accum = 8'h00; 
        #5 $display("ZERO: accum=%d, zero_flag=%b", accum, zero);

        #100;
        $finish;
    end

endmodule
