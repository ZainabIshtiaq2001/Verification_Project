# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2025.06
# platform  : Linux 3.10.0-1160.119.1.el7.x86_64
# version   : 2025.06p002 64 bits
# build date: 2025.08.26 14:59:20 UTC
# ----------------------------------------
# started   : 2026-05-02 21:51:08 PKT
# hostname  : pc9.(none)
# pid       : 27470
# arguments : '-style' 'windows' '-label' 'session_0' '-console' '//127.0.0.1:44146' '-data' 'AAAAjHicY2RgYLCp////PwMYMD6A0Aw2jAyoAMRnQhUJbEChGRhYUZVrMRQzJDMUMWQyFDCUANn6DGlAVhlDPJCdChQpBfL0gHQyQw5YDwDf9w8z' '-bridge_url' '10.103.77.38:38053' '-proj' '/home/Abid.Hussain/verification/3.AHB-Lite-project/jgproject/sessionLogs/session_0' '-init' '-hidden' '/home/Abid.Hussain/verification/3.AHB-Lite-project/jgproject/.tmp/.initCmds.tcl' 'scripts/fpv_setup.tcl'
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
include scripts/fpv_setup.tcl
include scripts/fpv_setup.tcl
include scripts/fpv_setup.tcl
visualize -violation -property <embedded>::ahb3liten.u_checker._assert_10 -new_window
visualize -violation -property <embedded>::ahb3liten.u_checker._assert_4 -new_window
include scripts/fpv_setup.tcl
include scripts/fpv_setup.tcl
include scripts/fpv_setup.tcl
include scripts/fpv_setup.tcl
include scripts/fpv_setup.tcl
include scripts/fpv_setup.tcl
include scripts/fpv_setup.tcl
visualize -violation -property <embedded>::ahb3liten.u_checker._assert_7 -new_window
include scripts/fpv_setup.tcl
visualize -violation -property <embedded>::ahb3liten.u_checker._assert_7 -new_window
include scripts/fpv_setup.tcl
include scripts/fpv_setup.tcl
visualize -violation -property <embedded>::ahb3liten.u_checker._assert_4 -new_window
visualize -violation -property <embedded>::ahb3liten.u_checker._assert_5 -new_window
include scripts/fpv_setup.tcl
visualize -violation -property <embedded>::ahb3liten.u_checker._assert_5 -new_window
visualize -violation -property <embedded>::ahb3liten.u_checker._assert_5 -new_window
include scripts/fpv_setup.tcl
include scripts/fpv_setup.tcl
visualize -violation -property <embedded>::ahb3liten.u_checker._assert_7 -new_window
visualize -violation -property <embedded>::ahb3liten.u_checker._assert_4 -new_window
include scripts/fpv_setup.tcl
visualize -violation -property <embedded>::ahb3liten.u_checker._assert_5 -new_window
visualize -violation -property <embedded>::ahb3liten.u_checker._assert_5 -new_window
include scripts/fpv_setup.tcl
visualize -violation -property <embedded>::ahb3liten.u_checker._assert_4 -new_window
visualize -violation -property <embedded>::ahb3liten.u_checker._assert_4 -new_window
visualize -violation -property <embedded>::ahb3liten.u_checker._assert_5 -new_window
visualize -violation -property <embedded>::ahb3liten.u_checker._assert_6 -new_window
include scripts/fpv_setup.tcl
visualize -violation -property <embedded>::ahb3liten.u_checker._assert_8 -new_window
include scripts/fpv_setup.tcl
visualize -violation -property <embedded>::ahb3liten.u_checker._assert_9 -new_window
