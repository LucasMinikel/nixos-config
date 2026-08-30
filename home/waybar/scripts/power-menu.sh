#!/usr/bin/env bash
set -euo pipefail

WOFI_ARGS=(--dmenu --insensitive --prompt "Bateria" --cache-file /dev/null)

notify() {
    notify-send -a "Bateria" "$@" >/dev/null 2>&1 || true
}

declare -A PROFILE_BY_LABEL

build_menu() {
    local current
    current="$(powerprofilesctl get 2>/dev/null || true)"

    local icon name profile
    while IFS= read -r profile; do
        [[ -z "$profile" ]] && continue
        case "$profile" in
            performance) icon="󰓅"; name="Desempenho" ;;
            balanced) icon="󰗑"; name="Equilibrado" ;;
            power-saver) icon="󰌪"; name="Economia de energia" ;;
            *) icon="󰗑"; name="$profile" ;;
        esac
        local mark=""
        [[ "$profile" == "$current" ]] && mark=" (atual)"
        local label="$icon $name$mark"
        PROFILE_BY_LABEL["$label"]="$profile"
        printf '%s\n' "$label"
    done < <(powerprofilesctl list 2>/dev/null | grep -oE '^\**\s*[a-z-]+:' | tr -d '*: ')
}

choice="$(build_menu | wofi "${WOFI_ARGS[@]}")"
[[ -z "$choice" ]] && exit 0

profile="${PROFILE_BY_LABEL[$choice]:-}"
[[ -z "$profile" ]] && exit 0

if powerprofilesctl set "$profile" >/dev/null 2>&1; then
    notify "Perfil de energia: $profile"
else
    notify "Falha ao mudar o perfil de energia"
fi
