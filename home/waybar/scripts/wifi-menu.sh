#!/usr/bin/env bash
set -euo pipefail

WOFI_ARGS=(--dmenu --insensitive --prompt "Wi-Fi" --cache-file /dev/null)

notify() {
    notify-send -a "Wi-Fi" "$@" >/dev/null 2>&1 || true
}

ENABLE_LABEL="󰖩 Ativar Wi-Fi"
DISABLE_LABEL="󰖪 Desativar Wi-Fi"
FORGET_LABEL="󰆴 Esquecer rede salva"
HIDDEN_LABEL="󰐕 Conectar a rede oculta"
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

    printf '%s\n' "$FORGET_LABEL"
    printf '%s\n' "$HIDDEN_LABEL"
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

if [[ "$choice" == "$FORGET_LABEL" ]]; then
    declare -A CONN_NAME_BY_LABEL
    menu=""
    while IFS=: read -r name type; do
        [[ "$type" == "802-11-wireless" ]] || continue
        label="󰖩 $name"
        CONN_NAME_BY_LABEL["$label"]="$name"
        menu+="$label"$'\n'
    done < <(nmcli -t -f NAME,TYPE connection show)

    if [[ -z "$menu" ]]; then
        notify "Nenhuma rede salva"
        exit 0
    fi

    pick="$(printf '%s' "$menu" | wofi --dmenu --insensitive --prompt "Esquecer rede" --cache-file /dev/null)"
    [[ -z "$pick" ]] && exit 0

    conn_name="${CONN_NAME_BY_LABEL[$pick]:-}"
    [[ -z "$conn_name" ]] && exit 0

    if nmcli connection delete id "$conn_name" >/dev/null 2>&1; then
        notify "Rede \"$conn_name\" esquecida"
    else
        notify "Falha ao esquecer $conn_name"
    fi
    exit 0
fi

if [[ "$choice" == "$HIDDEN_LABEL" ]]; then
    hidden_ssid="$(wofi --dmenu --prompt "Nome da rede oculta" --cache-file /dev/null <<< "")"
    [[ -z "$hidden_ssid" ]] && exit 0

    hidden_password="$(wofi --dmenu --password --prompt "Senha (vazio se aberta)" --cache-file /dev/null <<< "")"

    if [[ -n "$hidden_password" ]]; then
        ok=$(nmcli device wifi connect "$hidden_ssid" password "$hidden_password" hidden yes >/dev/null 2>&1 && echo 1 || echo 0)
    else
        ok=$(nmcli device wifi connect "$hidden_ssid" hidden yes >/dev/null 2>&1 && echo 1 || echo 0)
    fi

    if [[ "$ok" == "1" ]]; then
        notify "Conectado a $hidden_ssid"
    else
        notify "Falha ao conectar a $hidden_ssid"
    fi
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
