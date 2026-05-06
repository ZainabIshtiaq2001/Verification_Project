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

  // ============================================================
  // VALID TRANSFER CONDITION (ADDRESS PHASE)
  // Spec: Section 3.2 (Transfer Types)
  // ============================================================
  logic valid_transfer;
  assign valid_transfer = HSEL && HREADY && (HTRANS inside {2'b10, 2'b11});

  // ============================================================
  // 1. RESET BEHAVIOR
  // Spec: Section 7.1.2 (Reset)
  // ============================================================
  property p_reset;
    disable iff (1'b0) // Must disable the default to check reset itself
    !HRESETn |-> (HREADYOUT == 1'b1 && HRESP == 1'b0);
  endproperty

  assert property (p_reset)
    $info("PASS: Reset compliant");
  else
    $error("FAIL: Reset violation (Sec 7.1.2)");

  // ============================================================
  // 1b. BOUNDED RESET RECOVERY
  // Spec: Reset recovery requirement
  // Requirement: After reset, HREADY goes high and HRESP returns OK within a bounded number of cycles
  // ============================================================
  property p_reset_bounded;
    $rose(HRESETn) |-> ##[0:16] (HREADYOUT && !HRESP);
  endproperty

  assert property (p_reset_bounded)
    $info("PASS: Reset recovery bounded");
  else
    $error("FAIL: Reset recovery too slow");

  // ============================================================
  // 2. IDLE / BUSY RESPONSE
  // Spec: Section 3.2
  // ============================================================
  property p_idle_busy;
    ($past(HSEL) && $past(HTRANS) inside {2'b00, 2'b01} && $past(HREADY)) |-> (HREADYOUT && !HRESP);
  endproperty

  assert property (p_idle_busy)
    $info("PASS: Idle/Busy response OK");
  else
    $error("FAIL: Idle/Busy response violation");

  // ============================================================
  // 3. NO X PROPAGATION
  // Spec: Safe outputs
  // ============================================================
  property p_no_x;
    !$isunknown(HREADYOUT) && !$isunknown(HRESP);
  endproperty

  assert property (p_no_x)
    $info("PASS: No X detected");
  else
    $error("FAIL: X propagation detected");

  // ============================================================
  // 4. VALID WAIT STATE
  // Spec: Section 3.3
  // ============================================================
  property p_wait_state;
    $fell(HREADYOUT) |-> $past(valid_transfer);
  endproperty

  assert property (p_wait_state)
    $info("PASS: Valid wait state");
  else
    $error("FAIL: Illegal wait state");

  // ============================================================
  // 5. ERROR RESPONSE (2-cycle)
  // Spec: Section 3.6
  // ============================================================
  property p_error;
    (HRESP && !HREADYOUT) |=> (HRESP && HREADYOUT);
  endproperty

  assert property (p_error)
    $info("PASS: Error response OK");
  else
    $error("FAIL: Error response violation");

  // ============================================================
  // 6. READ DATA VALIDITY (FIXED PIPELINE)
  // Spec: Section 5.1
  // ============================================================
  property p_read_data;
    // Data is only valid when HREADYOUT goes high to finish the data phase
    ($past(valid_transfer && !HWRITE)) ##0 (HREADYOUT == 1'b1) |-> !$isunknown(HRDATA);
  endproperty

  assert property (p_read_data)
    $info("PASS: Read data valid");
  else
    $error("FAIL: HRDATA invalid");

  // ============================================================
  // 7-11. FUNCTIONAL MEMORY CORRECTNESS 
  // Spec: RAM correctness, Byte Isolation, Readback stability
  // Requirement: These check the RAM .
  // ============================================================
  
 
  wire [15:0] f_addr;
  assume property ($stable(f_addr));

  // Pipeline Tracking Registers
  logic       trk_active;
  logic       trk_write;
  logic [2:0] trk_size;

  // Track the Address Phase for our address
  always @(posedge HCLK) begin
    if (!HRESETn) begin
      trk_active <= 0;
    end else if (HREADY) begin
      if (valid_transfer && (HADDR[15:2] == f_addr[15:2])) begin
        trk_active <= 1;
        trk_write  <= HWRITE;
        trk_size   <= HSIZE;
      end else begin
        trk_active <= 0;
      end
    end
  end

  // Data Phase Completion Signals
  wire data_phase_done = trk_active && HREADYOUT;
  wire write_done      = data_phase_done && trk_write;
  wire read_done       = data_phase_done && !trk_write;

  // Shadow Memory
  logic [31:0] shadow_mem;
  logic        shadow_valid;

  always @(posedge HCLK) begin
    if (!HRESETn) begin
      shadow_valid <= 0;
      shadow_mem   <= 0;
    end else if (write_done) begin
      // Covers #10 (Valid memory change) and #11 (Byte isolation)
      shadow_valid <= 1;
      if (trk_size == 3'b010) begin
        shadow_mem <= HWDATA;
      end else if (trk_size == 3'b000) begin
        // Requirement: Byte write to address A does not modify bytes A+1, A+2, A+3
        case (f_addr[1:0])
          2'b00: shadow_mem[7:0]   <= HWDATA[7:0];
          2'b01: shadow_mem[15:8]  <= HWDATA[15:8];
          2'b10: shadow_mem[23:16] <= HWDATA[23:16];
          2'b11: shadow_mem[31:24] <= HWDATA[31:24];
        endcase
      end
    end else if (read_done && !shadow_valid) begin
      
      // Locks initial state to prove #7 (Memory stability)
      // Requirement: No memory location changes without a valid write transaction
      
      shadow_mem   <= HRDATA;
      shadow_valid <= 1;
    end
  end

  // Covers #8 & #9: Data written must be readable from same address
  // Requirement: Data written to address A must be readable from address A
    
  property p_memory_correctness;
    (read_done && shadow_valid) |-> (HRDATA == shadow_mem);
  endproperty

  assert property (p_memory_correctness)
    $info("PASS: All Memory Functional Requirements Verified");
  else
    $error("FAIL: Memory Integrity, Readback, or Byte Isolation violated!");

endmodule
