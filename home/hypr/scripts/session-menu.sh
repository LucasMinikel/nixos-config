#!/usr/bin/env bash
set -euo pipefail

LOCK="󰌾 Bloquear"
SUSPEND="󰒲 Suspender"
RESTART="󰜉 Reiniciar"
POWEROFF="󰐥 Desligar"
LOGOUT="󰍃 Sair do Hyprland"

choice="$(printf '%s\n%s\n%s\n%s\n%s\n' "$LOCK" "$SUSPEND" "$RESTART" "$POWEROFF" "$LOGOUT" | wofi --dmenu --insensitive --prompt "Energia" --cache-file /dev/null)"
[[ -z "$choice" ]] && exit 0

case "$choice" in
    "$LOCK") hyprlock ;;
    "$SUSPEND") systemctl suspend ;;
    "$RESTART") systemctl reboot ;;
    "$POWEROFF") systemctl poweroff ;;
    "$LOGOUT") hyprctl dispatch exit ;;
esac
