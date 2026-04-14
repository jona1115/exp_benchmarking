## System Information

| Item | Value |
|---|---|
| Collected at (UTC) | 2026-04-14 03:52:46 UTC |
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
| `bench_expq` | `binary128` | `expq` | 10000000 | 7503255563 | 750.326 | 1332754.818 | ok | - |
| `bench_expf` | `binary32` | `expf` | 10000000 | 29903933 | 2.990 | 334404173.525 | ok | - |
| `bench_expq` | `binary128` | `expq` | 10000000 | 7503255563 | 750.326 | 1332754.818 | ok | - |
| `bench_expf_mpfr` | `binary32` | `mpfr_expf` | 10000000 | 7530501783 | 753.050 | 1327932.758 | ok | - |
| `bench_exp_mpfr64` | `binary64` | `mpfr_exp64` | 10000000 | 9421820309 | 942.182 | 1061366.028 | ok | - |
| `bench_exp_mpfr` | `binary128` | `mpfr_exp` | 10000000 | 14189402489 | 1418.940 | 704751.311 | ok | - |
| `bench_softfloat32` | `binary32` | `sf_expf` | 10000000 | 1625907433 | 162.591 | 6150411.639 | ok | - |
| `bench_softfloat64` | `binary64` | `sf_exp` | 10000000 | 2010677779 | 201.068 | 4973447.314 | ok | - |
| `bench_softfloat` | `binary128` | `sf_expq` | 10000000 | 5134914310 | 513.491 | 1947452.167 | ok | - |
| `bench_intelm` | `binary64` | `-` | - | - | - | - | parse-warning | could not parse one or more metrics |
