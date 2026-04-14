/* To compile and run:
gcc -O3 -march=native -std=c11 -DSOFTFLOAT_FAST_INT64 \
  -I./berkeley-softfloat-3/build/Linux-x86_64-GCC \
  -I./berkeley-softfloat-3/source/include \
  bench_softfloat64.c ./berkeley-softfloat-3/build/Linux-x86_64-GCC/softfloat.a \
  -lm -o bench_softfloat64 && ./bench_softfloat64
*/

#define _POSIX_C_SOURCE 200809L

#include <math.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

#include "./berkeley-softfloat-3/build/Linux-x86_64-GCC/platform.h"
#include "./berkeley-softfloat-3/source/include/softfloat.h"

#ifndef N
#define N 1000000
#endif

#ifndef REPEATS
#define REPEATS 10
#endif

static float64_t sf_inputs[N];
static volatile float64_t sink;

static float64_t sf_zero;
static float64_t sf_one;
static float64_t sf_himark;
static float64_t sf_lomark;
static float64_t sf_inv_ln2;
static float64_t sf_ln2;
static float64_t sf_c1;
static float64_t sf_c2;
static float64_t sf_c3;
static float64_t sf_c4;
static float64_t sf_c5;
static float64_t sf_c6;
static float64_t sf_c7;
static float64_t sf_c8;
static float64_t sf_c9;
static float64_t sf_c10;

static inline uint64_t ns_now(void) {
    struct timespec ts;
#ifdef CLOCK_MONOTONIC_RAW
    clock_gettime(CLOCK_MONOTONIC_RAW, &ts);
#else
    clock_gettime(CLOCK_MONOTONIC, &ts);
#endif
    return (uint64_t)ts.tv_sec * 1000000000ull + (uint64_t)ts.tv_nsec;
}

static float64_t native_to_sf64(double x) {
    float64_t y;
    memcpy(&y.v, &x, sizeof(x));
    return y;
}

static double sf64_to_native(float64_t x) {
    double y;
    memcpy(&y, &x.v, sizeof(y));
    return y;
}

static bool f64_is_nan_soft(float64_t x) {
    uint64_t exp = (x.v >> 52) & 0x7FFu;
    uint64_t frac = x.v & UINT64_C(0x000FFFFFFFFFFFFF);
    return exp == 0x7FFu && frac != 0;
}

static bool f64_is_inf_soft(float64_t x) {
    uint64_t exp = (x.v >> 52) & 0x7FFu;
    uint64_t frac = x.v & UINT64_C(0x000FFFFFFFFFFFFF);
    return exp == 0x7FFu && frac == 0;
}

static bool f64_signbit_soft(float64_t x) {
    return (x.v >> 63) != 0;
}

static float64_t sf64_scalbn_exact(float64_t x, int k) {
    uint64_t bits = x.v;
    int exp = (int)((bits >> 52) & 0x7FFu);
    int new_exp;

    if (k == 0) return x;
    if (exp == 0 || exp == 0x7FF) {
        return native_to_sf64(scalbn(sf64_to_native(x), k));
    }

    new_exp = exp + k;
    if (new_exp <= 0 || new_exp >= 0x7FF) {
        return native_to_sf64(scalbn(sf64_to_native(x), k));
    }

    bits = (bits & UINT64_C(0x800FFFFFFFFFFFFF)) | ((uint64_t)new_exp << 52);
    x.v = bits;
    return x;
}

static void init_constants(void) {
    sf_zero = native_to_sf64(0.0);
    sf_one = native_to_sf64(1.0);
    sf_himark = native_to_sf64(709.782712893384);
    sf_lomark = native_to_sf64(-745.133219101941);
    sf_inv_ln2 = native_to_sf64(1.44269504088896340735992468100189214);
    sf_ln2 = native_to_sf64(0.693147180559945309417232121458176568);

    sf_c1 = native_to_sf64(1.0);
    sf_c2 = native_to_sf64(1.0 / 2.0);
    sf_c3 = native_to_sf64(1.0 / 6.0);
    sf_c4 = native_to_sf64(1.0 / 24.0);
    sf_c5 = native_to_sf64(1.0 / 120.0);
    sf_c6 = native_to_sf64(1.0 / 720.0);
    sf_c7 = native_to_sf64(1.0 / 5040.0);
    sf_c8 = native_to_sf64(1.0 / 40320.0);
    sf_c9 = native_to_sf64(1.0 / 362880.0);
    sf_c10 = native_to_sf64(1.0 / 3628800.0);
}

static float64_t sf_exp_soft(float64_t x) {
    int_fast32_t n_i;
    float64_t n;
    float64_t r;
    float64_t poly;
    float64_t y;

    if (f64_is_nan_soft(x)) return x;
    if (f64_is_inf_soft(x)) return f64_signbit_soft(x) ? sf_zero : x;
    if (f64_lt(sf_himark, x)) return native_to_sf64(INFINITY);
    if (f64_lt(x, sf_lomark)) return sf_zero;

    n_i = f64_to_i32(f64_mul(x, sf_inv_ln2), softfloat_round_near_even, false);
    n = i32_to_f64((int32_t)n_i);
    r = f64_sub(x, f64_mul(n, sf_ln2));

    poly = sf_c10;
    poly = f64_add(sf_c9, f64_mul(r, poly));
    poly = f64_add(sf_c8, f64_mul(r, poly));
    poly = f64_add(sf_c7, f64_mul(r, poly));
    poly = f64_add(sf_c6, f64_mul(r, poly));
    poly = f64_add(sf_c5, f64_mul(r, poly));
    poly = f64_add(sf_c4, f64_mul(r, poly));
    poly = f64_add(sf_c3, f64_mul(r, poly));
    poly = f64_add(sf_c2, f64_mul(r, poly));
    poly = f64_add(sf_c1, f64_mul(r, poly));
    y = f64_add(sf_one, f64_mul(r, poly));

    return sf64_scalbn_exact(y, (int)n_i);
}

static void init_inputs(void) {
    for (int i = 0; i < N; ++i) {
        double x = -5.0 + 10.0 * ((double)i / (double)N);
        sf_inputs[i] = native_to_sf64(x);
    }
}

int main(void) {
    float64_t sum = sf_zero;

    init_constants();
    init_inputs();

    softfloat_roundingMode = softfloat_round_near_even;
    softfloat_detectTininess = softfloat_tininess_afterRounding;

    for (int i = 0; i < N; ++i) {
        sum = f64_add(sum, sf_exp_soft(sf_inputs[i]));
    }
    sink = sum;

    sum = sf_zero;
    uint64_t t0 = ns_now();

    for (int r = 0; r < REPEATS; ++r) {
        for (int i = 0; i < N; ++i) {
            sum = f64_add(sum, sf_exp_soft(sf_inputs[i]));
        }
    }

    uint64_t t1 = ns_now();
    sink = sum;

    uint64_t total_ns = t1 - t0;
    double calls = (double)REPEATS * (double)N;
    double ns_per_call = (double)total_ns / calls;
    double evals_per_sec = 1e9 / ns_per_call;

    puts("SoftFloat exp benchmark");
    printf("format           = binary64\n");
    printf("N                = %d\n", N);
    printf("repeats          = %d\n", REPEATS);
    printf("total calls      = %.0f\n", calls);
    printf("total time (ns)  = %llu\n", (unsigned long long)total_ns);
    printf("ns / sf_exp      = %.3f\n", ns_per_call);
    printf("sf_exp / second  = %.3f\n", evals_per_sec);

    return 0;
}
