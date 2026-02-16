#!/usr/bin/env bash
set -euo pipefail

echo "=== ZSH Default Shell Setup ==="

########################################
# 0) Helpers
########################################
USER_TO_CHANGE="${SUDO_USER:-$USER}"

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
ZSH_PATH="$(command -v zsh || true)"

if [[ -z "${ZSH_PATH}" ]] || [[ ! -x "${ZSH_PATH}" ]]; then
  echo "❌ zsh installation failed or zsh not executable at: ${ZSH_PATH:-<empty>}"
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
# 4) Change login shell if needed (robust)
#    - Read from passwd DB (not $SHELL)
#    - Prefer sudo usermod (works in scripts)
#    - Fall back to chsh if usermod unavailable
########################################
CURRENT_SHELL="$(getent passwd "${USER_TO_CHANGE}" | awk -F: '{print $7}')"

echo "Current login shell (passwd): ${CURRENT_SHELL}"

if [[ "${CURRENT_SHELL}" != "${ZSH_PATH}" ]]; then
  echo "🔧 Changing login shell → ${ZSH_PATH}"

  # Ensure we have sudo cached early (clearer failure than mid-command)
  if ! sudo -v; then
    echo "❌ sudo authentication failed; cannot change login shell."
    exit 1
  fi

  if command -v usermod >/dev/null 2>&1; then
    # Most reliable in scripted environments
    sudo usermod -s "${ZSH_PATH}" "${USER_TO_CHANGE}"
  else
    # Fallback (may fail in some PAM/script contexts)
    if ! chsh -s "${ZSH_PATH}" "${USER_TO_CHANGE}"; then
      echo "❌ Failed to change shell via chsh."
      echo "   Try: sudo usermod -s \"${ZSH_PATH}\" \"${USER_TO_CHANGE}\""
      exit 1
    fi
  fi

  # Verify immediately from passwd DB
  NEW_SHELL="$(getent passwd "${USER_TO_CHANGE}" | awk -F: '{print $7}')"
  if [[ "${NEW_SHELL}" != "${ZSH_PATH}" ]]; then
    echo "❌ Shell change did not stick. Current (passwd): ${NEW_SHELL}"
    exit 1
  fi

  echo "🎉 Default shell updated for ${USER_TO_CHANGE}!"
  echo "⚠️  You must LOG OUT of your graphical session (or reboot) for it to take effect."
else
  echo "✅ Login shell already set to zsh"
fi

########################################
# 5) Verification hint
########################################
cat <<'EOF'

After logout/login, verify with:

  getent passwd "$USER" | awk -F: '{print $7}'
  echo $SHELL
  ps -p $$ -o comm=

Expected:
  - passwd shell: /usr/bin/zsh
  - comm: zsh

EOF
