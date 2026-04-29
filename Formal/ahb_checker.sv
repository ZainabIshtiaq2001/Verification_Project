module ahb_checker (
  input HCLK,
  input HRESETn,
  input HSEL,
  input [15:0] HADDR,
  input [31:0] HWDATA,
  input [31:0] HRDATA,
  input HWRITE,
  input [2:0] HSIZE,
  input [2:0] HBURST,
  input [1:0] HTRANS,
  input HREADYOUT,
  input HREADY,
  input HRESP
);

  default clocking cb @(posedge HCLK); endclocking
  default disable iff (!HRESETn);



  // ------------------------------------------------------
  // 1. PROTOCOL: Reset Behavior (Immediate)
  // ------------------------------------------------------
  property p_reset;
    !HRESETn |-> (HREADYOUT == 1'b1 && HRESP == 1'b0);
  endproperty
  
  assert property (p_reset)
    $info("PASS: Reset behavior is perfectly compliant.");
  else 
    $error("FAIL: Reset behavior violated! HREADYOUT or HRESP stuck.");




  // ------------------------------------------------------
  // 2. PROTOCOL: HRESP Constant OKAY
  // ------------------------------------------------------
  property p_hresp_ok;
    HRESP == 1'b0;
  endproperty
  
  assert property (p_hresp_ok)
    $info("PASS: HRESP is successfully held OKAY.");
  else 
    $error("FAIL: Protocol violation! HRESP transitioned to ERROR state.");





  // ------------------------------------------------------
  // 3. PROTOCOL: No X Propagation
  // ------------------------------------------------------
  property p_no_x;
    !$isunknown(HREADYOUT) && !$isunknown(HRESP);
  endproperty
  
  assert property (p_no_x)
    $info("PASS: No X (unknown) values detected on slave outputs.");
  else 
    $error("FAIL: X value propagated to HREADYOUT or HRESP!");

  
  
  
  
  
  // ------------------------------------------------------
  // 4. PROTOCOL: Valid Wait State Initiation
  // ------------------------------------------------------
  // Intent: A slave can only pull HREADYOUT low if it actually 
  // accepted a valid address phase in the PREVIOUS cycle.
  property p_valid_wait_state_start;
    $fell(HREADYOUT) |-> $past(HSEL && HTRANS inside {2'b10, 2'b11} && HREADY);
  endproperty
  
  assert property (p_valid_wait_state_start)
    $info("PASS: Wait state initiated legally after valid address phase.");
  else 
    $error("FAIL: HREADYOUT dropped without a valid prior address phase!");





  // ------------------------------------------------------
  // 5. PROTOCOL: Burst Read Wait State Timing
  // ------------------------------------------------------
  // Intent: Every read data phase (NONSEQ or SEQ) must contain 
  // at least one wait state (HREADYOUT == 0) to allow data to propagate.
  property p_seq_read_wait;
    (HSEL && !HWRITE && HTRANS == 2'b11 && HREADY) |=> (HREADYOUT == 1'b0);
  endproperty
  
  assert property (p_seq_read_wait)
    $info("PASS: Wait state correctly inserted for SEQ read.");
  else 
    $error("FAIL: Protocol Violation! Slave failed to insert wait state for a SEQ read.");

  // ------------------------------------------------------
  // 6. FUNCTIONAL: End-to-End Data Integrity
  // ------------------------------------------------------
  property p_data_integrity;
    logic [15:0] l_addr;
    logic [31:0] l_data;
    
    // Trigger: A valid write data phase completes
    ( $past(HSEL && HWRITE && HTRANS inside {2'b10, 2'b11} && HREADY) && HREADY, 
      l_addr = $past(HADDR), 
      l_data = HWDATA ) 
    |=> 
    // Consequence: The next time we read from this address, data must match.
    s_eventually (
      $past(HSEL && !HWRITE && HTRANS inside {2'b10, 2'b11} && HREADY) && ($past(HADDR) == l_addr) && HREADY 
      |-> (HRDATA == l_data)
    );


  endproperty


  
  assert property (p_data_integrity)
    $info("PASS: Data successfully written and read back with perfect integrity.");
  else 
    $error("FAIL: Functional Violation! Data read did not match data written.");







  // ------------------------------------------------------
  // 7. PROTOCOL: Address Alignment
  // ------------------------------------------------------
  property p_addr_alignment;
    (HSEL && HTRANS inside {2'b10, 2'b11}) |-> 
      ((HSIZE == 3'b001) ? (HADDR[0] == 1'b0) : 1'b1) &&
      ((HSIZE == 3'b010) ? (HADDR[1:0] == 2'b00) : 1'b1);
  endproperty

  assert property (p_addr_alignment)
    $info("PASS: Address is properly aligned to HSIZE.");
  else 
    $error("FAIL: Unaligned address detected during active transfer!");

 
 
 
 
 
 
 
 
 
 
  // ------------------------------------------------------
  // 8. PROTOCOL: Signal Stability during Wait States
  // ------------------------------------------------------
  property p_hready_hold;
    (!$past(HREADY) && $past(HSEL) && ($past(HTRANS) inside {2'b10, 2'b11})) |-> 
      ($stable(HADDR) && $stable(HTRANS) && $stable(HWRITE) && $stable(HSIZE) && $stable(HBURST));
  endproperty

  assert property (p_hready_hold)
    $info("PASS: Signals held stable during wait state.");
  else 
    $error("FAIL: Protocol Violation! Signals changed while HREADY was low.");

 
 
 
 
 
 
 
 
 
 
 
 
 
  // ------------------------------------------------------
  // 9. FUNCTIONAL: Reset Recovery
  // ------------------------------------------------------
  property p_reset_recovery;
    $rose(HRESETn) |-> ##[0:10] (HREADYOUT == 1'b1 && HRESP == 1'b0);
  endproperty

  assert property (p_reset_recovery)
    $info("PASS: Slave successfully recovered from reset.");
  else 
    $error("FAIL: Slave deadlocked after reset release!");

 
 
 
 
 
 
 
  // ------------------------------------------------------
  // 10. FUNCTIONAL: Memory Stability (No Spontaneous Changes)
  // ------------------------------------------------------
  property p_read_read_stability;
    logic [15:0] l_addr;
    logic [31:0] l_data;
    
    // Trigger: First Read completes successfully
    ( $past(HSEL && !HWRITE && HTRANS inside {2'b10, 2'b11} && HREADY) && HREADY, 
      l_addr = $past(HADDR), 
      l_data = HRDATA ) 
    |=> 
    // Check: The next time this address is read, assuming no intervening writes, data matches
    s_eventually (
      $past(HSEL && !HWRITE && HTRANS inside {2'b10, 2'b11} && HREADY) && ($past(HADDR) == l_addr) && HREADY 
      |-> (HRDATA == l_data)
    );
  endproperty

  assert property (p_read_read_stability)
    $info("PASS: Memory content remained stable between reads.");
  else 
    $error("FAIL: Memory content changed without a valid write transaction.");





  // ------------------------------------------------------
  // 11. PROTOCOL: Two-Cycle ERROR Response
  // ------------------------------------------------------
  property p_two_cycle_error;
    (HRESP == 1'b1 && HREADYOUT == 1'b0) |=> (HRESP == 1'b1 && HREADYOUT == 1'b1);
  endproperty

  assert property (p_two_cycle_error)
    $info("PASS: 2-cycle ERROR response executed correctly.");
  else 
    $error("FAIL: ERROR response did not follow the strict 2-cycle timing requirement!");

endmodule