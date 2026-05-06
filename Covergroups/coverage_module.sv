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

  logic hwrite_local;
  logic [2:0] hburst_local;
  logic [2:0] hsize_local;
  logic [31:0] haddr_local;




  always @(posedge HCLK) begin
  htrans_local <= bus1.HTRANS;
  hready_local <= bus1.HREADY;
  hprot_local  <= bus1.HPROT;

  hwrite_local <= bus1.HWRITE;
  hburst_local <= bus1.HBURST;
  hsize_local  <= bus1.HSIZE;
  haddr_local  <= bus1.HADDR;
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
  // COVERGROUP 2: Hwrite (Write/Read Signal)
  // ========================================================================
covergroup HWRITE_covergroup @(posedge HCLK);
  option.per_instance = 1;

  coverpoint hwrite_local {
    bins read  = {0};
    bins write = {1};
  }

endgroup
// ========================================================================
  // COVERGROUP 3: HBURST (Burst Type Signals)
  // ========================================================================
covergroup HBURST_covergroup @(posedge HCLK);
  option.per_instance = 1;

  coverpoint hburst_local {
    bins single = {3'b000};
    bins incr   = {3'b001};
    bins wrap4  = {3'b010};
    bins incr4  = {3'b011};
    bins wrap8  = {3'b100};
    bins incr8  = {3'b101};
    bins wrap16 = {3'b110};
    bins incr16 = {3'b111};
  }

endgroup


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
  // COVERGROUP 5: HSIZE (Transfer Size Signals)
  // ========================================================================
covergroup HSIZE_covergroup @(posedge HCLK);
  option.per_instance = 1;

  coverpoint hsize_local {
    bins byte_bin  = {3'b000};
    bins halfword  = {3'b001};
    bins word      = {3'b010};
  }

endgroup
// ========================================================================
  // COVERGROUP 6: Address Alignment for 
  // ========================================================================
covergroup ADDR_ALIGN_covergroup @(posedge HCLK);
  option.per_instance = 1;

  coverpoint haddr_local[2:0] {
    bins aligned_0 = {3'b000};
    bins aligned_2 = {3'b010};
    bins aligned_4 = {3'b100};
    bins others    = default;
  }

endgroup
// ========================================================================
  // COVERGROUP 7: Cross Coverage of HTRANS and HWRITE
  // ========================================================================

covergroup cross_HTRANS_HWRITE @(posedge HCLK);
  option.per_instance = 1;

  coverpoint htrans_local;
  coverpoint hwrite_local;

  cross htrans_local, hwrite_local;

endgroup
  // ========================================================================
  // COVERGROUP 8: Cross Coverage of Hwrite and Hready
  // ========================================================================
covergroup cross_HWRITE_HREADY @(posedge HCLK);
  option.per_instance = 1;

  coverpoint hwrite_local;
  coverpoint hready_local;

  cross hwrite_local, hready_local;

endgroup

// ========================================================================
  // COVERGROUP 9: Cross Coverage of HTRANS and HBURST
  // ========================================================================

covergroup cross_HTRANS_HBURST @(posedge HCLK);
  option.per_instance = 1;

  coverpoint htrans_local;
  coverpoint hburst_local;

  cross htrans_local, hburst_local;

endgroup

// ========================================================================
  // COVERGROUP 10: Cross Coverage of HSIZE and HADDR[2:0]
  // ========================================================================

covergroup cross_HSIZE_ADDR @(posedge HCLK);
  option.per_instance = 1;

  coverpoint hsize_local;
  coverpoint haddr_local[2:0];

  cross hsize_local, haddr_local;

endgroup

// ========================================================================
  // COVERGROUP 11: Cross Coverage of HTRANS and HREADY
  // ========================================================================

covergroup cross_HTRANS_HWRITE_HREADY @(posedge HCLK);
  option.per_instance = 1;

  coverpoint htrans_local;
  coverpoint hwrite_local;
  coverpoint hready_local;

  cross htrans_local, hwrite_local, hready_local;

endgroup

  // ========================================================================
  // COVERGROUP 12: Cross Coverage of HTRANS and HREADY
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
HWRITE_covergroup hwrite_cg;
HBURST_covergroup hburst_cg;
HSIZE_covergroup hsize_cg;
ADDR_ALIGN_covergroup addr_align_cg;

cross_HTRANS_HWRITE cross1_cg;
cross_HWRITE_HREADY cross2_cg;
cross_HTRANS_HBURST cross3_cg;
cross_HSIZE_ADDR cross4_cg;
cross_HTRANS_HWRITE_HREADY cross5_cg;

initial begin
htrans_cg = new();
hprot_cg = new();
htrans_hready_cg = new();
  hwrite_cg = new();
  hburst_cg = new();
  hsize_cg = new();
  addr_align_cg = new();

  cross1_cg = new();
  cross2_cg = new();
  cross3_cg = new();
  cross4_cg = new();
  cross5_cg = new();
end


endmodule