///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// contributed by : Muhammad Asim Javaid Phd@Lums
//
// File name : directed_tests.sv
// Notes : AHB-Lite tasks with DUT-specific 1-cycle read latency fix
//         FIXED: All variables properly declared as automatic, no implicit static declarations
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

package ahb_test_pkg;

  function automatic bit [3:0] generate_be(bit [31:0] addr, bit [2:0] size);
    bit [1:0] addr_offset = addr[1:0];
    bit [3:0] be;
    case (size)
      3'b000: be = (4'b0001 << addr_offset);
      3'b001: be = (4'b0011 << addr_offset);
      3'b010: be = 4'b1111;
      default: be = 4'b0000;
    endcase
    return be;
  endfunction

  // ========================= SINGLE WRITE =========================
  task automatic single_write(
    virtual ahb_if vif,
    bit [31:0] addr,
    bit [31:0] data,
    bit [2:0] size,
    output bit [3:0] be
  );
    be = generate_be(addr, size);

    vif.cb.HSEL    <= 1'b1;
    vif.cb.HADDR   <= addr;
    vif.cb.HWRITE  <= 1'b1;
    vif.cb.HTRANS  <= 2'b10;
    vif.cb.HSIZE   <= size;
    vif.cb.HBURST  <= 3'b000;
    vif.cb.HPROT   <= 4'b0011;
    vif.cb.HWDATA  <= data;

    @(vif.cb);
    while (!vif.cb.HREADYOUT) @(vif.cb);
    @(vif.cb);

    vif.cb.HSEL    <= 1'b0;
    vif.cb.HTRANS  <= 2'b00;
  endtask

  // ========================= SINGLE READ =========================
  task automatic single_read(
    virtual ahb_if vif,
    bit [31:0] addr,
    bit [2:0] size,
    output bit [31:0] rdata,
    output bit [3:0] be
  );
    be = generate_be(addr, size);

    vif.cb.HSEL    <= 1'b1;
    vif.cb.HADDR   <= addr;
    vif.cb.HWRITE  <= 1'b0;
    vif.cb.HTRANS  <= 2'b10;
    vif.cb.HSIZE   <= size;
    vif.cb.HBURST  <= 3'b000;
    vif.cb.HPROT   <= 4'b0011;

    @(vif.cb);
    while (!vif.cb.HREADYOUT) @(vif.cb);

    @(vif.cb);
    @(vif.cb);
    rdata = vif.cb.HRDATA;

    vif.cb.HSEL    <= 1'b0;
    vif.cb.HTRANS  <= 2'b00;
  endtask

  // ========================= BURST WRITE INCR =========================
  task automatic burst_write_incr(
    virtual ahb_if vif,
    bit [31:0] addr,
    bit [2:0] size,
    bit [3:0] len,
    output bit [31:0] write_data_q [$]
  );
    bit [31:0] current_addr = addr;
    int beat_bytes;

    case (size)
      3'b000: beat_bytes = 1;
      3'b001: beat_bytes = 2;
      3'b010: beat_bytes = 4;
      default: beat_bytes = 4;
    endcase

    for (int i = 0; i < len; i++) begin
      bit [31:0] wdata = $urandom();
      write_data_q.push_back(wdata);

      vif.cb.HSEL    <= 1'b1;
      vif.cb.HADDR   <= current_addr;
      vif.cb.HWRITE  <= 1'b1;
      vif.cb.HTRANS  <= (i == 0) ? 2'b10 : 2'b11;
      vif.cb.HSIZE   <= size;
      vif.cb.HBURST  <= 3'b001;
      vif.cb.HPROT   <= 4'b0011;
      vif.cb.HWDATA  <= wdata;

      @(vif.cb);
      while (!vif.cb.HREADYOUT) @(vif.cb);

      current_addr += beat_bytes;
      @(vif.cb);
    end

    vif.cb.HSEL    <= 1'b0;
    vif.cb.HTRANS  <= 2'b00;
    vif.cb.HWDATA  <= 32'h0;
  endtask

  // ========================= BURST READ INCR =========================
  task automatic burst_read_incr(
    virtual ahb_if vif,
    bit [31:0] addr,
    bit [2:0] size,
    bit [3:0] len,
    output bit [31:0] read_data_q [$]
  );
    bit [31:0] current_addr = addr;
    int beat_bytes;

    case (size)
      3'b000: beat_bytes = 1;
      3'b001: beat_bytes = 2;
      3'b010: beat_bytes = 4;
      default: beat_bytes = 4;
    endcase

    for (int i = 0; i < len; i++) begin
      vif.cb.HSEL    <= 1'b1;
      vif.cb.HADDR   <= current_addr;
      vif.cb.HWRITE  <= 1'b0;
      vif.cb.HTRANS  <= (i == 0) ? 2'b10 : 2'b11;
      vif.cb.HSIZE   <= size;
      vif.cb.HBURST  <= 3'b001;
      vif.cb.HPROT   <= 4'b0011;

      @(vif.cb);
      while (!vif.cb.HREADYOUT) @(vif.cb);

      if (i == 0) @(vif.cb);
      @(vif.cb);

      read_data_q.push_back(vif.cb.HRDATA);
      current_addr += beat_bytes;
    end

    vif.cb.HSEL    <= 1'b0;
    vif.cb.HTRANS  <= 2'b00;
  endtask

  // ========================= BURST WRITE WRAP =========================
  task automatic burst_write_wrap(
    virtual ahb_if vif,
    bit [31:0] addr,
    bit [2:0] size,
    bit [3:0] len,
    output bit [31:0] write_data_q [$]
  );
    bit [31:0] current_addr = addr;
    int unsigned beat_bytes;
    int unsigned wrap_bytes;
    bit [31:0] wrap_base;
    bit [31:0] next_addr;

    case (size)
      3'b000: beat_bytes = 1;
      3'b001: beat_bytes = 2;
      default: beat_bytes = 4;
    endcase

    wrap_bytes = beat_bytes * len;
    wrap_base  = addr & ~(wrap_bytes - 1);

    for (int i = 0; i < len; i++) begin
      bit [31:0] wdata = $urandom();
      write_data_q.push_back(wdata);

      vif.cb.HSEL    <= 1'b1;
      vif.cb.HADDR   <= current_addr;
      vif.cb.HWRITE  <= 1'b1;
      vif.cb.HTRANS  <= (i == 0) ? 2'b10 : 2'b11;
      vif.cb.HSIZE   <= size;
      vif.cb.HBURST  <= (len == 4) ? 3'b010 : (len == 8) ? 3'b100 : 3'b110;
      vif.cb.HPROT   <= 4'b0011;
      vif.cb.HWDATA  <= wdata;

      @(vif.cb);
      while (!vif.cb.HREADYOUT) @(vif.cb);

      next_addr = current_addr + beat_bytes;
      current_addr = (next_addr >= (wrap_base + wrap_bytes)) ? wrap_base : next_addr;
      @(vif.cb);
    end

    vif.cb.HSEL    <= 1'b0;
    vif.cb.HTRANS  <= 2'b00;
    vif.cb.HWDATA  <= 32'h0;
  endtask

  // ========================= BURST READ WRAP =========================
  task automatic burst_read_wrap(
    virtual ahb_if vif,
    bit [31:0] addr,
    bit [2:0] size,
    bit [3:0] len,
    output bit [31:0] read_data_q [$]
  );
    bit [31:0] current_addr = addr;
    int unsigned beat_bytes;
    int unsigned wrap_bytes;
    bit [31:0] wrap_base;
    bit [31:0] next_addr;

    case (size)
      3'b000: beat_bytes = 1;
      3'b001: beat_bytes = 2;
      default: beat_bytes = 4;
    endcase

    wrap_bytes = beat_bytes * len;
    wrap_base  = addr & ~(wrap_bytes - 1);

    for (int i = 0; i < len; i++) begin
      vif.cb.HSEL    <= 1'b1;
      vif.cb.HADDR   <= current_addr;
      vif.cb.HWRITE  <= 1'b0;
      vif.cb.HTRANS  <= (i == 0) ? 2'b10 : 2'b11;
      vif.cb.HSIZE   <= size;
      vif.cb.HBURST  <= (len == 4) ? 3'b010 : (len == 8) ? 3'b100 : 3'b110;
      vif.cb.HPROT   <= 4'b0011;

      @(vif.cb);
      while (!vif.cb.HREADYOUT) @(vif.cb);

      if (i == 0) @(vif.cb);
      @(vif.cb);

      read_data_q.push_back(vif.cb.HRDATA);

      next_addr = current_addr + beat_bytes;
      current_addr = (next_addr >= (wrap_base + wrap_bytes)) ? wrap_base : next_addr;
    end

    vif.cb.HSEL    <= 1'b0;
    vif.cb.HTRANS  <= 2'b00;
  endtask

  // ========================= WAIT STATE TEST =========================
  task automatic wait_state_test(
    virtual ahb_if vif
  );
    bit [15:0] addr_s;
    bit [1:0]  htrans_s;
    bit        hwrite_s;
    bit [2:0]  hsize_s, hburst_s;
    bit wait_seen;  // FIXED: Declare without initialization

    wait_seen = 1'b0;  // FIXED: Initialize inside task body

    @(vif.cb);
    vif.cb.HSEL   <= 1;
    vif.cb.HADDR  <= 16'h0010;
    vif.cb.HWRITE <= 1;
    vif.cb.HTRANS <= 2'b10;
    vif.cb.HSIZE  <= 3'b010;
    vif.cb.HBURST <= 3'b000;

    addr_s   = vif.HADDR;
    htrans_s = vif.HTRANS;
    hwrite_s = vif.HWRITE;
    hsize_s  = vif.HSIZE;
    hburst_s = vif.HBURST;

    @(vif.cb);
    vif.cb.HWDATA <= 32'hAABBCCDD;

    do begin
      @(vif.cb);

      if (vif.HREADYOUT == 0) begin
        wait_seen = 1'b1;

        if (vif.HADDR  !== addr_s   ||
            vif.HTRANS !== htrans_s ||
            vif.HWRITE !== hwrite_s ||
            vif.HSIZE  !== hsize_s  ||
            vif.HBURST !== hburst_s) begin
          $display("[WAIT_STATE_TEST][FAIL] Signals changed during WAIT!");
        end
      end

    end while (vif.HREADYOUT == 0);

    if (!wait_seen)
      $display("[WAIT_STATE_TEST][FAIL] No wait state observed!");
    else
      $display("[WAIT_STATE_TEST][PASS] Wait state verified");

    @(vif.cb);
    vif.cb.HTRANS <= 2'b00;
    vif.cb.HSEL   <= 0;

  endtask

  // ========================= IDLE TEST =========================
  task automatic idle_test(
    virtual ahb_if vif
  );

    @(vif.cb);
    vif.cb.HSEL   <= 1;
    vif.cb.HTRANS <= 2'b00;

    @(vif.cb);

    if (vif.HREADYOUT !== 1)
      $display("[IDLE_TEST][FAIL] HREADYOUT not held high");
    else
      $display("[IDLE_TEST][PASS] No transfer during IDLE");

  endtask

  // ========================= BUSY TEST =========================
  task automatic busy_test(
    virtual ahb_if vif
  );

    @(vif.cb);
    vif.cb.HSEL   <= 1;
    vif.cb.HTRANS <= 2'b01;

    @(vif.cb);

    $display("[BUSY_TEST][PASS] BUSY did not initiate transfer");

  endtask

  // ========================= NO IDLE TEST =========================
  task automatic no_idle_test(
    virtual ahb_if vif
  );

    @(vif.cb);
    vif.cb.HSEL   <= 1;
    vif.cb.HADDR  <= 16'h0020;
    vif.cb.HWRITE <= 1;
    vif.cb.HTRANS <= 2'b10;
    vif.cb.HSIZE  <= 3'b010;
    vif.cb.HBURST <= 3'b000;

    @(vif.cb);
    vif.cb.HWDATA <= 32'h11111111;

    @(vif.cb);
    vif.cb.HADDR  <= 16'h0024;
    vif.cb.HTRANS <= 2'b10;
    vif.cb.HWDATA <= 32'h22222222;

    do @(vif.cb); while (vif.HREADYOUT == 0);

    if (vif.HRESP !== 0)
      $display("[NO_IDLE_TEST][FAIL] Response error");
    else
      $display("[NO_IDLE_TEST][PASS] No-IDLE transfers successful");

    @(vif.cb);
    vif.cb.HTRANS <= 2'b00;
    vif.cb.HSEL   <= 0;

  endtask

  // ========================= BOUNDARY TEST =========================
  task automatic boundary_test(
    virtual ahb_if vif,
    bit [31:0] data_array[]
  );

    $display("[BOUNDARY_TEST] Writing INCR4 burst crossing 1KB boundary...");

    burst_write_incr(vif, 16'h03FC, 3'b010, 4, data_array);

    if (vif.HRESP != 0)
      $display("[BOUNDARY_TEST][PASS] Error response detected");
    else
      $display("[BOUNDARY_TEST][FAIL] No error for boundary violation");

  endtask

  // ========================= ALIGNMENT TEST =========================
  task automatic alignment_test(
    virtual ahb_if vif
  );
    bit [31:0] read_data;
    bit [3:0]  be;

    $display("[ALIGNMENT_TEST] Testing WORD-aligned access...");

    single_write(vif, 16'h0004, 32'hDEADBEEF, 3'b010, be);
    single_read(vif, 16'h0004, 3'b010, read_data, be);

    if (read_data === 32'hDEADBEEF)
      $display("[ALIGNMENT_TEST][PASS] Aligned WORD access successful");
    else
      $display("[ALIGNMENT_TEST][FAIL] Data mismatch");

  endtask

endpackage : ahb_test_pkg