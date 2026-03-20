#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_LOCAL="$ROOT_DIR/.env.local"

if [[ -f "$ENV_LOCAL" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_LOCAL"
fi

is_wsl=0
if grep -qi microsoft /proc/version 2>/dev/null; then
  is_wsl=1
fi

is_windows_factorio=0
if [[ -n "${FACTORIO_PATH:-}" && "${FACTORIO_PATH##*.}" == "exe" ]]; then
  is_windows_factorio=1
fi

if [[ ! ($is_wsl -eq 1 && $is_windows_factorio -eq 1) && -n "${FACTORIO_PLAYER_DATA:-}" ]]; then
  if [[ ! -f "$FACTORIO_PLAYER_DATA" ]]; then
    echo "Error: FACTORIO_PLAYER_DATA does not exist: $FACTORIO_PLAYER_DATA" >&2
    exit 1
  fi
  mkdir -p "$HOME/.factorio"
  ln -sfn "$FACTORIO_PLAYER_DATA" "$HOME/.factorio/player-data.json" || true
fi

extra_args=()
has_factorio_path=0
has_config=0
for arg in "$@"; do
  if [[ "$arg" == "--factorio-path" ]]; then
    has_factorio_path=1
  elif [[ "$arg" == "--config" || "$arg" == "-c" ]]; then
    has_config=1
  fi
done

if [[ $has_factorio_path -eq 0 && -n "${FACTORIO_PATH:-}" ]]; then
  extra_args+=(--factorio-path "$FACTORIO_PATH")
fi

cd "$ROOT_DIR"

if [[ $is_wsl -eq 1 && -n "${FACTORIO_PATH:-}" && "${FACTORIO_PATH##*.}" == "exe" ]]; then
  # Design decision: when running from WSL against Windows factorio.exe, invoke
  # Windows node directly so all internal paths are handled with Windows semantics.
  win_root="$(wslpath -w "$ROOT_DIR")"
  win_parent_root="$(wslpath -w "$(cd "$ROOT_DIR/.." && pwd)")"
  win_factorio_path="$(wslpath -w "$FACTORIO_PATH")"

  local_config="$ROOT_DIR/.factorio-test.local.json"
  if [[ $has_factorio_path -eq 0 && $has_config -eq 0 ]]; then
    node -e 'const fs=require("fs");const p=process.argv[1];const inPath=process.argv[2];const outPath=process.argv[3];const cfg=JSON.parse(fs.readFileSync(inPath,"utf8"));cfg.factorioPath=p;fs.writeFileSync(outPath,JSON.stringify(cfg,null,2));' "$win_factorio_path" "$ROOT_DIR/factorio-test.json" "$local_config"
  fi

  cmdline="set PATH=%PATH%;C:\\Program Files\\nodejs && cd /d $win_root && node node_modules\\factorio-test-cli\\cli.js"
  for arg in "$@"; do
    if [[ "$arg" == *" "* ]]; then
      cmdline+=" \"${arg//\"/\\\"}\""
    else
      cmdline+=" $arg"
    fi
  done
  if [[ $has_factorio_path -eq 0 && $has_config -eq 0 ]]; then
    cmdline+=" --config .factorio-test.local.json"
  fi
  # Design decision: factorio-test-cli can fail with EEXIST on Windows when a
  # stale junction for the mod-under-test remains in the scratch mods folder.
  # Remove it pre-run to keep local test iteration deterministic.
  rm -rf "$ROOT_DIR/../.factorio-test/mods/squirrel_madness" || true
  win_mod_link="${win_parent_root}\\.factorio-test\\mods\\squirrel_madness"
  cmd.exe /S /C "if exist \"$win_mod_link\\NUL\" rmdir /S /Q \"$win_mod_link\"" > /dev/null 2>&1 || true
  cmd.exe /S /C "if exist \"$win_mod_link\" del /F /Q \"$win_mod_link\"" > /dev/null 2>&1 || true
  exec cmd.exe /S /C "$cmdline"
fi

exec npx factorio-test "$@" "${extra_args[@]}"
