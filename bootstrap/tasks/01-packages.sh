#!/usr/bin/env bash
set -euo pipefail

# --------------------------------------
# Pacman: Install only (NO full upgrade)
# - Refreshes package DB safely (no -u)
# - Installs only missing packages
# - Verifies what installed vs failed
# --------------------------------------

PACMAN_PKGS=(
  keepassxc
  yazi
  zsh
  cava
  cmatrix
  ttf-firacode-nerd
  zsh-autosuggestions
  # zsh-autocomplete
  # cbonsai
)

need_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    exec sudo -E "$0" "$@"
  fi
}

is_installed() {
  # Returns 0 if installed, 1 if not
  pacman -Q "$1" >/dev/null 2>&1
}

main() {
  need_root "$@"

  echo "==> Refreshing package databases (no full upgrade)"
  # Avoid partial-upgrade pitfalls by requiring a fresh sync before install
  pacman -Sy --noconfirm

  echo "==> Installing packages (only if missing): ${PACMAN_PKGS[*]}"
  # Don't let one failure abort the whole run; we want a full report.
  install_failed=()
  install_ok=()

  for pkg in "${PACMAN_PKGS[@]}"; do
    if is_installed "$pkg"; then
      echo "  ✓ Already installed: $pkg"
      install_ok+=("$pkg")
      continue
    fi

    echo "  + Installing: $pkg"
    if pacman -S --needed --noconfirm "$pkg"; then
      install_ok+=("$pkg")
    else
      echo "  ✗ Install failed: $pkg"
      install_failed+=("$pkg")
    fi
  done

  echo
  echo "==> Verification check"
  verified_ok=()
  verified_fail=()

  for pkg in "${PACMAN_PKGS[@]}"; do
    if is_installed "$pkg"; then
      verified_ok+=("$pkg")
    else
      verified_fail+=("$pkg")
    fi
  done

  echo
  echo "==> Results"
  if ((${#verified_ok[@]})); then
    echo "✅ Installed/Present (${#verified_ok[@]}):"
    printf '  - %s\n' "${verified_ok[@]}"
  else
    echo "✅ Installed/Present (0)"
  fi

  echo
  if ((${#verified_fail[@]})); then
    echo "❌ Missing/Failed (${#verified_fail[@]}):"
    printf '  - %s\n' "${verified_fail[@]}"
    exit 1
  else
    echo "🎉 All requested packages are installed."
  fi
}

main "$@"
