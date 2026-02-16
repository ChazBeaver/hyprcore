#!/usr/bin/env bash
set -euo pipefail

echo "=== ZSH Default Shell Setup ==="

########################################
# 1) Install zsh if missing
########################################
if ! command -v zsh >/dev/null 2>&1; then
  echo "🔧 zsh not found — installing via pacman..."
  sudo pacman -Sy --needed --noconfirm zsh
else
  echo "✅ zsh already installed"
fi

########################################
# 2) Locate zsh path
########################################
ZSH_PATH="$(command -v zsh)"

if [[ -z "${ZSH_PATH}" ]]; then
  echo "❌ zsh installation failed"
  exit 1
fi

echo "📍 zsh located at: ${ZSH_PATH}"

########################################
# 3) Ensure allowed shell
########################################
if ! grep -qxF "${ZSH_PATH}" /etc/shells; then
  echo "🔧 Adding ${ZSH_PATH} to /etc/shells"
  echo "${ZSH_PATH}" | sudo tee -a /etc/shells >/dev/null
else
  echo "✅ zsh already allowed in /etc/shells"
fi

########################################
# 4) Change login shell if needed
########################################
CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"

echo "Current login shell: ${CURRENT_SHELL}"

if [[ "${CURRENT_SHELL}" != "${ZSH_PATH}" ]]; then
  echo "🔧 Changing login shell → zsh"
  chsh -s "${ZSH_PATH}"
  echo
  echo "🎉 Default shell updated!"
  echo "⚠️  You must LOG OUT of your graphical session for it to take effect."
else
  echo "✅ Login shell already set to zsh"
fi

########################################
# 5) Verification hint
########################################
cat <<EOF

After logout/login, verify with:

  echo \$SHELL
  ps -p \$\$ -o comm=

Both should show: zsh

EOF
