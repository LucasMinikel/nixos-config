#!/usr/bin/env bash
set -euo pipefail

WALLPAPER_DIR="$HOME/nixos-config/wallpapers"
DEFAULT_WALLPAPER="$WALLPAPER_DIR/comic_original.png"

for _ in {1..20}; do
    if awww query >/dev/null 2>&1; then
        break
    fi
    sleep 0.2
done

if [[ -f "$DEFAULT_WALLPAPER" ]]; then
    wp="$DEFAULT_WALLPAPER"
else
    wp=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | shuf -n1)
fi

if [[ -n "$wp" ]]; then
    awww img "$wp" \
        --resize crop \
        --transition-type grow \
        --transition-pos center \
        --transition-duration 1
fi
