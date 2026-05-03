///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// contributed by : Muhammad Asim Javaid Phd@Lums
//
// File name : directed_tests.sv
// Title : testbench for project part c
// Notes : Testbench for verifying the AHB design+scoreboard implementation
// INC RANDOM TESTS, BURST TESTS, SINGLE TESTS, REPORTING
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

// ========================================================================
// TEST PACKAGE - Contains all test tasks
// ========================================================================
package ahb_test_pkg;

  // ========================================================================
  // SINGLE WRITE TRANSACTION
  // ========================================================================
    task automatic single_write(
    virtual ahb_if vif,
    bit [31:0] addr,
    bit [31:0] data,
    bit [2:0] size,
    output bit [3:0] be
  );
    
    be = generate_be(addr, size);
    
    // Address Phase - Set HSEL HIGH
    vif.cb.HSEL    <= 1'b1;
    vif.cb.HADDR   <= addr;
    vif.cb.HWRITE  <= 1'b1;
    vif.cb.HTRANS  <= 2'b10;  // NONSEQ
    vif.cb.HSIZE   <= size;
    vif.cb.HBURST  <= 3'b000; // SINGLE
    vif.cb.HPROT   <= 4'b0011;
    
    @(vif.cb);
    
    // Data Phase - KEEP HSEL HIGH, setup data
    vif.cb.HWDATA  <= data;
    
    // Wait for HREADYOUT (HSEL stays high)
    while (!vif.cb.HREADYOUT)
      @(vif.cb);
    
    // One more clock after HREADYOUT
    @(vif.cb);
    
    // NOW return to IDLE - bring HSEL low
    vif.cb.HSEL    <= 1'b0;
    vif.cb.HTRANS  <= 2'b00;
    
    $display("[WRITE @ %0t] Addr=0x%08h | Data=0x%08h | Size=%0d | BE=0x%h | HSEL kept high",
             $time, addr, data, size, be);
  endtask
  // ========================================================================
  // SINGLE READ TRANSACTION
  // ========================================================================
   task automatic single_read(
    virtual ahb_if vif,
    bit [31:0] addr,
    bit [2:0] size,
    output bit [31:0] rdata,
    output bit [3:0] be
  );
    
    be = generate_be(addr, size);
    
    // Address Phase - Set HSEL HIGH
    vif.cb.HSEL    <= 1'b1;
    vif.cb.HADDR   <= addr;
    vif.cb.HWRITE  <= 1'b0;
    vif.cb.HTRANS  <= 2'b10;  // NONSEQ
    vif.cb.HSIZE   <= size;
    vif.cb.HBURST  <= 3'b000; // SINGLE
    vif.cb.HPROT   <= 4'b0011;
    
    @(vif.cb);
    
    // Wait for HREADYOUT (HSEL stays high)
    while (!vif.cb.HREADYOUT)
      @(vif.cb);
    
    // Capture read data on next clock
    @(vif.cb);
    rdata = vif.cb.HRDATA;
    
    // NOW return to IDLE - bring HSEL low
    vif.cb.HSEL    <= 1'b0;
    vif.cb.HTRANS  <= 2'b00;
    
    $display("[READ @ %0t] Addr=0x%08h | Data=0x%08h | Size=%0d | BE=0x%h | HSEL kept high",
             $time, addr, rdata, size, be);
  endtask 
  // ========================================================================
  // BURST WRITE - INCR MODE
  // ========================================================================
     task automatic burst_write_incr(
    virtual ahb_if vif,
    bit [31:0] addr,
    bit [2:0] size,
    bit [3:0] len,
    output bit [31:0] write_data_q [$]
  );
    
    bit [3:0] be = generate_be(addr, size);
    bit [31:0] current_addr = addr;
    bit [31:0] write_data;
    
    for (int i = 0; i < len; i++) begin
      write_data = $urandom();
      write_data_q.push_back(write_data);
      
      // Address Phase
      vif.cb.HSEL    <= 1'b1;
      vif.cb.HADDR   <= current_addr;
      vif.cb.HWRITE  <= 1'b1;
      vif.cb.HTRANS  <= (i == 0) ? 2'b10 : 2'b11;
      vif.cb.HSIZE   <= size;
      vif.cb.HBURST  <= 3'b001; // INCR
      vif.cb.HPROT   <= 4'b0011;
      vif.cb.HWDATA  <= 32'h0;  // No data yet
      
      @(vif.cb);  // Clock edge - DUT latches address
      
      // Data Phase - Now present data for THIS address
      vif.cb.HWDATA  <= write_data;
      // Keep HADDR same (already latched)
      // Keep HTRANS as SEQ
      
      // Wait for HREADYOUT
      while (!vif.cb.HREADYOUT)
        @(vif.cb);
      
      $display("[BURST_WRITE_INCR @ %0t] Addr=0x%08h | Data=0x%08h | Beat=%0d/%0d",
               $time, current_addr, write_data, i+1, len);
      
      // Calculate next address for NEXT iteration
      case (size)
        3'b000: current_addr += 1;
        3'b001: current_addr += 2;
        3'b010: current_addr += 4;
        default: current_addr += 4;
      endcase
      
      // Clock edge to end data phase
      @(vif.cb);
    end
    
    // Return to IDLE
    vif.cb.HTRANS  <= 2'b00;
    vif.cb.HSEL    <= 1'b0;
  endtask
  
  // ========================================================================
  // BURST READ - INCR MODE
  // ========================================================================
     task automatic burst_read_incr(
    virtual ahb_if vif,
    bit [31:0] addr,
    bit [2:0] size,
    bit [3:0] len,
    output bit [31:0] read_data_q [$]
  );
    
    bit [3:0] be = generate_be(addr, size);
    bit [31:0] current_addr = addr;
    bit [31:0] rdata;
    
    for (int i = 0; i < len; i++) begin
      // Address Phase
      vif.cb.HSEL    <= 1'b1;
      vif.cb.HADDR   <= current_addr;
      vif.cb.HWRITE  <= 1'b0;
      vif.cb.HTRANS  <= (i == 0) ? 2'b10 : 2'b11;  // NONSEQ for first, SEQ for rest
      vif.cb.HSIZE   <= size;
      vif.cb.HBURST  <= 3'b001; // INCR
      vif.cb.HPROT   <= 4'b0011;
      
      @(vif.cb);
      
      // Wait for HREADYOUT
      while (!vif.cb.HREADYOUT)
        @(vif.cb);
      
      // Pipeline: Data comes NEXT cycle after address+HREADYOUT
      @(vif.cb);
      rdata = vif.cb.HRDATA;
      read_data_q.push_back(rdata);
      
      $display("[BURST_READ_INCR @ %0t] Addr=0x%08h | Data=0x%08h | Beat=%0d/%0d",
               $time, current_addr, rdata, i+1, len);
      
      // Calculate next address
      case (size)
        3'b000: current_addr += 1;
        3'b001: current_addr += 2;
        3'b010: current_addr += 4;
        default: current_addr += 4;
      endcase
    end
    
    // Return to IDLE
    vif.cb.HTRANS  <= 2'b00;
    vif.cb.HSEL    <= 1'b0;
  endtask 
  // ========================================================================
  // BURST WRITE - WRAP MODE
  // ========================================================================
   task automatic burst_write_wrap(
    virtual ahb_if vif,
    bit [31:0] addr,
    bit [2:0] size,
    bit [3:0] len,
    output bit [31:0] write_data_q [$]
  );
    
    bit [3:0] be = generate_be(addr, size);
    bit [31:0] current_addr = addr;
    bit [31:0] write_data;
    int unsigned beat_bytes;
    int unsigned wrap_bytes;
    bit [31:0] wrap_base;
    bit [31:0] next_addr;
    
    case (size)
      3'b000: beat_bytes = 1;
      3'b001: beat_bytes = 2;
      default: beat_bytes = 4;
    endcase
    
    wrap_bytes = beat_bytes * len;
    wrap_base = addr & ~(wrap_bytes - 1);
    
    for (int i = 0; i < len; i++) begin
      write_data = $urandom();
      write_data_q.push_back(write_data);
      
      // Address Phase
      vif.cb.HSEL    <= 1'b1;
      vif.cb.HADDR   <= current_addr;
      vif.cb.HWRITE  <= 1'b1;
      vif.cb.HTRANS  <= (i == 0) ? 2'b10 : 2'b11;
      vif.cb.HSIZE   <= size;
      vif.cb.HBURST  <= (len == 4) ? 3'b010 : (len == 8) ? 3'b100 : 3'b110; // WRAP
      vif.cb.HPROT   <= 4'b0011;
      
      @(vif.cb);  // Clock edge
      
      // Data Phase - Keep address/size stable
      vif.cb.HWDATA  <= write_data;
      // ← Keep HADDR, HSIZE, HTRANS, HBURST stable
      
      // Wait for HREADYOUT
      while (!vif.cb.HREADYOUT)
        @(vif.cb);
      
      // One more clock
      @(vif.cb);
      
      $display("[BURST_WRITE_WRAP @ %0t] Addr=0x%08h | Data=0x%08h | Beat=%0d/%0d",
               $time, current_addr, write_data, i+1, len);
      
      // Calculate next address with wrap
      next_addr = current_addr + beat_bytes;
      if (next_addr >= (wrap_base + wrap_bytes))
        current_addr = wrap_base;
      else
        current_addr = next_addr;
    end
    
    // Return to IDLE
    vif.cb.HTRANS  <= 2'b00;
    vif.cb.HSEL    <= 1'b0;
  endtask
  
  // ========================================================================
  // BURST READ - WRAP MODE
  // ========================================================================
    task automatic burst_read_wrap(
    virtual ahb_if vif,
    bit [31:0] addr,
    bit [2:0] size,
    bit [3:0] len,
    output bit [31:0] read_data_q [$]
  );
    
    bit [3:0] be = generate_be(addr, size);
    bit [31:0] current_addr = addr;
    bit [31:0] rdata;
    int unsigned beat_bytes;
    int unsigned wrap_bytes;
    bit [31:0] wrap_base;
    bit [31:0] next_addr;
    
    case (size)
      3'b000: beat_bytes = 1;
      3'b001: beat_bytes = 2;
      default: beat_bytes = 4;
    endcase
    
    wrap_bytes = beat_bytes * len;
    wrap_base = addr & ~(wrap_bytes - 1);
    
    for (int i = 0; i < len; i++) begin
      // Address Phase
      vif.cb.HSEL    <= 1'b1;
      vif.cb.HADDR   <= current_addr;
      vif.cb.HWRITE  <= 1'b0;
      vif.cb.HTRANS  <= (i == 0) ? 2'b10 : 2'b11;
      vif.cb.HSIZE   <= size;
      vif.cb.HBURST  <= (len == 4) ? 3'b010 : (len == 8) ? 3'b100 : 3'b110; // WRAP
      vif.cb.HPROT   <= 4'b0011;
      
      @(vif.cb);
      
      // Wait for HREADYOUT
      while (!vif.cb.HREADYOUT)
        @(vif.cb);
      
      // Pipeline: Data comes NEXT cycle
      @(vif.cb);
      rdata = vif.cb.HRDATA;
      read_data_q.push_back(rdata);
      
      $display("[BURST_READ_WRAP @ %0t] Addr=0x%08h | Data=0x%08h | Beat=%0d/%0d",
               $time, current_addr, rdata, i+1, len);
      
      // Calculate next address with wrap
      next_addr = current_addr + beat_bytes;
      if (next_addr >= (wrap_base + wrap_bytes))
        current_addr = wrap_base;
      else
        current_addr = next_addr;
    end
    
    // Return to IDLE
    vif.cb.HTRANS  <= 2'b00;
    vif.cb.HSEL    <= 1'b0;
  endtask
  
  // ========================================================================
  // HELPER FUNCTION - BYTE ENABLE GENERATION
  // ========================================================================
  function automatic bit [3:0] generate_be(bit [31:0] addr, bit [2:0] size);
    bit [1:0] addr_offset = addr[1:0];
    bit [3:0] be;
    
    case (size)
      3'b000: be = (4'b0001 << addr_offset);  // BYTE
      3'b001: be = (4'b0011 << addr_offset);  // HALFWORD
      3'b010: be = 4'b1111;                   // WORD
      default: be = 4'b0000;
    endcase
    return be;
  endfunction

endpackage : ahb_test_pkg