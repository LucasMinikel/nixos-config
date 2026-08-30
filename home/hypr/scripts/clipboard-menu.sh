#!/usr/bin/env bash
set -euo pipefail

selection="$(cliphist list | wofi --dmenu --insensitive --prompt "Clipboard" --cache-file /dev/null)"
[[ -z "$selection" ]] && exit 0

printf '%s' "$selection" | cliphist decode | wl-copy
