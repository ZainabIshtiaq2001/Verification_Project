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
    ahb3lite_if.master bus1
);

  timeunit 1ns;
  timeprecision 1ns;

  // ========================================================================
  // COVERGROUP 1: HTRANS (AHB Transfer Type)
  // Covers all valid AHB transfer types
  // ========================================================================
  covergroup HTRANS_covergroup @(posedge HCLK);
    option.per_instance = 1;
    coverpoint bus1.HTRANS {
      bins idle    = {2'b00};  // No transfer
      bins busy    = {2'b01};  // Busy transfer
      bins nonseq  = {2'b10};  // Non-sequential transfer
      bins seq     = {2'b11};  // Sequential transfer
    }
  endgroup : HTRANS_covergroup

  // ========================================================================
  // COVERGROUP 4: HPROT (Protection Control Signals)
  // Covers cache, buffer, privilege level, and access type combinations
  // ========================================================================
  covergroup HPROT_covergroup @(posedge HCLK);
    option.per_instance = 1;
    coverpoint bus1.HPROT {
      bins hprot_nc_nb_usr_opcode = {4'b0000};  // Non-cacheable, non-bufferable, user, opcode
      bins hprot_nc_nb_usr_data   = {4'b0001};  // Non-cacheable, non-bufferable, user, data
      bins hprot_nc_nb_priv_opcode= {4'b0010};  // Non-cacheable, non-bufferable, privileged, opcode
      bins hprot_nc_nb_priv_data  = {4'b0011};  // Non-cacheable, non-bufferable, privileged, data
    }
  endgroup : HPROT_covergroup

  // ========================================================================
  // COVERGROUP 10 (LAST): Cross Coverage of HTRANS and HREADY
  // Covers interaction between transfer types and transfer readiness
  // ========================================================================
  covergroup cross_cg_HTRANS_and_HREADY @(posedge HCLK);
    option.per_instance = 1;
    option.cross_auto_bin_max = 0;
    coverpoint bus1.HTRANS {
      bins idle    = {2'b00};
      bins busy    = {2'b01};
      bins nonseq  = {2'b10};
      bins seq     = {2'b11};
    }
    coverpoint bus1.HREADY {
      bins ready     = {1'b1};  // Transfer ready
      bins not_ready = {1'b0};  // Transfer not ready (wait state)
    }
    cross bus1.HTRANS, bus1.HREADY {
      bins idle_ready        = binsof(bus1.HTRANS.idle) && binsof(bus1.HREADY.ready);
      bins nonseq_ready      = binsof(bus1.HTRANS.nonseq) && binsof(bus1.HREADY.ready);
      bins nonseq_not_ready  = binsof(bus1.HTRANS.nonseq) && binsof(bus1.HREADY.not_ready);
      bins seq_ready         = binsof(bus1.HTRANS.seq) && binsof(bus1.HREADY.ready);
      bins busy_not_ready    = binsof(bus1.HTRANS.busy) && binsof(bus1.HREADY.not_ready);
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