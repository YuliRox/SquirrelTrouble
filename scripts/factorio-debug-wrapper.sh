#!/usr/bin/env bash
set -euo pipefail

detect_factorio_exe() {
  local candidates=(
    "/mnt/c/Program Files/Factorio/bin/x64/factorio.exe"
    "/mnt/c/Program Files (x86)/Steam/steamapps/common/Factorio/bin/x64/factorio.exe"
  )
  local exe
  for exe in "${candidates[@]}"; do
    if [[ -f "$exe" ]]; then
      printf '%s\n' "$exe"
      return 0
    fi
  done
  return 1
}

to_windows_path() {
  local value="$1"
  if [[ "$value" == /mnt/* ]]; then
    wslpath -w "$value"
  else
    printf '%s\n' "$value"
  fi
}

FACTORIO_EXE="${FACTORIO_EXE:-}"
if [[ -z "$FACTORIO_EXE" ]]; then
  FACTORIO_EXE="$(detect_factorio_exe || true)"
fi

if [[ -z "$FACTORIO_EXE" || ! -f "$FACTORIO_EXE" ]]; then
  echo "Error: factorio.exe not found. Set FACTORIO_EXE explicitly." >&2
  exit 1
fi

path_flags=(
  "--config"
  "--mod-directory"
  "--load-game"
  "--benchmark"
  "--map-gen-settings"
  "--map-settings"
  "--mod-settings"
)

expect_path=0
translated_args=()
for arg in "$@"; do
  if [[ $expect_path -eq 1 ]]; then
    translated_args+=("$(to_windows_path "$arg")")
    expect_path=0
    continue
  fi

  translated_args+=("$arg")

  for flag in "${path_flags[@]}"; do
    if [[ "$arg" == "$flag" ]]; then
      expect_path=1
      break
    fi
  done
done

exec "$FACTORIO_EXE" "${translated_args[@]}"
