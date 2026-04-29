module ahb_cover (
  input HCLK,
  input HRESETn,
  input HSEL,
  input [1:0] HTRANS,
  input HREADY,
  input HWRITE,
  input HRESP,
  input [2:0] HBURST
);

  // ------------------------------------------
  // NONSEQ observed
  // ------------------------------------------
  cover property (@(posedge HCLK)
    HRESETn && HTRANS == 2'b10
  );

  // ------------------------------------------
  // SEQ observed
  // ------------------------------------------
  cover property (@(posedge HCLK)
    HRESETn && HTRANS == 2'b11
  );

  // ------------------------------------------
  // Back-to-back transfers
  // ------------------------------------------
  cover property (@(posedge HCLK)
    HTRANS == 2'b10 ##1 HTRANS == 2'b11
  );

  // ------------------------------------------
  // WAIT state observed
  // ------------------------------------------
  cover property (@(posedge HCLK)
    !HREADY
  );

  // ------------------------------------------
  // Write observed
  // ------------------------------------------
  cover property (@(posedge HCLK)
    HWRITE && HSEL
  );

  // ------------------------------------------
  // Error response observed
  // ------------------------------------------
  cover property (@(posedge HCLK)
    HRESP == 1'b1
  );

  // ------------------------------------------
  // Burst activity observed
  // ------------------------------------------
  cover property (@(posedge HCLK)
    HBURST != 3'b000
  );

endmodule
