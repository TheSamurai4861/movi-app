#!/usr/bin/env bash

set -euo pipefail

CMD_EXE="/mnt/c/Windows/System32/cmd.exe"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CMD_SCRIPT="${SCRIPT_DIR}/flutter_win.cmd"

usage() {
  cat <<'EOF'
Usage:
  scripts/flutter_win.sh [--output FILE] [--flutter PATH] [flutter args...]

Examples:
  scripts/flutter_win.sh --output output/flutter-analyze.txt analyze
  scripts/flutter_win.sh --output output/flutter-test.txt test
  scripts/flutter_win.sh --output output/flutter-run.txt run -d windows --dart-define-from-file=.env

Options:
  --output FILE   Output log file relative to the project root.
  --flutter PATH  Explicit Windows path to flutter(.bat).
  --help          Show this help.
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
flutter_executable=""
flutter_args=()
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
    --flutter)
      shift
      [[ $# -gt 0 ]] || {
        echo "--flutter requires a value" >&2
        exit 1
      }
      flutter_executable="$1"
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --)
      shift
      flutter_args+=("$@")
      break
      ;;
    *)
      flutter_args+=("$1")
      ;;
  esac
  shift
done

if ((${#flutter_args[@]} == 0)); then
  echo "No Flutter arguments provided." >&2
  usage
  exit 1
fi

timestamp="$(date +%Y%m%d-%H%M%S)"
if [[ -z "${output_file}" ]]; then
  output_file="output/flutter-${timestamp}.log"
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
printf '%s\n' "${flutter_args[@]}" > "${args_file}"
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

if [[ -n "${flutter_executable}" ]]; then
  cmd+=(-FlutterExecutable "${flutter_executable}")
fi

echo "Running Windows Flutter from ${PROJECT_ROOT}"
echo "Output file: ${output_path}"

"${cmd[@]}"
