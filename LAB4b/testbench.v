`timescale 1ns/10ps
`define simulation_time 300000000
`define cycle_time      1000.0

`define pat "./Pattern_sti.dat"
`define exp "./Pattern_exp.dat"

module testfixture;

    //---------------------------------------------------------
    // Signal & Memory Declaration
    //---------------------------------------------------------
    reg  [15:0] PAT [0:255];
    reg  [15:0] EXP [0:255];

    reg         clk = 0;
    reg         reset_n;

    wire        SCL;
    wire        SDAi;
    reg         SDAoe; 
    reg         SDAo;
    
    // I2C-like Bidirectional SDA Control
    pullup(SDA);
    assign SCL  = clk;
    assign SDA  = SDAoe ? SDAo : 1'bz;
    assign SDAi = SDA;

    //---------------------------------------------------------
    // Clock Generation
    //---------------------------------------------------------
    always #(`cycle_time/2) clk = ~clk; 

    //---------------------------------------------------------
    // DUT Instantiation
    //---------------------------------------------------------
    wire [7:0]  aout;
    wire [15:0] dout;
    wire        avalid, dvalid; // 注意：原程式碼漏掉宣告這兩個 wire

    SDAM u_SDAM (
        .reset_n(reset_n), 
        .scl(SCL), 
        .sda(SDA), 
        .avalid(avalid), 
        .aout(aout), 
        .dvalid(dvalid), 
        .dout(dout)  
    );

    //---------------------------------------------------------
    // Variables & Flags
    //---------------------------------------------------------
    integer i, j;
    integer err_cnt;
    reg     [15:0] wdata2;
    reg            check_result_flag;
    reg            tws_rdout;

    //---------------------------------------------------------
    // Main Simulation Process
    //---------------------------------------------------------
    initial begin
        // Data Initialization
        $readmemh(`pat, PAT);
        $readmemh(`exp, EXP);

        // Reset Sequence
        reset_n = 1;
        SDAoe   = 0;
        SDAo    = 1;
        err_cnt = 0;

        #1;  reset_n = 0;
        #(`cycle_time * 3); #1; reset_n = 1;

        $display(" ----------------------------------------------------------------------");
        $display(" TEST START !!!");
        $display(" ----------------------------------------------------------------------");
        
        #(`cycle_time * 0.25);

        // SDAM WRITE Test
        $display(" SDAM [ WRITE ] Test ..."); 
        $display("  ");

        for (i = 0; i <= 31; i = i + 1) begin
            $display(" Address and Data %d write...", i);
            wdata2 = PAT[i];
            tws_write(i, wdata2);
            
            $display(" Result Check ..."); 
            wait(avalid & dvalid); 
            $display("  ");
        end

        #(`cycle_time * 1);       

        // Final Report
        if (err_cnt === 0) begin
            $display("\n-----------------------------------------------------");
            $display("Congratulations! All data have been generated successfully!");
            $display("-------------------------PASS------------------------\n");
        end
        else begin
            $display("\n-----------------------------------------------------");
            $display("FAIL! Please Correct Your Code! Error Count: %d", err_cnt);
            $display("-------------------------FAIL------------------------\n");
        end

        $finish;
    end

    // Timeout Monitor
    initial begin
        #(`simulation_time);
        $display("\n-----------------------------------------------------");
        $display("The simulation can't be terminated properly! Timeout !!");
        $display("-------------------------------------------------------\n");
        $finish;
    end

    //---------------------------------------------------------
    // Result Checker
    //---------------------------------------------------------
    always @(negedge SCL) begin
        if (avalid & dvalid) begin
            check_result;
        end
    end

    //---------------------------------------------------------
    // Waveform Dump (FSDB)
    //---------------------------------------------------------
    initial begin
        $fsdbDumpfile("SDAM.fsdb");
        $fsdbDumpvars("+all");
    end

    //---------------------------------------------------------
    // TASKS
    //---------------------------------------------------------

    // Check Result Task
    task check_result;
        begin
            if (dout !== EXP[aout]) begin
                $display(" [ERROR] Pattern address %d Fail!, expected %h, got %h", aout, EXP[aout], dout);
                err_cnt = err_cnt + 1;                        
            end
        end
    endtask

    // TWS (I2C-like) Write Task
    task tws_write; 
        input [7:0]  addr;
        input [15:0] wdata;
        integer k; 
        begin
            SDAoe = 1;
            // Start bit / Preamble
            @(posedge SCL); #1; SDAo = 1;
            @(posedge SCL); #1; SDAo = 0;
            @(posedge SCL); #1; SDAo = 1;

            // Send Address (LSB to MSB)
            for (k = 0; k <= 7; k = k + 1) begin
                @(posedge SCL); #1;
                SDAo = addr[k];
            end

            // Send Data (LSB to MSB)
            for (k = 0; k <= 15; k = k + 1) begin
                @(posedge SCL); #1;
                SDAo = wdata[k];
            end

            // End bit
            @(posedge SCL); #1;
            SDAo = 1;
            #1;
            SDAoe = 0; // Release Bus
        end
    endtask

endmodule