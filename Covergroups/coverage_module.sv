///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// contributed by : Muhammad Asim Javaid Phd@Lums
//
// File name : coverage_module.sv
// Title : coverage_module for project part c
// Notes : Covergroups and coverpoints are in this file
//
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
import ahb3lite_pkg::*;

module coverage_module(
    input logic HCLK,
    input logic HRESETn,
    ahb_if.master bus1
);

  timeunit 1ns;
  timeprecision 1ns;

  // Create local copies of interface signals to avoid scoping issues
  logic [1:0] htrans_local;
  logic hready_local;
  logic [3:0] hprot_local;

  always @(posedge HCLK) begin
    htrans_local <= bus1.HTRANS;
    hready_local <= bus1.HREADY;
    hprot_local  <= bus1.HPROT;
  end

  // ========================================================================
  // COVERGROUP 1: HTRANS (AHB Transfer Type)
  // Covers all valid AHB transfer types
  // ========================================================================
  covergroup HTRANS_covergroup @(posedge HCLK);
    option.per_instance = 1;
    coverpoint htrans_local {
      bins idle    = {2'b00};
      bins busy    = {2'b01};
      bins nonseq  = {2'b10};
      bins seq     = {2'b11};
    }
  endgroup : HTRANS_covergroup

  // ========================================================================
  // COVERGROUP 4: HPROT (Protection Control Signals)
  // ========================================================================
  covergroup HPROT_covergroup @(posedge HCLK);
    option.per_instance = 1;
    coverpoint hprot_local {
      bins hprot_nc_nb_usr_opcode = {4'b0000};
      bins hprot_nc_nb_usr_data   = {4'b0001};
      bins hprot_nc_nb_priv_opcode= {4'b0010};
      bins hprot_nc_nb_priv_data  = {4'b0011};
    }
  endgroup : HPROT_covergroup

  // ========================================================================
  // COVERGROUP 10: Cross Coverage of HTRANS and HREADY
  // ========================================================================
  covergroup cross_cg_HTRANS_and_HREADY @(posedge HCLK);
    option.per_instance = 1;
    
    coverpoint htrans_local {
      bins idle    = {2'b00};
      bins busy    = {2'b01};
      bins nonseq  = {2'b10};
      bins seq     = {2'b11};
    }
    
    coverpoint hready_local {
      bins ready     = {1'b1};
      bins not_ready = {1'b0};
    }
    
    cross htrans_local, hready_local {
      bins idle_ready        = binsof(htrans_local.idle) && binsof(hready_local.ready);
      bins nonseq_ready      = binsof(htrans_local.nonseq) && binsof(hready_local.ready);
      bins nonseq_not_ready  = binsof(htrans_local.nonseq) && binsof(hready_local.not_ready);
      bins seq_ready         = binsof(htrans_local.seq) && binsof(hready_local.ready);
      bins busy_not_ready    = binsof(htrans_local.busy) && binsof(hready_local.not_ready);
    }
  endgroup : cross_cg_HTRANS_and_HREADY

  // ========================================================================
  // Covergroup Instantiation
  // ========================================================================
  HTRANS_covergroup htrans_cg;
  HPROT_covergroup hprot_cg;
  cross_cg_HTRANS_and_HREADY htrans_hready_cg;

  initial begin
    htrans_cg = new();
    hprot_cg = new();
    htrans_hready_cg = new();
  end

endmodule