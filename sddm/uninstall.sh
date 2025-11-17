#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "This uninstaller must run with root privileges (use sudo)." >&2
  exit 1
fi

rm -f /etc/sddm.conf.d/background.conf
rm -f /usr/share/sddm/themes/breeze/theme.conf.user
rm -f /usr/share/backgrounds/sddm-black.png

echo "SDDM patch uninstalled. Restart SDDM to apply."
