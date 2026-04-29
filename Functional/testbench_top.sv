`timescale 1ns/1ns
module tb_top;

   // ---------------- INTERFACE ----------------
   ahb_if ahb();

   // ---------------- CLOCK ----------------
   initial begin
      ahb.HCLK = 0;
      forever #5 ahb.HCLK = ~ahb.HCLK; // 10ns period
   end

   // ---------------- RESET ----------------
   initial begin
      ahb.HRESETn = 0;
      #20;
      ahb.HRESETn = 1;
   end

   // ---------------- INITIALIZE SIGNALS ----------------
   initial begin
        ahb.HSEL   = 0;
        ahb.HADDR  = 0;
        ahb.HWRITE = 0;
        ahb.HTRANS = 2'b00; // IDLE
        ahb.HSIZE  = 0;
        ahb.HBURST = 0;
        ahb.HWDATA = 0;
   end
   // ---------------- CONNECT READY ----------------
   assign ahb.HREADY = ahb.HREADYOUT;

   // ---------------- DUT ----------------
   ahb3liten dut (
      .HCLK      (ahb.HCLK),
      .HRESETn   (ahb.HRESETn),
      .HSEL      (ahb.HSEL),
      .HADDR     (ahb.HADDR),
      .HWDATA    (ahb.HWDATA),
      .HRDATA    (ahb.HRDATA),
      .HWRITE    (ahb.HWRITE),
      .HSIZE     (ahb.HSIZE),
      .HBURST    (ahb.HBURST),
      .HPROT     (4'b0),           // ignored
      .HTRANS    (ahb.HTRANS),
      .HREADYOUT (ahb.HREADYOUT),
      .HREADY    (ahb.HREADY),
      .HRESP     (ahb.HRESP)
   );

   directed_tests dt(ahb);
   // if error try 
   //program directed_tests(ahb_if ahb);

endmodule