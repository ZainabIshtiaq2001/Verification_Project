`timescale 1ns/1ns
interface ahb_if #(
    parameter ADDR_W=16, DATA_W=32 //this is from design file HADDR_SIZE and HDATA_SIZE
    ) ();

// ---------------- CLOCK & RESET ----------------
   logic HCLK;
   logic HRESETn;

// ---------------- MASTER → SLAVE ----------------
   logic                  HSEL; //decoder signal. HSEL 1 is for 1 slave.
   logic [ADDR_W-1:0]     HADDR;
   logic                  HWRITE; //1 for write, 0 for read
   logic [2:0]            HSIZE;
   logic [2:0]            HBURST; // 3 bits for 8 burst types: SINGLE, INCR, WRAP4, INCR4, WRAP8, INCR8, WRAP16, INCR16
   logic [1:0]            HTRANS; //2 width for the 4 states: IDLE, BUSY, NONSEQ, SEQ   
   logic [DATA_W-1:0]     HWDATA; //MAIN TRANSFER DATA BUS

// ---------------- SLAVE → MASTER ----------------
   logic [DATA_W-1:0]     HRDATA; // trasnfers data from slave to master
   logic                  HREADYOUT; // 1 = transfer completes, 0 = wait state inserted    
   logic                  HRESP; // 0 for OKAY, 1 for ERROR

// ---------------- SHARED ----------------
   logic                  HREADY;   // driven from HREADYOUT in TB

// ---------------- CLOCKING BLOCK ----------------
   clocking cb @(posedge HCLK);
      default input #1step output #1step; //THROWS WARNING.

      output HSEL, HADDR, HWRITE, HSIZE, HBURST, HTRANS, HWDATA;
      input  HRDATA, HREADYOUT, HRESP;
      input  HREADY;
   endclocking
   
   // ---------------- MODPORTS ----------------
   modport master (
      clocking cb,
      output HSEL, HADDR, HWRITE, HSIZE, HBURST, HTRANS, HWDATA,
      input  HCLK, HRESETn, HRDATA, HREADYOUT, HRESP, HREADY
      
   ); //refer to figure 1-2 Manager interface from specs

   modport slave (
      
      input  HCLK, HRESETn, HSEL, HADDR, HWRITE, HSIZE, HBURST, HTRANS, HWDATA,
      output HRDATA, HREADYOUT, HRESP,
      input  HREADY //from the testbench
   ); //refer to figure 1-3 Subordinate interface from specs

endinterface