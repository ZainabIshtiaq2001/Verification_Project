FLIST = flist.f
TOP   = tb_top

.PHONY: all build run clean gui coverage report

# Default target
all: run

# ---------------- BUILD + RUN (combined in xrun) ----------------
run: clean
	xrun -f $(FLIST) \
	     -top $(TOP) \
	     -access +rwc \
	     -coverage all \
	     -covoverwrite \
	     -covtest test_1 \
	     -covworkdir cov_work

# ---------------- GUI MODE ----------------
gui: clean
	xrun -f $(FLIST) \
	     -top $(TOP) \
	     -access +rwc \
	     -coverage all \
	     -gui

# ---------------- COVERAGE REPORT ----------------
report:
	imc -load cov_work/scope/test_1 \
	    -exec "report -summary -out final_report.txt; exit"

# ---------------- CLEAN ----------------
clean:
	rm -rf xrun.* INCA_libs waves.shm cov_work *.log final_report.txt