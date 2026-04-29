`timescale 1ns/1ns
interface ahb_if #(
    parameter ADDR_W=16, DATA_W=32
    ) ();

// ---------------- CLOCK & RESET ----------------
   logic HCLK;
   logic HRESETn;

// ---------------- MASTER → SLAVE ----------------
   logic                  HSEL;
   logic [ADDR_W-1:0]     HADDR;
   logic                  HWRITE;
   logic [2:0]            HSIZE;
   logic [2:0]            HBURST;
   logic [1:0]            HTRANS;
   logic [DATA_W-1:0]     HWDATA;
   logic [3:0]            HPROT;        // ← ADD THIS

// ---------------- SLAVE → MASTER ----------------
   logic [DATA_W-1:0]     HRDATA;
   logic                  HREADYOUT;
   logic                  HRESP;

// ---------------- SHARED ----------------
   logic                  HREADY;

// ---------------- CLOCKING BLOCK ----------------
   clocking cb @(posedge HCLK);
      default input #1step output #1step;

      output HSEL, HADDR, HWRITE, HSIZE, HBURST, HTRANS, HWDATA, HPROT;  // ← ADD HPROT
      input  HRDATA, HREADYOUT, HRESP;
      input  HREADY;
   endclocking
   
// ---------------- MODPORTS ----------------
   modport master (
      clocking cb,
      output HSEL, HADDR, HWRITE, HSIZE, HBURST, HTRANS, HWDATA, HPROT,  // ← ADD HPROT
      input  HCLK, HRESETn, HRDATA, HREADYOUT, HRESP, HREADY
   );

   modport slave (
      input  HCLK, HRESETn, HSEL, HADDR, HWRITE, HSIZE, HBURST, HTRANS, HWDATA, HPROT,  // ← ADD HPROT
      output HRDATA, HREADYOUT, HRESP,
      input  HREADY
   );

endinterface