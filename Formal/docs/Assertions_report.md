| Assertion Name             | Type       | Spec Clause              | Description                                | Expected Result | Actual Result | Notes                  |
| -------------------------- | ---------- | ------------------------ | ------------------------------------------ | --------------- | ------------- | ---------------------- |
| p_reset                    | Protocol   | Reset (Sec 7.1.2)        | Slave outputs must be OKAY during reset    | PASS            | PASS          | Correct reset behavior |
| p_idle_busy_response       | Protocol   | Transfer Types (Sec 3.2) | IDLE/BUSY should get zero wait-state OKAY  | PASS            | PASS          | RAM behaves correctly  |
| p_no_x                     | Protocol   | General                  | No unknown values on outputs               | PASS            | PASS          | No X propagation       |
| p_valid_wait_state_start   | Protocol   | Timing                   | Wait state must follow valid address phase | **FAIL**        | FAIL          |  BUG FOUND in DUT    |
| p_two_cycle_error          | Protocol   | Error Response           | ERROR must last exactly 2 cycles           | PASS            | PASS          | No violation           |
| p_reset_recovery           | Functional | Reset                    | System recovers after reset                | PASS            | PASS          | Stable                 |
| p_transfer_only_when_ready | Protocol   | Basic Transfer           | Transfer only when HREADY=1                | **FAIL**        | FAIL          |  DUT ignores HREADY  |
| p_read_stable_no_write     | Functional | Memory                   | Memory stable without write                | PASS            | PASS          | Correct RAM behavior   |
