#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

########################################
# Config
########################################
APPDOTS_REPO="https://github.com/ChazBeaver/appdots"
HYPRDOTS_REPO="https://github.com/ChazBeaver/hyprdots"

CLONE_BASE_DIR="$HOME/Projects"

########################################
# Detection
########################################
uses_hyprland() {
  # 1) Strongest: user has Hyprland config
  [[ -d "$HOME/.config/hypr" ]] && return 0

  # 2) Hyprland binaries present
  command -v Hyprland >/dev/null 2>&1 && return 0
  command -v hyprctl   >/dev/null 2>&1 && return 0

  return 1
}

########################################
# Helpers
########################################
need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "❌ Missing required command: $1"
    exit 1
  }
}

repo_name() {
  basename "$1"
}

ensure_repo() {
  local url="$1"
  local name dest

  name="$(repo_name "$url")"
  dest="$CLONE_BASE_DIR/$name"

  mkdir -p "$CLONE_BASE_DIR"

  if [[ -d "$dest/.git" ]]; then
    echo "🔁 Updating $name"
    ( cd "$dest" && git pull --ff-only )
  else
    echo "⬇️  Cloning $name"
    git clone "$url" "$dest"
  fi

  echo "$dest"
}

run_script() {
  local repo_path="$1"
  local script="$2"

  if [[ ! -f "$repo_path/$script" ]]; then
    echo "⚠️  Missing $script in $(basename "$repo_path"), skipped"
    return 0
  fi

  echo "▶️  $(basename "$repo_path")/$script"
  ( cd "$repo_path" && bash "$script" )
}

########################################
# Main
########################################
need_cmd git
need_cmd bash

echo
echo "🧠 HyprCore Install"
echo "Clone dir: $CLONE_BASE_DIR"
echo

# Always: appdots
APP_PATH="$(ensure_repo "$APPDOTS_REPO")"
run_script "$APP_PATH" install.sh

# Conditional: hyprdots
if uses_hyprland; then
  echo
  echo "✅ Hyprland detected — installing hyprdots..."
  HYPR_PATH="$(ensure_repo "$HYPRDOTS_REPO")"
  run_script "$HYPR_PATH" install.sh
else
  echo
  echo "ℹ️  Hyprland not detected — skipping hyprdots."
fi

echo
echo "✅ HyprCore install complete"
