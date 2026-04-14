SHELL := /usr/bin/env bash
.RECIPEPREFIX := >

CC ?= gcc
CFLAGS ?= -O3 -march=native

BIN_DIR := build/bin
BUILD_LOG_DIR := build/build_logs
RUN_LOG_DIR := build/run_logs

SOFTFLOAT_DIR := berkeley-softfloat-3
SOFTFLOAT_BUILD_DIR := $(SOFTFLOAT_DIR)/build/Linux-x86_64-GCC
SOFTFLOAT_LIB := $(SOFTFLOAT_BUILD_DIR)/softfloat.a
SOFTFLOAT_INC := -I$(SOFTFLOAT_BUILD_DIR) -I$(SOFTFLOAT_DIR)/source/include

ONEAPI_SETVARS ?= /opt/intel/oneapi/setvars.sh
MKL_CC ?= icx
MKL_CFLAGS ?= -qmkl
MKL_LIBS ?=

BENCHES := bench_exp bench_expq bench_expf bench_expf_mpfr bench_exp_mpfr64 bench_exp_mpfr bench_softfloat32 bench_softfloat64 bench_softfloat128 bench_intelm
BINARIES := $(addprefix $(BIN_DIR)/,$(BENCHES))
RUN_TARGETS := $(addprefix run-,$(BENCHES))

.PHONY: all clean run list help $(RUN_TARGETS)

all: $(BINARIES)

help:
>echo "Targets:"
>echo "  make all      - build every benchmark that can compile on this system"
>echo "  make run      - run all successfully built benchmarks"
>echo "  make list     - show which benchmark binaries are currently available"
>echo "  make clean    - remove build artifacts and generated result files"
>echo ""
>echo "Optional overrides:"
>echo "  CC=clang"
>echo "  CFLAGS='-O2 -march=native'"
>echo "  ONEAPI_SETVARS=/opt/intel/oneapi/setvars.sh"
>echo "  MKL_CC=icx"
>echo "  MKL_CFLAGS='-I/path/to/mkl/include'"
>echo "  MKL_LIBS='-L/path/to/mkl/lib -lmkl_rt -lpthread -lm -ldl'"

list:
>for b in $(BENCHES); do \
>  if [ -x "$(BIN_DIR)/$$b" ]; then \
>    echo "$$b: built"; \
>  else \
>    echo "$$b: unavailable"; \
>  fi; \
>done

clean:
>rm -rf build
>rm -f results.md
>rm -f results.csv

define TRY_BUILD
@mkdir -p "$(BIN_DIR)" "$(BUILD_LOG_DIR)"
@set +e; \
cmd='$(1)'; \
log="$(BUILD_LOG_DIR)/$(2).build.log"; \
echo "[build] $(2)"; \
echo "$$cmd" > "$$log"; \
eval "$$cmd" >> "$$log" 2>&1; \
rc=$$?; \
if [ $$rc -ne 0 ]; then \
  echo "[warn] $(2): compile failed, skipping. See $$log"; \
  rm -f "$(BIN_DIR)/$(2)"; \
else \
  echo "[ok] $(2): $(BIN_DIR)/$(2)"; \
fi; \
exit 0
endef

define TRY_RUN
@mkdir -p "$(RUN_LOG_DIR)"
@set +e; \
bin="$(BIN_DIR)/$(1)"; \
out="$(RUN_LOG_DIR)/$(1).txt"; \
if [ ! -x "$$bin" ]; then \
  echo "[warn] $(1): not built, skipping run"; \
  rm -f "$$out"; \
  exit 0; \
fi; \
echo "[run] $(1)"; \
"$$bin" > "$$out" 2>&1; \
rc=$$?; \
if [ $$rc -ne 0 ]; then \
  echo "[warn] $(1): runtime failure (exit $$rc). See $$out"; \
else \
  echo "[ok] $(1): wrote $$out"; \
fi; \
exit 0
endef

$(BIN_DIR)/bench_exp: bench_exp.c
>$(call TRY_BUILD,$(CC) $(CFLAGS) bench_exp.c -o $(BIN_DIR)/bench_exp -lm,bench_exp)

$(BIN_DIR)/bench_expf: bench_expf.c
>$(call TRY_BUILD,$(CC) $(CFLAGS) bench_expf.c -o $(BIN_DIR)/bench_expf -lm,bench_expf)

$(BIN_DIR)/bench_expq: bench_expq.c
>$(call TRY_BUILD,$(CC) $(CFLAGS) bench_expq.c -o $(BIN_DIR)/bench_expq -lquadmath,bench_expq)

$(BIN_DIR)/bench_exp_mpfr: bench_exp_mpfr.c
>$(call TRY_BUILD,$(CC) $(CFLAGS) bench_exp_mpfr.c -o $(BIN_DIR)/bench_exp_mpfr -lmpfr -lgmp,bench_exp_mpfr)

$(BIN_DIR)/bench_expf_mpfr: bench_expf_mpfr.c
>$(call TRY_BUILD,$(CC) $(CFLAGS) bench_expf_mpfr.c -o $(BIN_DIR)/bench_expf_mpfr -lmpfr -lgmp,bench_expf_mpfr)

$(BIN_DIR)/bench_exp_mpfr64: bench_exp_mpfr64.c
>$(call TRY_BUILD,$(CC) $(CFLAGS) bench_exp_mpfr64.c -o $(BIN_DIR)/bench_exp_mpfr64 -lmpfr -lgmp,bench_exp_mpfr64)

$(BIN_DIR)/bench_softfloat32: bench_softfloat32.c
>$(call TRY_BUILD,$(CC) $(CFLAGS) -std=c11 -DSOFTFLOAT_FAST_INT64 $(SOFTFLOAT_INC) bench_softfloat32.c $(SOFTFLOAT_LIB) -lm -o $(BIN_DIR)/bench_softfloat32,bench_softfloat32)

$(BIN_DIR)/bench_softfloat64: bench_softfloat64.c
>$(call TRY_BUILD,$(CC) $(CFLAGS) -std=c11 -DSOFTFLOAT_FAST_INT64 $(SOFTFLOAT_INC) bench_softfloat64.c $(SOFTFLOAT_LIB) -lm -o $(BIN_DIR)/bench_softfloat64,bench_softfloat64)

$(BIN_DIR)/bench_softfloat128: bench_softfloat128.c
>$(call TRY_BUILD,$(CC) $(CFLAGS) -std=c11 -DSOFTFLOAT_FAST_INT64 $(SOFTFLOAT_INC) bench_softfloat128.c $(SOFTFLOAT_LIB) -lquadmath -o $(BIN_DIR)/bench_softfloat128,bench_softfloat128)

$(BIN_DIR)/bench_intelm: bench_intelm.c
>@mkdir -p "$(BIN_DIR)" "$(BUILD_LOG_DIR)"
>@set +e; \
>log="$(BUILD_LOG_DIR)/bench_intelm.build.log"; \
>echo "[build] bench_intelm"; \
>if [ ! -f "$(ONEAPI_SETVARS)" ]; then \
>  printf '%s\n' "setvars not found: $(ONEAPI_SETVARS)" > "$$log"; \
>  echo "[warn] bench_intelm: $(ONEAPI_SETVARS) not found, skipping. See $$log"; \
>  rm -f "$(BIN_DIR)/bench_intelm"; \
>  exit 0; \
>fi; \
>cmd='source "$(ONEAPI_SETVARS)" >/dev/null 2>&1 && command -v "$(MKL_CC)" >/dev/null 2>&1 && "$(MKL_CC)" $(CFLAGS) $(MKL_CFLAGS) bench_intelm.c -o "$(BIN_DIR)/bench_intelm" $(MKL_LIBS)'; \
>echo "$$cmd" > "$$log"; \
>/usr/bin/env bash -lc "$$cmd" >> "$$log" 2>&1; \
>rc=$$?; \
>if [ $$rc -ne 0 ]; then \
>  echo "[warn] bench_intelm: compile failed, skipping. See $$log"; \
>  rm -f "$(BIN_DIR)/bench_intelm"; \
>else \
>  echo "[ok] bench_intelm: $(BIN_DIR)/bench_intelm"; \
>fi; \
>exit 0

run: all $(RUN_TARGETS)

run-bench_exp:
>$(call TRY_RUN,bench_exp)

run-bench_expf:
>$(call TRY_RUN,bench_expf)

run-bench_expq:
>$(call TRY_RUN,bench_expq)

run-bench_exp_mpfr:
>$(call TRY_RUN,bench_exp_mpfr)

run-bench_expf_mpfr:
>$(call TRY_RUN,bench_expf_mpfr)

run-bench_exp_mpfr64:
>$(call TRY_RUN,bench_exp_mpfr64)

run-bench_softfloat32:
>$(call TRY_RUN,bench_softfloat32)

run-bench_softfloat64:
>$(call TRY_RUN,bench_softfloat64)

run-bench_softfloat128:
>$(call TRY_RUN,bench_softfloat128)

run-bench_intelm:
>@mkdir -p "$(RUN_LOG_DIR)"
>@set +e; \
>bin="$(BIN_DIR)/bench_intelm"; \
>out="$(RUN_LOG_DIR)/bench_intelm.txt"; \
>if [ ! -x "$$bin" ]; then \
>  echo "[warn] bench_intelm: not built, skipping run"; \
>  rm -f "$$out"; \
>  exit 0; \
>fi; \
>if [ ! -f "$(ONEAPI_SETVARS)" ]; then \
>  echo "[warn] bench_intelm: $(ONEAPI_SETVARS) not found, skipping run"; \
>  rm -f "$$out"; \
>  exit 0; \
>fi; \
>echo "[run] bench_intelm"; \
>cmd='source "$(ONEAPI_SETVARS)" >/dev/null 2>&1 && "$(BIN_DIR)/bench_intelm"'; \
>/usr/bin/env bash -lc "$$cmd" > "$$out" 2>&1; \
>rc=$$?; \
>if [ $$rc -ne 0 ]; then \
>  echo "[warn] bench_intelm: runtime failure (exit $$rc). See $$out"; \
>else \
>  echo "[ok] bench_intelm: wrote $$out"; \
>fi; \
>exit 0
