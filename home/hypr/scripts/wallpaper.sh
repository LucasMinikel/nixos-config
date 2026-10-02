#!/usr/bin/env bash
set -uo pipefail

WALLPAPER_DIR="$HOME/nixos-config/wallpapers"
DEFAULT_WALLPAPER="$WALLPAPER_DIR/comic_original.png"

if [[ -f "$DEFAULT_WALLPAPER" ]]; then
    wp="$DEFAULT_WALLPAPER"
else
    wp=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | shuf -n1)
fi

[[ -n "${wp:-}" ]] || exit 0

# No boot o awww-daemon pode estar vivo mas ainda sem o output registrado,
# então "awww query" ok não significa que "awww img" vai funcionar: em vez
# de só esperar o daemon responder, insiste no comando real até ele pegar.
for _ in {1..150}; do
    if awww img "$wp" \
        --resize crop \
        --transition-type grow \
        --transition-pos center \
        --transition-duration 1 >/dev/null 2>&1; then
        exit 0
    fi
    sleep 0.2
done
