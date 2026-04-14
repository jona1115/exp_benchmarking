## System Information

| Item | Value |
|---|---|
| Collected at (UTC) | 2026-04-14 05:04:50 UTC |
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
| CUDA toolkit | release 11.5, V11.5.119 (/usr/bin/nvcc) |
| CUDA driver/GPU | driver 580.126.09, CUDA runtime 13.0, GPUs 1 (first: NVIDIA GeForce RTX 2070 with Max-Q Design) |

## Benchmark Results

| Benchmark | Data Type | Function | Total Calls | Total Time (ns) | ns / call | Calls / second | Status | Notes |
|---|---|---|---:|---:|---:|---:|---|---|
| `bench_exp` | `binary64` | `exp` | 10000000 | 53052603 | 5.305 | 188492165.031 | ok | - |
| `bench_expq` | `binary128` | `expq` | 10000000 | 7514443842 | 751.444 | 1330770.475 | ok | - |
| `bench_expf` | `binary32` | `expf` | 10000000 | 30310254 | 3.031 | 329921352.688 | ok | - |
| `bench_cuda_expf` | `binary32` | `cuda_expf` | 10000000 | 81466608 | 8.147 | 122749679.231 | ok | CUDA launch: 1 block x 4 threads |
| `bench_cuda_exp` | `binary64` | `cuda_exp` | 10000000 | 1579107782 | 157.911 | 6332689.962 | ok | CUDA launch: 1 block x 2 threads |
| `bench_cuda_expq` | `binary128` | `cuda_exp128dd` | 10000000 | 10499464417 | 1049.946 | 952429.534 | ok | CUDA launch: 1 block x 1 thread; binary128 emulated with double-double |
| `bench_expf_mpfr` | `binary32` | `mpfr_expf` | 10000000 | 8108890693 | 810.889 | 1233214.305 | ok | - |
| `bench_exp_mpfr64` | `binary64` | `mpfr_exp64` | 10000000 | 10389379324 | 1038.938 | 962521.407 | ok | - |
| `bench_exp_mpfr` | `binary128` | `mpfr_exp` | 10000000 | 14781357451 | 1478.136 | 676527.852 | ok | - |
| `bench_softfloat32` | `binary32` | `sf_expf` | 10000000 | 1684656351 | 168.466 | 5935928.710 | ok | - |
| `bench_softfloat64` | `binary64` | `sf_exp` | 10000000 | 2105843380 | 210.584 | 4748691.235 | ok | - |
| `bench_softfloat128` | `binary128` | `sf_expq` | 10000000 | 5253277253 | 525.328 | 1903573.621 | ok | - |
| `bench_intelm` | `binary64` | `-` | - | - | - | - | parse-warning | runtime failed or metrics missing |
