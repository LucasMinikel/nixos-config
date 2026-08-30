#!/usr/bin/env bash
set -euo pipefail

WOFI_ARGS=(--dmenu --insensitive --prompt "Bluetooth" --cache-file /dev/null)

notify() {
    notify-send -a "Bluetooth" "$@" >/dev/null 2>&1 || true
}

ENABLE_LABEL="󰂯 Ativar Bluetooth"
DISABLE_LABEL="󰂲 Desativar Bluetooth"
MANAGER_LABEL="󰍜 Abrir gerenciador completo (parear novo dispositivo)"
declare -A MAC_BY_LABEL
declare -A CONNECTED_BY_LABEL

powered() {
    bluetoothctl show | grep -q "Powered: yes"
}

build_menu() {
    if powered; then
        printf '%s\n' "$DISABLE_LABEL"
    else
        printf '%s\n' "$ENABLE_LABEL"
        printf '%s\n' "$MANAGER_LABEL"
        return
    fi

    while IFS= read -r line; do
        [[ "$line" =~ ^Device\ ([0-9A-Fa-f:]+)\ (.+)$ ]] || continue
        local mac="${BASH_REMATCH[1]}"
        local name="${BASH_REMATCH[2]}"

        local connected=""
        if bluetoothctl info "$mac" | grep -q "Connected: yes"; then
            connected=1
        fi

        local icon="󰂯"
        local mark=""
        if [[ -n "$connected" ]]; then
            icon="󰂱"
            mark=" (conectado)"
        fi

        local label="$icon $name$mark"
        MAC_BY_LABEL["$label"]="$mac"
        [[ -n "$connected" ]] && CONNECTED_BY_LABEL["$label"]=1
        printf '%s\n' "$label"
    done < <(bluetoothctl devices Paired)

    printf '%s\n' "$MANAGER_LABEL"
}

choice="$(build_menu | wofi "${WOFI_ARGS[@]}")"
[[ -z "$choice" ]] && exit 0

if [[ "$choice" == "$DISABLE_LABEL" ]]; then
    bluetoothctl power off >/dev/null 2>&1
    notify "Bluetooth desativado"
    exit 0
elif [[ "$choice" == "$ENABLE_LABEL" ]]; then
    bluetoothctl power on >/dev/null 2>&1
    notify "Bluetooth ativado"
    exit 0
fi

if [[ "$choice" == "$MANAGER_LABEL" ]]; then
    exec blueman-manager
fi

mac="${MAC_BY_LABEL[$choice]:-}"
[[ -z "$mac" ]] && exit 0

if [[ -n "${CONNECTED_BY_LABEL[$choice]:-}" ]]; then
    if bluetoothctl disconnect "$mac" >/dev/null 2>&1; then
        notify "Desconectado"
    else
        notify "Falha ao desconectar"
    fi
else
    if bluetoothctl connect "$mac" >/dev/null 2>&1; then
        notify "Conectado"
    else
        notify "Falha ao conectar"
    fi
fi
