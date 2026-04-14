/*
To compile and run:
nvcc -O3 bench_cuda_exp.cu -o bench_cuda_exp && ./bench_cuda_exp
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

#define CUDA_THREADS 2

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

__global__ static void kernel_exp_limited(const double *x, double *partial, int n) {
    int tid = (int)threadIdx.x;
    double sum = 0.0;

    for (int i = tid; i < n; i += CUDA_THREADS) {
        sum += exp(x[i]);
    }

    partial[tid] = sum;
}

int main(void) {
    int device_count = 0;
    double *h_x = NULL;
    double *h_partial = NULL;
    double *d_x = NULL;
    double *d_partial = NULL;
    double host_sum = 0.0;

    CUDA_CHECK(cudaGetDeviceCount(&device_count));
    if (device_count <= 0) {
        fprintf(stderr, "No CUDA device detected.\n");
        return 1;
    }

    h_x = (double *)malloc(sizeof(double) * (size_t)N);
    h_partial = (double *)malloc(sizeof(double) * (size_t)CUDA_THREADS);
    if (h_x == NULL || h_partial == NULL) {
        fprintf(stderr, "Host allocation failed.\n");
        free(h_x);
        free(h_partial);
        return 1;
    }

    for (int i = 0; i < N; ++i) {
        h_x[i] = -5.0 + 10.0 * ((double)i / (double)N);
    }

    CUDA_CHECK(cudaMalloc((void **)&d_x, sizeof(double) * (size_t)N));
    CUDA_CHECK(cudaMalloc((void **)&d_partial, sizeof(double) * (size_t)CUDA_THREADS));
    CUDA_CHECK(cudaMemcpy(d_x, h_x, sizeof(double) * (size_t)N, cudaMemcpyHostToDevice));

    kernel_exp_limited<<<1, CUDA_THREADS>>>(d_x, d_partial, N);
    CUDA_CHECK(cudaGetLastError());
    CUDA_CHECK(cudaDeviceSynchronize());

    uint64_t t0 = ns_now();
    for (int r = 0; r < REPEATS; ++r) {
        kernel_exp_limited<<<1, CUDA_THREADS>>>(d_x, d_partial, N);
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

        puts("CUDA exp benchmark");
        printf("format           = binary64\n");
        printf("cuda threads     = %d\n", CUDA_THREADS);
        printf("total calls      = %.0f\n", calls);
        printf("total time (ns)  = %llu\n", (unsigned long long)total_ns);
        printf("ns / cuda_exp    = %.3f\n", ns_per_call);
        printf("cuda_exp / second = %.3f\n", evals_per_sec);
    }

    cudaFree(d_partial);
    cudaFree(d_x);
    free(h_partial);
    free(h_x);
    return 0;
}
