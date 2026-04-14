# exp_benchmarking

## How to run?
Run: `./runme.sh`, the results will pop out in `results.md` and `results.csv`.

## CORE-MATH Integration
- `make` now builds extra benchmarks that call CORE-MATH directly:
  - `bench_coremath_expf` -> `cr_expf` from `core-math/src/binary32/exp/expf.c`
  - `bench_coremath_exp` -> `cr_exp` from `core-math/src/binary64/exp/exp.c`
  - `bench_coremath_expq` -> `cr_expq` from `core-math/src/binary128/exp/expq.c`
- These are linked straight from CORE-MATH source files, so no separate install step is required.
- If a compiler cannot build a target (for example some GCC versions and `cr_expq`), the Makefile keeps going and marks only that benchmark as unavailable.

## Results
Latest benchmark table: [results.md](results.md)

## Contribute
1. Add your benchmark, recommended to prefix the file name with `bench_*`
2. Add it into `runme.sh` and Makefile's `BENCHES` variable (top of both the files).

## Submodule Mirror
- Berkeley SoftFloat [[Web link](https://www.jhauser.us/arithmetic/SoftFloat.html), [GitHub link](https://github.com/ucb-bar/berkeley-softfloat-3)], mirror: [https://github.com/jona1115/berkeley-softfloat-3](https://github.com/jona1115/berkeley-softfloat-3)
- The CORE-Math Project [[GitLab link](https://gitlab.inria.fr/core-math/core-math/)], mirror: [https://github.com/jona1115/core-math-mirror](https://github.com/jona1115/core-math-mirror)
