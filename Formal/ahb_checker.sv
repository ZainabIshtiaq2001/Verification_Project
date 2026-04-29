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
  // 1. ASSERTION 1: Reset Behavior (Immediate)
  // Ensures slave outputs are correctly initialized on reset
  // ------------------------------------------------------
  property p_reset;
    !HRESETn |-> (HREADYOUT == 1'b1 && HRESP == 1'b0);
  endproperty

  assert property (p_reset)
    $display("PASS (_assert_1): Reset behavior is correct.")
  else
    $error("FAIL (_assert_1): Incorrect reset values on HREADYOUT or HRESP!");



  // ------------------------------------------------------
  // 2. ASSERTION 2: Response Validity
  // Ensures HRESP always stays within legal values (OKAY)
  // ------------------------------------------------------
  property p_hresp_ok;
    HRESP == 1'b0;
  endproperty

  assert property (p_hresp_ok)
    $display("PASS (_assert_2): HRESP is always valid (OKAY).")
  else
    $error("FAIL (_assert_2): Invalid HRESP detected!");



  // ------------------------------------------------------
  // 3. ASSERTION 3: Signal Stability (No X/Z)
  // Ensures no unknown values propagate to outputs
  // ------------------------------------------------------
  property p_no_x;
    !$isunknown(HREADYOUT) && !$isunknown(HRESP);
  endproperty

  assert property (p_no_x)
    $display("PASS (_assert_3): No unknown values on outputs.")
  else
    $error("FAIL (_assert_3): X/Z detected on outputs!");



  // ------------------------------------------------------
  // 4. ASSERTION 4: Valid Wait-State Start
  // Ensures HREADYOUT is pulled low ONLY after a valid address phase
  // (HSEL=1, valid HTRANS, AND HREADY=1 in previous cycle)
  // ------------------------------------------------------
  property p_valid_wait_state_start;
    $fell(HREADYOUT) |-> $past(HSEL && HTRANS inside {2'b10, 2'b11} && HREADY);
  endproperty

  assert property (p_valid_wait_state_start)
    $display("PASS (_assert_4): Wait state started correctly.")
  else
    $error("FAIL (_assert_4): HREADYOUT dropped without valid prior address phase!");



  // ------------------------------------------------------
  // 5. ASSERTION 5: Wait-State Requirement for SEQ Reads
  // Ensures every SEQ read inserts at least one wait state
  // (Required for 2-cycle memory latency)
  // ------------------------------------------------------
  property p_seq_read_wait;
    (HSEL && !HWRITE && HTRANS == 2'b11 && HREADY)
    |=> (HREADYOUT == 1'b0);
  endproperty

  assert property (p_seq_read_wait)
    $display("PASS (_assert_5): Wait state inserted for SEQ read.")
  else
    $error("FAIL (_assert_5): Missing wait state for SEQ read!");



  // ------------------------------------------------------
  // 6. ASSERTION 6: End-to-End Data Integrity
  // Ensures data written to an address is correctly read back later
  // ------------------------------------------------------
  property p_data_integrity;
    logic [15:0] l_addr;
    logic [31:0] l_data;

    // Capture write
    ( $past(HSEL && HWRITE && HTRANS inside {2'b10, 2'b11} && HREADY) && HREADY,
      l_addr = $past(HADDR),
      l_data = HWDATA )
    |=> 
    // Check read later
    s_eventually (
      $past(HSEL && !HWRITE && HTRANS inside {2'b10, 2'b11} && HREADY) &&
      ($past(HADDR) == l_addr) && HREADY
      |-> (HRDATA == l_data)
    );
  endproperty

  assert property (p_data_integrity)
    $display("PASS (_assert_6): Data integrity maintained.")
  else
    $error("FAIL (_assert_6): Data mismatch between write and read!");

endmodule