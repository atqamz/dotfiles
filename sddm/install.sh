#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "This installer must run with root privileges (use sudo)." >&2
  exit 1
fi

module_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install -Dm644 "$module_dir/etc/sddm.conf.d/background.conf" /etc/sddm.conf.d/background.conf
install -Dm644 "$module_dir/usr/share/sddm/themes/breeze/theme.conf.user" /usr/share/sddm/themes/breeze/theme.conf.user
install -Dm644 "$module_dir/usr/share/backgrounds/sddm-black.png" /usr/share/backgrounds/sddm-black.png

echo "SDDM patch installed. Restart SDDM to apply."
