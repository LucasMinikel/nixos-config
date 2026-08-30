#!/usr/bin/env bash
set -euo pipefail

WOFI_ARGS=(--dmenu --insensitive --prompt "Brilho" --cache-file /dev/null)

notify() {
    notify-send -a "Brilho" "$@" >/dev/null 2>&1 || true
}

build_menu() {
    for pct in 100 75 50 25 10 5; do
        printf '󰃟 Brilho %s%%\n' "$pct"
    done
}

choice="$(build_menu | wofi "${WOFI_ARGS[@]}")"
[[ -z "$choice" ]] && exit 0

if [[ "$choice" =~ ^󰃟\ Brilho\ ([0-9]+)%$ ]]; then
    pct="${BASH_REMATCH[1]}"
    brightnessctl set "${pct}%" >/dev/null 2>&1
    notify "Brilho: ${pct}%"
fi
