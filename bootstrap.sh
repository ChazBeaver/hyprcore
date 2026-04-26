#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# hyprcore/bootstrap.sh
# The true cold-boot orchestrator. Run this ONCE on a brand-new machine
# immediately after base OS install (Omarchy, Arch, etc.).
#
# Responsibilities:
#   1. Ensure the two sibling repos exist on disk
#   2. Run appdots/bootstrap.sh (apps + app-level system tweaks)
#   3. Run hyprdots/bootstrap.sh (Hyprland env)
#
# Everything else (packages, symlinks, OS settings, default shell)
# is delegated to the repos that own those concerns.

# ------------------------------------------------------------------
# Configuration — override via env if your layout differs
# ------------------------------------------------------------------
: "${PROJECTS_DIR:=$HOME/Projects/home}"
: "${APPDOTS_REPO:=git@github.com:YOURUSER/appdots.git}"
: "${HYPRDOTS_REPO:=git@github.com:YOURUSER/hyprdots.git}"

APPDOTS_DIR="$PROJECTS_DIR/appdots"
HYPRDOTS_DIR="$PROJECTS_DIR/hyprdots"

cat <<'EOF'

 _                                       
| |__  _   _ _ __  _ __ ___ ___  _ __ ___
| '_ \| | | | '_ \| '__/ __/ _ \| '__/ _ \
| | | | |_| | |_) | | | (_| (_) | | |  __/
|_| |_|\__, | .__/|_|  \___\___/|_|  \___|
       |___/|_|

    Fresh-machine bootstrap

EOF

die() { echo "❌ $*" >&2; exit 1; }

command -v git >/dev/null 2>&1 || die "git not found. Install it first."

mkdir -p "$PROJECTS_DIR"

clone_or_pull() {
  local repo_url="$1"
  local dest="$2"
  local name
  name="$(basename "$dest")"

  if [ -d "$dest/.git" ]; then
    echo "🔄 $name already cloned, pulling latest"
    git -C "$dest" pull --ff-only
  elif [ -d "$dest" ]; then
    die "$dest exists but is not a git repo. Move it aside and re-run."
  else
    echo "📥 Cloning $name → $dest"
    git clone "$repo_url" "$dest"
  fi
}

run_bootstrap() {
  local repo_dir="$1"
  local bs="$repo_dir/bootstrap.sh"
  [ -x "$bs" ] || chmod +x "$bs" 2>/dev/null || true
  [ -f "$bs" ] || die "$bs not found"
  echo
  echo "▶ Running $(basename "$repo_dir")/bootstrap.sh"
  echo "────────────────────────────────────────"
  "$bs"
  echo "────────────────────────────────────────"
}

echo "📂 Projects dir: $PROJECTS_DIR"
echo

# 1. Fetch repos
clone_or_pull "$APPDOTS_REPO"  "$APPDOTS_DIR"
clone_or_pull "$HYPRDOTS_REPO" "$HYPRDOTS_DIR"

# 2. appdots first — installs the apps hyprdots configs may reference
run_bootstrap "$APPDOTS_DIR"

# 3. hyprdots second — Hyprland env assumes apps exist
run_bootstrap "$HYPRDOTS_DIR"

echo
echo "✅ hyprcore bootstrap complete."
echo "   From now on: pull each repo and run its ./sync.sh for updates."
