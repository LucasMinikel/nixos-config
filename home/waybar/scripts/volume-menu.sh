#!/usr/bin/env bash
set -euo pipefail

WOFI_ARGS=(--dmenu --insensitive --prompt "Volume" --cache-file /dev/null)

notify() {
    notify-send -a "Volume" "$@" >/dev/null 2>&1 || true
}

MUTE_LABEL="󰝟 Mutar/Desmutar saída"
MIC_MUTE_LABEL="󰍭 Mutar/Desmutar microfone"
declare -A SINK_ID_BY_LABEL
declare -A SOURCE_ID_BY_LABEL

parse_devices() {
    local section="$1" icon="$2" map_name="$3"
    local -n map_ref="$map_name"
    local in_section=0
    while IFS= read -r line; do
        if [[ "$line" == *"├─ ${section}:"* ]]; then
            in_section=1
            continue
        elif [[ "$line" == *"├─"* || "$line" == *"└─"* ]]; then
            in_section=0
            continue
        fi
        [[ "$in_section" -eq 1 ]] || continue
        [[ "$line" =~ ([0-9]+)\.\ +(.+[^[:space:]])[[:space:]]+\[vol: ]] || continue
        local id="${BASH_REMATCH[1]}"
        local name="${BASH_REMATCH[2]}"
        local mark=""
        [[ "$line" == *"*"* ]] && mark=" (padrão)"
        local label="$icon $name$mark"
        map_ref["$label"]="$id"
        printf '%s\n' "$label"
    done < <(wpctl status)
}

build_menu() {
    printf '%s\n' "$MUTE_LABEL"
    for pct in 100 75 50 25 10 0; do
        printf '󰕾 Volume %s%%\n' "$pct"
    done
    parse_devices "Sinks" "󰓃" SINK_ID_BY_LABEL

    printf '%s\n' "$MIC_MUTE_LABEL"
    parse_devices "Sources" "󰍬" SOURCE_ID_BY_LABEL
}

choice="$(build_menu | wofi "${WOFI_ARGS[@]}")"
[[ -z "$choice" ]] && exit 0

if [[ "$choice" == "$MUTE_LABEL" ]]; then
    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    notify "Mudo alternado"
    exit 0
fi

if [[ "$choice" == "$MIC_MUTE_LABEL" ]]; then
    wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
    notify "Mudo do microfone alternado"
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
    exit 0
fi

source_id="${SOURCE_ID_BY_LABEL[$choice]:-}"
if [[ -n "$source_id" ]]; then
    wpctl set-default "$source_id"
    notify "Entrada de áudio alterada"
fi
