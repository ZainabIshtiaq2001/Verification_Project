// ==============================================================================
// File: ahb_checker.sv
// Role: Assertions on the Formal Slave (JasperGold DUT)
// Project: EE-5214 Verification of Digital Systems (Role B)
// ==============================================================================
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
  // 2. PROTOCOL: Zero Wait-State OKAY for IDLE/BUSY
  // FIXED: HTrans to HTRANS
  // ------------------------------------------------------
  property p_idle_busy_response;
    ($past(HSEL) && $past(HTRANS) inside {2'b00, 2'b01} && $past(HREADY)) 
    |-> (HREADYOUT == 1'b1 && HRESP == 1'b0);
  endproperty
  
  assert property (p_idle_busy_response)
    $info("PASS: Slave correctly gave 0-wait state OKAY to IDLE/BUSY.");
  else 
    $error("FAIL: Protocol Violation! Slave stalled or gave ERROR during IDLE/BUSY.");

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
  // *** THIS IS THE BUG I FOUND IN THE DUT! ***
  // ------------------------------------------------------
  property p_valid_wait_state_start;
    $fell(HREADYOUT) |-> $past(HSEL && HTRANS inside {2'b10, 2'b11} && HREADY);
  endproperty
  
  assert property (p_valid_wait_state_start)
    $info("PASS: Wait state initiated legally after valid address phase.");
  else 
    $error("FAIL: BUG FOUND! HREADYOUT dropped without a valid prior address phase!");

 

endmodule