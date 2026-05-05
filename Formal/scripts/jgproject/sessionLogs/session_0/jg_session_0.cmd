# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2025.06
# platform  : Linux 3.10.0-1160.119.1.el7.x86_64
# version   : 2025.06p002 64 bits
# build date: 2025.08.26 14:59:20 UTC
# ----------------------------------------
# started   : 2026-05-01 22:46:55 PKT
# hostname  : pc9.(none)
# pid       : 27644
# arguments : '-style' 'windows' '-label' 'session_0' '-console' '//127.0.0.1:41686' '-data' 'AAAAfHicY2RgYLCp////PwMYMD6A0Aw2jAyoAMRnQhUJbEChGRhYUZVLMaQxFDCUMcQzFDOkMpQwlAJ5ekA6mSEHrAYA9BgL7A==' '-bridge_url' '10.103.77.38:41202' '-proj' '/home/Abid.Hussain/verification/3.AHB-Lite-project/scripts/jgproject/sessionLogs/session_0' '-init' '-hidden' '/home/Abid.Hussain/verification/3.AHB-Lite-project/scripts/jgproject/.tmp/.initCmds.tcl' 'fpv_setup.tcl'
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
