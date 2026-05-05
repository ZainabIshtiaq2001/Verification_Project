// ==============================================================================
// File: bind_ahb.sv
// Removed the 'module bind_ahb;' wrapper so bindings apply globally.
// ==============================================================================

  // 1. Bind the Assertions (Checks the Slave)
  bind ahb3liten ahb_checker u_checker (
     .HRESETn    (HRESETn),
     .HCLK       (HCLK),
     .HSEL       (HSEL),
     .HADDR      (HADDR),
     .HWDATA     (HWDATA),
     .HRDATA     (HRDATA),
     .HWRITE     (HWRITE),
     .HSIZE      (HSIZE),
     .HBURST     (HBURST),
     .HTRANS     (HTRANS),
     .HREADYOUT  (HREADYOUT),
     .HREADY     (HREADY),
     .HRESP      (HRESP)
  );

  // 2. Bind the Assumptions (CRITICAL: Constrains JasperGold to drive legal traffic)
  bind ahb3liten ahb_assumptions u_assumptions (
     .HCLK       (HCLK),
     .HRESETn    (HRESETn),
     .HSEL       (HSEL),
     .HADDR      (HADDR),
     .HTRANS     (HTRANS),
     .HSIZE      (HSIZE),
     .HBURST     (HBURST),
     .HREADY     (HREADY),
     .HWRITE     (HWRITE) 
  );

  // 3. Bind the Covers
  bind ahb3liten ahb_cover u_cover (
     .HCLK       (HCLK),
     .HRESETn    (HRESETn),
     .HSEL       (HSEL),
     .HADDR      (HADDR),
     .HTRANS     (HTRANS),
     .HREADY     (HREADY),
     .HWRITE     (HWRITE),
     .HRESP      (HRESP),
     .HREADYOUT  (HREADYOUT), 
     .HBURST     (HBURST),
     .HSIZE      (HSIZE)
  );