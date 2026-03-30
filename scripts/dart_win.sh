#!/usr/bin/env bash

set -euo pipefail

CMD_EXE="/mnt/c/Windows/System32/cmd.exe"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CMD_SCRIPT="${SCRIPT_DIR}/dart_win.cmd"

usage() {
  cat <<'EOF'
Usage:
  scripts/dart_win.sh [--output FILE] [--dart PATH] [dart args...]

Examples:
  scripts/dart_win.sh --output output/dart-format.txt format lib/src/foo.dart
  scripts/dart_win.sh --output output/dart-run.txt run tool/analyze_run_log.dart run.txt

Options:
  --output FILE  Output log file relative to the project root.
  --dart PATH    Explicit Windows path to dart(.bat).
  --help         Show this help.
EOF
}

if [[ ! -x "${CMD_EXE}" ]]; then
  echo "cmd.exe not found at ${CMD_EXE}" >&2
  exit 1
fi

if [[ ! -f "${CMD_SCRIPT}" ]]; then
  echo "Windows helper not found: ${CMD_SCRIPT}" >&2
  exit 1
fi

output_file=""
dart_executable=""
dart_args=()
args_file=""

cleanup() {
  if [[ -n "${args_file}" && -f "${args_file}" ]]; then
    rm -f "${args_file}"
  fi
}

trap cleanup EXIT

while (($# > 0)); do
  case "$1" in
    --output)
      shift
      [[ $# -gt 0 ]] || {
        echo "--output requires a value" >&2
        exit 1
      }
      output_file="$1"
      ;;
    --dart)
      shift
      [[ $# -gt 0 ]] || {
        echo "--dart requires a value" >&2
        exit 1
      }
      dart_executable="$1"
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --)
      shift
      dart_args+=("$@")
      break
      ;;
    *)
      dart_args+=("$1")
      ;;
  esac
  shift
done

if ((${#dart_args[@]} == 0)); then
  echo "No Dart arguments provided." >&2
  usage
  exit 1
fi

timestamp="$(date +%Y%m%d-%H%M%S)"
if [[ -z "${output_file}" ]]; then
  output_file="output/dart-${timestamp}.log"
fi

if [[ "${output_file}" = /* ]]; then
  output_path="${output_file}"
else
  output_path="${PROJECT_ROOT}/${output_file}"
fi

mkdir -p "$(dirname "${output_path}")"

project_root_win="$(wslpath -w "${PROJECT_ROOT}")"
cmd_script_win="$(wslpath -w "${CMD_SCRIPT}")"
output_file_win="$(wslpath -w "${output_path}")"
args_file="$(mktemp)"
printf '%s\n' "${dart_args[@]}" > "${args_file}"
args_file_win="$(wslpath -w "${args_file}")"

cmd=(
  "${CMD_EXE}"
  /d
  /c
  "${cmd_script_win}"
  "${project_root_win}"
  "${output_file_win}"
  "${args_file_win}"
)

if [[ -n "${dart_executable}" ]]; then
  cmd+=("${dart_executable}")
fi

echo "Running Windows Dart from ${PROJECT_ROOT}"
echo "Output file: ${output_path}"

"${cmd[@]}"
