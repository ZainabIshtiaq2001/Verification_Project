# ==========================================================
# Makefile for AHB-Lite Assertion-Based Verification
# ==========================================================

# File list (you can also use flist if you create one)
FLIST = ./flist.f

# Simulation flags
BASICFLAGS = -access +rwc -sv -disable_sem2009 -clean

# Top testbench (YOU MUST HAVE THIS FILE)
TOP = ../tb/test_top.sv

# RTL + Checker + Bind
DUT = ../packages/ahb3lite_pkg.sv design.sv mem.sv ahb_checker.sv bind_ahb.sv

# ==========================================================
# Default Target
# ==========================================================
all: clean checkall

.PHONY: all clean

# ==========================================================
# Runs
# ==========================================================

nobugs:
	xrun $(DUT) $(TOP) $(BASICFLAGS) -logfile nobugs.log

check1:
	xrun $(DUT) $(TOP) $(BASICFLAGS) -logfile check1.log -define check1

check2:
	xrun $(DUT) $(TOP) $(BASICFLAGS) -logfile check2.log -define check2

check3:
	xrun $(DUT) $(TOP) $(BASICFLAGS) -logfile check3.log -define check3

check4:
	xrun $(DUT) $(TOP) $(BASICFLAGS) -logfile check4.log -define check4

check5:
	xrun $(DUT) $(TOP) $(BASICFLAGS) -logfile check5.log -define check5

check6:
	xrun $(DUT) $(TOP) $(BASICFLAGS) -logfile check6.log -define check6

check7:
	xrun $(DUT) $(TOP) $(BASICFLAGS) -logfile check7.log -define check7

check8:
	xrun $(DUT) $(TOP) $(BASICFLAGS) -logfile check8.log -define check8

checkall:
	xrun $(DUT) $(TOP) $(BASICFLAGS) -logfile checkall.log \
	-define check1 -define check2 -define check3 -define check4 \
	-define check5 -define check6 -define check7 -define check8

# ==========================================================
# Clean
# ==========================================================
clean:
	@-rm -rf xcelium.d
	@-rm -rf *.shm
	@-rm -rf *.log
	@-rm -rf *.history
	@-rm -rf *.key
	@-rm -rf *.vcd
	@-rm -rf .simvision
	@-rm -rf waves.shm
	@-clear
