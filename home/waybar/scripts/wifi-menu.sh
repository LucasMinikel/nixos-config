#!/usr/bin/env bash
set -euo pipefail

WOFI_ARGS=(--dmenu --insensitive --prompt "Wi-Fi" --cache-file /dev/null)

notify() {
    notify-send -a "Wi-Fi" "$@" >/dev/null 2>&1 || true
}

ENABLE_LABEL="󰖩 Ativar Wi-Fi"
DISABLE_LABEL="󰖪 Desativar Wi-Fi"
declare -A SSID_BY_LABEL
declare -A INUSE_BY_LABEL

build_menu() {
    if [[ "$(nmcli radio wifi)" == "enabled" ]]; then
        printf '%s\n' "$DISABLE_LABEL"
    else
        printf '%s\n' "$ENABLE_LABEL"
        return
    fi

    local seen=" "
    while IFS=: read -r inuse ssid signal security; do
        [[ -z "$ssid" ]] && continue
        [[ "$seen" == *" $ssid "* ]] && continue
        seen+="$ssid "

        local icon="󰤨"
        if (( signal < 40 )); then icon="󰤟"
        elif (( signal < 70 )); then icon="󰤢"
        fi

        local mark=""
        [[ "$inuse" == "*" ]] && mark=" (conectado)"

        local lock=""
        [[ -n "$security" ]] && lock=" 󰌾"

        local label="$icon $ssid ($signal%)$lock$mark"
        SSID_BY_LABEL["$label"]="$ssid"
        [[ "$inuse" == "*" ]] && INUSE_BY_LABEL["$label"]=1
        printf '%s\n' "$label"
    done < <(nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list --rescan yes 2>/dev/null | sort -t: -k3 -rn)
}

choice="$(build_menu | wofi "${WOFI_ARGS[@]}")"
[[ -z "$choice" ]] && exit 0

if [[ "$choice" == "$DISABLE_LABEL" ]]; then
    nmcli radio wifi off
    notify "Wi-Fi desativado"
    exit 0
elif [[ "$choice" == "$ENABLE_LABEL" ]]; then
    nmcli radio wifi on
    notify "Wi-Fi ativado"
    exit 0
fi

ssid="${SSID_BY_LABEL[$choice]:-}"
[[ -z "$ssid" ]] && exit 0

if [[ -n "${INUSE_BY_LABEL[$choice]:-}" ]]; then
    nmcli connection down id "$ssid" >/dev/null 2>&1 || true
    notify "Desconectado de $ssid"
    exit 0
fi

if nmcli -t -f NAME connection show | grep -Fxq "$ssid"; then
    if nmcli connection up id "$ssid" >/dev/null 2>&1; then
        notify "Conectado a $ssid"
    else
        notify "Falha ao conectar a $ssid"
    fi
    exit 0
fi

password="$(wofi --dmenu --password --prompt "Senha de $ssid" --cache-file /dev/null <<< "")"
[[ -z "$password" ]] && exit 0

if nmcli device wifi connect "$ssid" password "$password" >/dev/null 2>&1; then
    notify "Conectado a $ssid"
else
    notify "Falha ao conectar a $ssid" "Verifique a senha."
fi
