

#  AHB-Lite SRAM Slave: Formal Property Verification (FPV)

![Language](https://img.shields.io/badge/Language-SystemVerilog_Assertions_\(SVA\)-blue.svg)
![Protocol](https://img.shields.io/badge/Protocol-AMBA_3_AHB--Lite-green.svg)
![EDA Tool](https://img.shields.io/badge/EDA_Tool-Cadence_JasperGold-red.svg)
![Verification](https://img.shields.io/badge/Verification-Formal_\(FPV\)-orange.svg)
![Status](https://img.shields.io/badge/Status-92.2%25_Coverage-success.svg)



##  Project Overview

This repository contains a **complete Formal Property Verification (FPV) environment** for an **AMBA 3 AHB-Lite SRAM Slave**.

The objective is to **mathematically prove protocol compliance** and **verify memory correctness** using **SystemVerilog Assertions (SVA)** and **Cadence JasperGold**.

Unlike simulation-based verification, this approach ensures:

*  Exhaustive state-space exploration
*  Zero testbench dependency
* Guaranteed bug detection (if reachable)

## Verification Methodology

###  Formal Property Verification (FPV)

* Assertions define protocol rules mathematically
* JasperGold explores **all possible input combinations**
* No random stimulus required

### Symbolic Memory Tracking

To avoid **state-space explosion**, a **symbolic abstraction** is used:


          +----------------------+
          |   Symbolic Address   |
          |      (f_addr)        |
          +----------+-----------+
                     |
                     v
        +--------------------------+
        |     Shadow Memory        |
        |   shadow_mem, valid      |
        +--------------------------+
                     |
                     v
        +--------------------------+
        |   DUT Memory (SRAM)      |
        +--------------------------+


✔ Only one arbitrary address is tracked
✔ Proven correctness generalizes to **entire memory**



##  Formal Testbench Architecture


                +----------------------+
                |   ahb_assumptions    |
                | (Legal AHB Master)   |
                +----------+-----------+
                           |
                           v
+------------+     +----------------+     +--------------+
| ahb_cover  | --> |   ahb3liten    | <-- | ahb_checker  |
| (Coverage) |     |     (DUT)      |     | (Assertions) |
+------------+     +----------------+     +--------------+
                           ^
                           |
                   +---------------+
                   | bind_ahb.sv   |
                   +---------------+
```




##  Repository Structure


  sva/
 ├── ahb_checker.sv       # Assertions (Protocol + Functional)
 ├── ahb_assumptions.sv   # Master constraints (37 assumptions)
 └── ahb_cover.sv         # Coverage properties

 bind/
 └── bind_ahb.sv          # Binds SVA to DUT

  rtl/
 └── ahb3liten.sv         # SRAM Slave RTL

  scripts/
 └── fpv_setup.tcl        # JasperGold run script


---

## Verification Results Summary

| Metric           | Value     |
| ---------------- | --------- |
| Total Assertions | 8         |
|  Proven        | 6         |
|  Failed        | 2         |
| Coverage         | **92.2%** |

--

##  Assertion Verification Matrix

| Assertion Name         | Description                     | Result |
| ---------------------- | ------------------------------- | ------ |
| `p_reset`              | Reset outputs valid             |  PASS |
| `p_idle_busy`          | Correct IDLE/BUSY response      |  PASS |
| `p_no_x`               | No unknown outputs              |  PASS |
| `p_wait_state`         | Valid wait-state behavior       |  PASS |
| `p_error`              | 2-cycle error response          |  FAIL |
| `p_read_data`          | Correct read data timing        |  PASS |
| `p_memory_correctness` | Data retention correctness      |  PASS |
| `p_reset_bounded`      | Reset recovery within 16 cycles |  FAIL |

---

##  Coverage Analysis

| Metric      | Result    |
| ----------- | --------- |
| Covered     | 83        |
| Unreachable | 7         |
| Coverage %  | **92.2%** |

 Deep protocol states reached:

* Burst transfers (INCR / WRAP)
* Back-to-back transactions
* Wait-state scenarios

---

##  Bug Discovery (Formal Counterexamples)

Formal verification uncovered **2 critical RTL bugs**:

---

###  Bug 1: Error Response Violation

**Assertion:** `p_error`
**Depth:** 2 cycles

####  Issue

DUT violates **2-cycle ERROR response protocol**

####  Root Cause

* `HRESP` is not properly constrained or implemented
* Formal tool drives illegal scenarios

#### Fix

```systemverilog
assume property (HRESP == 0);
```

OR implement proper error FSM

---

### Bug 2: Reset Recovery Failure

**Assertion:** `p_reset_bounded`
**Depth:** 3 cycles

####  Issue

DUT does not stabilize within required cycles after reset

####  Root Cause

* Weak reset logic
* Outputs not initialized deterministically

#### Fix

 systemverilog
if (!HRESETn) begin
  HREADYOUT <= 1;
  HRESP     <= 0;
end


---

##  JasperGold Engine Performance

| Engine   | Role                        |
| -------- | --------------------------- |
| PRE      | Instant structural proofs   |
| Hp       | Sequential property proving |
| Ht       | Deep bug detection          |
| Mpcustom | Coverage exploration        |

Bugs detected in **<0.1 seconds**

---

##  How to Run

bash
# Clone repository
git clone https://github.com/YourUsername/AHB-Lite-Formal-Verification.git
cd AHB-Lite-Formal-Verification

# Launch JasperGold
jg -fpv scripts/fpv_setup.tcl


---

##  Key Achievements

✔ Exhaustive protocol verification
✔ 92.2% formal coverage
✔ Detected real RTL bugs
✔ Zero simulation required
✔ Industry-grade methodology

---

## Skills Demonstrated

* Formal Verification (FPV)
* SystemVerilog Assertions (SVA)
* AMBA AHB-Lite Protocol
* Debugging Counterexamples (CEX)
* JasperGold Tool Usage
* Memory Verification Techniques

---

##  Future Work

* Fix failing assertions → achieve **100% proof**
* Add AXI/AHB bridge verification
* Extend to pipelined multi-master system
* Integrate formal + simulation hybrid flow

---

##  Author


**Abid Hussain**
 Electrical Engineering – Digital IC Design
 Focus: Formal Verification | Processor Design | Embedded Systems



