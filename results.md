## System Information

| Item | Value |
|---|---|
| Collected at (UTC) | 2026-04-14 03:08:59 UTC |
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
| `bench_exp` | `exp` | 10000000 | 50845100 | 5.085 | 196675785.867 | ok | - |
| `bench_expf` | `expf` | 10000000 | 30579115 | 3.058 | 327020582.512 | ok | - |
| `bench_expq` | `expq` | 10000000 | 7523749322 | 752.375 | 1329124.559 | ok | - |
| `bench_expf_mpfr` | `mpfr_expf` | 1000000 | 746289671 | 746.290 | 1339962.268 | ok | - |
| `bench_exp_mpfr64` | `mpfr_exp64` | 1000000 | 912871882 | 912.872 | 1095443.972 | ok | - |
| `bench_exp_mpfr` | `mpfr_exp` | 1000000 | 1396234641 | 1396.235 | 716211.997 | ok | - |
| `bench_softfloat` | `sf_expq` | 50000000 | 26134595332 | 522.692 | 1913172.918 | ok | - |
| `bench_intelm` | `exp` | 10000000 | 9700752 | 0.970 | 1030847917.770 | ok | - |
