#!/usr/bin/env bash
# Aguarda o daemon de wallpaper iniciar
sleep 1

WALLPAPER_DIR="$HOME/nixos-config/wallpapers"

# Pega um wallpaper aleatório da pasta
wp=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | shuf -n1)

if [[ -n "$wp" ]]; then
    awww img "$wp" \
        --transition-type grow \
        --transition-pos center \
        --transition-duration 1
fi
