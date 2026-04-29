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



  default clocking cb @(posedge HCLK); endclocking
  default disable iff (!HRESETn);

  // ======================================================
  // 1. Address alignment
  // ======================================================
  assume property (
    (HSEL && HTRANS inside {2'b10,2'b11}) |->
    (
      (HSIZE == 3'b000) ||
      (HSIZE == 3'b001 && HADDR[0] == 0) ||
      (HSIZE == 3'b010 && HADDR[1:0] == 0)
    )
  );

  // ======================================================
  // 2. SEQ follows NONSEQ/SEQ
  // ======================================================
  assume property (
    (HTRANS == 2'b11) |-> ($past(HTRANS) inside {2'b10,2'b11})
  );

  // ======================================================
  // 3. Fixed burst completion (4-beat)
  // ======================================================
  assume property (
    (HSEL && HTRANS == 2'b10 && HBURST inside {3'b010,3'b011} && HREADY)
    |=> (HTRANS == 2'b11)[->3]
  );

  // ======================================================
  // 4. Hold signals during wait
  // ======================================================
  assume property (
    (!$past(HREADY)) |->
    ($stable(HADDR) && $stable(HTRANS) && 
     $stable(HSIZE) && $stable(HBURST) && $stable(HWRITE))
  );

  // ======================================================
  // 6. No BUSY in SINGLE
  // ======================================================
  assume property (
    (HBURST == 3'b000) |-> (HTRANS != 2'b01)
  );

  // ======================================================
  // 7. WRAP boundary (WRAP4, WORD)
  // ======================================================
  assume property (
    (HSEL && HTRANS == 2'b11 && HBURST == 3'b010 && HSIZE == 3'b010) |->
    (HADDR[15:4] == $past(HADDR[15:4]))
  );

endmodule
