## System Information

| Item | Value |
|---|---|
| Collected at (UTC) | 2026-04-14 03:35:46 UTC |
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
| `bench_exp` | `binary64` | `exp` | 10000000 | 49389426 | 4.939 | 202472488.747 | ok | - |
| `bench_expf` | `binary32` | `expf` | 10000000 | 30521464 | 3.052 | 327638281.047 | ok | - |
| `bench_expq` | `binary128` | `expq` | 10000000 | 7466364539 | 746.636 | 1339339.909 | ok | - |
| `bench_expf_mpfr` | `binary32` | `mpfr_expf` | 10000000 | 7703947834 | 770.395 | 1298035.788 | ok | - |
| `bench_exp_mpfr64` | `binary64` | `mpfr_exp64` | 10000000 | 9755381851 | 975.538 | 1025075.200 | ok | - |
| `bench_exp_mpfr` | `binary128` | `mpfr_exp` | 10000000 | 13726895850 | 1372.690 | 728496.822 | ok | - |
| `bench_softfloat32` | `binary32` | `sf_expf` | 10000000 | 1591050648 | 159.105 | 6285155.041 | ok | - |
| `bench_softfloat64` | `binary64` | `sf_exp` | 10000000 | 2040843237 | 204.084 | 4899935.389 | ok | - |
| `bench_softfloat` | `binary128` | `sf_expq` | 10000000 | 5145119615 | 514.512 | 1943589.411 | ok | - |
| `bench_intelm` | `binary64` | `exp` | 10000000 | 9168021 | 0.917 | 1090747937.859 | ok | - |
