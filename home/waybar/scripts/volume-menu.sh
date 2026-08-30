#!/usr/bin/env bash
set -euo pipefail

WOFI_ARGS=(--dmenu --insensitive --prompt "Volume" --cache-file /dev/null)

notify() {
    notify-send -a "Volume" "$@" >/dev/null 2>&1 || true
}

MUTE_LABEL="󰝟 Mutar/Desmutar"
declare -A SINK_ID_BY_LABEL

build_menu() {
    printf '%s\n' "$MUTE_LABEL"
    for pct in 100 75 50 25 10 0; do
        printf '󰕾 Volume %s%%\n' "$pct"
    done

    local in_sinks=0
    while IFS= read -r line; do
        if [[ "$line" == *"├─ Sinks:"* ]]; then
            in_sinks=1
            continue
        elif [[ "$line" == *"├─"* || "$line" == *"└─"* ]]; then
            in_sinks=0
            continue
        fi
        [[ "$in_sinks" -eq 1 ]] || continue
        [[ "$line" =~ ([0-9]+)\.\ +(.+[^[:space:]])[[:space:]]+\[vol: ]] || continue
        local id="${BASH_REMATCH[1]}"
        local name="${BASH_REMATCH[2]}"
        local mark=""
        [[ "$line" == *"*"* ]] && mark=" (padrão)"
        local label="󰓃 $name$mark"
        SINK_ID_BY_LABEL["$label"]="$id"
        printf '%s\n' "$label"
    done < <(wpctl status)
}

choice="$(build_menu | wofi "${WOFI_ARGS[@]}")"
[[ -z "$choice" ]] && exit 0

if [[ "$choice" == "$MUTE_LABEL" ]]; then
    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    notify "Mudo alternado"
    exit 0
fi

if [[ "$choice" =~ ^󰕾\ Volume\ ([0-9]+)%$ ]]; then
    pct="${BASH_REMATCH[1]}"
    wpctl set-volume @DEFAULT_AUDIO_SINK@ "${pct}%"
    notify "Volume: ${pct}%"
    exit 0
fi

sink_id="${SINK_ID_BY_LABEL[$choice]:-}"
if [[ -n "$sink_id" ]]; then
    wpctl set-default "$sink_id"
    notify "Saída de áudio alterada"
fi
