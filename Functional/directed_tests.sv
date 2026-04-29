`timescale 1ns/1ns
program directed_tests(ahb_if ahb);

initial begin
   wait (ahb.HRESETn);

//-----writes in SINGLE mode-----
    single_write(16'h0010, 3'b000, 8'hAA);         // BYTE  -test1
    single_write(16'h0020, 3'b001, 16'hAABB);      // HALFWORD-test2
    single_write(16'h0030, 3'b010, 32'hAABBCCDD);  // WORD  -test3

//-----reads in SINGLE mode-----
    single_read(16'h0010, 3'b000, 8'hAA);        // BYTE     -test4
    single_read(16'h0020, 3'b001, 16'hAABB);     // HALFWORD -test5
    single_read(16'h0030, 3'b010, 32'hAABBCCDD); // WORD     -test6

   #80;
   $finish;
end


function string size_to_str(input [2:0] size);
    case (size)
        3'b000: return "BYTE";
        3'b001: return "HALFWORD";
        3'b010: return "WORD";
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



endprogram