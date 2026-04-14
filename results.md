## System Information

| Item | Value |
|---|---|
| Collected at (UTC) | 2026-04-14 04:15:42 UTC |
| OS | Ubuntu 22.04.5 LTS |
| Kernel | Linux 6.8.0-94-generic |
| Architecture | x86_64 |
| CPU model | Intel(R) Core(TM) i7-9750H CPU @ 2.60GHz |
| CPU cores (physical / logical) | 6 / 12 |
| Threads per core | 2 |
| GCC | gcc (Ubuntu 11.4.0-1ubuntu1~22.04.3) 11.4.0 (/usr/bin/gcc) |
| libquadmath | 12.3.0-1ubuntu1~22.04.3 (libquadmath0:amd64), SONAME libquadmath.so.0 (/usr/lib/x86_64-linux-gnu/libquadmath.so.0.0.0) |
| MPFR | 4.1.0 |
| GMP | 6.2.1 |
| SoftFloat commit | a0c6494cdc11 |
| Intel MKL | 2025.0.3 (from /opt/intel/oneapi/mkl/2025.3/include/mkl_version.h) |

## Benchmark Results

| Benchmark | Data Type | Function | Total Calls | Total Time (ns) | ns / call | Calls / second | Status | Notes |
|---|---|---|---:|---:|---:|---:|---|---|
| `bench_expq` | `binary128` | `expq` | 10000000 | 7410866746 | 741.087 | 1349369.830 | ok | - |
| `bench_expf` | `binary32` | `expf` | 10000000 | 29381010 | 2.938 | 340355896.547 | ok | - |
| `bench_expq` | `binary128` | `expq` | 10000000 | 7410866746 | 741.087 | 1349369.830 | ok | - |
| `bench_expf_mpfr` | `binary32` | `mpfr_expf` | 10000000 | 7164947382 | 716.495 | 1395683.662 | ok | - |
| `bench_exp_mpfr64` | `binary64` | `mpfr_exp64` | 10000000 | 8836847838 | 883.685 | 1131625.234 | ok | - |
| `bench_exp_mpfr` | `binary128` | `mpfr_exp` | 10000000 | 13917146931 | 1391.715 | 718538.077 | ok | - |
| `bench_softfloat32` | `binary32` | `sf_expf` | 10000000 | 1586270768 | 158.627 | 6304093.981 | ok | - |
| `bench_softfloat64` | `binary64` | `sf_exp` | 10000000 | 2011921521 | 201.192 | 4970372.798 | ok | - |
| `bench_softfloat128` | `binary128` | `sf_expq` | 10000000 | 4873680997 | 487.368 | 2051837.206 | ok | - |
| `bench_intelm` | `binary64` | `-` | - | - | - | - | skipped | source "/opt/intel/oneapi/setvars.sh" >/dev/null 2>&1 && command -v "icx" >/dev/null 2>&1 && "icx" -O3 -march=native -qmkl bench_intelm.c -o "build/bin/bench_intelm"  |
