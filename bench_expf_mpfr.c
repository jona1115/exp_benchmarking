/* To compile and run:
gcc -O3 -march=native bench_expf_mpfr.c -o bench_expf_mpfr -lmpfr -lgmp && ./bench_expf_mpfr
*/

#define _POSIX_C_SOURCE 200809L

#include <mpfr.h>
#include <stdint.h>
#include <stdio.h>
#include <time.h>

#ifndef N
#define N 100000
#endif

#ifndef REPEATS
#define REPEATS 10
#endif

#ifndef PREC_BITS
#define PREC_BITS 24
#endif

static mpfr_t x[N];
volatile float sink;

static inline uint64_t ns_now(void) {
    struct timespec ts;
#ifdef CLOCK_MONOTONIC_RAW
    clock_gettime(CLOCK_MONOTONIC_RAW, &ts);
#else
    clock_gettime(CLOCK_MONOTONIC, &ts);
#endif
    return (uint64_t)ts.tv_sec * 1000000000ull + (uint64_t)ts.tv_nsec;
}

int main(void) {
    mpfr_t y;
    mpfr_t sum;

    mpfr_init2(y, PREC_BITS);
    mpfr_init2(sum, PREC_BITS);

    // Pre-generate inputs so the benchmark is not just one repeated constant.
    // Keep values in a moderate range to avoid overflow/underflow dominating.
    for (int i = 0; i < N; i++) {
        float xi = -5.0f + 10.0f * ((float)i / (float)N);
        mpfr_init2(x[i], PREC_BITS);
        mpfr_set_flt(x[i], xi, MPFR_RNDN);
    }

    // Warm-up
    mpfr_set_ui(sum, 0, MPFR_RNDN);
    for (int i = 0; i < N; i++) {
        mpfr_exp(y, x[i], MPFR_RNDN);
        mpfr_add(sum, sum, y, MPFR_RNDN);
    }
    sink = mpfr_get_flt(sum, MPFR_RNDN);

    mpfr_set_ui(sum, 0, MPFR_RNDN);
    uint64_t t0 = ns_now();

    for (int r = 0; r < REPEATS; r++) {
        for (int i = 0; i < N; i++) {
            mpfr_exp(y, x[i], MPFR_RNDN);
            mpfr_add(sum, sum, y, MPFR_RNDN);
        }
    }

    uint64_t t1 = ns_now();
    sink = mpfr_get_flt(sum, MPFR_RNDN);

    uint64_t total_ns = t1 - t0;
    double calls = (double)REPEATS * (double)N;
    double ns_per_call = (double)total_ns / calls;
    double evals_per_sec = 1e9 / ns_per_call;

    printf("format           = binary32\n");
    printf("precision (bits) = %d\n", PREC_BITS);
    printf("total calls      = %.0f\n", calls);
    printf("total time (ns)  = %llu\n", (unsigned long long)total_ns);
    printf("ns / mpfr_expf   = %.3f\n", ns_per_call);
    printf("mpfr_expf / second= %.3f\n", evals_per_sec);

    for (int i = 0; i < N; i++) {
        mpfr_clear(x[i]);
    }
    mpfr_clear(y);
    mpfr_clear(sum);

    return 0;
}
