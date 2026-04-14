/* To compile and run
gcc -O3 -march=native -fno-finite-math-only -frounding-math \
  bench_coremath_expf.c core-math/src/binary32/exp/expf.c \
  -o bench_coremath_expf -lm && ./bench_coremath_expf
*/

#include <stdint.h>
#include <stdio.h>
#include <time.h>

#ifndef N
#define N 1000000
#endif

float cr_expf(float);

static inline uint64_t ns_now(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC_RAW, &ts);
    return (uint64_t)ts.tv_sec * 1000000000ull + (uint64_t)ts.tv_nsec;
}

volatile float sink;

int main(void) {
    static float x[N];
    float sum = 0.0f;

    // Pre-generate inputs so the benchmark is not just one repeated constant.
    // Keep values in a moderate range to avoid overflow/underflow dominating.
    for (int i = 0; i < N; i++) {
        x[i] = -5.0f + 10.0f * ((float)i / (float)N);
    }

    // Warm-up
    for (int i = 0; i < N; i++) {
        sum += cr_expf(x[i]);
    }
    sink = sum;

    sum = 0.0f;
    uint64_t t0 = ns_now();

    for (int r = 0; r < 10; r++) {
        for (int i = 0; i < N; i++) {
            sum += cr_expf(x[i]);
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
    printf("ns / cr_expf     = %.3f\n", ns_per_call);
    printf("cr_expf / second = %.3f\n", evals_per_sec);

    return 0;
}
