#!/usr/bin/env bash
set -euo pipefail

WOFI_ARGS=(--dmenu --insensitive --prompt "Bluetooth" --cache-file /dev/null)

notify() {
    notify-send -a "Bluetooth" "$@" >/dev/null 2>&1 || true
}

ENABLE_LABEL="󰂱 Ativar Bluetooth"
DISABLE_LABEL="󰂲 Desativar Bluetooth"
PAIR_LABEL="󰂰 Procurar dispositivo novo"
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

        local icon="󰂱"
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

    printf '%s\n' "$PAIR_LABEL"
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

if [[ "$choice" == "$PAIR_LABEL" ]]; then
    notify "Procurando dispositivos Bluetooth..." "Isso leva uns 8 segundos."
    bluetoothctl --timeout 8 scan on >/dev/null 2>&1 || true

    paired_macs=" $(bluetoothctl devices Paired | awk '{print $2}' | tr '\n' ' ') "
    declare -A NEWMAC_BY_LABEL
    menu=""
    while IFS= read -r line; do
        [[ "$line" =~ ^Device\ ([0-9A-Fa-f:]+)\ (.+)$ ]] || continue
        mac="${BASH_REMATCH[1]}"
        name="${BASH_REMATCH[2]}"
        [[ "$paired_macs" == *" $mac "* ]] && continue
        label="󰂱 $name"
        NEWMAC_BY_LABEL["$label"]="$mac"
        menu+="$label"$'\n'
    done < <(bluetoothctl devices)

    if [[ -z "$menu" ]]; then
        notify "Nenhum dispositivo novo encontrado"
        exit 0
    fi

    pick="$(printf '%s' "$menu" | wofi --dmenu --insensitive --prompt "Parear dispositivo" --cache-file /dev/null)"
    [[ -z "$pick" ]] && exit 0

    new_mac="${NEWMAC_BY_LABEL[$pick]:-}"
    [[ -z "$new_mac" ]] && exit 0

    bluetoothctl agent NoInputNoOutput >/dev/null 2>&1 || true
    bluetoothctl default-agent >/dev/null 2>&1 || true

    if bluetoothctl pair "$new_mac" >/dev/null 2>&1; then
        bluetoothctl trust "$new_mac" >/dev/null 2>&1 || true
        if bluetoothctl connect "$new_mac" >/dev/null 2>&1; then
            notify "Pareado e conectado"
        else
            notify "Pareado" "Não foi possível conectar automaticamente."
        fi
    else
        notify "Falha ao parear"
    fi
    exit 0
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
