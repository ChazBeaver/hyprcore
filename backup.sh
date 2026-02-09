#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

########################################
# Config
########################################
APPDOTS_REPO="https://github.com/ChazBeaver/appdots"
HYPRDOTS_REPO="https://github.com/ChazBeaver/hyprdots"
OMARCHYDOTS_REPO="https://github.com/ChazBeaver/omarchydots"

CLONE_BASE_DIR="$HOME/Projects"

########################################
# Detection
########################################
detect_os() {
  case "$(uname -s)" in
    Linux)  echo "linux" ;;
    Darwin) echo "macos" ;;
    *)      echo "unknown" ;;
  esac
}

is_nixos() {
  [[ -e /etc/NIXOS ]] && return 0
  grep -qi '^ID=nixos' /etc/os-release 2>/dev/null && return 0
  return 1
}

is_arch() {
  [[ -f /etc/arch-release ]] && return 0
  command -v pacman >/dev/null 2>&1 && return 0
  return 1
}

uses_hyprland() {
  [[ -d "$HOME/.config/hypr" ]] && return 0
  command -v Hyprland >/dev/null 2>&1 && return 0
  command -v hyprctl  >/dev/null 2>&1 && return 0
  return 1
}

is_omarchy() {
  command -v omarchy-menu >/dev/null 2>&1 && return 0
  [[ -d "$HOME/.local/share/omarchy" ]] && return 0
  [[ -d "/usr/share/omarchy" ]] && return 0
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

  [[ -f "$repo_path/$script" ]] || {
    echo "⚠️  Missing $script in $(basename "$repo_path"), skipped"
    return
  }

  echo "▶️  $(basename "$repo_path")/$script"
  ( cd "$repo_path" && bash "$script" )
}

########################################
# Main
########################################
need_cmd git
need_cmd bash

OS="$(detect_os)"

echo
echo "🧠 HyprCore Backup"
echo "OS: $OS"
echo "Clone dir: $CLONE_BASE_DIR"
echo

DO_APPDOTS=1
DO_HYPRDOTS=0
DO_OMARCHYDOTS=0

if [[ "$OS" == "linux" ]]; then
  uses_hyprland && DO_HYPRDOTS=1

  if ! is_nixos && is_arch && is_omarchy; then
    DO_OMARCHYDOTS=1
  fi
fi

echo "Backup plan:"
echo "  appdots:      $([[ $DO_APPDOTS -eq 1 ]] && echo YES || echo NO)"
echo "  hyprdots:     $([[ $DO_HYPRDOTS -eq 1 ]] && echo YES || echo NO)"
echo "  omarchydots:  $([[ $DO_OMARCHYDOTS -eq 1 ]] && echo YES || echo NO)"
echo

if [[ $DO_APPDOTS -eq 1 ]]; then
  APP_PATH="$(ensure_repo "$APPDOTS_REPO")"
  run_script "$APP_PATH" backup.sh
fi

if [[ $DO_HYPRDOTS -eq 1 ]]; then
  HYPR_PATH="$(ensure_repo "$HYPRDOTS_REPO")"
  run_script "$HYPR_PATH" backup.sh
fi

if [[ $DO_OMARCHYDOTS -eq 1 ]]; then
  OMAR_PATH="$(ensure_repo "$OMARCHYDOTS_REPO")"
  run_script "$OMAR_PATH" backup.sh
fi

echo
echo "✅ HyprCore backup complete"
