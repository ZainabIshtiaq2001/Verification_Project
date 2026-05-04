`timescale 1ns/1ns

interface ahb_if #(
    parameter ADDR_W = 16,
    parameter DATA_W = 32
) (
    input logic HCLK,
    input logic HRESETn
);

  // ========================================================================
  // MASTER → SLAVE SIGNALS
  // ========================================================================
  logic                  HSEL;
  logic [ADDR_W-1:0]     HADDR;
  logic                  HWRITE;
  logic [2:0]            HSIZE;
  logic [2:0]            HBURST;
  logic [1:0]            HTRANS;
  logic [DATA_W-1:0]     HWDATA;
  logic [3:0]            HPROT;
  logic                  HREADY;       // ← MASTER DRIVES THIS

  // ========================================================================
  // SLAVE → MASTER SIGNALS
  // ========================================================================
  logic [DATA_W-1:0]     HRDATA;
  logic                  HREADYOUT;
  logic                  HRESP;

  // ========================================================================
  // CLOCKING BLOCK
  // ========================================================================
  clocking cb @(posedge HCLK);
    default input #1step output #1step;
    output HSEL, HADDR, HWRITE, HSIZE, HBURST, HTRANS, HWDATA, HPROT, HREADY;  // ← ADD HREADY
    input  HRDATA, HREADYOUT, HRESP;
  endclocking

  // ========================================================================
  // MODPORTS
  // ========================================================================
  modport master (
    clocking cb,
    input  HCLK, HRESETn,
    output HSEL, HADDR, HWRITE, HSIZE, HBURST, HTRANS, HWDATA, HPROT, HREADY,  // ← ADD HREADY
    input  HRDATA, HREADYOUT, HRESP
  );

  modport slave (
    input  HCLK, HRESETn, HSEL, HADDR, HWRITE, HSIZE, HBURST, HTRANS, HWDATA, HPROT, HREADY,  // ← ADD HREADY
    output HRDATA, HREADYOUT, HRESP
  );

  modport monitor (
    input  HCLK, HRESETn, HSEL, HADDR, HWRITE, HSIZE, HBURST, HTRANS, HWDATA, HPROT,
           HRDATA, HREADYOUT, HRESP, HREADY
  );

endinterface