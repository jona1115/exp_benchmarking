#include <stdio.h>
#include <stdint.h>
#include <time.h>
#include <mkl.h>

#ifndef N
#define N 1000000
#endif

static inline uint64_t ns_now(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC_RAW, &ts);
    return (uint64_t)ts.tv_sec * 1000000000ull + (uint64_t)ts.tv_nsec;
}

volatile double sink;

int main(void) {
    static double x[N], y[N];
    double sum = 0.0;

    for (int i = 0; i < N; i++) {
        x[i] = -5.0 + 10.0 * ((double)i / (double)N);
    }

    for (int i = 0; i < N; i++) {
        vdExp(1, &x[i], &y[i]);   // warm-up, scalar-ish use
        sum += y[i];
    }
    sink = sum;

    sum = 0.0;
    uint64_t t0 = ns_now();

    for (int r = 0; r < 10; r++) {
        vdExp(N, x, y);           // vector MKL call
        for (int i = 0; i < N; i++) {
            sum += y[i];
        }
    }

    uint64_t t1 = ns_now();
    sink = sum;

    uint64_t total_ns = t1 - t0;
    double calls = 10.0 * (double)N;
    double ns_per_call = (double)total_ns / calls;
    double evals_per_sec = 1e9 / ns_per_call;

    printf("total calls      = %.0f\n", calls);
    printf("total time (ns)  = %llu\n", (unsigned long long)total_ns);
    printf("ns / exp         = %.3f\n", ns_per_call);
    printf("exp / second     = %.3f\n", evals_per_sec);

    return 0;
}