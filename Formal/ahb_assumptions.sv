
// ==============================================================================
// File: ahb_assumptions.sv
// Role: Constraints on the Formal Master (JasperGold)
// ==============================================================================
module ahb_assumptions (
  input HCLK,
  input HRESETn,
  input HSEL,
  input [15:0] HADDR,
  input [1:0] HTRANS,
  input [2:0] HSIZE,
  input [2:0] HBURST,
  input HWRITE,
  input HREADY
);

  // Default clocking
  default clocking cb @(posedge HCLK); endclocking
  default disable iff (!HRESETn);

  // ----------------------------------------------------------------------------
  // Protocol 1: HADDR aligned to HSIZE on every NONSEQ and SEQ
  // ----------------------------------------------------------------------------
  property a_align;
    (HSEL && HTRANS inside {2'b10, 2'b11}) |-> 
    ((HSIZE == 3'b000) || 
     (HSIZE == 3'b001 && HADDR[0] == 1'b0) || 
     (HSIZE == 3'b010 && HADDR[1:0] == 2'b00));
  endproperty
  assume_addr_align: assume property (a_align);
  cover_addr_align:  cover property (a_align);

  // ----------------------------------------------------------------------------
  // Protocol 2: SEQ can only follow NONSEQ or SEQ
  // ----------------------------------------------------------------------------
  property a_seq_rule;
    (HTRANS == 2'b11) |-> ($past(HTRANS) inside {2'b10, 2'b11});
  endproperty
  assume_seq_rule: assume property (a_seq_rule);
  cover_seq_rule:  cover property (a_seq_rule);

  // ----------------------------------------------------------------------------
  // Protocol 3: Fixed-length burst completes exactly the declared number of beats
  // (Example for INCR4 / WRAP4 - requires 3 SEQ beats after the NONSEQ)
  // ----------------------------------------------------------------------------
  property a_burst_len_4;
    (HSEL && HTRANS == 2'b10 && HBURST inside {3'b010, 3'b011} && HREADY) |=> 
    (HTRANS == 2'b11 && HREADY)[->3];
  endproperty
  assume_burst_len_4: assume property (a_burst_len_4);

  // ----------------------------------------------------------------------------
  // Protocol 4: All address-phase signals held stable when HREADY=0
  // ----------------------------------------------------------------------------
  property a_stable_wait;
    (!$past(HREADY)) |-> 
    ($stable(HADDR) && $stable(HTRANS) && $stable(HSIZE) && $stable(HBURST) && $stable(HWRITE));
  endproperty
  assume_stable_wait: assume property (a_stable_wait);
  cover_wait_state:   cover property (!$past(HREADY) && HREADY); // Cover wait state ending

  // ----------------------------------------------------------------------------
  // Protocol 6: BUSY not legal inside a SINGLE transfer
  // ----------------------------------------------------------------------------
  property a_no_busy_single;
    (HBURST == 3'b000) |-> (HTRANS != 2'b01);
  endproperty
  assume_no_busy_single: assume property (a_no_busy_single);

  // ----------------------------------------------------------------------------
  // Protocol 7: WRAP burst address stays within its naturally-aligned boundary
  // (Example for WRAP4 with WORD size -> 16-byte boundary -> HADDR[15:4] is stable)
  // ----------------------------------------------------------------------------
  property a_wrap4_word_boundary;
    (HSEL && HTRANS == 2'b11 && HBURST == 3'b010 && HSIZE == 3'b010) |->
    (HADDR[15:4] == $past(HADDR[15:4]));
  endproperty
  assume_wrap4_bound: assume property (a_wrap4_word_boundary);

endmodule