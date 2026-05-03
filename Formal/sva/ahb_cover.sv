// ==============================================================================
// File: ahb_cover.sv
// Role: Cover properties — JasperGold-safe version
// ==============================================================================

module ahb_cover (
  input logic        HCLK,
  input logic        HRESETn,
  input logic        HSEL,
  input logic [31:0] HADDR,
  input logic [1:0]  HTRANS,
  input logic        HREADY,
  input logic        HWRITE,
  input logic        HRESP,
  input logic        HREADYOUT,
  input logic [2:0]  HBURST,
  input logic [2:0]  HSIZE
);

  // ------------------------------------------------------------
  // Global clocking + reset (Jasper-safe style)
  // ------------------------------------------------------------
  default clocking cb @(posedge HCLK); endclocking
  default disable iff (!HRESETn);

  // ------------------------------------------------------------
  // C1: Single write transfer completes
  // ------------------------------------------------------------
  cover property (
    HSEL && HREADY &&
    HTRANS == 2'b10 &&
    HWRITE &&
    HBURST == 3'b000 ##1
    (HREADYOUT && !HRESP)
  );

  // ------------------------------------------------------------
  // C2: Single read transfer completes
  // ------------------------------------------------------------
  cover property (
    HSEL && HREADY &&
    HTRANS == 2'b10 &&
    !HWRITE &&
    HBURST == 3'b000 ##1
    (HREADYOUT && !HRESP)
  );

  // ------------------------------------------------------------
  // C3: Wait state insertion
  // ------------------------------------------------------------
  cover property (
    HSEL && HREADY &&
    HTRANS == 2'b10 ##1
    (!HREADYOUT ##1 HREADYOUT)
  );

  // ------------------------------------------------------------
  // C4: Error response handshake
  // ------------------------------------------------------------
  cover property (
    HRESP && !HREADYOUT ##1
    (HRESP && HREADYOUT)
  );

  // ------------------------------------------------------------
  // C5: INCR4 burst (NONSEQ + 3 SEQ + finish)
  // ------------------------------------------------------------
  cover property (
    HSEL && HREADY &&
    HTRANS == 2'b10 &&
    HBURST == 3'b011 ##1
    (HTRANS == 2'b11)[*3] ##1
    (HTRANS inside {2'b00, 2'b10})
  );

  // ------------------------------------------------------------
  // C6: WRAP4 burst
  // ------------------------------------------------------------
  cover property (
    HSEL && HREADY &&
    HTRANS == 2'b10 &&
    HBURST == 3'b010 ##1
    (HTRANS == 2'b11)[*3] ##1
    (HTRANS inside {2'b00, 2'b10})
  );

  // ------------------------------------------------------------
  // C7: BUSY cycle inside burst
  // ------------------------------------------------------------
  cover property (
    HSEL && HREADY &&
    HTRANS == 2'b10 &&
    HBURST != 3'b000 ##1
    (HTRANS == 2'b01 ##1 HTRANS == 2'b11)
  );

  // ------------------------------------------------------------
  // C8: Back-to-back transfers (no IDLE gap)
  // ------------------------------------------------------------
  cover property (
    HSEL && HREADY &&
    HTRANS == 2'b10 ##1
    (HREADYOUT && HTRANS == 2'b10)
  );

endmodule