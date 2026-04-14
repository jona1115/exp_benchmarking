// To compile and run:
/*
gcc -O3 -march=native -std=c11 -DSOFTFLOAT_FAST_INT64 -I./berkeley-softfloat-3/build/Linux-x86_64-GCC -I./berkeley-softfloat-3/source/include bench_softfloat.c ./berkeley-softfloat-3/build/Linux-x86_64-GCC/softfloat.a -lquadmath -o bench_softfloat && ./bench_softfloat
*/
//
// This benchmark uses a SoftFloat implementation of expq that follows the
// same overall structure as libquadmath's expq:
// - large-constant rounding to extract n, t1, and t2
// - exp(t1 / 256) and exp(t2 / 32768) lookup tables
// - a small polynomial for exp(r) - 1 on the tiny residual
//
// The lookup tables are generated once at startup using libquadmath, then the
// benchmarked function itself uses SoftFloat arithmetic in the hot path.

#define _POSIX_C_SOURCE 200809L

#include <quadmath.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

#include "./berkeley-softfloat-3/build/Linux-x86_64-GCC/platform.h"
#include "./berkeley-softfloat-3/source/include/softfloat.h"

#ifndef N
#define N 10000000
#endif

#ifndef REPEATS
#define REPEATS 5
#endif

#define ARG1_MIN (-89)
#define ARG1_MAX 89
#define ARG1_COUNT (ARG1_MAX - ARG1_MIN + 1)

#define ARG2_MIN (-65)
#define ARG2_MAX 65
#define ARG2_COUNT (ARG2_MAX - ARG2_MIN + 1)

_Static_assert(sizeof(float128_t) == sizeof(__float128),
               "float128_t and __float128 must both be 16 bytes");

static float128_t sf_inputs[N];
static __float128 ref_inputs[N];
static volatile float128_t sink;

static float128_t sf_zero;
static float128_t sf_one;
static float128_t sf_himark;
static float128_t sf_lomark;
static float128_t sf_threep96;
static float128_t sf_threep103;
static float128_t sf_threep111;
static float128_t sf_inv_ln2;
static float128_t sf_ln2_0;
static float128_t sf_ln2_1;
static float128_t sf_tiny;
static float128_t sf_two16383;
static float128_t sf_two8;
static float128_t sf_two15;
static float128_t sf_p1;
static float128_t sf_p2;
static float128_t sf_p3;
static float128_t sf_p4;
static float128_t sf_p5;
static float128_t sf_p6;

static float128_t sf_arg1_hi[ARG1_COUNT];
static float128_t sf_arg1_lo[ARG1_COUNT];
static float128_t sf_res1[ARG1_COUNT];
static float128_t sf_arg2_hi[ARG2_COUNT];
static float128_t sf_arg2_lo[ARG2_COUNT];
static float128_t sf_res2[ARG2_COUNT];

static inline uint64_t ns_now(void) {
  struct timespec ts;
#ifdef CLOCK_MONOTONIC_RAW
  clock_gettime(CLOCK_MONOTONIC_RAW, &ts);
#else
  clock_gettime(CLOCK_MONOTONIC, &ts);
#endif
  return (uint64_t)ts.tv_sec * 1000000000ull + (uint64_t)ts.tv_nsec;
}

static __float128 sf_to_native(float128_t x) {
  __float128 y;
  memcpy(&y, &x, sizeof(y));
  return y;
}

static float128_t native_to_sf(__float128 x) {
  float128_t y;
  memcpy(&y, &x, sizeof(y));
  return y;
}

static uint64_t f128_hi(float128_t x) {
#ifdef LITTLEENDIAN
  return x.v[1];
#else
  return x.v[0];
#endif
}

static uint64_t f128_lo(float128_t x) {
#ifdef LITTLEENDIAN
  return x.v[0];
#else
  return x.v[1];
#endif
}

static bool f128_signbit_soft(float128_t x) {
  return (f128_hi(x) >> 63) != 0;
}

static bool f128_is_nan_soft(float128_t x) {
  uint64_t hi = f128_hi(x);
  uint64_t lo = f128_lo(x);
  uint16_t exp = (uint16_t)((hi >> 48) & 0x7FFFu);
  uint64_t frac_hi = hi & UINT64_C(0x0000FFFFFFFFFFFF);

  return exp == 0x7FFFu && (frac_hi != 0 || lo != 0);
}

static bool f128_is_inf_soft(float128_t x) {
  uint64_t hi = f128_hi(x);
  uint64_t lo = f128_lo(x);
  uint16_t exp = (uint16_t)((hi >> 48) & 0x7FFFu);
  uint64_t frac_hi = hi & UINT64_C(0x0000FFFFFFFFFFFF);

  return exp == 0x7FFFu && frac_hi == 0 && lo == 0;
}

static int arg1_index(int t) {
  return t - ARG1_MIN;
}

static int arg2_index(int t) {
  return t - ARG2_MIN;
}

static float128_t sf_scalbn_exact(float128_t x, int_fast64_t k) {
  float128_t z = x;
  uint64_t hi;
  int_fast32_t exp;

  if (k == 0) return x;

  hi = f128_hi(z);
  exp = (int_fast32_t)((hi >> 48) & 0x7FFFu);
  if (exp == 0 || exp == 0x7FFF) {
    return native_to_sf(scalbnq(sf_to_native(x), (int)k));
  }

  exp += (int_fast32_t)k;
  if (exp <= 0 || exp >= 0x7FFF) {
    return native_to_sf(scalbnq(sf_to_native(x), (int)k));
  }

  hi = (hi & UINT64_C(0x8000FFFFFFFFFFFF)) | ((uint64_t)exp << 48);

#ifdef LITTLEENDIAN
  z.v[1] = hi;
#else
  z.v[0] = hi;
#endif

  return z;
}

static void init_sf_expq_tables(void) {
  static bool initialized = false;

  if (initialized) return;

  /* These scalar constants mirror libquadmath's C[] table in expq.c.
     The lookup tables below are the structural counterparts of the packed
     __expq_table sections: arg1 hi/lo pairs, arg2 hi/lo pairs, and the two
     exp() result tables. Unlike GCC's generated header, this local version
     synthesizes simpler tables at startup, so the low-part arg tables are
     zero rather than the exact split residuals from expq_table.h. */
  sf_zero = native_to_sf(0.0Q);
  sf_one = native_to_sf(1.0Q);
  sf_himark = native_to_sf(11356.523406294143949491931077970765Q);
  sf_lomark = native_to_sf(-11433.4627433362978788372438434526231Q);
  sf_threep96 = native_to_sf(59421121885698253195157962752.0Q);
  sf_threep103 = native_to_sf(30423614405477505635920876929024.0Q);
  sf_threep111 = native_to_sf(7788445287802241442795744493830144.0Q);
  sf_inv_ln2 = native_to_sf(1.44269504088896340735992468100189204Q);
  sf_ln2_0 = native_to_sf(0.693147180559945309417232121457981864Q);
  sf_ln2_1 = native_to_sf(-1.94704509238074995158795957333327386E-31Q);
  sf_tiny = native_to_sf(1.0e-4900Q);
  sf_two16383 = native_to_sf(5.94865747678615882542879663314003565E+4931Q);
  sf_two8 = native_to_sf(256.0Q);
  sf_two15 = native_to_sf(32768.0Q);
  sf_p1 = native_to_sf(0.5Q);
  sf_p2 = native_to_sf(1.66666666666666666666666666666666683E-01Q);
  sf_p3 = native_to_sf(4.16666666666666666666654902320001674E-02Q);
  sf_p4 = native_to_sf(8.33333333333333333333314659767198461E-03Q);
  sf_p5 = native_to_sf(1.38888888889899438565058018857254025E-03Q);
  sf_p6 = native_to_sf(1.98412698413981650382436541785404286E-04Q);

  for (int t = ARG1_MIN; t <= ARG1_MAX; ++t) {
    int idx = arg1_index(t);
    __float128 arg = scalbnq((__float128)t, -8);

    sf_arg1_hi[idx] = native_to_sf(arg);
    sf_arg1_lo[idx] = sf_zero;
    sf_res1[idx] = native_to_sf(expq(arg));
  }

  for (int t = ARG2_MIN; t <= ARG2_MAX; ++t) {
    int idx = arg2_index(t);
    __float128 arg = scalbnq((__float128)t, -15);

    sf_arg2_hi[idx] = native_to_sf(arg);
    sf_arg2_lo[idx] = sf_zero;
    sf_res2[idx] = native_to_sf(expq(arg));
  }

  initialized = true;
}

static float128_t sf_expq_libquadmath(float128_t x) {
  int tval1;
  int tval2;
  int n_i;
  bool unsafe;
  float128_t n;
  float128_t t;
  float128_t xl;
  float128_t ex2;
  float128_t scale;
  float128_t poly;
  float128_t x2;
  float128_t x22;
  float128_t result;

  if (f128_is_nan_soft(x)) return x;
  if (f128_is_inf_soft(x)) return f128_signbit_soft(x) ? sf_zero : x;

  if (!(f128_lt(x, sf_himark) && f128_lt(sf_lomark, x))) {
    if (f128_lt(x, sf_himark)) {
      return f128_mul(sf_tiny, sf_tiny);
    }
    return f128_mul(sf_two16383, x);
  }

  n = f128_add(f128_mul(x, sf_inv_ln2), sf_threep111);
  n = f128_sub(n, sf_threep111);
  x = f128_sub(x, f128_mul(n, sf_ln2_0));
  xl = f128_mul(n, sf_ln2_1);

  t = f128_add(x, sf_threep103);
  t = f128_sub(t, sf_threep103);
  tval1 = (int)f128_to_i64_r_minMag(f128_mul(t, sf_two8), false);
  x = f128_sub(x, sf_arg1_hi[arg1_index(tval1)]);
  xl = f128_sub(xl, sf_arg1_lo[arg1_index(tval1)]);

  t = f128_add(x, sf_threep96);
  t = f128_sub(t, sf_threep96);
  tval2 = (int)f128_to_i64_r_minMag(f128_mul(t, sf_two15), false);
  x = f128_sub(x, sf_arg2_hi[arg2_index(tval2)]);
  xl = f128_sub(xl, sf_arg2_lo[arg2_index(tval2)]);
  x = f128_add(x, xl);

  ex2 = f128_mul(sf_res1[arg1_index(tval1)], sf_res2[arg2_index(tval2)]);
  n_i = (int)f128_to_i64_r_minMag(n, false);
  unsafe = (n_i >= 15000 || n_i <= -15000);
  ex2 = sf_scalbn_exact(ex2, n_i >> (unsafe ? 1 : 0));

  poly = f128_add(sf_p5, f128_mul(x, sf_p6));
  poly = f128_add(sf_p4, f128_mul(x, poly));
  poly = f128_add(sf_p3, f128_mul(x, poly));
  poly = f128_add(sf_p2, f128_mul(x, poly));
  poly = f128_add(sf_p1, f128_mul(x, poly));

  x2 = f128_mul(x, x);
  x22 = f128_add(x, f128_mul(x2, poly));
  result = f128_add(ex2, f128_mul(x22, ex2));

  if (!unsafe) return result;

  scale = sf_scalbn_exact(sf_one, n_i - (n_i >> 1));
  return f128_mul(result, scale);
}

static void init_inputs(void) {
  for (int i = 0; i < N; ++i) {
    __float128 x = -5.0Q + 10.0Q * ((__float128)i / (__float128)N);
    ref_inputs[i] = x;
    sf_inputs[i] = native_to_sf(x);
  }
}

static void print_sample(__float128 x) {
  char x_buf[64];
  char sf_buf[128];
  char ref_buf[128];
  char err_buf[128];
  float128_t y_sf = sf_expq_libquadmath(native_to_sf(x));
  __float128 y = sf_to_native(y_sf);
  __float128 ref = expq(x);
  __float128 abs_err = fabsq(y - ref);

  quadmath_snprintf(x_buf, sizeof(x_buf), "%.6Qf", x);
  quadmath_snprintf(sf_buf, sizeof(sf_buf), "%.36Qg", y);
  quadmath_snprintf(ref_buf, sizeof(ref_buf), "%.36Qg", ref);
  quadmath_snprintf(err_buf, sizeof(err_buf), "%.6Qe", abs_err);

  printf("x=%8s  sf=%s  ref=%s  abs_err=%s\n",
         x_buf, sf_buf, ref_buf, err_buf);
}

static void print_error_summary(void) {
  __float128 max_abs_err = 0.0Q;
  __float128 max_rel_err = 0.0Q;
  __float128 x_at_max = 0.0Q;

  for (int i = 0; i < N; ++i) {
    __float128 ref = expq(ref_inputs[i]);
    __float128 got = sf_to_native(sf_expq_libquadmath(sf_inputs[i]));
    __float128 abs_err = fabsq(got - ref);
    __float128 rel_err = abs_err / ref;

    if (rel_err > max_rel_err) {
      max_rel_err = rel_err;
      max_abs_err = abs_err;
      x_at_max = ref_inputs[i];
    }
  }

  char x_buf[64];
  char abs_buf[128];
  char rel_buf[128];

  quadmath_snprintf(x_buf, sizeof(x_buf), "%.6Qf", x_at_max);
  quadmath_snprintf(abs_buf, sizeof(abs_buf), "%.6Qe", max_abs_err);
  quadmath_snprintf(rel_buf, sizeof(rel_buf), "%.6Qe", max_rel_err);

  printf("max abs err      = %s at x=%s\n", abs_buf, x_buf);
  printf("max rel err      = %s at x=%s\n", rel_buf, x_buf);
}

int main(void) {
  float128_t sum = native_to_sf(0.0Q);

  init_sf_expq_tables();
  init_inputs();

  softfloat_roundingMode = softfloat_round_near_even;
  softfloat_detectTininess = softfloat_tininess_afterRounding;

  for (int i = 0; i < N; ++i) {
    sum = f128_add(sum, sf_expq_libquadmath(sf_inputs[i]));
  }
  sink = sum;

  sum = native_to_sf(0.0Q);
  uint64_t t0 = ns_now();

  for (int r = 0; r < REPEATS; ++r) {
    for (int i = 0; i < N; ++i) {
      sum = f128_add(sum, sf_expq_libquadmath(sf_inputs[i]));
    }
  }

  uint64_t t1 = ns_now();
  sink = sum;

  uint64_t total_ns = t1 - t0;
  double calls = (double)REPEATS * (double)N;
  double ns_per_call = (double)total_ns / calls;
  double evals_per_sec = 1e9 / ns_per_call;

  puts("SoftFloat libquadmath-style exp benchmark");
  printf("N                = %d\n", N);
  printf("repeats          = %d\n", REPEATS);
  printf("arg1 table       = %d entries\n", ARG1_COUNT);
  printf("arg2 table       = %d entries\n", ARG2_COUNT);
  printf("total calls      = %.0f\n", calls);
  printf("total time (ns)  = %llu\n", (unsigned long long)total_ns);
  printf("ns / sf_expq     = %.3f\n", ns_per_call);
  printf("sf_expq / second = %.3f\n", evals_per_sec);
  // puts("");

  // print_sample(-5.0Q);
  // print_sample(-1.0Q);
  // print_sample(0.0Q);
  // print_sample(1.0Q);
  // print_sample(5.0Q);
  // puts("");
  // print_error_summary();

  return 0;
}
