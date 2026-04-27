# Test Plan

/*
This is the testplan.md required fro PART 1 of the project 

Porject: Verify funtionality and protocol compliance of AHB-Lite RAM
using directed test scenarios

This testplan ensures coverage of:
- All HSIZE values (BYTE, HALFWORD, WORD)
- All HBURST types (SINGLE, INCR4, INCR8, INCR16, WRAP4, WRAP8)
- HTRANS transitions (IDLE, NONSEQ, SEQ)
- Wait-state behavior (HREADYOUT = 0)
- Back-to-back transfers without IDLE

*/
### -------------SECTION 1: SINGLE READ WRITES

##--------------- Test 1: SINGLE WRITE (BYTE)

Inputs:
- HSEL = 1
- HTRANS = NONSEQ
- HWRITE = 1
- HSIZE = BYTE
- HBURST = SINGLE
- HADDR = 0x04 ( ALIGNED TO 1 BYTE, no restrictions)
- HWDATA = 0xAA

Expected:
- Only 1 byte at the address is written
- Other bytes remain unchanged
- HRESP = OKAY
- HREADYOUT = 1 after completion

##-------------- Test 2: SINGLE WRITE (HALFWORD)

Inputs:
- HSEL = 1
- HTRANS = NONSEQ
- HWRITE = 1
- HSIZE = HALFWORD
- HBURST = SINGLE
- HADDR = 0x04,0x06 (LSB = 0, multiples of 2)
- HWDATA = 0xAABB

Expected:
- 2 bytes written at address
- Remaining bytes unchanged
- HRESP = OKAY


##-------------- Test 3: SINGLE WRITE (WORD)

Inputs:
- HSEL = 1
- HTRANS = NONSEQ
- HWRITE = 1
- HSIZE = WORD
- HBURST = SINGLE
- HADDR = 0x04,0x08,0x0C (LSB[1:0] = 00, aligned to 4 bytes or multiples of 4)
- HWDATA = 0xAABBCCDD

Expected:
- Full 32-bit word written
- HRESP = OKAY




##--------------------Test 4: SINGLE READ (BYTE)

Precondition:
- Address 0x04 already written with known value (e.g., 0xAA)

Inputs:
- HSEL = 1
- HTRANS = NONSEQ
- HWRITE = 0
- HSIZE = BYTE
- HBURST = SINGLE
- HADDR = 0x04

Expected:
- HRDATA returns correct byte at address 0x04
- Other bytes ignored
- HRESP = OKAY


##-------------------- Test 5: SINGLE READ (HALFWORD)

Precondition:
- Address 0x06 already written with known value (e.g., 0xAABB)

Inputs:
- HSEL = 1
- HTRANS = NONSEQ
- HWRITE = 0
- HSIZE = HALFWORD
- HBURST = SINGLE
- HADDR = 0x06

Expected:
- HRDATA returns correct 2-byte value
- HRESP = OKAY

## --------------- Test 6: SINGLE READ (WORD)

Precondition:
- Address already written with known value

Inputs:
- HSEL = 1
- HTRANS = NONSEQ
- HWRITE = 0
- HSIZE = WORD
- HBURST = SINGLE
- HADDR = same as written address

Expected:
- HRDATA matches stored value
- HRESP = OKAY


### -------------SECTION 2: INCREMENT READ WRITES

## ---------------Test 7: INCR4 Write + read

Write Phase Inputs:
- HSEL = 1
- HTRANS = NONSEQ → SEQ → SEQ → SEQ
- HWRITE = 1
- HSIZE = WORD //This can be  A BYTE/HALFWORD/WORD
- HBURST = INCR4
- HADDR = 0x10 (aligned to 4 bytes)
- HWDATA = 4 different values (e.g., 0x11, 0x22, 0x33, 0x44)

Expected (Write):
- Data written to 4 consecutive addresses:
  0x10, 0x14, 0x18, 0x1C

Read Phase Inputs:
- HSEL = 1
- HTRANS = NONSEQ → SEQ → SEQ → SEQ
- HWRITE = 0
- HSIZE = WORD
- HBURST = INCR4
- HADDR = 0x10

Expected (Read):
- HRDATA returns values in order:
  0x11, 0x22, 0x33, 0x44
- Addresses increment correctly
- HRESP = OKAY

## --------------Test 8: INCR8 write then read(WORD)

Write Phase Inputs:
- HSEL = 1
- HTRANS = NONSEQ → SEQ → SEQ → SEQ → SEQ → SEQ → SEQ → SEQ
- HWRITE = 1
- HSIZE = WORD //This can be  A BYTE/HALFWORD/WORD
- HBURST = INCR8
- HADDR = 0x20 (aligned to 4 bytes)
- HWDATA = 8 different values (e.g., 0x11, 0x22, ..., 0x88)

Expected (Write):
- Data written to 8 consecutive addresses:
  0x20, 0x24, 0x28, 0x2C, 0x30, 0x34, 0x38, 0x3C

Read Phase Inputs:
- HSEL = 1
- HTRANS = NONSEQ → SEQ → SEQ → SEQ → SEQ → SEQ → SEQ → SEQ
- HWRITE = 0
- HSIZE = WORD
- HBURST = INCR8
- HADDR = 0x20

Expected (Read):
- HRDATA returns values in correct order (8 beats)
- Address increments correctly each cycle
- HRESP = OKAY

## --------------Test 9: INCR16 write then read

Write Phase Inputs:
- HSEL = 1
- HTRANS = NONSEQ → SEQ (repeated for total 16 beats)
- HWRITE = 1
- HSIZE = WORD //This can be  A BYTE/HALFWORD/WORD
- HBURST = INCR16
- HADDR = 0x40 (aligned to 4 bytes)
- HWDATA = 16 different values

Expected (Write):
- Data written to 16 consecutive addresses:
  0x40, 0x44, 0x48, ..., up to 0x7C

Read Phase Inputs:
- HSEL = 1
- HTRANS = NONSEQ → SEQ (16 beats total)
- HWRITE = 0
- HSIZE = WORD
- HBURST = INCR16
- HADDR = 0x40

Expected (Read):
- HRDATA returns all 16 values correctly in sequence
- Address increments properly each beat
- HRESP = OKAY

### ----------- Section 3: WRAPPING (WRAP4 AND WRAP8)

## --------------Test 10: WRAP4 write then read

Write Phase Inputs:
- HSEL = 1
- HTRANS = NONSEQ → SEQ → SEQ → SEQ
- HWRITE = 1
- HSIZE = WORD
- HBURST = WRAP4
- HADDR = 0x0C (chosen to force wrap)
- HWDATA = 4 different values

Expected (Write):
- Address sequence:
  0x0C → 0x10 → 0x14 → wraps → 0x00
- Data written correctly at wrapped addresses

Read Phase:
- Same burst pattern

Expected (Read):
- Data returned correctly in wrapped order
- HRESP = OKAY


## ----------------Test 11: WRAP8 write then reaed
Inputs:
- HBURST = WRAP8
- HSIZE = WORD
- HADDR chosen near boundary

Expected:
- Address increments and wraps within 32-byte boundary
- All data written and read correctly


### ----------------Section 4: WAIT STATE (HREADY = 0) from the SLAVE/subordinate

## ----------------Test 12: Wait state

Inputs:
- HSEL = 1
- HTRANS = NONSEQ
- HWRITE = 1 (can also test read later)
- HSIZE = WORD
- HBURST = SINGLE
- HADDR = 0x10
- HWDATA = 0xAABBCCDD

Condition:
- During the transfer, slave drives HREADYOUT = 0 for at least one cycle

Expected:
- While HREADYOUT = 0:
  - HADDR remains constant
  - HTRANS remains unchanged
  - HWRITE, HSIZE, HBURST remain unchanged
- Transfer completes only when HREADYOUT returns to 1
- Data is written correctly after wait
- HRESP = OKAY

## ----------------Test 13: HTRANS = IDLE, to ensure no trasnfer occurs durng IDLE state

Inputs:
- HSEL = 1
- HTRANS = IDLE

Expected:
- No read or write occurs
- Memory unchanged

## ----------------Test 14: HTRANS = BUSY, verified BUSY does not initiate transfer

Inputs:
- HSEL = 1
- HTRANS = BUSY

Expected:
- No data transfer occurs
- Address/control signals held

### ---------------Section 5: No idle and consecutive transfering

## ----------------Test 15: No idle when consecutive trasnfer
Inputs:
- First transfer:
  - HSEL = 1
  - HTRANS = NONSEQ
  - HWRITE = 1
  - HSIZE = WORD
  - HBURST = SINGLE
  - HADDR = 0x20
  - HWDATA = 0x11111111

- Immediately followed by second transfer (next cycle):
  - HTRANS = NONSEQ (no IDLE in between)
  - HWRITE = 1
  - HADDR = 0x24
  - HWDATA = 0x22222222

Expected:
- No IDLE cycle between transfers
- Both writes complete successfully
- Data written correctly to both addresses
- HRESP = OKAY for both transfers
- Pipeline operates without interruption


### ---------------Section 6: boundary checks

## ------------------Test 15: 1KB boundary check (INCR burst)

Inputs:
- HBURST = INCR4
- HSIZE = WORD
- HADDR near 1KB boundary (e.g., 0x3FC)

Expected:
- Transfer does not cross 1KB boundary
- Proper behavior maintained

## ----------------Test 16: Address allignment test, to check behaviour
Inputs:
- HSIZE = WORD
- HADDR = 0x04 (aligned)

Expected:
- Transfer succeeds normally

Note:
- Misaligned addresses are not tested as they are illegal
