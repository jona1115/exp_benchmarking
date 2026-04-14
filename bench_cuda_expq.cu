/*
To compile and run:
nvcc -O3 bench_cuda_expq.cu -o bench_cuda_expq && ./bench_cuda_expq

CUDA does not provide native IEEE binary128 device arithmetic. This benchmark
uses a double-double input representation and evaluates exp(hi + lo) as:
  exp(hi) * (1 + expm1(lo))
with CUDA libdevice math.
*/

#define _POSIX_C_SOURCE 200809L

#include <cuda_runtime.h>

#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#ifndef N
#define N 1000000
#endif

#ifndef REPEATS
#define REPEATS 10
#endif

#define CUDA_THREADS 1

typedef struct {
    double hi;
    double lo;
} dd128_t;

static volatile double sink;

static inline uint64_t ns_now(void) {
    struct timespec ts;
#ifdef CLOCK_MONOTONIC_RAW
    clock_gettime(CLOCK_MONOTONIC_RAW, &ts);
#else
    clock_gettime(CLOCK_MONOTONIC, &ts);
#endif
    return (uint64_t)ts.tv_sec * 1000000000ull + (uint64_t)ts.tv_nsec;
}

#define CUDA_CHECK(call)                                                        \
    do {                                                                        \
        cudaError_t err__ = (call);                                             \
        if (err__ != cudaSuccess) {                                             \
            fprintf(stderr, "CUDA error at %s:%d: %s\n", __FILE__, __LINE__,    \
                    cudaGetErrorString(err__));                                 \
            return 1;                                                           \
        }                                                                       \
    } while (0)

__device__ static double exp128_dd_approx(dd128_t x) {
    double e_hi = exp(x.hi);
    double corr = 1.0 + expm1(x.lo);
    return e_hi * corr;
}

__global__ static void kernel_exp128_limited(const dd128_t *x, double *partial, int n) {
    int tid = (int)threadIdx.x;
    double sum = 0.0;

    for (int i = tid; i < n; i += CUDA_THREADS) {
        sum += exp128_dd_approx(x[i]);
    }

    partial[tid] = sum;
}

int main(void) {
    int device_count = 0;
    dd128_t *h_x = NULL;
    double *h_partial = NULL;
    dd128_t *d_x = NULL;
    double *d_partial = NULL;
    double host_sum = 0.0;

    CUDA_CHECK(cudaGetDeviceCount(&device_count));
    if (device_count <= 0) {
        fprintf(stderr, "No CUDA device detected.\n");
        return 1;
    }

    h_x = (dd128_t *)malloc(sizeof(dd128_t) * (size_t)N);
    h_partial = (double *)malloc(sizeof(double) * (size_t)CUDA_THREADS);
    if (h_x == NULL || h_partial == NULL) {
        fprintf(stderr, "Host allocation failed.\n");
        free(h_x);
        free(h_partial);
        return 1;
    }

    for (int i = 0; i < N; ++i) {
        long double x = -5.0L + 10.0L * ((long double)i / (long double)N);
        double hi = (double)x;
        double lo = (double)(x - (long double)hi);
        h_x[i].hi = hi;
        h_x[i].lo = lo;
    }

    CUDA_CHECK(cudaMalloc((void **)&d_x, sizeof(dd128_t) * (size_t)N));
    CUDA_CHECK(cudaMalloc((void **)&d_partial, sizeof(double) * (size_t)CUDA_THREADS));
    CUDA_CHECK(cudaMemcpy(d_x, h_x, sizeof(dd128_t) * (size_t)N, cudaMemcpyHostToDevice));

    kernel_exp128_limited<<<1, CUDA_THREADS>>>(d_x, d_partial, N);
    CUDA_CHECK(cudaGetLastError());
    CUDA_CHECK(cudaDeviceSynchronize());

    uint64_t t0 = ns_now();
    for (int r = 0; r < REPEATS; ++r) {
        kernel_exp128_limited<<<1, CUDA_THREADS>>>(d_x, d_partial, N);
    }
    CUDA_CHECK(cudaGetLastError());
    CUDA_CHECK(cudaDeviceSynchronize());
    uint64_t t1 = ns_now();

    CUDA_CHECK(cudaMemcpy(h_partial, d_partial, sizeof(double) * (size_t)CUDA_THREADS,
                          cudaMemcpyDeviceToHost));
    for (int i = 0; i < CUDA_THREADS; ++i) {
        host_sum += h_partial[i];
    }
    sink = host_sum;

    {
        uint64_t total_ns = t1 - t0;
        double calls = (double)REPEATS * (double)N;
        double ns_per_call = (double)total_ns / calls;
        double evals_per_sec = 1e9 / ns_per_call;

        puts("CUDA expq benchmark (binary128 emulation)");
        printf("format           = binary128 (emulated)\n");
        printf("cuda threads     = %d\n", CUDA_THREADS);
        printf("total calls      = %.0f\n", calls);
        printf("total time (ns)  = %llu\n", (unsigned long long)total_ns);
        printf("ns / cuda_exp128dd = %.3f\n", ns_per_call);
        printf("cuda_exp128dd / second = %.3f\n", evals_per_sec);
    }

    cudaFree(d_partial);
    cudaFree(d_x);
    free(h_partial);
    free(h_x);
    return 0;
}
