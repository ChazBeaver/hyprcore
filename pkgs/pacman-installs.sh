#!/usr/bin/env bash
set -euo pipefail

PACMAN_PKGS=(
  keepassxc
  yazi
  zsh
)

need_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    exec sudo -E "$0" "$@"
  fi
}

main() {
  need_root "$@"

  echo "==> Updating repos + installing (pacman): ${PACMAN_PKGS[*]}"
  pacman -Syu --needed --noconfirm "${PACMAN_PKGS[@]}"

  echo "==> Installed:"
  pacman -Q "${PACMAN_PKGS[@]}"
}

main "$@"
