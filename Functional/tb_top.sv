`timescale 1ns / 1ps

module tb_top;

  import ahb_test_pkg::*;

  parameter CLOCK_PERIOD = 10;

  reg clk;
  reg rst_n;

  bit [31:0] mem_model [0:1023];

  int pass_count = 0;
  int fail_count = 0;
  int total_writes = 0;
  int total_reads = 0;

  //  Verbosity control
  bit VERBOSE = 1;

  localparam int SINGLE_ITERS = 1000;
  localparam int BURST_ITERS  = 50;
  localparam int BURST_LEN    = 18;

  initial begin
    clk = 1'b0;
    forever #(CLOCK_PERIOD/2) clk = ~clk;
  end

  initial begin
    rst_n = 1'b1;
    repeat(2) @(posedge clk);
    rst_n = 1'b0;
    repeat(5) @(posedge clk);
    rst_n = 1'b1;
  end

  ahb_if ahb_bus(clk, rst_n);
  assign ahb_bus.HREADY = rst_n ? ahb_bus.HREADYOUT : 1'b1;

  ahb3liten dut (
    .HCLK(ahb_bus.HCLK),
    .HRESETn(ahb_bus.HRESETn),
    .HSEL(ahb_bus.HSEL),
    .HADDR(ahb_bus.HADDR),
    .HWDATA(ahb_bus.HWDATA),
    .HRDATA(ahb_bus.HRDATA),
    .HWRITE(ahb_bus.HWRITE),
    .HTRANS(ahb_bus.HTRANS),
    .HSIZE(ahb_bus.HSIZE),
    .HBURST(ahb_bus.HBURST),
    .HPROT(ahb_bus.HPROT),
    .HREADYOUT(ahb_bus.HREADYOUT),
    .HRESP(ahb_bus.HRESP),
    .HREADY(ahb_bus.HREADY)
  );

  function automatic void update_memory(bit [31:0] addr, bit [31:0] data, bit [3:0] be);
    bit [9:0] word_addr;
    word_addr = addr[11:2];

    for (int i = 0; i < 4; i++)
      if (be[i]) mem_model[word_addr][i*8+:8] = data[i*8+:8];
  endfunction

  function automatic bit [31:0] get_expected(bit [31:0] addr);
    return mem_model[addr[11:2]];
  endfunction

  //  NEW: Scoreboard check + print
  task automatic check_and_print(
      input string txn_type,
      input bit [31:0] addr,
      input bit [31:0] expected,
      input bit [31:0] actual
  );
      if (actual === expected) begin
          pass_count++;
          if (VERBOSE)
              $display("[%s][PASS] Addr: 0x%08h | Exp: 0x%08h | Got: 0x%08h",
                        txn_type, addr, expected, actual);
      end else begin
          fail_count++;
          $display("[%s][FAIL] Addr: 0x%08h | Exp: 0x%08h | Got: 0x%08h <<< ERROR",
                    txn_type, addr, expected, actual);
      end
  endtask

  task automatic print_report();
    $display("\n");
    $display("====================================");
    $display("    SCOREBOARD FINAL REPORT");
    $display("====================================");
    $display("Total Write Transactions: %0d", total_writes);
    $display("Total Read Transactions:  %0d", total_reads);
    $display("Total Passes: %0d", pass_count);
    $display("Total Fails:  %0d", fail_count);
    $display("====================================\n");

    if (fail_count == 0)
      $display("*** ALL TESTS PASSED ***\n");
    else
      $display("*** %0d TESTS FAILED ***\n", fail_count);
  endtask

  initial begin
    bit [31:0] read_data;
    bit [3:0]  be;
    bit [31:0] write_data_queue [$];
    bit [31:0] read_data_queue [$];

    bit [31:0] addr;
    bit [31:0] data;
    bit [31:0] base;
    bit [31:0] exp;

    @(negedge rst_n);
    @(posedge clk);
    repeat(5) @(posedge clk);

    $display("\n\n");
    $display("========================================");
    $display("   AHB LITE VERIFICATION TESTBENCH");
    $display("========================================\n");

    // ================= SINGLE TESTS =================
    $display("\n========== SINGLE WRITE/READ TESTS (1000) ==========\n");

    for (int i = 0; i < SINGLE_ITERS; i++) begin
      addr = (i % 256) << 2;
      data = $urandom();

      single_write(ahb_bus, addr, data, 3'b010, be);
      update_memory(addr, data, be);
      total_writes++;

      single_read(ahb_bus, addr, 3'b010, read_data, be);

      check_and_print("SINGLE", addr, get_expected(addr), read_data);

      total_reads++;
    end

    // ================= INCR BURSTS =================
    $display("\n========== BURST INCR TESTS (50 runs, len=18) ==========\n");

    for (int t = 0; t < BURST_ITERS; t++) begin
      base = 32'h00001000 + (t * 4 * BURST_LEN);

      write_data_queue.delete();
      burst_write_incr(ahb_bus, base, 3'b010, BURST_LEN, write_data_queue);
      total_writes += BURST_LEN;

      for (int i = 0; i < write_data_queue.size(); i++)
        update_memory(base + (i*4), write_data_queue[i], 4'b1111);

      read_data_queue.delete();
      burst_read_incr(ahb_bus, base, 3'b010, BURST_LEN, read_data_queue);
      total_reads += BURST_LEN;

      for (int i = 0; i < read_data_queue.size(); i++) begin
        exp = get_expected(base + (i*4));
        check_and_print("INCR", base + (i*4), exp, read_data_queue[i]);
      end
    end

    // ================= WRAP BURSTS =================
    $display("\n========== BURST WRAP TESTS (50 runs, len=18) ==========\n");

    for (int t = 0; t < BURST_ITERS; t++) begin
      base = 32'h00002000 + (t * 4 * BURST_LEN);

      write_data_queue.delete();
      burst_write_wrap(ahb_bus, base, 3'b010, BURST_LEN, write_data_queue);
      total_writes += BURST_LEN;

      for (int i = 0; i < write_data_queue.size(); i++)
        update_memory(base + (i*4), write_data_queue[i], 4'b1111);

      read_data_queue.delete();
      burst_read_wrap(ahb_bus, base, 3'b010, BURST_LEN, read_data_queue);
      total_reads += BURST_LEN;

      for (int i = 0; i < read_data_queue.size(); i++) begin
        exp = get_expected(base + (i*4));
        check_and_print("WRAP", base + (i*4), exp, read_data_queue[i]);
      end
    end

    print_report();
    $finish;
  end

endmodule