`timescale 1ns / 1ps

module tb_top;

  import ahb_test_pkg::*;

  parameter CLOCK_PERIOD = 10;

  reg clk;
  reg rst_n;

  bit [31:0] mem_model [0:1023];

  // =============== SCOREBOARD COUNTERS ===============
  int single_pass = 0, single_fail = 0;
  int burst_incr_pass = 0, burst_incr_fail = 0;
  int burst_wrap_pass = 0, burst_wrap_fail = 0;
  int wait_state_pass = 0, wait_state_fail = 0;
  int idle_pass = 0, idle_fail = 0;
  int busy_pass = 0, busy_fail = 0;
  int no_idle_pass = 0, no_idle_fail = 0;
  int boundary_pass = 0, boundary_fail = 0;
  int alignment_pass = 0, alignment_fail = 0;

  int total_pass = 0;
  int total_fail = 0;

  // =============== TEST CONTROL PARAMETERS ===============
  localparam bit ENABLE_SINGLE_TESTS   = 1;
  localparam bit ENABLE_BURST_INCR     = 1;
  localparam bit ENABLE_BURST_WRAP     = 1;
  localparam bit ENABLE_SPECIAL_TESTS  = 1;
  localparam int SINGLE_TEST_ITERATIONS = 1000;
  localparam int BURST_TEST_ITERATIONS  = 50;
  localparam int SPECIAL_TEST_ITERATIONS = 50;

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

  function automatic bit [31:0] extract_read_data(bit [31:0] read_data, bit [31:0] addr, bit [2:0] size);
    bit [31:0] extracted;
    
    case (size)
      3'b000: extracted = read_data & 32'h000000FF;
      3'b001: extracted = read_data & 32'h0000FFFF;
      3'b010: extracted = read_data;
      default: extracted = 'x;
    endcase
    
    return extracted;
  endfunction

  task automatic check_and_print(
      input string txn_name,
      input bit [31:0] addr,
      input bit [31:0] expected,
      input bit [31:0] actual,
      input bit [2:0] size,
      inout int pass_cnt,
      inout int fail_cnt
  );
    bit [31:0] extracted_actual;
    
    extracted_actual = extract_read_data(actual, addr, size);
    
    if (extracted_actual === expected) begin
      pass_cnt++;
      total_pass++;
      $display("[PASS] Addr: 0x%08h | Exp: 0x%08h | Got: 0x%08h", addr, expected, extracted_actual);
    end else begin
      fail_cnt++;
      total_fail++;
      $display("[FAIL] Addr: 0x%08h | Exp: 0x%08h | Got: 0x%08h", addr, expected, extracted_actual);
    end
  endtask

  task automatic print_report();
    $display("\n");
    $display("================================================================================");
    $display("                     COMPREHENSIVE VERIFICATION REPORT");
    $display("================================================================================");
    $display("Test Category              | PASSED | FAILED | Total | Pass%%");
    $display("--------------------------------------------------------------------------------");
    print_test_line("SINGLE READ/WRITE TESTS", single_pass, single_fail);
    print_test_line("BURST INCR TESTS", burst_incr_pass, burst_incr_fail);
    print_test_line("BURST WRAP TESTS", burst_wrap_pass, burst_wrap_fail);
    print_test_line("WAIT STATE TESTS", wait_state_pass, wait_state_fail);
    print_test_line("IDLE TESTS", idle_pass, idle_fail);
    print_test_line("BUSY TESTS", busy_pass, busy_fail);
    print_test_line("NO-IDLE TESTS", no_idle_pass, no_idle_fail);
    print_test_line("BOUNDARY TESTS", boundary_pass, boundary_fail);
    print_test_line("ALIGNMENT TESTS", alignment_pass, alignment_fail);
    $display("--------------------------------------------------------------------------------");
    print_test_line("TOTAL", total_pass, total_fail);
    $display("================================================================================\n");

    if (total_fail == 0)
      $display("*** ALL TESTS PASSED *** [%0d / %0d]\n", total_pass, total_pass + total_fail);
    else
      $display("*** %0d TESTS FAILED *** [%0d PASSED / %0d TOTAL]\n", total_fail, total_pass, total_pass + total_fail);
  endtask

  task automatic print_test_line(string name, int passed, int failed);
    int total = passed + failed;
    real pass_pct = (total > 0) ? (passed * 100.0) / total : 0;
    $display("%-26s | %6d | %6d | %5d | %5.1f%%", name, passed, failed, total, pass_pct);
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
    bit [31:0] temp_data_q [$];

    @(negedge rst_n);
    @(posedge clk);
    repeat(5) @(posedge clk);

    $display("\n");
    $display("================================================================================");
    $display("            AHB-LITE VERIFICATION TESTBENCH WITH SCOREBOARDING");
    $display("================================================================================\n");

    // =============== SINGLE WRITE/READ TESTS - 1000 ITERATIONS ===============
    if (ENABLE_SINGLE_TESTS) begin
      $display("\n========== TEST SET 1: SINGLE WRITE/READ TESTS (%0d iterations) ==========\n", SINGLE_TEST_ITERATIONS);

      for (int iter = 0; iter < SINGLE_TEST_ITERATIONS; iter++) begin
        bit [2:0] size_sel;
        
        size_sel = $urandom() % 3;
        
        case (size_sel)
          3'b000: addr = {$urandom() % 256, 2'b00};
          3'b001: addr = {$urandom() % 256, 1'b0, 1'b0};
          3'b010: addr = {$urandom() % 256, 2'b00};
          default: addr = 0;
        endcase
        
        data = $urandom();
        
        case (size_sel)
          3'b000: single_write(ahb_bus, addr, data, 3'b000, be);
          3'b001: single_write(ahb_bus, addr, data, 3'b001, be);
          3'b010: single_write(ahb_bus, addr, data, 3'b010, be);
        endcase
        update_memory(addr, data, be);
        
        case (size_sel)
          3'b000: begin
            single_read(ahb_bus, addr, 3'b000, read_data, be);
            exp = get_expected(addr);
            check_and_print("BYTE_READ", addr, exp, read_data, 3'b000, single_pass, single_fail);
          end
          3'b001: begin
            single_read(ahb_bus, addr, 3'b001, read_data, be);
            exp = get_expected(addr);
            check_and_print("HALFWORD_READ", addr, exp, read_data, 3'b001, single_pass, single_fail);
          end
          3'b010: begin
            single_read(ahb_bus, addr, 3'b010, read_data, be);
            exp = get_expected(addr);
            check_and_print("WORD_READ", addr, exp, read_data, 3'b010, single_pass, single_fail);
          end
        endcase
      end

      $display("\n[SINGLE TESTS COMPLETED] Passed: %0d, Failed: %0d\n", single_pass, single_fail);
    end

    // =============== BURST INCR TESTS - 50 ITERATIONS ===============
    if (ENABLE_BURST_INCR) begin
      $display("\n========== TEST SET 2: BURST INCR TESTS (Repeated %0d times) ==========\n", BURST_TEST_ITERATIONS);

      for (int iter = 0; iter < BURST_TEST_ITERATIONS; iter++) begin
        base = 32'h00001000 + (iter * 32'h100);
        write_data_queue.delete();
        burst_write_incr(ahb_bus, base, 3'b010, 4, write_data_queue);
        for (int i = 0; i < write_data_queue.size(); i++)
          update_memory(base + (i*4), write_data_queue[i], 4'b1111);
        
        read_data_queue.delete();
        burst_read_incr(ahb_bus, base, 3'b010, 4, read_data_queue);
        for (int i = 0; i < read_data_queue.size(); i++) begin
          exp = get_expected(base + (i*4));
          check_and_print($sformatf("INCR4_BEAT%0d", i), base + (i*4), exp, 
                         read_data_queue[i], 3'b010, burst_incr_pass, burst_incr_fail);
        end
      end

      $display("\n[BURST INCR TESTS COMPLETED] Passed: %0d, Failed: %0d\n", burst_incr_pass, burst_incr_fail);
    end

    // =============== BURST WRAP TESTS - 50 ITERATIONS ===============
    if (ENABLE_BURST_WRAP) begin
      $display("\n========== TEST SET 3: BURST WRAP TESTS (Repeated %0d times) ==========\n", BURST_TEST_ITERATIONS);

      for (int iter = 0; iter < BURST_TEST_ITERATIONS; iter++) begin
        base = 32'h00002000 + (iter * 32'h100);
        write_data_queue.delete();
        burst_write_wrap(ahb_bus, base, 3'b010, 4, write_data_queue);
        for (int i = 0; i < write_data_queue.size(); i++)
          update_memory(base + (i*4), write_data_queue[i], 4'b1111);
        
        read_data_queue.delete();
        burst_read_wrap(ahb_bus, base, 3'b010, 4, read_data_queue);
        for (int i = 0; i < read_data_queue.size(); i++) begin
          exp = get_expected(base + (i*4));
          check_and_print($sformatf("WRAP4_BEAT%0d", i), base + (i*4), exp,
                         read_data_queue[i], 3'b010, burst_wrap_pass, burst_wrap_fail);
        end
      end

      $display("\n[BURST WRAP TESTS COMPLETED] Passed: %0d, Failed: %0d\n", burst_wrap_pass, burst_wrap_fail);
    end

    // =============== SPECIAL TESTS - 50 ITERATIONS ===============
    if (ENABLE_SPECIAL_TESTS) begin
      $display("\n========== TEST SET 4: SPECIAL TESTS (Repeated %0d times) ==========\n", SPECIAL_TEST_ITERATIONS);

      for (int iter = 0; iter < SPECIAL_TEST_ITERATIONS; iter++) begin
        wait_state_test(ahb_bus);
        if (ahb_bus.HRESP === 0) begin wait_state_pass++; total_pass++; end
        else begin wait_state_fail++; total_fail++; end

        idle_test(ahb_bus);
        if (ahb_bus.HRESP === 0) begin idle_pass++; total_pass++; end
        else begin idle_fail++; total_fail++; end

        busy_test(ahb_bus);
        if (ahb_bus.HRESP === 0) begin busy_pass++; total_pass++; end
        else begin busy_fail++; total_fail++; end

        no_idle_test(ahb_bus);
        if (ahb_bus.HRESP === 0) begin no_idle_pass++; total_pass++; end
        else begin no_idle_fail++; total_fail++; end

        temp_data_q.delete();
        temp_data_q = '{32'h11, 32'h22, 32'h33, 32'h44};
        boundary_test(ahb_bus, temp_data_q);
        if (ahb_bus.HRESP != 0) begin boundary_pass++; total_pass++; end
        else begin boundary_fail++; total_fail++; end

        alignment_test(ahb_bus);
        if (ahb_bus.HRESP === 0) begin alignment_pass++; total_pass++; end
        else begin alignment_fail++; total_fail++; end
      end
    end

    print_report();
    $finish;
  end

endmodule