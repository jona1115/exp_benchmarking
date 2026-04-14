## System Information

| Item | Value |
|---|---|
| Collected at (UTC) | 2026-04-14 18:39:30 UTC |
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
| CUDA toolkit | release 12.8, V12.8.61 (/usr/local/cuda-12.8/bin/nvcc) |
| CUDA driver/GPU | unavailable (NVIDIA-SMI has failed because it couldn't communicate with the NVIDIA driver. Make sure that the latest NVIDIA driver is installed and running.) |

## Benchmark Results

| Benchmark | Data Type | Function | Total Calls | Total Time (ns) | ns / call | Calls / second | Status | Notes |
|---|---|---|---:|---:|---:|---:|---|---|
| `bench_exp` | `binary64` | `exp` | 10000000 | 44981625 | 4.498 | 222313000.031 | ok | - |
| `bench_coremath_exp` | `binary64` | `cr_exp` | 10000000 | 63512940 | 6.351 | 157448230.235 | ok | CORE-MATH: cr_exp from core-math/src/binary64/exp/exp.c |
| `bench_expq` | `binary128` | `expq` | 10000000 | 8138060137 | 813.806 | 1228794.065 | ok | - |
| `bench_coremath_expq` | `binary128` | `cr_expq` | 10000000 | 371595153 | 37.160 | 26911007.636 | ok | CORE-MATH: cr_expq from core-math/src/binary128/exp/expq.c |
| `bench_expf` | `binary32` | `expf` | 10000000 | 28026977 | 2.803 | 356799093.959 | ok | - |
| `bench_coremath_expf` | `binary32` | `cr_expf` | 10000000 | 45289197 | 4.529 | 220803208.324 | ok | CORE-MATH: cr_expf from core-math/src/binary32/exp/expf.c |
| `bench_cuda_expf` | `binary32` | `-` | - | - | - | - | parse-warning | CUDA error at bench_cuda_expf.cu:67: no CUDA-capable device is detected |
| `bench_cuda_exp` | `binary64` | `-` | - | - | - | - | parse-warning | CUDA error at bench_cuda_exp.cu:67: no CUDA-capable device is detected |
| `bench_cuda_expq` | `binary128` | `-` | - | - | - | - | parse-warning | CUDA error at bench_cuda_expq.cu:83: no CUDA-capable device is detected |
| `bench_expf_mpfr` | `binary32` | `mpfr_expf` | 10000000 | 7163417542 | 716.342 | 1395981.728 | ok | - |
| `bench_exp_mpfr64` | `binary64` | `mpfr_exp64` | 10000000 | 9186574992 | 918.657 | 1088544.970 | ok | - |
| `bench_exp_mpfr` | `binary128` | `mpfr_exp` | 10000000 | 13442842818 | 1344.284 | 743890.272 | ok | - |
| `bench_softfloat32` | `binary32` | `sf_expf` | 10000000 | 1393065883 | 139.307 | 7178411.389 | ok | - |
| `bench_softfloat64` | `binary64` | `sf_exp` | 10000000 | 1883921629 | 188.392 | 5308076.433 | ok | - |
| `bench_softfloat128` | `binary128` | `sf_expq` | 10000000 | 4330949878 | 433.095 | 2308962.302 | ok | - |
| `bench_intelm` | `binary64` | `-` | - | - | - | - | skipped | setvars not found: /opt/intel/oneapi/setvars.sh |
