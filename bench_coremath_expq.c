/* To compile and run
gcc -O3 -march=native -fno-finite-math-only -frounding-math \
  bench_coremath_expq.c core-math/src/binary128/exp/expq.c \
  -o bench_coremath_expq -lquadmath -lm && ./bench_coremath_expq
*/

#include <stdint.h>
#include <stdio.h>
#include <time.h>
#include <quadmath.h>

#ifndef N
#define N 1000000
#endif

__float128 cr_expq(__float128);

static inline uint64_t ns_now(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC_RAW, &ts);
    return (uint64_t)ts.tv_sec * 1000000000ull + (uint64_t)ts.tv_nsec;
}

volatile __float128 sink;

int main(void) {
    static __float128 x[N];
    __float128 sum = 0.0Q;

    // Pre-generate inputs so the benchmark is not just one repeated constant.
    // Keep values in a moderate range to avoid overflow/underflow dominating.
    for (int i = 0; i < N; i++) {
        x[i] = -5.0Q + 10.0Q * ((__float128)i / (__float128)N);
    }

    // Warm-up
    for (int i = 0; i < N; i++) {
        sum += cr_expq(x[i]);
    }
    sink = sum;

    sum = 0.0Q;
    uint64_t t0 = ns_now();

    for (int r = 0; r < 10; r++) {
        for (int i = 0; i < N; i++) {
            sum += cr_expq(x[i]);
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
    printf("ns / cr_expq     = %.3f\n", ns_per_call);
    printf("cr_expq / second = %.3f\n", evals_per_sec);

    return 0;
}
