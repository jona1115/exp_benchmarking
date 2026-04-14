## System Information

| Item | Value |
|---|---|
| Collected at (UTC) | 2026-04-14 02:57:36 UTC |
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
| `bench_exp` | `exp` | 10000000 | 51879780 | 5.188 | 192753323.164 | ok | - |
| `bench_expf` | `expf` | 10000000 | 29517371 | 2.952 | 338783559.010 | ok | - |
| `bench_expq` | `expq` | 10000000 | 7436894413 | 743.689 | 1344647.301 | ok | - |
| `bench_exp_mpfr` | `mpfr_exp` | 1000000 | 1378354363 | 1378.354 | 725502.836 | ok | - |
| `bench_softfloat` | `sf_expq` | 50000000 | 25893762061 | 517.875 | 1930966.998 | ok | - |
| `bench_intelm` | `-` | - | - | - | - | skipped | bench_intelm.c:4:10: fatal error: mkl.h: No such file or directory |
