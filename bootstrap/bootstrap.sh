#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
TASK_DIR="$SCRIPT_DIR/tasks"

echo
echo "========================================"
echo "   Omarchy Setup Runner"
echo "========================================"
echo

if [[ ! -d "$TASK_DIR" ]]; then
  echo "ERROR: tasks directory not found: $TASK_DIR"
  exit 1
fi

# ----------------------------------------
# Sudo (ask once, keep alive)
# ----------------------------------------
SUDO_KEEPALIVE_PID=""

cleanup() {
  if [[ -n "${SUDO_KEEPALIVE_PID:-}" ]]; then
    kill "$SUDO_KEEPALIVE_PID" &>/dev/null || true
  fi
}
trap cleanup EXIT

if command -v sudo &>/dev/null; then
  echo "==> Pre-authenticating sudo (so child scripts don't keep prompting)..."
  sudo -v

  # Keep sudo timestamp alive until this script exits
  ( while true; do sudo -n -v; sleep 60; done ) &>/dev/null &
  SUDO_KEEPALIVE_PID="$!"
  echo "==> Sudo keepalive enabled"
  echo
else
  echo "==> sudo not found; continuing without sudo keepalive"
  echo
fi

SUCCESS=()
FAILED=()

run_task() {
  local script="$1"

  echo "----------------------------------------"
  echo "Running: $(basename "$script")"
  echo "----------------------------------------"

  if bash "$script"; then
    SUCCESS+=("$(basename "$script")")
    echo "✔ SUCCESS"
  else
    FAILED+=("$(basename "$script")")
    echo "✖ FAILED"
  fi

  echo
}

# Run scripts in sorted order
while IFS= read -r -d '' file; do
  run_task "$file"
done < <(find "$TASK_DIR" -maxdepth 1 -type f -name "*.sh" -print0 | sort -z)

# ----------------------------------------
# Summary
# ----------------------------------------
echo "========================================"
echo "               SUMMARY"
echo "========================================"

echo
echo "Successful:"
if (( ${#SUCCESS[@]} == 0 )); then
  echo "  (none)"
else
  for s in "${SUCCESS[@]}"; do
    echo "  ✔ $s"
  done
fi

echo
echo "Failed:"
if (( ${#FAILED[@]} == 0 )); then
  echo "  (none)"
else
  for f in "${FAILED[@]}"; do
    echo "  ✖ $f"
  done
fi

echo

if (( ${#FAILED[@]} > 0 )); then
  echo "Setup completed WITH ERRORS"
  exit 1
else
  echo "Setup completed successfully"
fi
