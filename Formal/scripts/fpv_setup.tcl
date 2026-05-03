# =========================================================
# AHB-Lite SRAM Formal Verification Setup
# Role B - EE5214
# =========================================================

clear -all

set ROOT [pwd]

set top ahb3liten

# -----------------------------
# STEP 1: PACKAGE FIRST (VERY IMPORTANT)
# -----------------------------
analyze -sv09 $ROOT/packages/ahb3lite_pkg.sv

# -----------------------------
# STEP 2: RTL
# -----------------------------
analyze -sv09 $ROOT/rtl/mem.sv
analyze -sv09 $ROOT/rtl/design.sv

# -----------------------------
# STEP 3: SVA
# -----------------------------
analyze -sv09 $ROOT/sva/ahb_checker.sv
analyze -sv09 $ROOT/sva/ahb_assumptions.sv
#analyze -sv09 $ROOT/sva/ahb_cover.sv

# -----------------------------
# STEP 4: BIND
# -----------------------------
analyze -sv09 $ROOT/bind/bind_ahb.sv

# -----------------------------
# ELABORATE
# -----------------------------
elaborate -top $top -create_related_covers {precondition witness}

# -----------------------------
# CLOCK / RESET
# -----------------------------
clock HCLK
reset !HRESETn

# -----------------------------
# PROVE
# -----------------------------
prove -all