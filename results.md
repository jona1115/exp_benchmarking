## System Information

| Item | Value |
|---|---|
| Collected at (UTC) | 2026-04-14 04:22:04 UTC |
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

| Benchmark | Data Type | Function | Total Calls | Total Time (ns) | ns / call | Calls / second | Status | Notes |
|---|---|---|---:|---:|---:|---:|---|---|
| `bench_expq` | `binary128` | `expq` | 10000000 | 7500997085 | 750.100 | 1333156.097 | ok | - |
| `bench_expf` | `binary32` | `expf` | 10000000 | 30525161 | 3.053 | 327598599.726 | ok | - |
| `bench_expf_mpfr` | `binary32` | `mpfr_expf` | 10000000 | 7533395303 | 753.340 | 1327422.709 | ok | - |
| `bench_exp_mpfr64` | `binary64` | `mpfr_exp64` | 10000000 | 9333742320 | 933.374 | 1071381.623 | ok | - |
| `bench_exp_mpfr` | `binary128` | `mpfr_exp` | 10000000 | 13250769758 | 1325.077 | 754673.138 | ok | - |
| `bench_softfloat32` | `binary32` | `sf_expf` | 10000000 | 1580852215 | 158.085 | 6325701.989 | ok | - |
| `bench_softfloat64` | `binary64` | `sf_exp` | 10000000 | 1951479747 | 195.148 | 5124316.568 | ok | - |
| `bench_softfloat128` | `binary128` | `sf_expq` | 10000000 | 4848782411 | 484.878 | 2062373.427 | ok | - |
| `bench_intelm` | `binary64` | `exp` | 10000000 | 9060483 | 0.906 | 1103693920.070 | ok | - |
