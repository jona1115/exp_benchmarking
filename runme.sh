#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

BENCHES=(
  "bench_exp"
  "bench_expq"
  "bench_expf"
  "bench_cuda_expf"
  "bench_cuda_exp"
  "bench_cuda_expq"
  "bench_expf_mpfr"
  "bench_exp_mpfr64"
  "bench_exp_mpfr"
  "bench_softfloat32"
  "bench_softfloat64"
  "bench_softfloat128"
  "bench_intelm"
)

BIN_DIR="$ROOT_DIR/build/bin"
BUILD_LOG_DIR="$ROOT_DIR/build/build_logs"
RUN_LOG_DIR="$ROOT_DIR/build/run_logs"
RESULTS_MD="$ROOT_DIR/results.md"
RESULTS_CSV="$ROOT_DIR/results.csv"

normalize_value() {
  local s="${1:-}"
  s="${s//$'\r'/}"
  s="${s//$'\n'/ }"
  s="$(printf '%s' "$s" | awk '{$1=$1; print}' 2>/dev/null || true)"
  if [[ -z "$s" ]]; then
    s="unknown"
  fi
  printf '%s' "$s"
}

md_escape() {
  local s
  s="$(normalize_value "${1:-}")"
  s="${s//|/\\|}"
  printf '%s' "$s"
}

csv_escape() {
  local s="${1:-}"
  s="${s//$'\r'/ }"
  s="${s//$'\n'/ }"
  s="${s//\"/\"\"}"
  printf '"%s"' "$s"
}

write_csv_row() {
  local fields=()
  local field
  for field in "$@"; do
    fields+=("$(csv_escape "$field")")
  done
  local IFS=,
  printf '%s\n' "${fields[*]}"
}

write_info_row() {
  local key="$1"
  local value="$2"
  printf '| %s | %s |\n' "$(md_escape "$key")" "$(md_escape "$value")"
}

benchmark_datatype() {
  case "$1" in
    bench_expf|bench_expf_mpfr|bench_softfloat32|bench_cuda_expf)
      printf 'binary32'
      ;;
    bench_exp|bench_exp_mpfr64|bench_softfloat64|bench_intelm|bench_cuda_exp)
      printf 'binary64'
      ;;
    bench_expq|bench_exp_mpfr|bench_softfloat128|bench_cuda_expq)
      printf 'binary128'
      ;;
    *)
      printf 'unknown'
      ;;
  esac
}

benchmark_default_note() {
  case "$1" in
    bench_cuda_expf)
      printf 'CUDA launch: 1 block x 4 threads'
      ;;
    bench_cuda_exp)
      printf 'CUDA launch: 1 block x 2 threads'
      ;;
    bench_cuda_expq)
      printf 'CUDA launch: 1 block x 1 thread; binary128 emulated with double-double'
      ;;
    *)
      printf '-'
      ;;
  esac
}

package_version_for_path() {
  local path="${1:-}"
  local real_path=""
  local pkg_line=""
  local pkg=""
  local ver=""

  [[ -z "$path" || ! -e "$path" ]] && return 0

  real_path="$(realpath "$path" 2>/dev/null || printf '%s' "$path")"

  if command -v dpkg-query >/dev/null 2>&1; then
    pkg_line="$(dpkg-query -S "$real_path" 2>/dev/null | head -n1 || true)"
    if [[ -n "$pkg_line" ]]; then
      pkg="${pkg_line%%: *}"
      ver="$(dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null || true)"
      if [[ -n "$ver" ]]; then
        printf '%s (%s)' "$ver" "$pkg"
        return 0
      fi
      printf '%s' "$pkg"
      return 0
    fi
  fi

  if command -v rpm >/dev/null 2>&1; then
    ver="$(rpm -qf "$real_path" --qf '%{NAME} %{VERSION}-%{RELEASE}' 2>/dev/null || true)"
    if [[ -n "$ver" ]]; then
      printf '%s' "$ver"
      return 0
    fi
  fi
}

read_define_number() {
  local file="$1"
  local macro="$2"
  awk -v macro="$macro" '$1=="#define" && $2==macro {print $3; exit}' "$file" 2>/dev/null || true
}

detect_quadmath_info() {
  local cc_bin="${CC:-gcc}"
  local quadmath_path=""
  local quadmath_real=""
  local quadmath_pkg=""
  local quadmath_soname=""
  local out=""

  if command -v "$cc_bin" >/dev/null 2>&1; then
    quadmath_path="$("$cc_bin" -print-file-name=libquadmath.so 2>/dev/null || true)"
  fi

  if [[ -z "$quadmath_path" || "$quadmath_path" == "libquadmath.so" || ! -e "$quadmath_path" ]]; then
    if command -v ldconfig >/dev/null 2>&1; then
      quadmath_path="$(ldconfig -p 2>/dev/null | awk '/libquadmath\.so/{print $NF; exit}' || true)"
    fi
  fi

  if [[ -z "$quadmath_path" || ! -e "$quadmath_path" ]]; then
    printf 'not detected'
    return 0
  fi

  quadmath_real="$(realpath "$quadmath_path" 2>/dev/null || printf '%s' "$quadmath_path")"
  quadmath_pkg="$(package_version_for_path "$quadmath_real")"
  if command -v readelf >/dev/null 2>&1; then
    quadmath_soname="$(readelf -d "$quadmath_real" 2>/dev/null | awk '/SONAME/{gsub(/\[|\]/,"",$5); print $5; exit}' || true)"
  fi

  if [[ -n "$quadmath_pkg" ]]; then
    out="$quadmath_pkg"
  fi
  if [[ -n "$quadmath_soname" ]]; then
    if [[ -n "$out" ]]; then
      out="$out, SONAME $quadmath_soname"
    else
      out="SONAME $quadmath_soname"
    fi
  fi
  if [[ -z "$out" ]]; then
    out="$quadmath_real"
  else
    out="$out ($quadmath_real)"
  fi

  printf '%s' "$out"
}

detect_mpfr_version() {
  local version=""
  local header=""
  local major=""
  local minor=""
  local patch=""

  if command -v pkg-config >/dev/null 2>&1; then
    version="$(pkg-config --modversion mpfr 2>/dev/null || true)"
  fi
  if [[ -n "$version" ]]; then
    printf '%s' "$version"
    return 0
  fi

  for header in /usr/include/mpfr.h /usr/local/include/mpfr.h; do
    if [[ -f "$header" ]]; then
      version="$(awk '$1=="#define" && $2=="MPFR_VERSION_STRING" {gsub(/"/,"",$3); print $3; exit}' "$header" 2>/dev/null || true)"
      if [[ -n "$version" ]]; then
        printf '%s (from %s)' "$version" "$header"
        return 0
      fi
      major="$(read_define_number "$header" "MPFR_VERSION_MAJOR")"
      minor="$(read_define_number "$header" "MPFR_VERSION_MINOR")"
      patch="$(read_define_number "$header" "MPFR_VERSION_PATCHLEVEL")"
      if [[ -n "$major" && -n "$minor" && -n "$patch" ]]; then
        printf '%s.%s.%s (from %s)' "$major" "$minor" "$patch" "$header"
        return 0
      fi
    fi
  done

  printf 'not detected'
}

detect_gmp_version() {
  local version=""
  local header=""
  local major=""
  local minor=""
  local patch=""

  if command -v pkg-config >/dev/null 2>&1; then
    version="$(pkg-config --modversion gmp 2>/dev/null || true)"
  fi
  if [[ -n "$version" ]]; then
    printf '%s' "$version"
    return 0
  fi

  for header in /usr/include/gmp.h /usr/include/x86_64-linux-gnu/gmp.h /usr/local/include/gmp.h; do
    if [[ -f "$header" ]]; then
      major="$(read_define_number "$header" "__GNU_MP_VERSION")"
      minor="$(read_define_number "$header" "__GNU_MP_VERSION_MINOR")"
      patch="$(read_define_number "$header" "__GNU_MP_VERSION_PATCHLEVEL")"
      if [[ -n "$major" && -n "$minor" && -n "$patch" ]]; then
        printf '%s.%s.%s (from %s)' "$major" "$minor" "$patch" "$header"
        return 0
      fi
    fi
  done

  printf 'not detected'
}

detect_mkl_version() {
  local header=""
  local major=""
  local minor=""
  local update=""
  local raw=""
  local mkl_rt=""
  local candidate=""
  local candidates=()

  if [[ -n "${MKLROOT:-}" ]]; then
    candidates+=("$MKLROOT/include/mkl_version.h")
  fi
  candidates+=("/usr/include/mkl_version.h" "/opt/intel/oneapi/mkl/latest/include/mkl_version.h")

  shopt -s nullglob
  for candidate in /opt/intel/oneapi/mkl/*/include/mkl_version.h; do
    candidates+=("$candidate")
  done
  shopt -u nullglob

  for candidate in "${candidates[@]}"; do
    if [[ -f "$candidate" ]]; then
      header="$candidate"
      break
    fi
  done

  if [[ -n "$header" ]]; then
    major="$(read_define_number "$header" "__INTEL_MKL__")"
    minor="$(read_define_number "$header" "__INTEL_MKL_MINOR__")"
    update="$(read_define_number "$header" "__INTEL_MKL_UPDATE__")"
    if [[ -n "$major" && -n "$minor" && -n "$update" ]]; then
      printf '%s.%s.%s (from %s)' "$major" "$minor" "$update" "$header"
      return 0
    fi

    raw="$(read_define_number "$header" "INTEL_MKL_VERSION")"
    if [[ -n "$raw" ]]; then
      printf '%s (from %s)' "$raw" "$header"
      return 0
    fi
  fi

  if command -v ldconfig >/dev/null 2>&1; then
    mkl_rt="$(ldconfig -p 2>/dev/null | awk '/libmkl_rt\.so/{print $NF; exit}' || true)"
    if [[ -n "$mkl_rt" && -e "$mkl_rt" ]]; then
      raw="$(strings "$mkl_rt" 2>/dev/null | grep -m1 -E 'Intel\(R\).*(Math Kernel Library|oneAPI MKL)|oneAPI Math Kernel Library' || true)"
      if [[ -n "$raw" ]]; then
        printf '%s (%s)' "$raw" "$mkl_rt"
      else
        printf 'detected (%s), version string unavailable' "$mkl_rt"
      fi
      return 0
    fi
  fi

  printf 'not detected'
}

detect_cuda_toolkit_version() {
  local nvcc_path=""
  local version_line=""

  if ! command -v nvcc >/dev/null 2>&1; then
    printf 'not detected'
    return 0
  fi

  nvcc_path="$(command -v nvcc 2>/dev/null || true)"
  version_line="$(nvcc --version 2>/dev/null | awk -F', ' '/release /{print $2", "$3; exit}' || true)"
  if [[ -z "$version_line" ]]; then
    version_line="$(nvcc --version 2>/dev/null | tail -n1 || true)"
  fi

  if [[ -n "$nvcc_path" ]]; then
    printf '%s (%s)' "$version_line" "$nvcc_path"
  else
    printf '%s' "$version_line"
  fi
}

detect_cuda_driver_gpu_info() {
  local smi_probe=""
  local driver=""
  local first_gpu=""
  local gpu_count=""
  local cuda_runtime=""

  if ! command -v nvidia-smi >/dev/null 2>&1; then
    printf 'not detected'
    return 0
  fi

  smi_probe="$(nvidia-smi -L 2>&1 || true)"
  if [[ "$smi_probe" == *"NVIDIA-SMI has failed"* || "$smi_probe" == *"couldn't communicate with the NVIDIA driver"* ]]; then
    printf 'unavailable (%s)' "$(printf '%s' "$smi_probe" | head -n1)"
    return 0
  fi

  driver="$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -n1 || true)"
  first_gpu="$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -n1 || true)"
  gpu_count="$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | wc -l | tr -d '[:space:]' || true)"
  cuda_runtime="$(nvidia-smi 2>/dev/null | awk -F'CUDA Version: ' '/CUDA Version:/{split($2,a," "); print a[1]; exit}' || true)"

  if [[ -z "$driver" && -z "$first_gpu" ]]; then
    printf 'nvidia-smi present, but no GPU information available'
    return 0
  fi

  if [[ -z "$gpu_count" ]]; then
    gpu_count="unknown"
  fi
  if [[ -z "$driver" ]]; then
    driver="unknown"
  fi
  if [[ -z "$cuda_runtime" ]]; then
    cuda_runtime="unknown"
  fi
  if [[ -z "$first_gpu" ]]; then
    first_gpu="unknown"
  fi

  printf 'driver %s, CUDA runtime %s, GPUs %s (first: %s)' \
    "$driver" "$cuda_runtime" "$gpu_count" "$first_gpu"
}

detect_softfloat_commit() {
  local commit=""
  if commit="$(git -C "$ROOT_DIR/berkeley-softfloat-3" rev-parse --short=12 HEAD 2>/dev/null || true)"; then
    if [[ -n "$commit" ]]; then
      printf '%s' "$commit"
      return 0
    fi
  fi
  printf 'not detected'
}

detect_system_info() {
  local os_pretty=""
  local kernel=""
  local arch=""
  local cpu_model=""
  local logical_cores=""
  local threads_per_core=""
  local cores_per_socket=""
  local sockets=""
  local physical_cores=""
  local gcc_version=""
  local gcc_path=""

  os_pretty="$(awk -F= '/^PRETTY_NAME=/{gsub(/"/,"",$2); print $2; exit}' /etc/os-release 2>/dev/null || true)"
  kernel="$(uname -sr 2>/dev/null || true)"
  arch="$(uname -m 2>/dev/null || true)"

  if command -v lscpu >/dev/null 2>&1; then
    cpu_model="$(lscpu 2>/dev/null | awk -F: '/Model name:/{gsub(/^[ \t]+/, "", $2); print $2; exit}' || true)"
    threads_per_core="$(lscpu 2>/dev/null | awk -F: '/Thread\(s\) per core:/{gsub(/^[ \t]+/, "", $2); print $2; exit}' || true)"
    cores_per_socket="$(lscpu 2>/dev/null | awk -F: '/Core\(s\) per socket:/{gsub(/^[ \t]+/, "", $2); print $2; exit}' || true)"
    sockets="$(lscpu 2>/dev/null | awk -F: '/Socket\(s\):/{gsub(/^[ \t]+/, "", $2); print $2; exit}' || true)"
  fi
  if [[ -z "$cpu_model" && -f /proc/cpuinfo ]]; then
    cpu_model="$(awk -F: '/^model name/{gsub(/^[ \t]+/, "", $2); print $2; exit}' /proc/cpuinfo 2>/dev/null || true)"
  fi

  logical_cores="$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || true)"
  if [[ "$cores_per_socket" =~ ^[0-9]+$ && "$sockets" =~ ^[0-9]+$ ]]; then
    physical_cores=$((cores_per_socket * sockets))
  fi

  if command -v gcc >/dev/null 2>&1; then
    gcc_path="$(command -v gcc 2>/dev/null || true)"
    gcc_version="$(gcc --version 2>/dev/null | head -n1 || true)"
    if [[ -n "$gcc_path" ]]; then
      gcc_version="$gcc_version ($gcc_path)"
    fi
  else
    gcc_version="not detected"
  fi

  SYSTEM_OS="$os_pretty"
  SYSTEM_KERNEL="$kernel"
  SYSTEM_ARCH="$arch"
  SYSTEM_CPU_MODEL="$cpu_model"
  SYSTEM_LOGICAL_CORES="$logical_cores"
  SYSTEM_PHYSICAL_CORES="${physical_cores:-}"
  SYSTEM_THREADS_PER_CORE="$threads_per_core"
  SYSTEM_GCC="$gcc_version"
}

extract_eq_value() {
  local file="$1"
  local regex="$2"
  awk -F= -v re="$regex" '
    $0 ~ re {
      v = $2
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
      print v
      exit
    }
  ' "$file"
}

extract_ns_pair() {
  local file="$1"
  awk -F= '
    /^ns[[:space:]]*\/[[:space:]]*/ {
      lhs = $1
      rhs = $2
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", lhs)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", rhs)
      sub(/^ns[[:space:]]*\/[[:space:]]*/, "", lhs)
      printf "%s|%s\n", lhs, rhs
      exit
    }
  ' "$file"
}

extract_build_reason() {
  local build_log="$1"
  local reason=""

  if [[ -f "$build_log" ]]; then
    reason="$(grep -E -m1 'fatal error:|undefined reference|cannot find -l|No such file or directory|error:' "$build_log" || true)"
    if [[ -z "$reason" ]]; then
      reason="$(tail -n 1 "$build_log" 2>/dev/null || true)"
    fi
  fi

  if [[ -z "$reason" ]]; then
    reason="compile failed"
  fi

  reason="${reason//$'\r'/}"
  printf '%s' "$reason"
}

extract_run_reason() {
  local run_log="$1"
  local reason=""

  if [[ -f "$run_log" ]]; then
    reason="$(grep -E -m1 'CUDA error|No CUDA device|error:|failed|exception|terminated' "$run_log" || true)"
    if [[ -z "$reason" ]]; then
      reason="$(tail -n 1 "$run_log" 2>/dev/null || true)"
    fi
  fi

  if [[ -z "$reason" ]]; then
    reason="runtime failed or metrics missing"
  fi

  reason="${reason//$'\r'/}"
  printf '%s' "$reason"
}

echo "[runme] building and running benchmarks"
make run

detect_system_info
COLLECTED_AT_UTC="$(date -u +'%Y-%m-%d %H:%M:%S UTC' 2>/dev/null || true)"
LIBQUADMATH_INFO="$(detect_quadmath_info)"
MPFR_VERSION_INFO="$(detect_mpfr_version)"
GMP_VERSION_INFO="$(detect_gmp_version)"
SOFTFLOAT_COMMIT_INFO="$(detect_softfloat_commit)"
MKL_VERSION_INFO="$(detect_mkl_version)"
CUDA_TOOLKIT_INFO="$(detect_cuda_toolkit_version)"
CUDA_DRIVER_GPU_INFO="$(detect_cuda_driver_gpu_info)"

write_csv_row "benchmark" "datatype" "function" "total_calls" "total_time_ns" "ns_per_call" "calls_per_second" "status" "notes" > "$RESULTS_CSV"

{
  echo "## System Information"
  echo
  echo "| Item | Value |"
  echo "|---|---|"
  write_info_row "Collected at (UTC)" "$COLLECTED_AT_UTC"
  write_info_row "OS" "$SYSTEM_OS"
  write_info_row "Kernel" "$SYSTEM_KERNEL"
  write_info_row "Architecture" "$SYSTEM_ARCH"
  write_info_row "CPU model" "$SYSTEM_CPU_MODEL"
  if [[ -n "${SYSTEM_PHYSICAL_CORES:-}" ]]; then
    write_info_row "CPU cores (physical / logical)" "${SYSTEM_PHYSICAL_CORES} / ${SYSTEM_LOGICAL_CORES}"
  else
    write_info_row "CPU cores (logical)" "$SYSTEM_LOGICAL_CORES"
  fi
  write_info_row "Threads per core" "$SYSTEM_THREADS_PER_CORE"
  write_info_row "GCC" "$SYSTEM_GCC"
  write_info_row "libquadmath" "$LIBQUADMATH_INFO"
  write_info_row "MPFR" "$MPFR_VERSION_INFO"
  write_info_row "GMP" "$GMP_VERSION_INFO"
  write_info_row "SoftFloat commit" "$SOFTFLOAT_COMMIT_INFO"
  write_info_row "Intel MKL" "$MKL_VERSION_INFO"
  write_info_row "CUDA toolkit" "$CUDA_TOOLKIT_INFO"
  write_info_row "CUDA driver/GPU" "$CUDA_DRIVER_GPU_INFO"
  echo

  echo "## Benchmark Results"
  echo
  echo "| Benchmark | Data Type | Function | Total Calls | Total Time (ns) | ns / call | Calls / second | Status | Notes |"
  echo "|---|---|---|---:|---:|---:|---:|---|---|"

  for bench in "${BENCHES[@]}"; do
    bin="$BIN_DIR/$bench"
    run_log="$RUN_LOG_DIR/$bench.txt"
    build_log="$BUILD_LOG_DIR/$bench.build.log"

    function_name="-"
    datatype="unknown"
    total_calls="-"
    total_time_ns="-"
    ns_per_call="-"
    calls_per_second="-"
    status="ok"
    notes="$(benchmark_default_note "$bench")"
    notes_md="$notes"
    datatype="$(benchmark_datatype "$bench")"

    if [[ ! -x "$bin" ]]; then
      status="skipped"
      notes="$(extract_build_reason "$build_log")"
    elif [[ ! -f "$run_log" ]]; then
      status="skipped"
      notes="run log missing"
    else
      total_calls="$(extract_eq_value "$run_log" '^total calls[[:space:]]*=')"
      total_time_ns="$(extract_eq_value "$run_log" '^total time [(]ns[)][[:space:]]*=')"

      ns_pair="$(extract_ns_pair "$run_log")"
      if [[ -n "$ns_pair" ]]; then
        function_name="${ns_pair%%|*}"
        ns_per_call="${ns_pair#*|}"
      fi

      calls_per_second="$(extract_eq_value "$run_log" '/[[:space:]]*second[[:space:]]*=')"

      [[ -z "$function_name" ]] && function_name="-"
      [[ -z "$total_calls" ]] && total_calls="-"
      [[ -z "$total_time_ns" ]] && total_time_ns="-"
      [[ -z "$ns_per_call" ]] && ns_per_call="-"
      [[ -z "$calls_per_second" ]] && calls_per_second="-"

      if [[ "$total_calls" == "-" || "$total_time_ns" == "-" || "$ns_per_call" == "-" || "$calls_per_second" == "-" ]]; then
        status="parse-warning"
        notes="$(extract_run_reason "$run_log")"
      fi
    fi

    [[ -z "$notes" ]] && notes="-"
    write_csv_row "$bench" "$datatype" "$function_name" "$total_calls" "$total_time_ns" "$ns_per_call" "$calls_per_second" "$status" "$notes" >> "$RESULTS_CSV"
    notes_md="${notes//|/\\|}"
    printf '| `%s` | `%s` | `%s` | %s | %s | %s | %s | %s | %s |\n' \
      "$bench" "$datatype" "$function_name" "$total_calls" "$total_time_ns" "$ns_per_call" "$calls_per_second" "$status" "$notes_md"
  done
} > "$RESULTS_MD"

echo "[runme] wrote $RESULTS_MD"
echo "[runme] wrote $RESULTS_CSV"
