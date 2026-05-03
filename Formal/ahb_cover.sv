// ==============================================================================
// File: ahb_cover.sv
// Role: Cover properties — proves scenarios are reachable
// Project: EE-5214 Verification of Digital Systems (Role B)
//
// FIX: This module was referenced in bind_ahb.sv but was completely missing
// from the original submission.  Without it JasperGold throws an elaboration
// error: "module 'ahb_cover' not found".
// ==============================================================================

module ahb_cover (
  input HCLK,
  input HRESETn,
  input HSEL,
  input [15:0] HADDR,
  input [1:0]  HTRANS,
  input HREADY,
  input HWRITE,
  input HRESP,
  input HREADYOUT,
  input [2:0]  HBURST
);

  default clocking cb @(posedge HCLK); endclocking
  default disable iff (!HRESETn);

  // ------------------------------------------------------------------
  // C1: A simple single write transfer completes successfully
  // ------------------------------------------------------------------
  cover property (
    HSEL && HREADY && HTRANS == 2'b10 && HWRITE &&
    HBURST == 3'b000 &&
    ##1 HREADYOUT && !HRESP
  ) $info("COVER: Single write completed");

  // ------------------------------------------------------------------
  // C2: A simple single read transfer completes successfully
  // ------------------------------------------------------------------
  cover property (
    HSEL && HREADY && HTRANS == 2'b10 && !HWRITE &&
    HBURST == 3'b000 &&
    ##1 HREADYOUT && !HRESP
  ) $info("COVER: Single read completed");

  // ------------------------------------------------------------------
  // C3: A wait state is inserted (HREADYOUT de-asserted mid transfer)
  // ------------------------------------------------------------------
  cover property (
    HSEL && HREADY && HTRANS == 2'b10 &&
    ##1 !HREADYOUT &&
    ##1 HREADYOUT
  ) $info("COVER: Wait state observed");

  // ------------------------------------------------------------------
  // C4: An error response is generated (2-cycle error handshake)
  // ------------------------------------------------------------------
  cover property (
    HRESP && !HREADYOUT &&
    ##1 HRESP && HREADYOUT
  ) $info("COVER: Error response observed");

  // ------------------------------------------------------------------
  // C5: INCR4 burst (NONSEQ + 3 SEQ beats) completes
  // ------------------------------------------------------------------
  cover property (
    HSEL && HREADY && HTRANS == 2'b10 && HBURST == 3'b011 &&
    ##1 (HTRANS == 2'b11)[*3] ##1
    (HTRANS inside {2'b00, 2'b10})
  ) $info("COVER: INCR4 burst completed");

  // ------------------------------------------------------------------
  // C6: WRAP4 burst completes
  // ------------------------------------------------------------------
  cover property (
    HSEL && HREADY && HTRANS == 2'b10 && HBURST == 3'b010 &&
    ##1 (HTRANS == 2'b11)[*3] ##1
    (HTRANS inside {2'b00, 2'b10})
  ) $info("COVER: WRAP4 burst completed");

  // ------------------------------------------------------------------
  // C7: BUSY beat observed inside a burst
  // ------------------------------------------------------------------
  cover property (
    HSEL && HREADY && HTRANS == 2'b10 && HBURST != 3'b000 &&
    ##1 HTRANS == 2'b01 &&
    ##1 HTRANS == 2'b11
  ) $info("COVER: BUSY beat inside burst");

  // ------------------------------------------------------------------
  // C8: Back-to-back transfers (no IDLE between them)
  // ------------------------------------------------------------------
  cover property (
    HSEL && HREADY && HTRANS == 2'b10 && HBURST == 3'b000 &&
    ##1 HREADYOUT &&
    ##0 HTRANS == 2'b10
  ) $info("COVER: Back-to-back single transfers");

endmodule