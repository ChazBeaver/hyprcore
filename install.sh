#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# HyprCore repo root (directory where THIS install.sh lives)
HYPRCORE_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

APPDOTS_REPO="https://github.com/ChazBeaver/appdots"
HYPRDOTS_REPO="https://github.com/ChazBeaver/hyprdots"

# Always clone here
CLONE_BASE_DIR="$HOME/Projects/home"

uses_hyprland() {
  [[ -d "$HOME/.config/hypr" ]] && return 0
  command -v Hyprland >/dev/null 2>&1 && return 0
  command -v hyprctl  >/dev/null 2>&1 && return 0
  return 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "❌ Missing required command: $1"; exit 1; }
}

repo_name() {
  local base
  base="$(basename "$1")"
  echo "${base%.git}"
}

ensure_repo() {
  local url="$1"
  local name dest

  name="$(repo_name "$url")"
  dest="$CLONE_BASE_DIR/$name"

  mkdir -p "$CLONE_BASE_DIR"

  if [[ -d "$dest/.git" ]]; then
    echo "🔁 Updating $name" >&2
    ( cd "$dest" && git pull --ff-only ) >&2
  else
    echo "⬇️  Cloning $name → $dest" >&2
    git clone "$url" "$dest" >&2
  fi

  echo "$dest"
}

run_script() {
  local repo_path="$1"
  local script="$2"

  if [[ ! -f "$repo_path/$script" ]]; then
    echo "⚠️  Missing $script in $(basename "$repo_path"), skipped"
    echo "   ↳ Looked for: $repo_path/$script"
    return 0
  fi

  echo "▶️  $(basename "$repo_path")/$script"
  ( cd "$repo_path" && bash "$script" )
}

need_cmd git
need_cmd bash

echo
echo "🧠 HyprCore Install"
echo "HyprCore root: $HYPRCORE_ROOT"
echo "Clone dir:     $CLONE_BASE_DIR"
echo

APP_PATH="$(ensure_repo "$APPDOTS_REPO")"
run_script "$APP_PATH" install.sh

if uses_hyprland; then
  echo
  echo "✅ Hyprland detected — installing hyprdots..."
  HYPR_PATH="$(ensure_repo "$HYPRDOTS_REPO")"
  run_script "$HYPR_PATH" install.sh
else
  echo
  echo "ℹ️  Hyprland not detected — skipping hyprdots."
fi

# ----------------------------------------
# Final step: run HyprCore bootstrap from HyprCore root
# ----------------------------------------
BOOTSTRAP_PATH="$HYPRCORE_ROOT/bootstrap/bootstrap.sh"

echo
if [[ -f "$BOOTSTRAP_PATH" ]]; then
  echo "🚀 Final step — running HyprCore bootstrap: bootstrap/bootstrap.sh"
  ( cd "$HYPRCORE_ROOT" && bash "./bootstrap/bootstrap.sh" )
else
  echo "⚠️  HyprCore bootstrap not found, skipped"
  echo "   ↳ Looked for: $BOOTSTRAP_PATH"
fi

echo
echo "✅ HyprCore install complete"
