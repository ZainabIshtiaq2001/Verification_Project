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

  // ======================================================
  // 1. Address alignment check : 
  //HADDR aligned to HSIZE on every NONSEQ and SEQ
  // ======================================================
  property p_addr_align;
    @(posedge HCLK) disable iff (!HRESETn)
    (HSEL && HTRANS inside {2'b10,2'b11}) |->
    (
      (HSIZE == 3'b000) ||
      (HSIZE == 3'b001 && HADDR[0] == 0) ||
      (HSIZE == 3'b010 && HADDR[1:0] == 0)
    );
  endproperty

  assert property (p_addr_align);

  // ======================================================
  // 2. SEQ must follow NONSEQ or SEQ : 
  //SEQ can only follow NONSEQ or SEQ — not IDLE or BUSY at burst start
  // ======================================================
  property p_seq_rule;
    @(posedge HCLK) disable iff (!HRESETn)
    (HTRANS == 2'b11) |->
    ($past(HTRANS) inside {2'b10,2'b11});
  endproperty

  assert property (p_seq_rule);
// ======================================================
  // Rule 3: Fixed burst length check
  // For INCR4 / WRAP4 → max 4 transfers (Wait-state tolerant)
  // ======================================================
  property p_burst_len_4;
    @(posedge HCLK) disable iff (!HRESETn)
    (HSEL && HTRANS == 2'b10 && HBURST inside {3'b010, 3'b011} && HREADY) |=> 
    (HTRANS == 2'b11 && HREADY)[->3];
  endproperty

  assert property (p_burst_len_4);

  // ======================================================
  // Rule 4: Stable signals when HREADY = 0 (Wait States)
  // Master must hold control and address signals steady
  // ======================================================
  property p_hold;
    @(posedge HCLK) disable iff (!HRESETn)
    (!$past(HREADY)) |->
    $stable(HADDR) && $stable(HTRANS) && $stable(HWRITE) && $stable(HSIZE) && $stable(HBURST);
  endproperty

  assert property (p_hold);

  // ======================================================
  // Rule 5: HRESP=ERROR lasts exactly 2 cycles
  // Cycle 1: HRESP=1, HREADYOUT=0
  // Cycle 2: HRESP=1, HREADYOUT=1
  // ======================================================
  property p_error_response;
    @(posedge HCLK) disable iff (!HRESETn)
    (HRESP == 1'b1 && $past(HRESP) == 1'b0) |-> 
    (!HREADYOUT ##1 (HRESP == 1'b1 && HREADYOUT));
  endproperty

  assert property (p_error_response);

  // ======================================================
  // Rule 6: BUSY not in SINGLE burst
  // ======================================================
  property p_busy;
    @(posedge HCLK) disable iff (!HRESETn)
    (HBURST == 3'b000) |-> (HTRANS != 2'b01);
  endproperty

  assert property (p_busy);

  // ======================================================
  // Rule 7: WRAP burst address stays within boundary
  // Checks that upper address bits do not change for WRAP4
  // ======================================================
  property p_wrap4_boundary;
    @(posedge HCLK) disable iff (!HRESETn)
    (HSEL && HTRANS == 2'b11 && HBURST == 3'b010 && HSIZE == 3'b010) |->
    (HADDR[15:4] == $past(HADDR[15:4])); 
  endproperty

  assert property (p_wrap4_boundary);

  // ======================================================
  // Extra: Reset behavior (Slave MUST drive HREADYOUT high)
  // ======================================================
  property p_reset;
    @(posedge HCLK)
    !HRESETn |-> HREADYOUT;
  endproperty

  assert property (p_reset);

  // ======================================================
  // Extra: Functional sanity - no X propagation on Response
  // ======================================================
  property p_no_x;
    @(posedge HCLK) disable iff (!HRESETn)
    !$isunknown(HRESP);
  endproperty

  assert property (p_no_x);
endmodule
