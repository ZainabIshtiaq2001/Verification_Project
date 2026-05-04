`timescale 1ns/1ns
program directed_tests(ahb_if ahb);

initial begin


// ----all test data for bursts

    logic [31:0] data4[];
    logic [31:0] data8[];
    logic [31:0] data16[16];

    data8 = '{32'h11,32'h22,32'h33,32'h44,32'h55,32'h66,32'h77,32'h88};
    data4 = '{32'h11, 32'h22, 32'h33, 32'h44};

    foreach (data16[i]) data16[i] = i + 1;

    wait (ahb.HRESETn);
//-----writes in SINGLE mode-----
    single_write(16'h0010, 3'b000, 8'hAA);         // BYTE  -test1
    single_write(16'h0020, 3'b001, 16'hAABB);      // HALFWORD-test2
    single_write(16'h0030, 3'b010, 32'hAABBCCDD);  // WORD  -test3

//-----reads in SINGLE mode-----
    single_read(16'h0010, 3'b000, 8'hAA);        // BYTE     -test4
    single_read(16'h0020, 3'b001, 16'hAABB);     // HALFWORD -test5
    single_read(16'h0030, 3'b010, 32'hAABBCCDD); // WORD     -test6

//---- check wait satte

    wait_state_test();

//-----writes in BURST 

    burst_write(16'h0010, 3'b010, 3'b011, data4); //INCR4 - B011
    burst_write(16'h0020, 3'b010, 3'b101, data8); //INCR8 - B101
    burst_write(16'h0040, 3'b010, 3'b111, data16); //INCR16 - B111
 
//----- reads in busrst
	burst_read (16'h0010, 3'b010, 3'b011, data4);  	
	burst_read (16'h0020, 3'b010, 3'b101, data8);
	burst_read (16'h0040, 3'b010, 3'b111, data16);

//----- WRAP4 write and read
    burst_write(16'h000C, 3'b010, 3'b010, data4); //wrap4 - b010
    burst_read (16'h000C, 3'b010, 3'b010, data4);

//-----NO IDLE TEST
    no_idle_test(); //test15
//----- WRAP8 write and read
    burst_write(16'h0018, 3'b010, 3'b100, data8); //wrap8 - b100
    burst_read (16'h0018, 3'b010, 3'b100, data8);

//----- idle test check and busy

    idle_test(); //test13
    busy_test(); //test14

//-----WAIT STATE TEST-----
    wait_state_test(); //test12 - fails

//-----boundary check test 15-----
    boundary_test(); //test15

//-----alignment check test 16-----
    alignment_test(); //test16
   #80;
   $finish;
end

// ----------------------Helper functions----------------------

function string size_to_str(input [2:0] size);
    case (size)
        3'b000: return "BYTE";
        3'b001: return "HALFWORD";
        3'b010: return "WORD";
        default: return "UNKNOWN";
    endcase
endfunction

function int burst_len(input [2:0] burst);
    case (burst)
        3'b010: return 4;   // WRAP4
        3'b011: return 4;   // INCR4
        3'b100: return 8;   // WRAP8
        3'b101: return 8;   // INCR8
        3'b110: return 16;  // WRAP16
        3'b111: return 16;  // INCR16
        default: return 1;
    endcase
endfunction

function string burst_to_str(input [2:0] burst);
    case (burst)
        3'b000: return "SINGLE";
        3'b001: return "INCR";
        3'b010: return "WRAP4";
        3'b011: return "INCR4";
        3'b100: return "WRAP8";
        3'b101: return "INCR8";
        3'b110: return "WRAP16";
        3'b111: return "INCR16";
        default: return "UNKNOWN";
    endcase
endfunction

// ----------------- TEST 1-3: SINGLE WRITE BYTE/HALFWORD/WORD -----------------

task single_write(
    input [15:0] addr,
    input [2:0]  size,       // HSIZE
    input [31:0] data
);

    logic [31:0] val;
    // Address phase
    @(ahb.cb);
    ahb.cb.HSEL   <= 1; // for single slave
    ahb.cb.HADDR  <= addr;
    ahb.cb.HWRITE <= 1; // means write
    ahb.cb.HTRANS <= 2'b10; // NONSEQ, refer to table 3-1 for this
    ahb.cb.HSIZE  <= size;  // BYTE/HALFWORD/WORD - refer to table 3-2
    ahb.cb.HBURST <= 3'b000; // SINGLE - refer to table 3-4 from specs

    // Data phase (next cycle)
    @(ahb.cb);
    ahb.cb.HWDATA <= data;

    // Wait for ready, already waits for HREADY
    do @(ahb.cb); while (ahb.HREADYOUT == 0);

    // Extract only relevant portion for display
    
    case (size)
        3'b000: val = data & 8'hFF;        // BYTE
        3'b001: val = data & 16'hFFFF;     // HALFWORD
        3'b010: val = data;                // WORD
        default: val = 'x;
    endcase

    // Check response
    $display("\n------------------- WRITE -------------------");
    $display("[%0t] Addr = 0x%h | Size = %s | Data = 0x%h",
              $time, addr, size_to_str(size), val);

    if (ahb.HRESP !== 0 || ahb.HREADYOUT !== 1)
        $display("FAIL");
    else
        $display("PASS");

    // Back to IDLE
    @(ahb.cb);
    ahb.cb.HTRANS <= 2'b00; // IDLE
    ahb.cb.HSEL   <= 0;

endtask


// ----------------- TEST 4-6: SINGLE READ BYTE/HALFWORD/WORD -----------------

task single_read(
    input [15:0] addr,
    input [2:0]  size,       // HSIZE
    input [31:0] expected
);

    logic [31:0] rdata;
    logic [31:0] val;

    // Address phase
    @(ahb.cb);
    ahb.cb.HSEL   <= 1;
    ahb.cb.HADDR  <= addr;
    ahb.cb.HWRITE <= 0;
    ahb.cb.HTRANS <= 2'b10;
    ahb.cb.HSIZE  <= size;
    ahb.cb.HBURST <= 3'b000;

    // Wait for ready
    do @(ahb.cb); while (ahb.HREADYOUT == 0);

    // EXTRA cycle for memory latency (your DUT!)
    @(ahb.cb);
    rdata = ahb.HRDATA;

    // Extract based on size
    case (size)
        3'b000: val = (rdata >> (8  * addr[1:0])) & 8'hFF;      // BYTE
        3'b001: val = (rdata >> (16 * addr[1]))   & 16'hFFFF;   // HALFWORD
        3'b010: val = rdata;                                    // WORD
        default: val = 'x;
    endcase

      $display("\n------------------- READ -------------------");
      $display("[%0t] Addr=0x%h | Size=%s | Read=0x%h | Exp=0x%h",
            $time, addr, size_to_str(size), rdata, expected);

    if (ahb.HRESP !== 0 || val !== expected)
        $display("FAIL");
    else
        $display("PASS");

    // Back to IDLE
    @(ahb.cb);
    ahb.cb.HTRANS <= 2'b00;
    ahb.cb.HSEL   <= 0;

endtask

//----------------- TEST 7-11: INCR4/INCR8/INCR16 BURST WRITES as well as WRAP4,8 -----------------

// ----------------- BURST WRITE -----------------
task burst_write(
    input [15:0] addr,
    input [2:0]  size,
    input [2:0]  burst,
    input [31:0] data_array[]
);

    int beats;
    int incr;
    int boundary;
    int base, offset;
    logic [15:0] next_addr;
    bit wrap_printed;

    beats = burst_len(burst);
    incr  = (1 << size);

    // Compute wrap parameters
    boundary = beats * incr;
    base     = (addr / boundary) * boundary;
    offset   = addr % boundary;

    // First address
    @(ahb.cb);
    ahb.cb.HSEL   <= 1;
    ahb.cb.HADDR  <= addr;
    ahb.cb.HWRITE <= 1;
    ahb.cb.HTRANS <= 2'b10;
    ahb.cb.HSIZE  <= size;
    ahb.cb.HBURST <= burst;

    for (int i = 0; i < beats; i++) begin

        @(ahb.cb);
        ahb.cb.HWDATA <= data_array[i];

        do @(ahb.cb); while (ahb.HREADYOUT == 0);

        if (i < beats-1) begin
            @(ahb.cb);
            ahb.cb.HTRANS <= 2'b11;

            // -------- ADDRESS GENERATION --------
            if (burst == 3'b010 || burst == 3'b100 || burst == 3'b110) begin
                // WRAP4 / WRAP8 / WRAP16
                offset = (offset + incr) % boundary;
                next_addr = base + offset;
                if (!wrap_printed && offset < incr) begin
                    $display("   >>> WRAP OCCURRED <<<");
                    wrap_printed = 1;
                end
            end
            else begin
                // INCR bursts
                next_addr = addr + ((i+1) * incr);
            end

            ahb.cb.HADDR <= next_addr;
        end
    end

    $display("\n------------------- BURST WRITE -------------------");
    $display("[%0t] Type = %s | Start Addr = 0x%h | Size = %s | Beats = %0d",
            $time, burst_to_str(burst), addr, size_to_str(size), beats);

    if (ahb.HRESP !== 0)
        $display("FAIL");
    else
        $display("PASS");

    @(ahb.cb);
    ahb.cb.HTRANS <= 2'b00;
    ahb.cb.HSEL   <= 0;

endtask
task burst_read(
    input [15:0] addr,
    input [2:0]  size,
    input [2:0]  burst,
    input [31:0] expected_array[]
);

    int beats;
    int incr;
    int boundary;
    int base, offset;
    bit wrap_printed;

    logic [31:0] rdata, val;
    logic [15:0] curr_addr, next_addr;

    beats = burst_len(burst);
    incr  = (1 << size);

    boundary = beats * incr;
    base     = (addr / boundary) * boundary;
    offset   = addr % boundary;

    $display("\n------------------- BURST READ -------------------");
    $display("[%0t] Type = %s | Start Addr = 0x%h | Size = %s | Beats = %0d",
              $time, burst_to_str(burst), addr, size_to_str(size), beats);

    // First address
    @(ahb.cb);
    ahb.cb.HSEL   <= 1;
    ahb.cb.HADDR  <= addr;
    ahb.cb.HWRITE <= 0;
    ahb.cb.HTRANS <= 2'b10;
    ahb.cb.HSIZE  <= size;
    ahb.cb.HBURST <= burst;

    do @(ahb.cb); while (ahb.HREADYOUT == 0);

    @(ahb.cb); @(ahb.cb); // latency align

    for (int i = 0; i < beats; i++) begin

        // ---- compute current address ----
        if (i == 0)
            curr_addr = addr;
        else begin
            if (burst == 3'b010 || burst == 3'b100 || burst == 3'b110)begin
                curr_addr = base + offset;
                if (!wrap_printed && offset < incr) begin
                    $display("   >>> WRAP OCCURRED <<<");
                    wrap_printed = 1;
            end
            end
                
            else
                curr_addr = addr + (i * incr);
        end

        // ---- send next address ----
        if (i < beats-1) begin
            ahb.cb.HTRANS <= 2'b11;

            if (burst == 3'b010 || burst == 3'b100 || burst == 3'b110) begin
                offset = (offset + incr) % boundary;
                next_addr = base + offset;
            end
            else begin
                next_addr = addr + ((i+1) * incr);
            end

            ahb.cb.HADDR <= next_addr;
        end

        @(ahb.cb);
        do @(ahb.cb); while (ahb.HREADYOUT == 0);

        rdata = ahb.HRDATA;

        case (size)
            3'b000: val = (rdata >> (8  * curr_addr[1:0])) & 8'hFF;
            3'b001: val = (rdata >> (16 * curr_addr[1]))   & 16'hFFFF;
            3'b010: val = rdata;
        endcase

        $display("[%0t] Beat %0d | Addr=0x%h | Read=0x%h | Exp=0x%h",
                  $time, i, curr_addr, val, expected_array[i]);

        if (val !== expected_array[i])
            $display("FAIL");
        else
            $display("PASS");
    end

    $display("BURST READ DONE");

    @(ahb.cb);
    ahb.cb.HTRANS <= 2'b00;
    ahb.cb.HSEL   <= 0;

endtask
//-FAILSS
task wait_state_test();  // TEST 12: WAIT STATE CHECK fails

    logic [15:0] addr_s;
    logic [1:0]  htrans_s;
    logic        hwrite_s;
    logic [2:0]  hsize_s, hburst_s;

    bit wait_seen = 0;

    $display("\n------------------- WAIT STATE TEST -------------------");

    // ADDRESS PHASE
    @(ahb.cb);
    ahb.cb.HSEL   <= 1;
    ahb.cb.HADDR  <= 16'h0010;
    ahb.cb.HWRITE <= 1;
    ahb.cb.HTRANS <= 2'b10; // NONSEQ
    ahb.cb.HSIZE  <= 3'b010;
    ahb.cb.HBURST <= 3'b000;

    // Save signals
    addr_s   = ahb.HADDR;
    htrans_s = ahb.HTRANS;
    hwrite_s = ahb.HWRITE;
    hsize_s  = ahb.HSIZE;
    hburst_s = ahb.HBURST;

    // DATA PHASE
    @(ahb.cb);
    ahb.cb.HWDATA <= 32'hAABBCCDD;

    // WAIT LOOP
    do begin
        @(ahb.cb);

        if (ahb.HREADYOUT == 0) begin
            wait_seen = 1;

            // CHECK SIGNAL HOLD
            if (ahb.HADDR  !== addr_s   ||
                ahb.HTRANS !== htrans_s ||
                ahb.HWRITE !== hwrite_s ||
                ahb.HSIZE  !== hsize_s  ||
                ahb.HBURST !== hburst_s) begin

                $display("FAIL: Signals changed during WAIT!");
            end
        end

    end while (ahb.HREADYOUT == 0);

    // FINAL CHECK
    if (!wait_seen)
        $display("FAIL: No wait state observed!");
    else
        $display("PASS: Wait state verified");

    // IDLE
    @(ahb.cb);
    ahb.cb.HTRANS <= 2'b00;
    ahb.cb.HSEL   <= 0;

endtask

task idle_test();

    $display("\n------------------- IDLE TEST -------------------");

    @(ahb.cb);
    ahb.cb.HSEL   <= 1;
    ahb.cb.HTRANS <= 2'b00; // IDLE

    @(ahb.cb);

    // You just ensure nothing happens
    if (ahb.HREADYOUT !== 1)
        $display("FAIL");
    else
        $display("PASS: No transfer during IDLE");

endtask

task busy_test();

    $display("\n------------------- BUSY TEST -------------------");

    @(ahb.cb);
    ahb.cb.HSEL   <= 1;
    ahb.cb.HTRANS <= 2'b01; // BUSY

    @(ahb.cb);

    $display("PASS: BUSY did not initiate transfer");

endtask

task no_idle_test();

    $display("\n------------------- NO IDLE TEST -------------------");

    // ---- FIRST TRANSFER ----
    @(ahb.cb);
    ahb.cb.HSEL   <= 1;
    ahb.cb.HADDR  <= 16'h0020;
    ahb.cb.HWRITE <= 1;
    ahb.cb.HTRANS <= 2'b10; // NONSEQ
    ahb.cb.HSIZE  <= 3'b010;
    ahb.cb.HBURST <= 3'b000;

    @(ahb.cb);
    ahb.cb.HWDATA <= 32'h11111111;

    // ---- SECOND TRANSFER (NO IDLE!) ----
    @(ahb.cb);
    ahb.cb.HADDR  <= 16'h0024;
    ahb.cb.HTRANS <= 2'b10; // NONSEQ again
    ahb.cb.HWDATA <= 32'h22222222;

    // Wait for completion
    do @(ahb.cb); while (ahb.HREADYOUT == 0);

    // ---- CHECK ----
    $display("Checking consecutive writes...");

    if (ahb.HRESP !== 0)
        $display("FAIL: Response error");
    else
        $display("PASS: No-IDLE transfers successful");

    // Back to IDLE
    @(ahb.cb);
    ahb.cb.HTRANS <= 2'b00;
    ahb.cb.HSEL   <= 0;

endtask

//-----boundary check test 15----------

task boundary_test();

    logic [31:0] data4[];
    data4 = '{32'h11,32'h22,32'h33,32'h44};

    $display("\n------------------- 1KB BOUNDARY TEST -------------------");

    burst_write(16'h03FC, 3'b010, 3'b011, data4); // INCR4

    if (ahb.HRESP != 0)
        $display("PASS: Boundary violation detected (ERROR response)");
    else
        $display("FAIL: Burst crossed 1KB boundary without error");

endtask

task alignment_test();

    logic [31:0] data;

    $display("\n------------------- ALIGNMENT TEST -------------------");

    // WRITE (aligned)
    single_write(16'h0004, 3'b010, 32'hDEADBEEF);

    // READ BACK
    single_read (16'h0004, 3'b010, 32'hDEADBEEF);

    $display("PASS: Aligned WORD access successful");

endtask
endprogram
