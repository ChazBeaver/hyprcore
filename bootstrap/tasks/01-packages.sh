#!/usr/bin/env bash
set -euo pipefail

# --------------------------------------
# Pacman + AUR Installer
# --------------------------------------

PACMAN_PKGS=(
  keepassxc
  yazi
  zsh
  ttf-firacode-nerd
  libreoffice-fresh
  zsh-autosuggestions
  ripgrep
  cava
  cmatrix
  ddcutil
)

AUR_PKGS=(
  yaru-gtk-theme
  colloid-gtk-theme
  tela-icon-theme
)

need_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    exec sudo -E "$0" "$@"
  fi
}

is_installed() {
  pacman -Q "$1" >/dev/null 2>&1
}

is_aur_installed() {
  pacman -Q "$1" >/dev/null 2>&1
}

install_yay() {
  if command -v yay >/dev/null 2>&1; then
    return
  fi

  echo "==> Installing yay (AUR helper)"
  sudo pacman -S --needed --noconfirm git base-devel

  tmp_dir=$(mktemp -d)
  git clone https://aur.archlinux.org/yay.git "$tmp_dir/yay"
  pushd "$tmp_dir/yay" >/dev/null
  makepkg -si --noconfirm
  popd >/dev/null
}

main() {
  need_root "$@"

  echo "==> Refreshing package databases"
  pacman -Sy --noconfirm

  echo "==> Installing PACMAN packages"
  for pkg in "${PACMAN_PKGS[@]}"; do
    if is_installed "$pkg"; then
      echo "  ✓ Already installed: $pkg"
    else
      echo "  + Installing: $pkg"
      pacman -S --needed --noconfirm "$pkg" || echo "  ✗ Failed: $pkg"
    fi
  done

  echo
  echo "==> Ensuring AUR helper (yay)"
  install_yay

  echo
  echo "==> Installing AUR packages"
  for pkg in "${AUR_PKGS[@]}"; do
    if is_aur_installed "$pkg"; then
      echo "  ✓ Already installed: $pkg"
    else
      echo "  + Installing (AUR): $pkg"
      sudo -u "$SUDO_USER" yay -S --needed --noconfirm "$pkg" || echo "  ✗ Failed: $pkg"
    fi
  done

  echo
  echo "🎉 Done."
}

main "$@"
