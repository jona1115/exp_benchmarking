## System Information

| Item | Value |
|---|---|
| Collected at (UTC) | 2026-04-14 04:27:19 UTC |
| OS | Ubuntu 22.04.5 LTS |
| Kernel | Linux 5.15.0-171-generic |
| Architecture | x86_64 |
| CPU model | Intel(R) Xeon(R) Gold 6354 CPU @ 3.00GHz |
| CPU cores (physical / logical) | 4 / 4 |
| Threads per core | 1 |
| GCC | gcc (Ubuntu 11.4.0-1ubuntu1~22.04.3) 11.4.0 (/usr/bin/gcc) |
| libquadmath | 12.3.0-1ubuntu1~22.04.3 (libquadmath0:amd64), SONAME libquadmath.so.0 (/usr/lib/x86_64-linux-gnu/libquadmath.so.0.0.0) |
| MPFR | 4.1.0 |
| GMP | 6.2.1 |
| SoftFloat commit | a0c6494cdc11 |
| Intel MKL | not detected |

## Benchmark Results

| Benchmark | Data Type | Function | Total Calls | Total Time (ns) | ns / call | Calls / second | Status | Notes |
|---|---|---|---:|---:|---:|---:|---|---|
| `bench_exp` | `binary64` | `exp` | 10000000 | 45758076 | 4.576 | 218540657.173 | ok | - |
| `bench_expq` | `binary128` | `expq` | 10000000 | 8113075415 | 811.308 | 1232578.213 | ok | - |
| `bench_expf` | `binary32` | `expf` | 10000000 | 27814616 | 2.781 | 359523208.949 | ok | - |
| `bench_expf_mpfr` | `binary32` | `mpfr_expf` | 10000000 | 6756462875 | 675.646 | 1480064.375 | ok | - |
| `bench_exp_mpfr64` | `binary64` | `mpfr_exp64` | 10000000 | 8702405367 | 870.241 | 1149107.583 | ok | - |
| `bench_exp_mpfr` | `binary128` | `mpfr_exp` | 10000000 | 12915782733 | 1291.578 | 774246.533 | ok | - |
| `bench_softfloat32` | `binary32` | `sf_expf` | 10000000 | 1387772240 | 138.777 | 7205793.366 | ok | - |
| `bench_softfloat64` | `binary64` | `sf_exp` | 10000000 | 1884164632 | 188.416 | 5307391.844 | ok | - |
| `bench_softfloat128` | `binary128` | `sf_expq` | 10000000 | 4325291925 | 432.529 | 2311982.676 | ok | - |
| `bench_intelm` | `binary64` | `-` | - | - | - | - | skipped | setvars not found: /opt/intel/oneapi/setvars.sh |
