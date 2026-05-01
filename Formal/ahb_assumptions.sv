
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

  ///////////////////////////////////////////////////////////////////////////////


   // ----------------------------------------------------------------------------
  // Assumption 1: HTRANS is IDLE during reset
  // Section 7.1.2 (Reset).
  // ----------------------------------------------------------------------------
  property a_reset_htrans;
    disable iff (1'b0) (!HRESETn) |-> (HTRANS == 2'b00);
  endproperty
  assume_reset_htrans: assume property (a_reset_htrans);

  // ----------------------------------------------------------------------------
  // Assumption 2: Valid HTRANS values (No X or Z)
  // Section 3.2 (Transfer types).
  // ----------------------------------------------------------------------------
  property a_valid_htrans;
    HTRANS inside {2'b00, 2'b01, 2'b10, 2'b11};
  endproperty
  assume_valid_htrans: assume property (a_valid_htrans);

  // ----------------------------------------------------------------------------
  // Assumption 3: Valid HBURST values
  // Section 3.5 (Burst operation).
  // ----------------------------------------------------------------------------
  property a_valid_hburst;
    HBURST inside {[3'b000 : 3'b111]};
  endproperty
  assume_valid_hburst: assume property (a_valid_hburst);

  // ----------------------------------------------------------------------------
  // Assumption 4: Valid HSIZE values for 32-bit RAM (Byte, Halfword, Word)
  // Section 3.4 (Transfer size).
  // ----------------------------------------------------------------------------
  property a_valid_hsize;
    HSIZE inside {3'b000, 3'b001, 3'b010};
  endproperty
  assume_valid_hsize: assume property (a_valid_hsize);

  // ----------------------------------------------------------------------------
  // Assumption 5: Valid HWRITE values (No unknown states)
  // Section 3.1 (Basic transfers).
  // ----------------------------------------------------------------------------
  property a_valid_hwrite;
    !$isunknown(HWRITE);
  endproperty
  assume_valid_hwrite: assume property (a_valid_hwrite);

  // ----------------------------------------------------------------------------
  // Assumption 6: Valid HSEL values (No unknown states)
  // Section 4.1 (Address decoding).
  // ----------------------------------------------------------------------------
  property a_valid_hsel;
    !$isunknown(HSEL);
  endproperty
  assume_valid_hsel: assume property (a_valid_hsel);

  // ----------------------------------------------------------------------------
  // Assumption 7: Valid HREADY values (No unknown states)
  // Section 3.1 (Basic transfers).
  // ----------------------------------------------------------------------------
  property a_valid_hready;
    !$isunknown(HREADY);
  endproperty
  assume_valid_hready: assume property (a_valid_hready);

  // ----------------------------------------------------------------------------
  // Assumption 8: HADDR must not be unknown during an active transfer
  // Section 3.1 (Basic transfers).
  // ----------------------------------------------------------------------------
  property a_valid_haddr;
    (HSEL && HTRANS inside {2'b10, 2'b11}) |-> (!$isunknown(HADDR));
  endproperty
  assume_valid_haddr: assume property (a_valid_haddr);

  // ----------------------------------------------------------------------------
  // Assumption 9: Halfword address alignment
  // Section 3.4 (Transfer size).
  // ----------------------------------------------------------------------------
  property a_align_halfword;
    (HSEL && HTRANS inside {2'b10, 2'b11} && HSIZE == 3'b001) |-> (HADDR[0] == 1'b0);
  endproperty
  assume_align_halfword: assume property (a_align_halfword);

  // ----------------------------------------------------------------------------
  // Assumption 10: Word address alignment
  // Section 3.4 (Transfer size).
  // ----------------------------------------------------------------------------
  property a_align_word;
    (HSEL && HTRANS inside {2'b10, 2'b11} && HSIZE == 3'b010) |-> (HADDR[1:0] == 2'b00);
  endproperty
  assume_align_word: assume property (a_align_word);

  // ----------------------------------------------------------------------------
  // Assumption 11: 1KB burst boundary restriction
  // Section 4.1 (Address decoding).
  // ----------------------------------------------------------------------------
  property a_1kb_boundary;
    (HTRANS inside {2'b01, 2'b11}) |-> (HADDR[15:10] == $past(HADDR[15:10]));
  endproperty
  assume_1kb_boundary: assume property (a_1kb_boundary);

  // ----------------------------------------------------------------------------
  // Assumption 12: HADDR stable during wait states
  // Section 3.1 (Basic transfers).
  // ----------------------------------------------------------------------------
  property a_stable_haddr_wait;
    (!$past(HREADY)) |-> ($stable(HADDR));
  endproperty
  assume_stable_haddr_wait: assume property (a_stable_haddr_wait);

  // ----------------------------------------------------------------------------
  // Assumption 13: HTRANS stable during wait states
  // Section 3.1 (Basic transfers).
  // ----------------------------------------------------------------------------
  property a_stable_htrans_wait;
    (!$past(HREADY)) |-> ($stable(HTRANS));
  endproperty
  assume_stable_htrans_wait: assume property (a_stable_htrans_wait);

  // ----------------------------------------------------------------------------
  // Assumption 14: HSIZE stable during wait states
  // Section 3.1 (Basic transfers).
  // ----------------------------------------------------------------------------
  property a_stable_hsize_wait;
    (!$past(HREADY)) |-> ($stable(HSIZE));
  endproperty
  assume_stable_hsize_wait: assume property (a_stable_hsize_wait);

  // ----------------------------------------------------------------------------
  // Assumption 15: HBURST stable during wait states
  // Section 3.1 (Basic transfers).
  // ----------------------------------------------------------------------------
  property a_stable_hburst_wait;
    (!$past(HREADY)) |-> ($stable(HBURST));
  endproperty
  assume_stable_hburst_wait: assume property (a_stable_hburst_wait);

  // ----------------------------------------------------------------------------
  // Assumption 16: HWRITE stable during wait states
  // Section 3.1 (Basic transfers).
  // ----------------------------------------------------------------------------
  property a_stable_hwrite_wait;
    (!$past(HREADY)) |-> ($stable(HWRITE));
  endproperty
  assume_stable_hwrite_wait: assume property (a_stable_hwrite_wait);

  // ----------------------------------------------------------------------------
  // Assumption 17: HSEL stable during wait states
  // Section 4.1 (Address decoding).
  // ----------------------------------------------------------------------------
  property a_stable_hsel_wait;
    (!$past(HREADY)) |-> ($stable(HSEL));
  endproperty
  assume_stable_hsel_wait: assume property (a_stable_hsel_wait);

  // ----------------------------------------------------------------------------
  // Assumption 18: SEQ cannot follow IDLE (Bursts start with NONSEQ)
  // Section 3.2 (Transfer types).
  // ----------------------------------------------------------------------------
  property a_no_seq_after_idle;
    (HTRANS == 2'b11) |-> ($past(HTRANS) != 2'b00);
  endproperty
  assume_no_seq_after_idle: assume property (a_no_seq_after_idle);

  // ----------------------------------------------------------------------------
  // Assumption 19: Valid predecessors for SEQ
  // Section 3.2 (Transfer types).
  // ----------------------------------------------------------------------------
  property a_valid_seq_pred;
    (HTRANS == 2'b11) |-> ($past(HTRANS) inside {2'b01, 2'b10, 2'b11});
  endproperty
  assume_valid_seq_pred: assume property (a_valid_seq_pred);

  // ----------------------------------------------------------------------------
  // Assumption 20: Valid predecessors for BUSY
  // Section 3.2 (Transfer types).
  // ----------------------------------------------------------------------------
  property a_valid_busy_pred;
    (HTRANS == 2'b01) |-> ($past(HTRANS) inside {2'b01, 2'b10, 2'b11});
  endproperty
  assume_valid_busy_pred: assume property (a_valid_busy_pred);

  // ----------------------------------------------------------------------------
  // Assumption 21: SINGLE burst prevents SEQ
  // Section 3.5 (Burst operation).
  // ----------------------------------------------------------------------------
  property a_single_no_seq;
    ($past(HBURST) == 3'b000) |-> (HTRANS != 2'b11);
  endproperty
  assume_single_no_seq: assume property (a_single_no_seq);

  // ----------------------------------------------------------------------------
  // Assumption 22: SINGLE burst prevents BUSY
  // Section 3.5 (Burst operation).
  // ----------------------------------------------------------------------------
  property a_single_no_busy;
    ($past(HBURST) == 3'b000) |-> (HTRANS != 2'b01);
  endproperty
  assume_single_no_busy: assume property (a_single_no_busy);

  // ----------------------------------------------------------------------------
  // Assumption 23: Constant HSIZE during a burst
  // Section 3.5 (Burst operation).
  // ----------------------------------------------------------------------------
  property a_const_hsize_burst;
    (HTRANS inside {2'b01, 2'b11}) |-> ($stable(HSIZE));
  endproperty
  assume_const_hsize_burst: assume property (a_const_hsize_burst);

  // ----------------------------------------------------------------------------
  // Assumption 24: Constant HWRITE during a burst
  // Section 3.5 (Burst operation).
  // ----------------------------------------------------------------------------
  property a_const_hwrite_burst;
    (HTRANS inside {2'b01, 2'b11}) |-> ($stable(HWRITE));
  endproperty
  assume_const_hwrite_burst: assume property (a_const_hwrite_burst);

  // ----------------------------------------------------------------------------
  // Assumption 25: Constant HBURST during a burst
  // Section 3.5 (Burst operation).
  // ----------------------------------------------------------------------------
  property a_const_hburst_burst;
    (HTRANS inside {2'b01, 2'b11}) |-> ($stable(HBURST));
  endproperty
  assume_const_hburst_burst: assume property (a_const_hburst_burst);

  // ----------------------------------------------------------------------------
  // Assumption 26: INCR4 burst length constraint
  // Section 3.5 (Burst operation).
  // ----------------------------------------------------------------------------
  property a_burst_len_incr4;
    (HSEL && HTRANS == 2'b10 && HBURST == 3'b011 && HREADY) |=> 
    (HTRANS inside {2'b11, 2'b01} && HREADY)[->3];
  endproperty
  assume_burst_len_incr4: assume property (a_burst_len_incr4);

  // ----------------------------------------------------------------------------
  // Assumption 27: WRAP4 burst length constraint
  // Section 3.5 (Burst operation).
  // ----------------------------------------------------------------------------
  property a_burst_len_wrap4;
    (HSEL && HTRANS == 2'b10 && HBURST == 3'b010 && HREADY) |=> 
    (HTRANS inside {2'b11, 2'b01} && HREADY)[->3];
  endproperty
  assume_burst_len_wrap4: assume property (a_burst_len_wrap4);

  // ----------------------------------------------------------------------------
  // Assumption 28: INCR8 burst length constraint
  // Section 3.5 (Burst operation).
  // ----------------------------------------------------------------------------
  property a_burst_len_incr8;
    (HSEL && HTRANS == 2'b10 && HBURST == 3'b101 && HREADY) |=> 
    (HTRANS inside {2'b11, 2'b01} && HREADY)[->7];
  endproperty
  assume_burst_len_incr8: assume property (a_burst_len_incr8);

  // ----------------------------------------------------------------------------
  // Assumption 29: WRAP8 burst length constraint
  // Section 3.5 (Burst operation).
  // ----------------------------------------------------------------------------
  property a_burst_len_wrap8;
    (HSEL && HTRANS == 2'b10 && HBURST == 3'b100 && HREADY) |=> 
    (HTRANS inside {2'b11, 2'b01} && HREADY)[->7];
  endproperty
  assume_burst_len_wrap8: assume property (a_burst_len_wrap8);

  // ----------------------------------------------------------------------------
  // Assumption 30: INCR16 burst length constraint
  // Section 3.5 (Burst operation).
  // ----------------------------------------------------------------------------
  property a_burst_len_incr16;
    (HSEL && HTRANS == 2'b10 && HBURST == 3'b111 && HREADY) |=> 
    (HTRANS inside {2'b11, 2'b01} && HREADY)[->15];
  endproperty
  assume_burst_len_incr16: assume property (a_burst_len_incr16);

  // ----------------------------------------------------------------------------
  // Assumption 31: WRAP16 burst length constraint
  // Section 3.5 (Burst operation).
  // ----------------------------------------------------------------------------
  property a_burst_len_wrap16;
    (HSEL && HTRANS == 2'b10 && HBURST == 3'b110 && HREADY) |=> 
    (HTRANS inside {2'b11, 2'b01} && HREADY)[->15];
  endproperty
  assume_burst_len_wrap16: assume property (a_burst_len_wrap16);

endmodule