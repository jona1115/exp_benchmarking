## System Information

| Item | Value |
|---|---|
| Collected at (UTC) | 2026-04-14 03:02:48 UTC |
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
| Intel MKL | 2025.0.3 (from /opt/intel/oneapi/mkl/latest/include/mkl_version.h) |

## Benchmark Results

| Benchmark | Function | Total Calls | Total Time (ns) | ns / call | Calls / second | Status | Notes |
|---|---|---:|---:|---:|---:|---|---|
| `bench_exp` | `exp` | 10000000 | 50609188 | 5.061 | 197592579.434 | ok | - |
| `bench_expf` | `expf` | 10000000 | 29249800 | 2.925 | 341882679.540 | ok | - |
| `bench_expq` | `expq` | 10000000 | 7473299592 | 747.330 | 1338097.032 | ok | - |
| `bench_exp_mpfr` | `mpfr_exp` | 1000000 | 1397893018 | 1397.893 | 715362.325 | ok | - |
| `bench_softfloat` | `sf_expq` | 50000000 | 25696722902 | 513.934 | 1945773.404 | ok | - |
| `bench_intelm` | `exp` | 10000000 | 8922550 | 0.892 | 1120755837.737 | ok | - |
