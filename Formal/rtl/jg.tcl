clear -all

set top ahb3liten
set ROOT "/home/Abid.Hussain/verification/3.AHB-Lite-project"

# 1. Analyze RTL
#analyze -sv09 $ROOT/rtl/mem.sv
analyze -sv09 $ROOT/rtl/design.sv

# 2. Analyze SVA & Bind
analyze -sv09 $ROOT/sva/ahb_checker.sv
analyze -sv09 $ROOT/sva/ahb_assumptions.sv
# Make sure this file exists! If not, create an empty module ahb_cover; endmodule
analyze -sv09 $ROOT/sva/ahb_cover.sv 
analyze -sv09 $ROOT/bind/bind_ahb.sv

# 3. Elaborate 
# Use -bbox_a 16384 to keep the 8192-entry memory intact
elaborate -top $top -bbox_a 16384 -create_related_covers {precondition witness}

# 4. Setup Clock/Reset
clock HCLK
reset !HRESETn

# 5. Prove
prove -all